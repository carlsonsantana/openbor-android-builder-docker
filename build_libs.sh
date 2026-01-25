#!/bin/sh

set -e

export ANDROID_SDK_ROOT=/android-sdk
export ANDROID_NDK=/android-sdk/ndk/21.4.7075529

mkdir /mylibs

install_libpng_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ADDITIONAL_ARCHITECTURE_FLAGS="$2"
  ANDROID_API=$3
  TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"

  cd /mylibs/
  tar -xf libpng-1.6.36.tar.xz
  cd libpng-1.6.36

  /android-sdk/cmake/3.22.1/bin/cmake . -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-no-integrated-as -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$TOOLCHAIN_PATH/include -I$ANDROID_NDK/sources/android/cpufeatures" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar -DCMAKE_NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm -DCMAKE_RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib  -DCMAKE_INSTALL_PREFIX=$TOOLCHAIN_PATH -DCMAKE_SYSTEM_NAME=Android -DCMAKE_PREFIX_PATH=$TOOLCHAIN_PATH -DCMAKE_ANDROID_ARCH_ABI=$TOOLCHAIN_ARCHITECTURE -DCMAKE_ANDROID_API=$ANDROID_API -DCMAKE_FIND_ROOT_PATH=$TOOLCHAIN_PATH -DPNG_SHARED=OFF -DPNG_TESTS=OFF

  /android-sdk/cmake/3.22.1/bin/cmake --build build --target clean
  /android-sdk/cmake/3.22.1/bin/cmake --build build
  /android-sdk/cmake/3.22.1/bin/cmake --build build --target install

  if [ -f "/openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a" ]; then
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a
  else
    mkdir -p /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE
  fi
  cp $TOOLCHAIN_PATH/lib/libpng16.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a

  cd /mylibs/
  rm -r /mylibs/libpng-1.6.36
}

install_libpng() {
  cd /mylibs/
  curl -L https://sitsa.dl.sourceforge.net/project/libpng/libpng16/older-releases/1.6.36/libpng-1.6.36.tar.xz?viasf=1 --output /mylibs/libpng-1.6.36.tar.xz

  install_libpng_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3" 16
  install_libpng_architecture "arm64-v8a" "-march=armv8-a" 21
  install_libpng_architecture "x86" "-march=i686 -m32" 16
  install_libpng_architecture "x86_64" "-march=x86-64 -m64" 21
}


install_libvpx_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ADDITIONAL_ARCHITECTURE_FLAGS="$2"
  ANDROID_API=$3
  NDK_ARCH="$4"
  TARGET_ARCHITECTURE="$5"
  LDFLAGS="$6"
  ARCHTOOLS1="$7"
  ARCHTOOLS2="$8"
  ARCHTOOLS3="$9"
  TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"
  export CFLAGS="-D__ANDROID__ -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$ANDROID_NDK/sources/android/cpufeatures"
  export LDFLAGS="$LDFLAGS"
  export AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ar
  export CC=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS2-linux-android$ARCHTOOLS3$ANDROID_API-clang
  export CXX=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS2-linux-android$ARCHTOOLS3$ANDROID_API-clang++
  export LD=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ld
  export STRIP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-strip
  export RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ranlib
  export NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-nm

  cd /mylibs/
  tar -xzf v1.8.0.tar.gz
  cd libvpx-1.8.0/

  ./configure \
    --prefix=$TOOLCHAIN_PATH \
    --target=${TARGET} \
    --as=yasm \
    --enable-pic \
    --disable-docs \
    --enable-static \
    --disable-shared \
    --disable-dependency-tracking \
    --disable-examples \
    --disable-tools \
    --disable-debug \
    --disable-unit-tests \
    --enable-vp8 --enable-vp9 \
    --enable-vp9-postproc \
    --enable-vp9-highbitdepth \
    --enable-runtime-cpu-detect \
    --disable-webm-io \
    --disable-neon-asm
  make -j$(nproc) install

  if [ -f "/openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvpx.a" ]; then
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvpx.a
  else
    mkdir -p /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE
  fi
  cp $TOOLCHAIN_PATH/lib/libvpx.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvpx.a

  cd /mylibs/
  rm -r /mylibs/libvpx-1.8.0
}

install_libvpx() {
  cd /mylibs/
  curl -L https://github.com/webmproject/libvpx/archive/refs/tags/v1.8.0.tar.gz --output v1.8.0.tar.gz

  install_libvpx_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3" 16 "arm" "armv7-android-gcc" "-march=armv7-a" "arm" "armv7a" "eabi"
  install_libvpx_architecture "arm64-v8a" "-march=armv8-a" 21 "arm64" "arm64-android-gcc" "" "aarch64" "aarch64" ""
  install_libvpx_architecture "x86" "-march=i686 -m32" 16 "x86" "x86-android-gcc" "" "i686" "i686" ""
  install_libvpx_architecture "x86_64" "-march=x86-64 -m64" 21 "x86_64" "x86_64-android-gcc" "" "x86_64" "x86_64" ""
}


install_libogg_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ADDITIONAL_ARCHITECTURE_FLAGS="$2"
  ANDROID_API=$3
  TARGET_ARCHITECTURE="$4"
  HOST_ARCHITECTURE="$5"
  LDFLAGS="$6"
  ARCHTOOLS1="$7"
  ARCHTOOLS2="$8"
  ARCHTOOLS3="$9"
  TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"
  export CFLAGS="-g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$ANDROID_NDK/sources/android/cpufeatures"
  export CPPFLAGS="$CFLAGS"
  export LDFLAGS="$LDFLAGS"
  export AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ar
  export CC=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS2-linux-android$ARCHTOOLS3$ANDROID_API-clang
  export CXX=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS2-linux-android$ARCHTOOLS3$ANDROID_API-clang++
  export LD=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ld
  export STRIP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-strip
  export RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-ranlib
  export NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-nm

  cd /mylibs/
  tar -xf libogg-1.3.3.tar.xz
  cd libogg-1.3.3/

  ./configure \
    --prefix=$TOOLCHAIN_PATH \
    --target=${TARGET} \
    --host=${HOST_ARCHITECTURE} \
    --enable-static \
    --disable-shared \
    --disable-dependency-tracking
  make -j$(nproc) install

  if [ -f "/openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libogg.a" ]; then
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libogg.a
  else
    mkdir -p /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE
  fi
  cp $TOOLCHAIN_PATH/lib/libogg.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libogg.a

  cd /mylibs/
  rm -r /mylibs/libogg-1.3.3
}

install_libogg() {
  cd /mylibs/
  curl -L https://downloads.xiph.org/releases/ogg/libogg-1.3.3.tar.xz --output libogg-1.3.3.tar.xz

  install_libogg_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3" 16 "armv7-android-gcc" "armv7a-linux-androideabi" "-march=armv7-a" "arm" "armv7a" "eabi"
  install_libogg_architecture "arm64-v8a" "-march=armv8-a" 21 "arm64-android-gcc" "aarch64-linux-android" "" "aarch64" "aarch64" ""
  install_libogg_architecture "x86" "-march=i686 -m32" 16 "x86-android-gcc" "i686-linux-android" "" "i686" "i686" ""
  install_libogg_architecture "x86_64" "-march=x86-64 -m64" 21 "x86_64-android-gcc" "x86_64-linux-android" "" "x86_64" "x86_64" ""
}


install_libpng
install_libvpx
install_libogg


cd /openbor/engine/android
rm -R /mylibs
