#!/bin/bash
# Build FreeRDP 3.x with smartcard support and package as tarball
# Run this on Ubuntu 22.04 (or in a Docker container)
#
# Output: freerdp-3.x-linux64.tar.gz  (place in igel-freerdp/ root)

set -e

FREERDP_VERSION="3.0.0"
INSTALL_PREFIX="/opt/freerdp"
BUILD_DIR="/tmp/freerdp-build"
OUTPUT_DIR="/tmp/freerdp-root"

# --- Dependencies ---
sudo apt-get update
sudo apt-get install -y \
    git cmake ninja-build pkg-config \
    libssl-dev \
    libx11-dev libxext-dev libxrandr-dev libxi-dev libxrender-dev \
    libxkbcommon-dev libxkbfile-dev \
    libpcsclite-dev \
    libpulse-dev \
    libcups-dev \
    libusb-1.0-0-dev \
    libavcodec-dev libavutil-dev libswscale-dev \
    libsystemd-dev \
    libudev-dev \
    libdbus-1-dev

# --- Clone ---
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

if [ ! -d FreeRDP ]; then
    git clone --depth 1 --branch ${FREERDP_VERSION} https://github.com/FreeRDP/FreeRDP.git
fi

cd FreeRDP
mkdir -p build && cd build

# --- Configure ---
cmake .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DWITH_PCSC=ON \
    -DWITH_X11=ON \
    -DWITH_PULSE=ON \
    -DWITH_CUPS=ON \
    -DWITH_CHANNELS=ON \
    -DWITH_CLIENT_CHANNELS=ON \
    -DWITH_SERVER=OFF \
    -DWITH_SAMPLE=OFF \
    -DBUILD_TESTING=OFF \
    -DWITH_SWSCALE=ON \
    -DWITH_FFMPEG=ON

# --- Build ---
ninja -j"$(nproc)"

# --- Install to staging dir ---
rm -rf "$OUTPUT_DIR"
DESTDIR="$OUTPUT_DIR" ninja install

# --- Bundle required shared libs ---
# Copy libs that are NOT part of a standard IGEL OS base
BUNDLE_LIBS=(
    libpcsclite.so.1
    libavcodec.so.58
    libavutil.so.56
    libswscale.so.5
    libpulse.so.0
    libpulse-simple.so.0
    libcups.so.2
)

LIB_DEST="$OUTPUT_DIR${INSTALL_PREFIX}/lib/bundled"
mkdir -p "$LIB_DEST"

for libname in "${BUNDLE_LIBS[@]}"; do
    libpath=$(ldconfig -p | grep "$libname" | awk '{print $NF}' | head -1)
    if [ -n "$libpath" ]; then
        cp -L "$libpath" "$LIB_DEST/"
        echo "Bundled: $libpath"
    else
        echo "WARNING: $libname not found, skipping"
    fi
done

# Write ld.so.conf snippet so bundled libs are found at runtime
mkdir -p "$OUTPUT_DIR/etc/ld.so.conf.d"
echo "${INSTALL_PREFIX}/lib/bundled" > "$OUTPUT_DIR/etc/ld.so.conf.d/freerdp-bundled.conf"

# --- Create tarball ---
TARBALL="freerdp-${FREERDP_VERSION}-linux64.tar.gz"
tar -czf "/tmp/${TARBALL}" -C "$OUTPUT_DIR" .

echo ""
echo "Done! Copy the tarball to the recipe directory:"
echo "  cp /tmp/${TARBALL} $(dirname "$0")/freerdp-3.x-linux64.tar.gz"
