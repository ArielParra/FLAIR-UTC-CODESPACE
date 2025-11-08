#!/usr/bin/env bash
# Generates CMakePresets.json and VSCode settings for Flair SDK with Microsoft C++ IntelliSense

set -e  

echo "Configuring local Flair CMake presets..."

toolchains=($OECORE_CMAKE_TOOLCHAINS)
echo "Found toolchains: ${toolchains[*]}"

OUTPUT_FILE="./CMakePresets.json"

# --- 1. Generate CMakePresets.json ---
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

# --- 2. Generate VSCode settings ---
echo "Generating '.vscode/settings.json'..."
mkdir -p .vscode
cat > .vscode/settings.json <<EOF
{
  "C_Cpp.default.configurationProvider": "ms-vscode.cmake-tools",
  "cmake.configureOnOpen": true,
  "files.exclude": {
    "**/.git": true,
    "build": true
  }
}
EOF

# --- 3. Generate c_cpp_properties.json for IntelliSense ---
echo "Generating '.vscode/c_cpp_properties.json' for Microsoft C++ IntelliSense..."
cat > .vscode/c_cpp_properties.json <<EOF
{
    "configurations": [
        {
            "name": "Flair-Cross-Compile",
            "compilerPath": "/usr/bin/g++",
            "cStandard": "c11",
            "cppStandard": "c++17",
            "intelliSenseMode": "gcc-x64",
            "includePath": [
                "\${workspaceFolder}/**",
                "/opt/robomap3/2.1.3/armv7a-neon/sysroots/armv7a-neon-poky-linux-gnueabi/usr/include",
                "/opt/robomap3/2.1.3/armv7a-neon/sysroots/armv7a-neon-poky-linux-gnueabi/usr/include/c++/4.9.3",
                "\${FLAIR_ROOT}/flair-src/lib/**",
                "\${FLAIR_ROOT}/flair-src/tools/**",
                "\${FLAIR_ROOT}/flair-hds/src/lib/**",
                "\${FLAIR_ROOT}/flair-hds/src/tools/**",
                "\${FLAIR_ROOT}/flair-hds/dev/**"
            ]
        }
    ],
    "version": 4
}
EOF

echo "VSCode IntelliSense configuration generated."

# --- 4. Ensure build*/ folders are ignored in .gitignore ---
echo "Ensuring 'build*/' folders are ignored in .gitignore..."

if [ ! -f .gitignore ]; then
    echo "# Git ignore file" > .gitignore
fi

if ! grep -q '^build.*/' .gitignore; then
    echo -e "\n# Ignore build directories\nbuild*/" >> .gitignore
    echo ".gitignore updated with 'build*/'"
else
    echo ".gitignore already contains 'build*/'"
fi

# --- 5. Notify VS Code / Codespaces to reload workspace ---
if [ -n "$CODESPACES" ] && command -v code >/dev/null 2>&1; then
    echo "Reloading VSCode window to apply new IntelliSense settings..."
    code --force --reload-window || true
else
    echo "Setup complete. Open or Restart VSCode, and C++ IntelliSense should now find all headers."
fi
