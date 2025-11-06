#!/usr/bin/env bash
# Generates a local CMakePresets.json file for the Flair SDK in the current project folder.

set -e  

echo "Configuring local Flair CMake presets..."

toolchains=($OECORE_CMAKE_TOOLCHAINS)
echo "Found toolchains: ${toolchains[*]}"


OUTPUT_FILE="./CMakePresets.json"

echo "Generating ${OUTPUT_FILE}..."

{
    echo "{"
    echo "  \"version\": 3,"
    echo "  \"configurePresets\": ["
    
    count=0
    for arch in "${toolchains[@]}"; do
        (( count += 1 ))
        
        toolchain_var="OECORE_CMAKE_${arch^^}_TOOLCHAIN"
        sysroot_var="OECORE_${arch^^}_NATIVE_SYSROOT"
        toolchain=$(eval "echo \"\$$toolchain_var\"")
        CMAKE=$(eval "echo \"\$$sysroot_var\"")/usr/bin/cmake

        echo "    {"
        echo "      \"name\": \"flair-$arch\","
        echo "      \"displayName\": \"Flair $arch Cross-Compile\","
        echo "      \"description\": \"Configures using the Flair $arch toolchain.\","
        echo "      \"generator\": \"Unix Makefiles\","
        echo "      \"binaryDir\": \"\${sourceDir}/build_$arch\","
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
    for arch in "${toolchains[@]}"; do
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

echo "Local CMake presets successfully generated at ${OUTPUT_FILE}"
