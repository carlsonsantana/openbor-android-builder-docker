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
  tar -xzf v1.6.36.tar.gz
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
  curl -L https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.36.tar.gz --output /mylibs/v1.6.36.tar.gz

  install_libpng_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3" 16
  install_libpng_architecture "arm64-v8a" "-march=armv8-a" 21
  install_libpng_architecture "x86" "-march=i686 -m32" 16
  install_libpng_architecture "x86_64" "-march=x86-64 -m64" 21
}


install_libvpx_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ADDITIONAL_ARCHITECTURE_FLAGS="$2"
  ANDROID_API=$3
  TARGET_ARCHITECTURE="$4"
  LDFLAGS="$5"
  ARCHTOOLS1="$6"
  ARCHTOOLS2="$7"
  ARCHTOOLS3="$8"
  TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"
  export CFLAGS="-g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$ANDROID_NDK/sources/android/cpufeatures -D__ANDROID__"
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
  tar -xzf v1.8.0.tar.gz
  cd libvpx-1.8.0/

  ./configure \
    --prefix=$TOOLCHAIN_PATH \
    --target=${TARGET_ARCHITECTURE} \
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

  install_libvpx_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3" 16 "armv7-android-gcc" "-march=armv7-a" "arm" "armv7a" "eabi"
  install_libvpx_architecture "arm64-v8a" "-march=armv8-a" 21 "arm64-android-gcc" "" "aarch64" "aarch64" ""
  install_libvpx_architecture "x86" "-march=i686 -m32" 16 "x86-android-gcc" "" "i686" "i686" ""
  install_libvpx_architecture "x86_64" "-march=x86-64 -m64" 21 "x86_64-android-gcc" "" "x86_64" "x86_64" ""
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
    --target=${TARGET_ARCHITECTURE} \
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

  install_libogg_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3 -DBYTE_ORDER=LITTLE_ENDIAN" 16 "armv7-android-gcc" "armv7a-linux-androideabi" "-march=armv7-a" "arm" "armv7a" "eabi"
  install_libogg_architecture "arm64-v8a" "-march=armv8-a -DBYTE_ORDER=LITTLE_ENDIAN" 21 "arm64-android-gcc" "aarch64-linux-android" "" "aarch64" "aarch64" ""
  install_libogg_architecture "x86" "-march=i686 -m32 -DBYTE_ORDER=LITTLE_ENDIAN" 16 "x86-android-gcc" "i686-linux-android" "" "i686" "i686" ""
  install_libogg_architecture "x86_64" "-march=x86-64 -m64 -DBYTE_ORDER=LITTLE_ENDIAN" 21 "x86_64-android-gcc" "x86_64-linux-android" "" "x86_64" "x86_64" ""
}


install_libvorbis_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ADDITIONAL_ARCHITECTURE_FLAGS="$2"
  ANDROID_API=$3
  HOST_ARCHITECTURE="$4"
  LDFLAGS="$5"
  ARCHTOOLS1="$6"
  ARCHTOOLS2="$7"
  ARCHTOOLS3="$8"
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
  export OBJDUMP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/$ARCHTOOLS1-linux-android$ARCHTOOLS3-objdump
  export OGG_CFLAGS="-I$TOOLCHAIN_PATH/include"
  export OGG_LIBS="-L$TOOLCHAIN_PATH/lib -logg"

  cd /mylibs/
  tar -xzf tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8.tar.gz
  cd tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8/

  # Fix build errors
  patch < /opt/patches/tremor.patch

  ./autogen.sh \
    --prefix=$TOOLCHAIN_PATH \
    --host=${HOST_ARCHITECTURE} \
    --enable-static \
    --disable-shared \
    --disable-dependency-tracking \
    --enable-pic \
    --with-ogg=$TOOLCHAIN_PATH || \
    sed -i 's/XIPH_PATH_OGG(, as_fn_error $? "must have Ogg installed!" "$LINENO" 5)//g' ./configure && \
    ./configure \
    --prefix=$TOOLCHAIN_PATH \
    --host=${HOST_ARCHITECTURE} \
    --enable-static \
    --disable-shared \
    --disable-dependency-tracking \
    --enable-pic \
    --with-ogg=$TOOLCHAIN_PATH
  make -j$(nproc) install

  if [ -f "/openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvorbisidec.a" ]; then
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvorbisidec.a
  else
    mkdir -p /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE
  fi
  cp $TOOLCHAIN_PATH/lib/libvorbisidec.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvorbisidec.a

  cd /mylibs/
  rm -r /mylibs/tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8/
}

install_libvorbis() {
  cd /mylibs/
  curl -L https://gitlab.xiph.org/xiph/tremor/-/archive/7c30a66346199f3f09017a09567c6c8a3a0eedc8/tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8.tar.gz --output tremor-7c30a66346199f3f09017a09567c6c8a3a0eedc8.tar.gz

  install_libvorbis_architecture "armeabi-v7a" "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3 -DBYTE_ORDER=LITTLE_ENDIAN" 16 "armv7a-linux-androideabi" "-march=armv7-a" "arm" "armv7a" "eabi"
  install_libvorbis_architecture "arm64-v8a" "-march=armv8-a -DBYTE_ORDER=LITTLE_ENDIAN" 21 "aarch64-linux-android" "" "aarch64" "aarch64" ""
  install_libvorbis_architecture "x86" "-march=i686 -m32 -DBYTE_ORDER=LITTLE_ENDIAN" 16 "i686-linux-android" "" "i686" "i686" ""
  install_libvorbis_architecture "x86_64" "-march=x86-64 -m64 -DBYTE_ORDER=LITTLE_ENDIAN" 21 "x86_64-linux-android" "" "x86_64" "x86_64" ""
}


install_sdl_architecture() {
  TOOLCHAIN_ARCHITECTURE="$1"
  ANDROID_API=$2

  cd /mylibs/
  tar -xzf SDL2-2.0.10.tar.gz
  cd SDL2-2.0.10/

  mv include/SDL_config_android.h include/SDL_config.h
  mkdir jni
  echo "APP_ABI := $TOOLCHAIN_ARCHITECTURE" >> "jni/Application.mk"

  $ANDROID_NDK/ndk-build NDK_PROJECT_PATH=. NDK_DEBUG=0 APP_BUILD_SCRIPT=./Android.mk APP_PLATFORM=android-$ANDROID_API

  if [ -f "/openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libSDL2.so" ]; then
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libSDL2.so
    rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libhidapi.so
  else
    mkdir -p /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE
  fi
  cp libs/$TOOLCHAIN_ARCHITECTURE/libSDL2.so /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libSDL2.so
  cp libs/$TOOLCHAIN_ARCHITECTURE/libhidapi.so /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libhidapi.so

  cd /mylibs/
  rm -r /mylibs/SDL2-2.0.10/
}

install_sdl() {
  cd /mylibs/
  curl -L https://libsdl.org/release/SDL2-2.0.10.tar.gz --output SDL2-2.0.10.tar.gz

  install_sdl_architecture "armeabi-v7a" 16
  install_sdl_architecture "arm64-v8a" 21
  install_sdl_architecture "x86" 16
  install_sdl_architecture "x86_64" 21
}


install_libpng
install_libvpx
install_libogg
install_libvorbis
install_sdl


cd /openbor/engine/android
rm -R /mylibs
