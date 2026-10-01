#!/usr/bin/env bash
# The tools the dotfiles need that jk_os doesn't ship, installed for this
# user only: no package manager, no virtual environment. Each one goes into
# ~/.local/opt/<name> (built from source, or the project's own release build
# where that is how it is distributed) with its programs linked into
# ~/.local/bin; Python packages go into ~/.local with the system's pip
# (pip install --user). Every download is checked against a SHA-256 pinned
# here (or, for git, a commit). Rerunning skips what is already installed at
# the pinned version.
#
# Uses jk_os's own toolchain: gcc, make, autotools, cmake, ninja,
# pkg-config, python3/pip, git, curl, and its libraries' headers (ncurses,
# Wayland).
set -euo pipefail

OPT="$HOME/.local/opt"
BIN="$HOME/.local/bin"
mkdir -p "$OPT" "$BIN"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
JOBS=$(nproc 2>/dev/null || echo 2)

case "$(uname -m)" in
  x86_64) arch=x64 goarch=amd64 ;;
  aarch64|arm64) arch=arm64 goarch=arm64 ;;
  *) echo "unsupported architecture $(uname -m)" >&2; exit 1 ;;
esac

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }

# current <name> <version>: true if ~/.local/opt/<name> already has it.
current() { [[ "$(cat "$OPT/$1/.dotfiles-version" 2>/dev/null)" == "$2" ]]; }
# done_ <name> <version>: record the installed version.
done_() { echo "$2" > "$OPT/$1/.dotfiles-version"; ok "$1 $2"; }
# fetch <url> <sha256> <file>: download and verify.
fetch() {
  curl -fL --retry 3 --connect-timeout 20 -o "$3" "$1"
  [[ "$(sha256sum "$3" | cut -d' ' -f1)" == "$2" ]] || { echo "checksum mismatch: $1" >&2; exit 1; }
}
# link <name> <program>...: ~/.local/bin/<program> -> ~/.local/opt/<name>/bin/<program>
link() {
  local name="$1" p; shift
  for p in "$@"; do ln -sfn "$OPT/$name/bin/$p" "$BIN/$p"; done
}
# fresh <name>: an empty ~/.local/opt/<name> to install into.
fresh() { rm -rf "$OPT/$1"; mkdir -p "$OPT/$1"; }

# ---------------------------------------------------------------- zsh
ZSH_V=5.9.2 ZSH_SHA=36fa734374b44783582cec09bcd67822e2f992c779ec1624ab5596df078d2f81
if ! current zsh "$ZSH_V"; then
  info "Building zsh $ZSH_V"
  fetch "https://www.zsh.org/pub/zsh-$ZSH_V.tar.xz" "$ZSH_SHA" "$tmp/zsh.tar.xz"
  tar -xJf "$tmp/zsh.tar.xz" -C "$tmp"
  fresh zsh
  (cd "$tmp/zsh-$ZSH_V" && ./configure --prefix="$OPT/zsh" --enable-multibyte \
     --with-term-lib="ncursesw" --enable-etcdir="$OPT/zsh/etc" >/dev/null &&
   make -j"$JOBS" >/dev/null && make install.bin install.modules install.fns >/dev/null)
  link zsh zsh
  done_ zsh "$ZSH_V"
fi

# ---------------------------------------------------------------- universal-ctags
CTAGS_V=6.2.1 CTAGS_SHA=2c63efe9e0e083dc50e6fdd8c5414781cc8873d8c8940cf553c01870ed962f8c
if ! current ctags "$CTAGS_V"; then
  info "Building universal-ctags $CTAGS_V"
  fetch "https://github.com/universal-ctags/ctags/releases/download/v$CTAGS_V/universal-ctags-$CTAGS_V.tar.gz" \
    "$CTAGS_SHA" "$tmp/ctags.tar.gz"
  tar -xzf "$tmp/ctags.tar.gz" -C "$tmp"
  fresh ctags
  (cd "$tmp/universal-ctags-$CTAGS_V" && ./configure --prefix="$OPT/ctags" --disable-xml \
     --disable-json --disable-yaml --disable-seccomp >/dev/null &&
   make -j"$JOBS" >/dev/null && make install >/dev/null)
  link ctags ctags readtags
  done_ ctags "$CTAGS_V"
fi

# ---------------------------------------------------------------- cscope
CSCOPE_V=15.9 CSCOPE_SHA=e8bc6cd29bb90e1eb7447a23a2a419f719ab8fe96dd10f6e289accdb428d2a1f
if ! current cscope "$CSCOPE_V"; then
  info "Building cscope $CSCOPE_V"
  # Debian mirrors the upstream source (orig), without its packaging patches.
  fetch "https://deb.debian.org/debian/pool/main/c/cscope/cscope_$CSCOPE_V.orig.tar.xz" \
    "$CSCOPE_SHA" "$tmp/cscope.tar.xz"
  tar -xJf "$tmp/cscope.tar.xz" -C "$tmp"
  fresh cscope
  # cscope predates GCC's default C23 mode. It links -lncurses, and jk_os's
  # ncurses is the wide-character libncursesw: a linker script stands in.
  mkdir -p "$tmp/curses"
  echo 'INPUT(-lncursesw)' > "$tmp/curses/libncurses.so"
  (cd "$tmp/cscope-$CSCOPE_V" && CC=gcc CFLAGS="-O2 -std=gnu17" LDFLAGS="-L$tmp/curses" \
     ./configure --prefix="$OPT/cscope" --with-ncurses=/usr >/dev/null &&
   make -j"$JOBS" >/dev/null && make install >/dev/null)
  link cscope cscope ocs
  done_ cscope "$CSCOPE_V"
fi

# ---------------------------------------------------------------- Python packages
# With jk_os's Python, into ~/.local (pip's --user scheme). Meson builds
# wl-clipboard below.
info "Python packages: pynvim, pre-commit, meson (pip install --user)"
python3 -m pip install --user --quiet --upgrade --no-warn-script-location \
  "pynvim==0.6.0" "pre-commit==4.6.2" "meson==1.12.1"
ok "pynvim, pre-commit, meson"

# ---------------------------------------------------------------- wl-clipboard
WLC_V=2.3.0 WLC_COMMIT=67a7b937895bceec1ae5ccebb10216f63f70ca1b
if ! current wl-clipboard "$WLC_V"; then
  info "Building wl-clipboard $WLC_V"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "v$WLC_V" \
    https://github.com/bugaevc/wl-clipboard.git "$tmp/wl-clipboard"
  [[ "$(git -C "$tmp/wl-clipboard" rev-parse HEAD)" == "$WLC_COMMIT" ]] \
    || { echo "wl-clipboard v$WLC_V is not commit $WLC_COMMIT" >&2; exit 1; }
  fresh wl-clipboard
  "$BIN/meson" setup "$tmp/wl-build" "$tmp/wl-clipboard" --prefix "$OPT/wl-clipboard" \
    --buildtype release -Dfishcompletiondir=no \
    -Dzshcompletiondir="$OPT/wl-clipboard/share/zsh/site-functions" >/dev/null
  ninja -C "$tmp/wl-build" >/dev/null
  ninja -C "$tmp/wl-build" install >/dev/null
  link wl-clipboard wl-copy wl-paste
  done_ wl-clipboard "$WLC_V"
fi

# ---------------------------------------------------------------- fzf
# fzf is written in Go and released as one static program per platform.
FZF_V=0.74.4
case "$goarch" in
  amd64) FZF_SHA=05e6813a337cc722c3ed07e54a764b75cc5d671e2e60459db0ba696ee5fa7504 ;;
  arm64) FZF_SHA=5d673b849f494f0d64ec471d8640b153ca8849e3846a31da17abdcfce8df6b46 ;;
esac
if ! current fzf "$FZF_V"; then
  info "Installing fzf $FZF_V"
  fetch "https://github.com/junegunn/fzf/releases/download/v$FZF_V/fzf-$FZF_V-linux_$goarch.tar.gz" \
    "$FZF_SHA" "$tmp/fzf.tar.gz"
  fresh fzf
  mkdir -p "$OPT/fzf/bin"
  tar -xzf "$tmp/fzf.tar.gz" -C "$OPT/fzf/bin" fzf
  link fzf fzf
  done_ fzf "$FZF_V"
fi

# ---------------------------------------------------------------- Node.js
# Node.js's own Linux build (coc.nvim's runtime), the current LTS.
NODE_V=24.21.0
case "$arch" in
  x64)   NODE_SHA=fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6 ;;
  arm64) NODE_SHA=6ad1325edbdb5649c379b75a237147a666c95d4f9ae8d340fef2d1575d289ad2 ;;
esac
if ! current node "$NODE_V"; then
  info "Installing Node.js $NODE_V"
  fetch "https://nodejs.org/dist/v$NODE_V/node-v$NODE_V-linux-$arch.tar.xz" "$NODE_SHA" "$tmp/node.tar.xz"
  fresh node
  tar -xJf "$tmp/node.tar.xz" -C "$OPT/node" --strip-components=1
  link node node npm npx corepack
  done_ node "$NODE_V"
fi

# ---------------------------------------------------------------- Rust, bat
# rustup (herdr-agent-quota needs Rust too), then bat from source with cargo.
if ! command -v cargo >/dev/null && [[ ! -x "$HOME/.cargo/bin/cargo" ]]; then
  info "Installing Rust (rustup)"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path >/dev/null
fi
export PATH="$HOME/.cargo/bin:$PATH"
BAT_V=0.26.1
if ! current bat "$BAT_V"; then
  info "Building bat $BAT_V (cargo)"
  fresh bat
  cargo install --quiet --locked --root "$OPT/bat" "bat@$BAT_V"
  link bat bat
  done_ bat "$BAT_V"
fi

# ---------------------------------------------------------------- xdg-open
# Plasma opens URLs and files itself (kioclient); jk_os has no xdg-utils.
if ! command -v xdg-open >/dev/null; then
  cat > "$BIN/xdg-open" <<'EOF'
#!/bin/sh
exec kioclient exec "$@"
EOF
  chmod +x "$BIN/xdg-open"
  ok "xdg-open (kioclient)"
fi
