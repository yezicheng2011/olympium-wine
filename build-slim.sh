#!/bin/sh
# Copyright 2026 Ye Zicheng
# SPDX-License-Identifier: Apache-2.0
# Build a slim 64-bit Wine from the upstream Wine 11.0 source and pack it.
# The archive is written to dist/. It is not committed.
set -eu

cd "$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

for arg in "$@"; do
  case "$arg" in
    *harmonyos*|*HarmonyOS*|*huawei.com*)
      echo "Refusing a HarmonyOS or Huawei commercial input." >&2
      exit 2
      ;;
    *macos*|*darwin*|*iOS*|*ios*)
      echo "Refusing an Apple system image." >&2
      exit 2
      ;;
    --pack) PACK_ONLY=1 ;;
  esac
done

arch=$(uname -m)
if [ "$arch" != x86_64 ]; then
  echo "This Wine build is for an x86_64 Linux host. $arch is not built or tested." >&2
  exit 2
fi

version=11.0
source_url="https://dl.winehq.org/wine/source/11.0/wine-${version}.tar.xz"
source_sha=c07a6857933c1fc60dff5448d79f39c92481c1e9db5aa628db9d0358446e0701
work=${WORKDIR:-/tmp/olympium-wine-build}
prefix=${WINE_PREFIX:-$work/prefix}
mkdir -p "$work" dist

if [ "${PACK_ONLY:-}" != 1 ]; then
  tarball="$work/wine-${version}.tar.xz"
  if [ ! -f "$tarball" ]; then
    curl -fL --retry 3 --retry-delay 2 -o "$tarball.partial" "$source_url"
    mv "$tarball.partial" "$tarball"
  fi
  got=$(sha256sum "$tarball" | awk '{print $1}')
  if [ "$got" != "$source_sha" ]; then
    echo "SHA-256 mismatch for the Wine source." >&2
    exit 1
  fi
  rm -rf "$work/src"
  tar -C "$work" -xf "$tarball"
  mv "$work/wine-${version}" "$work/src"
  rm -rf "$work/build" "$prefix"
  mkdir "$work/build"
  (
    cd "$work/build"
    ../src/configure \
      --prefix="$prefix" \
      --enable-archs=x86_64 \
      --disable-tests \
      --without-cups \
      --without-gstreamer \
      --without-vulkan \
      --without-pulse \
      --with-x
    make -j"$(nproc)"
    make install
  )
fi

if [ ! -x "$prefix/bin/wine" ]; then
  echo "Wine was not installed at $prefix." >&2
  exit 1
fi

stage="$work/stage"
rm -rf "$stage"
mkdir -p "$stage/bin" "$stage/libexec" "$stage/prefix" "$stage/LICENSES"
cp -a "$prefix/bin/." "$stage/bin/"
cp -a "$prefix/lib" "$stage/lib"
if [ -d "$prefix/share" ]; then
  cp -a "$prefix/share" "$stage/share"
fi
# Development files are not needed to run a Windows program.
rm -f "$stage/bin/widl" "$stage/bin/winebuild" "$stage/bin/winegcc" \
  "$stage/bin/winedump" "$stage/bin/wmc" "$stage/bin/wrc" \
  "$stage/bin/winemaker" "$stage/bin/function_grep.pl"
rm -f "$stage/bin/winecpp" "$stage/bin/wineg++"
find "$stage" -name '*.a' -delete
find "$stage/lib" -type f \( -name '*.dll' -o -name '*.exe' -o -name '*.sys' -o -name '*.drv' -o -name '*.ocx' -o -name '*.cpl' -o -name '*.acm' \) -print0 \
  | xargs -0 x86_64-w64-mingw32-strip --strip-unneeded
find "$stage/bin" "$stage/lib" -type f -print0 | xargs -0 -r strip --strip-unneeded || true

if [ ! -f "$stage/bin/wine" ]; then
  echo "bin/wine disappeared while packing." >&2
  exit 1
fi
mv "$stage/bin/wine" "$stage/libexec/wine"
if [ -e "$stage/bin/wineserver" ]; then
  mv "$stage/bin/wineserver" "$stage/libexec/wineserver"
fi
cat > "$stage/bin/wine" <<'EOF'
#!/bin/sh
# Copyright 2026 Ye Zicheng
# SPDX-License-Identifier: Apache-2.0
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
export WINEPREFIX="${WINEPREFIX:-$root/prefix}"
# Do not download Wine Mono or Wine Gecko.
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=}"
exec "$root/libexec/wine" "$@"
EOF
chmod 755 "$stage/bin/wine"
# Keep the tool names, but point them at the wrapper.
for tool in wineboot winecfg wineconsole winefile winemine winepath msiexec regedit regsvr32 notepad msidb winedbg; do
  if [ -L "$stage/bin/$tool" ] || [ -e "$stage/bin/$tool" ]; then
    ln -sfn wine "$stage/bin/$tool"
  fi
done

src_tree=${WINE_SOURCE:-$work/src}
if [ -f "$src_tree/COPYING.LIB" ]; then
  cp "$src_tree/COPYING.LIB" "$stage/LICENSES/COPYING.LIB"
fi
if [ -f "$src_tree/LICENSE" ]; then
  cp "$src_tree/LICENSE" "$stage/LICENSES/LICENSE"
fi

cat > "$stage/EDITION" <<EOF
wine-slim 0.1.0
wine ${version}
arch x86_64
host linux
pe x86_64
EOF
printf '%s\n' linux > "$stage/HOST_OS"
cat > "$stage/NOTICE" <<EOF
Slim Wine runtime for Linkspan
Copyright 2026 Ye Zicheng for the first-party wrapper script.

Wine ${version} is LGPL-2.1-or-later. It is not relicensed as Apache-2.0.
The corresponding source is ${source_url}
sha256 ${source_sha}
This build is unmodified upstream source configured with
--enable-archs=x86_64 --disable-tests --without-cups --without-gstreamer
--without-vulkan --without-pulse --with-x.

This is not a Windows license, not a Windows system image, and not a product key.
Wine Mono and Wine Gecko are not included. 32-bit Windows programs are not supported.
The binaries are Linux x86_64 ELF files linked against glibc. They do not run on macOS or Windows.
EOF

hello=/tmp/olympium-wine-hello.c
cat > "$hello" <<'EOF'
#include <stdio.h>
int main(void) {
    printf("linkspan-guest-ok platform=windows format=exe\n");
    return 0;
}
EOF
x86_64-w64-mingw32-gcc -O2 -o "$work/hello.exe" "$hello"
rm -rf "$stage/prefix"
mkdir -p "$stage/prefix"
if ! env WINEPREFIX="$stage/prefix" WINEDEBUG=-all WINEDLLOVERRIDES='mscoree,mshtml=' DISPLAY= \
  "$stage/bin/wine" "$work/hello.exe" > "$work/hello.log" 2>"$work/hello.err"; then
  echo "The packed Wine did not run the test executable." >&2
  cat "$work/hello.err" >&2 || true
  exit 1
fi
if ! grep -q 'linkspan-guest-ok platform=windows format=exe' "$work/hello.log"; then
  echo "Wine ran, but the guest did not print the expected line." >&2
  exit 1
fi
cp "$work/hello.log" "$stage/SMOKE.txt"
if command -v i686-w64-mingw32-gcc >/dev/null 2>&1; then
  i686-w64-mingw32-gcc -O2 -o "$work/hello32.exe" "$hello"
  if env WINEPREFIX="$stage/prefix" WINEDEBUG=-all WINEDLLOVERRIDES='mscoree,mshtml=' DISPLAY= \
    "$stage/bin/wine" "$work/hello32.exe" > "$work/hello32.log" 2>&1; then
    echo "32-bit smoke unexpectedly succeeded. This build is not supposed to claim wow64." >&2
    exit 1
  fi
  echo "32-bit PE was refused or failed, as expected for this 64-bit-only build." >> "$stage/SMOKE.txt"
fi

cat > "$stage/PROVENANCE" <<EOF
product: wine-slim
edition: 0.1.0
wine: ${version}
arch: x86_64
host: linux
built: $(date -u +%Y-%m-%dT%H:%M:%SZ)
source: ${source_url}
source_sha256: ${source_sha}
license: LGPL-2.1-or-later
configure: --enable-archs=x86_64 --disable-tests --without-cups --without-gstreamer --without-vulkan --without-pulse --with-x
glibc: $(ldd --version | awk 'NR==1 {print; exit}')
smoke: a PE32+ console executable printed linkspan-guest-ok platform=windows format=exe
not_tested: macOS host, Windows host, aarch64, 32-bit PE, OpenGL, sound, a visible GUI window
not_included: Wine Mono, Wine Gecko, a Windows system image, a product key
EOF

archive=dist/wine-slim-x86_64.tar.gz
rm -f "$archive"
tar -C "$stage" -czf "$archive" .
sha256sum "$archive" | tee dist/wine-slim-x86_64.sha256
echo "Wrote $archive"
