#!/usr/bin/env bash
# Tools not available from conda-forge on both supported architectures.
set -euo pipefail
prefix="$HOME/.local/share/dotfiles/env"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CPPFLAGS="-I$prefix/include ${CPPFLAGS:-}"
export LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib ${LDFLAGS:-}"

if ! command -v wl-copy >/dev/null || ! command -v wl-paste >/dev/null; then
  git clone --depth 1 --branch v2.2.1 https://github.com/bugaevc/wl-clipboard.git "$tmp/wl-clipboard"
  meson setup "$tmp/wl-build" "$tmp/wl-clipboard" --prefix "$prefix" \
    --buildtype release -Dfishcompletiondir=no \
    -Dzshcompletiondir="$prefix/share/zsh/site-functions"
  meson compile -C "$tmp/wl-build"
  meson install -C "$tmp/wl-build"
fi

if ! command -v cscope >/dev/null; then
  # Debian mirrors the upstream source (orig), without its packaging patches.
  curl -fL --retry 3 --connect-timeout 20 --max-time 180 \
    https://deb.debian.org/debian/pool/main/c/cscope/cscope_15.9.orig.tar.xz -o "$tmp/cscope.tar.xz"
  printf '%s  %s\n' e8bc6cd29bb90e1eb7447a23a2a419f719ab8fe96dd10f6e289accdb428d2a1f \
    "$tmp/cscope.tar.xz" | sha256sum -c -
  tar -xJf "$tmp/cscope.tar.xz" -C "$tmp"
  (
    cd "$tmp/cscope-15.9"
    # cscope predates GCC's default C23 mode.
    CFLAGS="-O2 -std=gnu17 ${CFLAGS:-}" ./configure --prefix="$prefix"
    make -j2
    make install
  )
fi

# Plasma already provides a URL/file opener, but jk_os lacks xdg-utils.
if ! command -v xdg-open >/dev/null; then
  cat > "$prefix/bin/xdg-open" <<'EOF'
#!/bin/sh
exec kioclient exec "$@"
EOF
  chmod +x "$prefix/bin/xdg-open"
fi
