#!/usr/bin/env bash
# Bootstrap a new machine with my zsh + neovim + herdr setup.
#
# Usage:
#   ./install.sh                 # everything
#   ./install.sh --links-only    # only (re)link config files, install nothing
#   ./install.sh --no-deps       # skip system packages (apt/dnf/pacman/brew)
#   ./install.sh --no-fonts      # skip the FiraCode Nerd Font
#   ./install.sh --herdr-plugins # only (re)install herdr plugins (run inside herdr)
#
# Config files are symlinked, so editing ~/.config/nvim/init.vim edits the repo.
# Anything already in the way is moved to ~/.dotfiles-backup/<timestamp>/.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
BIN_DIR="$HOME/.local/bin"
BACKED_UP=0
NVIM_MIN_VERSION="0.10.0"

DO_DEPS=1
DO_FONTS=1
DO_TOOLS=1
DO_LINKS=1
DO_PLUGINS=1

while (($# > 0)); do
  case "$1" in
    --links-only)    DO_DEPS=0; DO_FONTS=0; DO_TOOLS=0; DO_PLUGINS=0 ;;
    --no-deps)       DO_DEPS=0 ;;
    --no-fonts)      DO_FONTS=0 ;;
    --herdr-plugins) DO_DEPS=0; DO_FONTS=0; DO_TOOLS=0; DO_LINKS=0; DO_PLUGINS=2 ;;
    -h|--help)       sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; exit 1 ;;
  esac
  shift
done

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
ARCH="$(uname -m)"

sudo_cmd() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# version_ge A B -> true when A >= B
version_ge() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" = "$2" ]
}

# link SRC DEST: symlink DEST -> SRC, backing up whatever was there before
link() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "already linked $dest"
    return
  fi
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    local backup="$BACKUP_DIR/${dest#"$HOME"/}"
    mkdir -p "$(dirname "$backup")"
    mv "$dest" "$backup"
    BACKED_UP=1
    warn "backed up existing $dest -> $BACKUP_DIR"
  fi
  ln -s "$src" "$dest"
  ok "linked $dest"
}

ORIG_PATH="$PATH"
export PATH="$BIN_DIR:$HOME/.cargo/bin:$PATH"

# ------------------------------------------------------------
# 1. System packages
# ------------------------------------------------------------

install_deps() {
  info "Installing system packages"
  if has apt-get; then
    sudo_cmd apt-get update
    sudo_cmd apt-get install -y \
      git curl wget unzip tar build-essential pkg-config \
      ripgrep fd-find fzf universal-ctags cscope clangd \
      nodejs npm python3 xclip wl-clipboard fontconfig zsh bat
    # Debian/Ubuntu ship fd as "fdfind"
    # ...and bat as "batcat"
    mkdir -p "$BIN_DIR"
    if has fdfind && ! has fd; then ln -sf "$(command -v fdfind)" "$BIN_DIR/fd"; fi
    if has batcat && ! has bat; then ln -sf "$(command -v batcat)" "$BIN_DIR/bat"; fi
  elif has dnf; then
    sudo_cmd dnf install -y \
      git curl wget unzip tar gcc gcc-c++ make pkgconf \
      ripgrep fd-find fzf ctags cscope clang-tools-extra \
      nodejs npm python3 xclip wl-clipboard fontconfig zsh bat
  elif has pacman; then
    sudo_cmd pacman -Sy --needed --noconfirm \
      git curl wget unzip tar base-devel \
      ripgrep fd fzf ctags cscope clang \
      nodejs npm python xclip wl-clipboard fontconfig zsh bat
  elif has brew; then
    brew install git curl wget ripgrep fd fzf universal-ctags cscope llvm node python zsh bat
  else
    warn "no supported package manager found; install git, curl, ripgrep, fd, fzf, ctags, node, npm yourself"
  fi

  # coc.nvim needs node >= 16
  if has node; then
    local node_major
    node_major="$(node -v | sed 's/^v//; s/\..*//')"
    [ "$node_major" -ge 16 ] || warn "node $(node -v) is too old for coc.nvim (need >= 16)"
  fi
}

# ------------------------------------------------------------
# 2. Tools: neovim, rust, herdr
# ------------------------------------------------------------

install_neovim() {
  if has nvim; then
    local v
    v="$(nvim --version | head -1 | sed 's/^NVIM v//; s/-.*//')"
    if version_ge "$v" "$NVIM_MIN_VERSION"; then
      ok "neovim $v already installed"
      return
    fi
    warn "neovim $v is older than $NVIM_MIN_VERSION, installing a newer one to ~/.local"
  fi

  info "Installing neovim (latest stable release)"
  if [ "$OS" = "Darwin" ]; then
    brew install neovim
    return
  fi
  local asset
  case "$ARCH" in
    x86_64)        asset="nvim-linux-x86_64" ;;
    aarch64|arm64) asset="nvim-linux-arm64" ;;
    *) die "no prebuilt neovim for $ARCH; install it manually" ;;
  esac
  local tmp
  tmp="$(mktemp -d)"
  curl -fL "https://github.com/neovim/neovim/releases/latest/download/${asset}.tar.gz" -o "$tmp/nvim.tar.gz"
  rm -rf "$HOME/.local/opt/nvim"
  mkdir -p "$HOME/.local/opt" "$BIN_DIR"
  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
  mv "$tmp/$asset" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$BIN_DIR/nvim"
  rm -rf "$tmp"
  ok "neovim installed to ~/.local/opt/nvim"
}

install_rust() {
  # Needed to build the herdr-agent-quota plugin
  if has cargo; then
    ok "rust/cargo already installed"
    return
  fi
  info "Installing rust (rustup)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  # shellcheck disable=SC1091
  . "$HOME/.cargo/env"
}

install_zsh() {
  info "Setting up zsh + oh-my-zsh"
  has zsh || die "zsh is not installed (run without --no-deps, or install it yourself)"

  local omz="$HOME/.oh-my-zsh"
  if [ -d "$omz" ]; then
    ok "oh-my-zsh already installed"
  else
    # KEEP_ZSHRC: our zshrc gets linked afterwards; RUNZSH/CHSH: don't take over this script
    ZSH="$omz" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "oh-my-zsh installed"
  fi

  local custom="$omz/custom" name url
  while read -r name url; do
    if [ -d "$custom/$name" ]; then
      ok "$name already installed"
    else
      git clone --depth=1 "$url" "$custom/$name" >/dev/null 2>&1 && ok "$name installed" \
        || warn "failed to clone $url"
    fi
  done <<EOF
themes/powerlevel10k https://github.com/romkatv/powerlevel10k.git
plugins/fzf-tab https://github.com/Aloxaf/fzf-tab.git
plugins/zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
plugins/zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
plugins/sshinfo https://github.com/SckyzO/zsh-sshinfo.git
EOF

  if [ "$(basename "${SHELL:-}")" != "zsh" ]; then
    chsh -s "$(command -v zsh)" && ok "default shell changed to zsh (log out and back in)" \
      || warn "couldn't change your shell; run: chsh -s $(command -v zsh)"
  fi
}

install_herdr() {
  if has herdr; then
    ok "herdr $(herdr --version 2>/dev/null | awk '{print $2}') already installed"
    return
  fi
  info "Installing herdr"
  curl -fsSL https://herdr.dev/install.sh | sh
  has herdr || die "herdr install finished but 'herdr' is not on PATH (expected in $BIN_DIR)"
}

install_fonts() {
  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    ok "FiraCode Nerd Font already installed"
    return
  fi
  info "Installing FiraCode Nerd Font"
  if [ "$OS" = "Darwin" ]; then
    brew install --cask font-fira-code-nerd-font
    return
  fi
  local dir="$HOME/.local/share/fonts/FiraCode" tmp
  tmp="$(mktemp -d)"
  curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -o "$tmp/FiraCode.zip"
  mkdir -p "$dir"
  unzip -oq "$tmp/FiraCode.zip" -d "$dir"
  rm -rf "$tmp"
  fc-cache -f "$dir" >/dev/null
  ok "font installed; select 'FiraCode Nerd Font' in your terminal"
}

# ------------------------------------------------------------
# 3. Config links
# ------------------------------------------------------------

link_configs() {
  info "Linking config files"
  link "$DOTFILES/zsh/zshrc"              "$HOME/.zshrc"
  link "$DOTFILES/zsh/zshenv"             "$HOME/.zshenv"
  link "$DOTFILES/zsh/p10k.zsh"           "$HOME/.p10k.zsh"
  if [ ! -e "$HOME/.zshrc.local" ]; then
    cp "$DOTFILES/zsh/zshrc.local.example" "$HOME/.zshrc.local"
    chmod 600 "$HOME/.zshrc.local"
    ok "created ~/.zshrc.local (machine-specific settings and secrets go here)"
  fi
  link "$DOTFILES/nvim/init.vim"          "$HOME/.config/nvim/init.vim"
  link "$DOTFILES/nvim/coc-settings.json" "$HOME/.config/nvim/coc-settings.json"
  link "$DOTFILES/nvim/cscope.vim"        "$HOME/.config/nvim/cscope.vim"
  link "$DOTFILES/herdr/config.toml"      "$HOME/.config/herdr/config.toml"
  link "$DOTFILES/bin/herdr-usage-watch"  "$BIN_DIR/herdr-usage-watch"
}

# ------------------------------------------------------------
# 4. Neovim plugins (vim-plug + coc extensions)
# ------------------------------------------------------------

install_nvim_plugins() {
  info "Installing neovim plugins"
  local plug="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
  if [ ! -f "$plug" ]; then
    curl -fLo "$plug" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    ok "vim-plug installed"
  fi
  # Errors from not-yet-installed plugins during this first run are expected
  nvim --headless -c 'PlugInstall --sync' -c 'qall' >/dev/null 2>&1 || true
  ok "vim-plug plugins installed"

  if has npm; then
    local ext_dir="$HOME/.config/coc/extensions"
    mkdir -p "$ext_dir"
    cp "$DOTFILES/nvim/coc-extensions.json" "$ext_dir/package.json"
    (cd "$ext_dir" && npm install --global-style --ignore-scripts --no-bin-links \
      --no-package-lock --omit=dev --silent) \
      && ok "coc extensions installed" \
      || warn "coc extension install failed; run :CocUpdate inside nvim"
  else
    warn "npm not found; skipping coc extensions"
  fi
}

# ------------------------------------------------------------
# 5. Herdr plugins + integrations
# ------------------------------------------------------------

herdr_server_running() {
  herdr status server 2>/dev/null | grep -q '^status: running'
}

install_herdr_plugins() {
  info "Installing herdr plugins"

  if herdr plugin list 2>/dev/null | grep -q "herdr-nvim"; then
    ok "herdr-nvim already installed"
  else
    herdr plugin install ChmaraX/herdr-nvim -y && ok "herdr-nvim installed" \
      || warn "herdr-nvim install failed"
  fi

  if has claude; then
    herdr integration install claude >/dev/null && ok "herdr claude integration installed" \
      || warn "herdr claude integration failed"
  fi
  if has codex; then
    herdr integration install codex >/dev/null && ok "herdr codex integration installed" \
      || warn "herdr codex integration failed"
  fi

  # herdr-agent-quota: its installer invokes plugin actions, which needs a running server
  local quota="$HOME/herdr-agent-quota"
  if [ ! -d "$quota/.git" ]; then
    git clone https://github.com/levi-qiao/herdr-agent-quota.git "$quota"
  fi
  if ! herdr_server_running; then
    warn "herdr server is not running: start 'herdr', then run '$DOTFILES/install.sh --herdr-plugins' in a pane to finish herdr-agent-quota"
    return
  fi
  local cfg
  cfg="$(herdr plugin config-dir herdr-agent-quota 2>/dev/null || true)"
  if [ -n "$cfg" ]; then
    mkdir -p "$cfg"
    cp "$DOTFILES"/herdr/plugin-config/herdr-agent-quota/* "$cfg/"
  fi
  (cd "$quota" && ./install.sh \
      --agent "$(sed 's/^only,//' "$DOTFILES/herdr/plugin-config/herdr-agent-quota/agents")" \
      --sidebar-layout "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/sidebar-layout")" \
      --row-gap "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/row-gap")" \
      --quota-percent "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/quota-percent")" \
      --fields "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/fields")" \
      --agent-order "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/agent-order")" \
      --low-quota-alert "$(cat "$DOTFILES/herdr/plugin-config/herdr-agent-quota/low-quota-alert")") \
    && ok "herdr-agent-quota installed" \
    || warn "herdr-agent-quota install failed; rerun '$quota/install.sh' manually"

  # The quota installer may rewrite config.toml in place of our symlink; restore it
  link "$DOTFILES/herdr/config.toml" "$HOME/.config/herdr/config.toml"
  herdr server reload-config >/dev/null 2>&1 || true
}

# ------------------------------------------------------------
# Run
# ------------------------------------------------------------

((DO_DEPS))  && install_deps
if ((DO_TOOLS)); then
  install_zsh
  install_neovim
  install_rust
  install_herdr
fi
((DO_FONTS)) && install_fonts
((DO_LINKS)) && link_configs
((DO_PLUGINS == 1)) && install_nvim_plugins
((DO_PLUGINS)) && install_herdr_plugins

info "Done"
case ":$ORIG_PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "add $BIN_DIR to your PATH" ;;
esac
((BACKED_UP)) && warn "previous configs saved in $BACKUP_DIR"
exit 0
