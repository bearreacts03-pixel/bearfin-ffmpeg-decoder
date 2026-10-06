#!/bin/bash
#
# Builds FFmpeg's audio decoders for Android (arm64-v8a and armeabi-v7a), so Bearfin can play
# AC3, E-AC3, DTS, TrueHD, FLAC, Opus and more on any phone without the server converting them.
#
# Run once from the BearfinAndroid folder:   ./ffmpeg-decoder/build-ffmpeg.sh
# Then rebuild the app normally. Takes about 5 to 15 minutes.
#
# License: this builds FFmpeg WITHOUT --enable-gpl or --enable-nonfree, so the result is LGPL.
# Based on build_ffmpeg.sh from AndroidX Media3 (Apache License 2.0, Copyright (C) 2019 The Android
# Open Source Project), reduced to the two phone architectures.
set -euo pipefail

cd "$(dirname "$0")/.."

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}}"
NDK_VERSION="26.1.10909125"
CMAKE_VERSION="3.22.1"
MIN_API=26
HOST_PLATFORM="darwin-x86_64"   # the Android NDK for macOS uses this name, also on Apple Silicon

MODULE_PATH="$(pwd)/ffmpeg-decoder/src/main"
JNI_PATH="${MODULE_PATH}/jni"
FFMPEG_PATH="${JNI_PATH}/ffmpeg"

# Decoders to include. Names are FFmpeg's. dca is DTS, mlp and truehd are Dolby TrueHD.
ENABLED_DECODERS=(vorbis opus flac alac pcm_mulaw pcm_alaw mp3 amrnb amrwb aac ac3 eac3 dca mlp truehd)

echo "== Android SDK: ${SDK}"

if [[ "$(uname -m)" == "arm64" ]] && ! /usr/bin/pgrep -q oahd; then
    echo "The Android NDK needs Rosetta on Apple Silicon. Install it with:"
    echo "  softwareupdate --install-rosetta --agree-to-license"
    exit 1
fi

echo "== Installing the NDK and CMake (skipped if already there)"
yes | sdkmanager --sdk_root="${SDK}" "ndk;${NDK_VERSION}" "cmake;${CMAKE_VERSION}" >/dev/null || true

NDK_PATH="${SDK}/ndk/${NDK_VERSION}"
TOOLCHAIN_PREFIX="${NDK_PATH}/toolchains/llvm/prebuilt/${HOST_PLATFORM}/bin"
if [[ ! -d "${TOOLCHAIN_PREFIX}" ]]; then
    echo "Could not find the NDK at ${NDK_PATH}"
    exit 1
fi

if [[ ! -d "${FFMPEG_PATH}" ]]; then
    echo "== Downloading FFmpeg 6.0"
    git clone --depth 1 --branch release/6.0 https://github.com/FFmpeg/FFmpeg.git "${FFMPEG_PATH}"
fi

COMMON_OPTIONS="
    --target-os=android
    --enable-static
    --disable-shared
    --disable-doc
    --disable-programs
    --disable-everything
    --disable-avdevice
    --disable-avformat
    --disable-swscale
    --disable-postproc
    --disable-avfilter
    --disable-symver
    --enable-swresample
    --extra-ldexeflags=-pie
    --disable-v4l2-m2m
    --disable-vulkan
"
for decoder in "${ENABLED_DECODERS[@]}"; do
    COMMON_OPTIONS="${COMMON_OPTIONS} --enable-decoder=${decoder}"
done

JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
cd "${FFMPEG_PATH}"
make distclean >/dev/null 2>&1 || true

echo "== Building armeabi-v7a (32-bit phones)"
./configure \
    --libdir=android-libs/armeabi-v7a \
    --arch=arm \
    --cpu=armv7-a \
    --cross-prefix="${TOOLCHAIN_PREFIX}/armv7a-linux-androideabi${MIN_API}-" \
    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
    --extra-cflags="-march=armv7-a -mfloat-abi=softfp" \
    --extra-ldflags="-Wl,--fix-cortex-a8" \
    ${COMMON_OPTIONS}
make -j"${JOBS}"
make install-libs
make clean

echo "== Building arm64-v8a (64-bit phones and the emulator on Apple Silicon)"
./configure \
    --libdir=android-libs/arm64-v8a \
    --arch=aarch64 \
    --cpu=armv8-a \
    --cross-prefix="${TOOLCHAIN_PREFIX}/aarch64-linux-android${MIN_API}-" \
    --nm="${TOOLCHAIN_PREFIX}/llvm-nm" \
    --ar="${TOOLCHAIN_PREFIX}/llvm-ar" \
    --ranlib="${TOOLCHAIN_PREFIX}/llvm-ranlib" \
    --strip="${TOOLCHAIN_PREFIX}/llvm-strip" \
    ${COMMON_OPTIONS}
make -j"${JOBS}"
make install-libs
make clean

echo
echo "Done. FFmpeg audio decoders are built. Now rebuild the app:"
echo "  ./gradlew assembleDebug"
