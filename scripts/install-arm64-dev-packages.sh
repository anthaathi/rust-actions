#!/usr/bin/env bash
# Download ARM64 Debian packages and expose only their cross-build headers,
# libraries, and pkg-config metadata. Do not install/configure foreign packages:
# their maintainer scripts may try to execute ARM64 binaries on the AMD64 host.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 package:arm64 [...]" >&2
  exit 2
fi

SUDO=""
command -v sudo >/dev/null 2>&1 && SUDO=sudo
. /etc/os-release

$SUDO dpkg --add-architecture arm64
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
  if ! grep -q '^Architectures: amd64' /etc/apt/sources.list.d/ubuntu.sources; then
    $SUDO sed -i '/^Types: deb$/a Architectures: amd64' /etc/apt/sources.list.d/ubuntu.sources
  fi
  $SUDO tee /etc/apt/sources.list.d/ubuntu-arm64.sources >/dev/null <<EOF
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: $VERSION_CODENAME $VERSION_CODENAME-updates $VERSION_CODENAME-security
Components: main universe
Architectures: arm64
EOF
else
  $SUDO sed -i 's/^deb /deb [arch=amd64] /' /etc/apt/sources.list
  $SUDO tee /etc/apt/sources.list.d/arm64.list >/dev/null <<EOF
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports $VERSION_CODENAME main universe
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports $VERSION_CODENAME-updates main universe
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports $VERSION_CODENAME-security main universe
EOF
fi

$SUDO apt-get update -qq
cache=$(mktemp -d)
root=$(mktemp -d)
trap 'rm -rf "$cache" "$root"' EXIT
mkdir -p "$cache/partial"

# Download and resolve dependencies, but never let dpkg configure ARM binaries.
$SUDO apt-get -y -qq --download-only   -o Dir::Cache::archives="$cache"   install "$@"

for deb in "$cache"/*.deb; do
  dpkg-deb -x "$deb" "$root"
done

copy_tree() {
  local source=$1 destination=$2
  if [ -d "$root/$source" ]; then
    $SUDO mkdir -p "$destination"
    $SUDO cp -a "$root/$source/." "$destination/"
  fi
}

copy_tree usr/include /usr/include
copy_tree usr/lib/aarch64-linux-gnu /usr/lib/aarch64-linux-gnu
copy_tree lib/aarch64-linux-gnu /lib/aarch64-linux-gnu
copy_tree usr/share/pkgconfig /usr/share/pkgconfig
# Ubuntu's usrmerge packages keep the real ARM loader under /usr/lib, while
# libc linker scripts refer to the canonical absolute /lib path.
if [ -e /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 ]; then
  $SUDO ln -sfn /usr/lib/aarch64-linux-gnu/ld-linux-aarch64.so.1 \
    /lib/ld-linux-aarch64.so.1
elif [ -e "$root/lib/ld-linux-aarch64.so.1" ] || [ -L "$root/lib/ld-linux-aarch64.so.1" ]; then
  $SUDO cp -a "$root/lib/ld-linux-aarch64.so.1" /lib/ld-linux-aarch64.so.1
else
  echo "ARM64 dynamic loader was not present in downloaded packages" >&2
  exit 1
fi

# Fail early if the requested GStreamer cross metadata was not extracted.
test -f /usr/lib/aarch64-linux-gnu/pkgconfig/gstreamer-1.0.pc
