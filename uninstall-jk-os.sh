#!/bin/sh
# Undo bootstrap-jk-os.sh: sh ./uninstall-jk-os.sh [--purge]
# POSIX sh intentionally, like the bootstrap: it must run from jk_os's plain sh.
#
# By default it removes what hooks the setup into your terminals and consoles:
#   - the marked "dotfiles shell" block in ~/.profile
#   - the Dotfiles Konsole profile and color scheme (and Konsole's default
#     profile setting, if it points at them)
#   - ~/.local/bin/dotfiles-shell
#   - the config symlinks into this repo (~/.zshrc, ~/.p10k.zsh, nvim, herdr,
#     ...); where the bootstrap moved an earlier file aside, the oldest copy in
#     ~/.dotfiles-backup is put back
# --purge also deletes what the bootstrap downloaded and built: the private
# environment (~/.local/share/dotfiles), oh-my-zsh, the Powerlevel10k caches,
# the FiraCode font, the Neovim from ~/.local/opt/nvim, Neovim's plugins and
# the coc extensions.
#
# Never touched: ~/.zshrc.local (your secrets), ~/.dotfiles-backup, and the
# tools with their own uninstallers (rust, herdr, claude).
set -eu

purge=0
for arg do
  case "$arg" in
    --purge) purge=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) printf 'Unsupported option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
say() { printf '  - %s\n' "$*"; }

# ~/.profile: drop the marked block, writing through a symlinked file.
profile="$HOME/.profile"
if [ -f "$profile" ] && grep -q '^# >>> dotfiles shell >>>$' "$profile"; then
  tmp_profile="$profile.dotfiles.$$"
  awk '/^# >>> dotfiles shell >>>$/ { skip = 1 } !skip { print } /^# <<< dotfiles shell <<<$/ { skip = 0 }' \
    "$profile" > "$tmp_profile"
  cat "$tmp_profile" > "$profile"
  rm -f "$tmp_profile"
  say "removed the dotfiles shell block from ~/.profile"
fi

konsole="$HOME/.local/share/konsole"
for f in "$konsole/Dotfiles.profile" "$konsole/Dotfiles.colorscheme" "$HOME/.local/bin/dotfiles-shell"; do
  if [ -e "$f" ] || [ -L "$f" ]; then
    rm -f "$f"
    say "removed ${f#"$HOME"/}"
  fi
done
konsolerc="$HOME/.config/konsolerc"
if [ -f "$konsolerc" ] && grep -q '^DefaultProfile=Dotfiles.profile$' "$konsolerc"; then
  grep -v '^DefaultProfile=Dotfiles.profile$' "$konsolerc" > "$konsolerc.dotfiles.$$"
  cat "$konsolerc.dotfiles.$$" > "$konsolerc"
  rm -f "$konsolerc.dotfiles.$$"
  say "Konsole's default profile is its own again"
fi

# The links install.sh makes (link_configs); only links into this repo go.
for rel in .zshrc .zshenv .p10k.zsh \
    .config/nvim/init.vim .config/nvim/coc-settings.json .config/nvim/cscope.vim \
    .config/herdr/config.toml .local/bin/herdr-usage-watch .local/bin/dotfiles-copy; do
  dest="$HOME/$rel"
  [ -L "$dest" ] || continue
  case "$(readlink "$dest")" in "$repo"/*) ;; *) continue ;; esac
  rm -f "$dest"
  restored=""
  for backup in "$HOME"/.dotfiles-backup/*/"$rel"; do   # oldest first: the original
    if [ -e "$backup" ] || [ -L "$backup" ]; then
      cp -a "$backup" "$dest"
      restored=" (restored ${backup#"$HOME"/})"
      break
    fi
  done
  say "unlinked ~/$rel$restored"
done
rmdir "$HOME/.config/nvim" "$HOME/.config/herdr" 2>/dev/null || true

if [ "$purge" = 1 ]; then
  nvim_link="$HOME/.local/bin/nvim"
  if [ -L "$nvim_link" ] && [ "$(readlink "$nvim_link")" = "$HOME/.local/opt/nvim/bin/nvim" ]; then
    rm -f "$nvim_link"
  fi
  data="${XDG_DATA_HOME:-$HOME/.local/share}"
  cache="${XDG_CACHE_HOME:-$HOME/.cache}"
  for d in "$HOME/.local/share/dotfiles" "$HOME/.oh-my-zsh" "$HOME/.local/opt/nvim" \
      "$HOME/.local/share/fonts/FiraCode" "$data/nvim/plugged" "$data/nvim/site/autoload/plug.vim" \
      "$HOME/.config/coc" "$cache/gitstatus" "$cache"/p10k-*; do
    if [ -e "$d" ] || [ -L "$d" ]; then
      rm -rf "$d"
      say "deleted ${d#"$HOME"/}"
    fi
  done
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f >/dev/null 2>&1 || true
fi

printf '\n%s\n' 'Done. New terminals and console logins use the plain jk_os shell.' \
  'Kept: ~/.zshrc.local and ~/.dotfiles-backup.'
if [ "$purge" = 0 ]; then
  printf '%s\n' 'The installed tools are still there: sh ./uninstall-jk-os.sh --purge deletes them.'
else
  printf '%s\n' 'Not removed (their own uninstallers): rust (rustup self uninstall), herdr, claude, ~/herdr-agent-quota.'
fi
