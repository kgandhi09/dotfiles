#!/bin/sh
# Run on the booted jk_os system: sh ./bootstrap-jk-os.sh [install.sh flags]
# POSIX sh intentionally: the base image has BusyBox ash, but no Bash.
set -eu

case "${1:-}" in
  -h|--help)
    printf '%s\n' 'Usage: sh ./bootstrap-jk-os.sh [--no-fonts] [--links-only] [--herdr-plugins]' \
      'Installs a private tool environment under ~/.local/share/dotfiles.' \
      'Run as your desktop user on the booted OS, not against its source/rootfs tree.'
    exit 0 ;;
esac
for arg do
  case "$arg" in
    --no-fonts|--links-only|--herdr-plugins|--no-chsh|--no-deps) ;;
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
  case "$arg" in --links-only|--herdr-plugins) maintenance=1 ;; esac
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
Font=FiraCode Nerd Font Mono,11,-1,5,50,0,0,0,0,0
EOF
  printf '\n%s\n' 'Ready. Open: konsole --profile Dotfiles' \
    'Or run: ~/.local/bin/dotfiles-shell' \
    'In Konsole, select the Dotfiles profile as default if desired.'
fi
