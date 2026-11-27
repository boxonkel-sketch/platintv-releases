#!/usr/bin/env bash
# Rebuilds ffmpeg/src/main/jniLibs: FFmpeg n6.0.1 (LGPL 2.1+, audio decoders only) and the JNI layer of Media3 1.5.0.
#
#   git clone --depth 1 --branch 1.5.0  https://github.com/androidx/media.git  "$WORK/media"
#   git clone --depth 1 --branch n6.0.1 https://github.com/FFmpeg/FFmpeg.git   "$WORK/ffmpeg"
#   sdkmanager "ndk;26.1.10909125" "cmake;3.22.1"
#
# Usage: build_ffmpeg.sh WORK
set -euo pipefail

WORK="$(realpath "$1")"
ROOT="$(realpath "$(dirname "$0")/..")"
SDK="${ANDROID_HOME:-$HOME/Android/Sdk}"
NDK="$SDK/ndk/26.1.10909125"
CMAKE="$SDK/cmake/3.22.1/bin"
BIN="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin"
API=24
JNI="$WORK/media/libraries/decoder_ffmpeg/src/main/jni"

DECODERS="aac aac_latm ac3 eac3 dca mlp truehd mp2 mp3 vorbis opus flac alac"

ffmpeg_abi() {
  local abi="$1" prefix="$2"; shift 2
  (
    cd "$WORK/ffmpeg"
    make distclean >/dev/null 2>&1 || true
    ./configure --libdir="android-libs/$abi" "$@" \
      --cross-prefix="$BIN/$prefix$API-" --nm="$BIN/llvm-nm" --ar="$BIN/llvm-ar" \
      --ranlib="$BIN/llvm-ranlib" --strip="$BIN/llvm-strip" \
      --target-os=android --enable-static --disable-shared --disable-doc --disable-programs --disable-everything \
      --disable-avdevice --disable-avformat --disable-swscale --disable-postproc --disable-avfilter --disable-symver \
      --enable-swresample --disable-v4l2-m2m --disable-vulkan \
      $(for d in $DECODERS; do echo "--enable-decoder=$d"; done)
    grep -q '^#define CONFIG_GPL 0$' config.h && grep -q '^#define CONFIG_NONFREE 0$' config.h
    grep FFMPEG_LICENSE config.h
    make -j4 >/dev/null
    make install-libs >/dev/null
  )
}

jni_abi() {
  local abi="$1" out="$WORK/out/$1"
  "$CMAKE/cmake" -G Ninja -DCMAKE_MAKE_PROGRAM="$CMAKE/ninja" -S "$JNI" -B "$out" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" -DANDROID_ABI="$abi" -DANDROID_PLATFORM="android-$API" \
    -DANDROID_STL=c++_static -DCMAKE_BUILD_TYPE=Release >/dev/null
  "$CMAKE/cmake" --build "$out" >/dev/null
  install -D "$out/libffmpegJNI.so" "$ROOT/ffmpeg/src/main/jniLibs/$abi/libffmpegJNI.so"
  "$BIN/llvm-strip" --strip-unneeded "$ROOT/ffmpeg/src/main/jniLibs/$abi/libffmpegJNI.so"
}

ln -sfn "$WORK/ffmpeg" "$JNI/ffmpeg"
ffmpeg_abi armeabi-v7a armv7a-linux-androideabi --arch=arm --cpu=armv7-a \
  --extra-cflags="-march=armv7-a -mfloat-abi=softfp" --extra-ldflags="-Wl,--fix-cortex-a8"
jni_abi armeabi-v7a
ffmpeg_abi arm64-v8a aarch64-linux-android --arch=aarch64 --cpu=armv8-a
jni_abi arm64-v8a
