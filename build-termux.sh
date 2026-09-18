#!/bin/bash
#
# Termux build script for Delta Key Generator
# Run this inside Termux after installing the prerequisites.
#
# Prerequisites (one-time):
#   pkg update && pkg upgrade -y
#   pkg install -y openjdk-17 git unzip wget
#   pkg install -y android-sdk android-sdk-build-tools
#
# Then:
#   cd ~/delta-key-generator
#   bash build-termux.sh
#
# Output APK:
#   app/build/outputs/apk/debug/app-debug.apk
#

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "=============================="
echo " Delta Key Generator - Termux Build"
echo "=============================="
echo

# 1. Check Java
if ! command -v java >/dev/null 2>&1; then
    echo "[ERROR] Java not installed. Run:"
    echo "  pkg install openjdk-17"
    exit 1
fi
echo "[OK] Java: $(java -version 2>&1 | head -1)"

# 2. Check ANDROID_SDK_ROOT
if [ -z "$ANDROID_SDK_ROOT" ]; then
    export ANDROID_SDK_ROOT="$HOME/android-sdk"
fi
if [ ! -d "$ANDROID_SDK_ROOT" ]; then
    # Try default Termux location
    if [ -d "/data/data/com.termux/files/home/android-sdk" ]; then
        export ANDROID_SDK_ROOT="/data/data/com.termux/files/home/android-sdk"
    else
        echo "[ERROR] Android SDK not found."
        echo "Install it with:"
        echo "  pkg install android-sdk android-sdk-build-tools"
        echo "Or set ANDROID_SDK_ROOT to point to your SDK location."
        exit 1
    fi
fi
echo "[OK] Android SDK: $ANDROID_SDK_ROOT"

# 3. Make sure required SDK components are installed
echo
echo "[STEP 1/4] Checking SDK components..."
SDKMANAGER="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
if [ ! -f "$SDKMANAGER" ]; then
    # fallback to root-level sdkmanager
    SDKMANAGER="$ANDROID_SDK_ROOT/tools/bin/sdkmanager"
fi
if [ -f "$SDKMANAGER" ]; then
    yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
    "$SDKMANAGER" "platforms;android-34" "build-tools;34.0.0" "platform-tools" >/dev/null 2>&1 || true
    echo "[OK] SDK components ready"
else
    echo "[WARN] sdkmanager not found - assuming components already installed"
fi

# 4. Verify gradle-wrapper.jar is present (it's bundled with this project)
WRAPPER_JAR="gradle/wrapper/gradle-wrapper.jar"
if [ ! -f "$WRAPPER_JAR" ]; then
    echo
    echo "[STEP 2/4] Downloading gradle-wrapper.jar..."
    mkdir -p gradle/wrapper
    wget -q -O "$WRAPPER_JAR" "https://raw.githubusercontent.com/gradle/gradle/v8.2.0/gradle/wrapper/gradle-wrapper.jar"
    if [ ! -s "$WRAPPER_JAR" ]; then
        echo "[ERROR] Failed to download gradle-wrapper.jar"
        exit 1
    fi
    echo "[OK] gradle-wrapper.jar downloaded"
else
    echo "[OK] gradle-wrapper.jar present"
fi

chmod +x ./gradlew

# 5. Build the APK
echo
echo "[STEP 3/4] Building APK (this may take 10-30 minutes on first run)..."
echo "Gradle will download dependencies on first build."
echo

./gradlew assembleDebug --no-daemon --console=plain 2>&1 | tail -50

# 6. Locate APK
APK="app/build/outputs/apk/debug/app-debug.apk"
if [ -f "$APK" ]; then
    echo
    echo "[STEP 4/4] Build successful!"
    echo
    echo "=============================="
    echo " APK READY"
    echo "=============================="
    echo "Location: $PROJECT_DIR/$APK"
    echo
    echo "To install on your phone:"
    echo "  termux-open $PROJECT_DIR/$APK"
    echo
    echo "Or copy it somewhere accessible:"
    echo "  cp $PROJECT_DIR/$APK ~/storage/downloads/DeltaKeyGenerator.apk"
    echo "  termux-open ~/storage/downloads/DeltaKeyGenerator.apk"
else
    echo
    echo "[ERROR] Build failed - APK not found."
    echo "Check the output above for errors."
    exit 1
fi
