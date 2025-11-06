#!/usr/bin/env bash
# Generates the global CMakeUserPresets.json file for the Flair SDK.
# This allows any project in VS Code to find and use the Flair toolchains.

set -e # Exit script on any error

echo "Configuring global Flair CMake presets..."

# --- 1. Validate Environment ---
if [[ -z "${FLAIR_ROOT}" ]]; then
    echo "Error: FLAIR_ROOT not set. Please source ~/.bashrc" >&2
    exit 1
fi
if [[ -z "$OECORE_CMAKE_TOOLCHAINS" ]]; then
    echo "Error: OECORE_CMAKE_TOOLCHAINS not set. Please source ~/.bashrc" >&2
    exit 1
fi

# OECORE_CMAKE_TOOLCHAINS is a space-separated string, convert to array
toolchains=($OECORE_CMAKE_TOOLCHAINS)
echo "Found toolchains: ${toolchains[*]}"

# --- 2. Define Output File ---
PRESETS_DIR="/root/.cmake"
OUTPUT_FILE="${PRESETS_DIR}/CMakeUserPresets.json"
mkdir -p "$PRESETS_DIR"

echo "Generating ${OUTPUT_FILE}..."

# --- 3. Generate CMakeUserPresets.json ---
{
    echo "{"
    echo "  \"version\": 3,"
    echo "  \"vendor\": { \"flair-sdk\": { \"version\": 1 } },"
    echo "  \"configurePresets\": ["
    
    count=0
    for arch in ${toolchains[@]}; do
        (( count += 1 ))
        
        # Dynamically get variable names
        toolchain_var="OECORE_CMAKE_${arch^^}_TOOLCHAIN"
        sysroot_var="OECORE_${arch^^}_NATIVE_SYSROOT"
        
        # Dereference variables
        toolchain=$(eval "echo \"\$$toolchain_var\"")
        CMAKE=$(eval "echo \"\$$sysroot_var\"")/usr/bin/cmake

        echo "    {"
        echo "      \"name\": \"flair-$arch\","
        echo "      \"displayName\": \"Flair $arch Cross-Compile\","
        echo "      \"description\": \"Configures using the Flair $arch toolchain.\","
        echo "      \"generator\": \"Unix Makefiles\","
        echo "      \"binaryDir\": \"${FLAIR_ROOT}/flair-build/build_usr/\${sourceDirName}/$arch\","
        echo "      \"cmakeExecutable\": \"${CMAKE}\","
        echo "      \"cacheVariables\": {"
        echo "        \"CMAKE_BUILD_TYPE\": \"Release\","
        echo "        \"CMAKE_TOOLCHAIN_FILE\": \"${toolchain}\""
        echo "      }"
        if (( ${#toolchains[@]} == $count )); then
            echo "    }"
        else
            echo "    },"
        fi
    done
    
    echo "  ],"
    echo "  \"buildPresets\": ["

    count=0
    for arch in ${toolchains[@]}; do
        (( count += 1 ))
        echo "    {"
        echo "      \"name\": \"build-flair-$arch\","
        echo "      \"displayName\": \"Build & Install Flair $arch\","
        echo "      \"configurePreset\": \"flair-$arch\","
        echo "      \"targets\": [\"install\"]"
        if (( ${#toolchains[@]} == $count )); then
            echo "    }"
        else
            echo "    },"
        fi
    done

    echo "  ]"
    echo "}"
} > "$OUTPUT_FILE"

echo "Global CMake presets successfully generated."