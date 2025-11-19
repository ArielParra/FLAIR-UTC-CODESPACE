#!/usr/bin/env bash
set -e

NB_THREADS=$(nproc)
FLAIR_BUILD_DIR="$FLAIR_ROOT/flair-build"
IDE_SCRIPT="cmake_codelite_outofsource.sh"

# Clean build directory
rm -rf "$FLAIR_BUILD_DIR/*"
mkdir -p "$FLAIR_BUILD_DIR"
cd "$FLAIR_BUILD_DIR"

# Run CMake for all toolchains
"$FLAIR_ROOT/flair-src/scripts/$IDE_SCRIPT" "$FLAIR_ROOT/flair-src/"

toolchains=($OECORE_CMAKE_TOOLCHAINS)

# Compile each architecture sequentially
for arch in "${toolchains[@]}"; do
    BUILD_DIR="$FLAIR_BUILD_DIR/build_$arch"
    cd "$BUILD_DIR"
    echo "[*] Building $arch..."
    make -j"$NB_THREADS"
    make install
done

# Wait for all parallel builds to finish
wait

# Ensure doc directory exists
mkdir -p "$FLAIR_ROOT/flair-install/doc"

# Generate documentation using Doxygen from the last arch
DOXYGEN=$(eval "echo \"\$OECORE_${arch^^}_NATIVE_SYSROOT\"")/usr/bin/doxygen
if [ -x "$DOXYGEN" ]; then
    "$DOXYGEN" "$FLAIR_ROOT/flair-src/lib/Doxyfile.in"
fi
