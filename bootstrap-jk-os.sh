#!/bin/sh
# Run on the booted jk_os system: sh ./bootstrap-jk-os.sh [install.sh flags]
# POSIX sh intentionally: the base image has BusyBox ash, but no Bash.
set -eu

case "${1:-}" in
  -h|--help)
    printf '%s\n' 'Usage: sh ./bootstrap-jk-os.sh [--no-fonts] [--links-only] [--herdr-plugins] [--zsh-only]' \
      'Installs a private tool environment under ~/.local/share/dotfiles.' \
      'Run as your desktop user on the booted OS, not against its source/rootfs tree.'
    exit 0 ;;
esac
for arg do
  case "$arg" in
    --no-fonts|--links-only|--herdr-plugins|--zsh-only|--no-chsh|--no-deps) ;;
    *) printf 'Unsupported option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

repo=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
prefix="$HOME/.local/share/dotfiles/env"
mamba="$HOME/.local/share/dotfiles/micromamba"
export MAMBA_ROOT_PREFIX="$HOME/.local/share/dotfiles/mamba"
# A host Python configuration must not redirect the private Python runtime.
unset PYTHONHOME PYTHONPATH

[ "$(uname -s)" = Linux ] || { echo 'This bootstrap requires Linux.' >&2; exit 1; }
case "$(uname -m)" in
  x86_64) platform=linux-64 ;;
  aarch64|arm64) platform=linux-aarch64 ;;
  *) echo 'Supported architectures: x86_64 and aarch64.' >&2; exit 1 ;;
esac

# The maintenance flags must not download or install dependencies.
maintenance=0
skip_deps=0
for arg do
  case "$arg" in --links-only|--herdr-plugins|--zsh-only) maintenance=1 ;; esac
  case "$arg" in --no-deps) skip_deps=1 ;; esac
done
if [ "$maintenance" = 1 ] || [ "$skip_deps" = 1 ]; then
  [ -x "$prefix/bin/bash" ] || { echo 'Run the full bootstrap first.' >&2; exit 1; }
else
  for tool in curl tar bzip2 mktemp; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing bootstrap tool: $tool" >&2; exit 1; }
  done
  # jk_os provides these compilers. Fail before downloading if the toolchain is absent.
  for tool in cc c++; do
    command -v "$tool" >/dev/null 2>&1 || { echo "Missing jk_os compiler: $tool" >&2; exit 1; }
  done
  if [ ! -x "$mamba" ]; then
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    trap 'exit 1' HUP INT TERM
    curl -fL --retry 3 "https://micro.mamba.pm/api/micromamba/$platform/latest" -o "$tmp/mamba.tar.bz2"
    tar -xjf "$tmp/mamba.tar.bz2" -C "$tmp" bin/micromamba
    "$tmp/bin/micromamba" --version
    mkdir -p "$(dirname "$mamba")"
    mv "$tmp/bin/micromamba" "$mamba"
  fi
  action=create
  [ ! -f "$prefix/conda-meta/history" ] || action=install
  "$mamba" "$action" --yes --no-rc --override-channels --channel conda-forge \
    --strict-channel-priority --platform "$platform" --prefix "$prefix" --file "$repo/packages/jk-os.txt"
fi

export PATH="$HOME/.local/bin:$prefix/bin:$HOME/.cargo/bin:$PATH"
if [ "$maintenance" = 0 ] && [ "$skip_deps" = 0 ]; then
  "$prefix/bin/bash" "$repo/scripts/jk-os-extras.sh"
fi
"$prefix/bin/bash" "$repo/install.sh" --no-deps --no-chsh "$@"

if [ "$maintenance" = 0 ]; then
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/konsole"
  # These are generated files: leave unrelated Konsole profiles untouched.
  cp "$repo/bin/dotfiles-shell" "$HOME/.local/bin/dotfiles-shell"
  chmod +x "$HOME/.local/bin/dotfiles-shell"
  cat > "$HOME/.local/share/konsole/Dotfiles.profile" <<EOF
[General]
Name=Dotfiles
Command="$HOME/.local/bin/dotfiles-shell"
Parent=FALLBACK/

[Appearance]
ColorScheme=Dotfiles
Font=FiraCode Nerd Font Mono,11,-1,5,50,0,0,0,0,0
EOF
  # Breeze palette on a pure black background.
  cat > "$HOME/.local/share/konsole/Dotfiles.colorscheme" <<'EOF'
[General]
Description=Dotfiles
Opacity=1

[Background]
Color=0,0,0
[BackgroundFaint]
Color=0,0,0
[BackgroundIntense]
Color=0,0,0
[Foreground]
Color=252,252,252
[ForegroundFaint]
Color=239,240,241
[ForegroundIntense]
Color=255,255,255
[Color0]
Color=35,38,39
[Color0Faint]
Color=49,54,59
[Color0Intense]
Color=127,140,141
[Color1]
Color=237,21,21
[Color1Faint]
Color=120,50,40
[Color1Intense]
Color=192,57,43
[Color2]
Color=17,209,22
[Color2Faint]
Color=23,162,98
[Color2Intense]
Color=28,220,154
[Color3]
Color=246,116,0
[Color3Faint]
Color=182,86,25
[Color3Intense]
Color=253,188,75
[Color4]
Color=29,153,243
[Color4Faint]
Color=27,102,143
[Color4Intense]
Color=61,174,233
[Color5]
Color=155,89,182
[Color5Faint]
Color=97,74,115
[Color5Intense]
Color=142,68,173
[Color6]
Color=26,188,156
[Color6Faint]
Color=24,108,96
[Color6Intense]
Color=22,160,133
[Color7]
Color=252,252,252
[Color7Faint]
Color=99,104,109
[Color7Intense]
Color=255,255,255
EOF
  # jk-dev's terminal (foot) starts a login /bin/sh, which reads ~/.profile:
  # hand it to the same zsh. Only terminal windows in a graphical session (a
  # pseudo-terminal with a display) do this; text-console and serial logins
  # and SSH keep jk_os's own shell. Rerunning replaces only the marked block.
  profile="$HOME/.profile"
  tmp_profile="$profile.dotfiles.$$"
  if [ -f "$profile" ]; then
    awk '/^# >>> dotfiles shell >>>$/ { skip = 1 } !skip { print } /^# <<< dotfiles shell <<<$/ { skip = 0 }' \
      "$profile" > "$tmp_profile"
  else
    : > "$tmp_profile"
  fi
  cat >> "$tmp_profile" <<'EOF'
# >>> dotfiles shell >>>
# Terminal windows (jk-dev's foot, desktop terminals) start the dotfiles zsh;
# text consoles (tty*), serial lines and SSH keep the plain shell.
case "$-" in
  *i*)
    case "$(tty 2>/dev/null)" in
      /dev/pts/*)
        [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] &&
          [ -x "$HOME/.local/share/dotfiles/env/bin/zsh" ] && [ -x "$HOME/.local/bin/dotfiles-shell" ] &&
          exec "$HOME/.local/bin/dotfiles-shell" ;;
    esac ;;
esac
# <<< dotfiles shell <<<
EOF
  # Write through, so a symlinked ~/.profile stays a symlink.
  cat "$tmp_profile" > "$profile"
  rm -f "$tmp_profile"

  printf '\n%s\n' 'Ready. Open: konsole --profile Dotfiles' \
    'Or run: ~/.local/bin/dotfiles-shell (jk-dev terminals start it too; text consoles keep sh)' \
    'In Konsole, select the Dotfiles profile as default if desired.'
fi
