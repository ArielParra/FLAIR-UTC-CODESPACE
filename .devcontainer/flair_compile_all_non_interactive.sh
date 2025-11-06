#!/usr/bin/env bash
set -e  # exit on first error

NB_THREADS=$(nproc)
FLAIR_BUILD_DIR="$FLAIR_ROOT/flair-build"
IDE_SCRIPT="cmake_codelite_outofsource.sh"

rm -rf "$FLAIR_BUILD_DIR/*"
mkdir -p "$FLAIR_BUILD_DIR"
cd "$FLAIR_BUILD_DIR"

"$FLAIR_ROOT/flair-src/scripts/$IDE_SCRIPT" "$FLAIR_ROOT/flair-src/"

toolchains=($OECORE_CMAKE_TOOLCHAINS)
for arch in "${toolchains[@]}"; do
    cd "$FLAIR_BUILD_DIR/build_$arch"
    make -j"$NB_THREADS"
    make install
done

DOXYGEN=$(eval "echo \"\$OECORE_${arch^^}_NATIVE_SYSROOT\"")/usr/bin/doxygen
if [ -x "$DOXYGEN" ]; then
    "$DOXYGEN" "$FLAIR_ROOT/flair-src/lib/Doxyfile.in"
fi
