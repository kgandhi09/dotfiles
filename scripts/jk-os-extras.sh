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
    --buildtype release -Dman-pages=disabled
  meson compile -C "$tmp/wl-build"
  meson install -C "$tmp/wl-build"
fi

if ! command -v cscope >/dev/null; then
  curl -fL --retry 3 https://downloads.sourceforge.net/cscope/cscope-15.9.tar.gz -o "$tmp/cscope.tar.gz"
  tar -xzf "$tmp/cscope.tar.gz" -C "$tmp"
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
