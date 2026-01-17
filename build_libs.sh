#!/bin/sh

set -e

export ANDROID_SDK_ROOT=/android-sdk
export ANDROID_NDK=/android-sdk/ndk/21.4.7075529
TOOLCHAIN_ARCHITECTURE="armeabi-v7a"
TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"
ADDITIONAL_ARCHITECTURE_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

mkdir /mylibs

cd /mylibs/
curl -L https://sitsa.dl.sourceforge.net/project/libpng/libpng16/older-releases/1.6.36/libpng-1.6.36.tar.xz?viasf=1 --output libpng-1.6.36.tar.xz
tar -xf libpng-1.6.36.tar.xz
cd libpng-1.6.36

/android-sdk/cmake/3.22.1/bin/cmake . -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-no-integrated-as -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$TOOLCHAIN_PATH/include -I$ANDROID_NDK/sources/android/cpufeatures" -DCMAKE_CXX_FLAGS="-no-integrated-as -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$TOOLCHAIN_PATH/include -I$ANDROID_NDK/sources/android/cpufeatures" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar -DCMAKE_NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm -DCMAKE_RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib  -DCMAKE_INSTALL_PREFIX=$TOOLCHAIN_PATH -DCMAKE_SYSTEM_NAME=Android -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_PREFIX_PATH=$TOOLCHAIN_PATH -DCMAKE_ANDROID_ARCH_ABI=$TOOLCHAIN_ARCHITECTURE -DCMAKE_ANDROID_API=16 -DCMAKE_FIND_ROOT_PATH=$TOOLCHAIN_PATH -DPNG_SHARED=OFF -DPNG_EXECUTABLES=OFF -DPNG_TESTS=OFF

/android-sdk/cmake/3.22.1/bin/cmake --build build --target clean
/android-sdk/cmake/3.22.1/bin/cmake --build build
/android-sdk/cmake/3.22.1/bin/cmake --build build --target install

rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a
cp $TOOLCHAIN_PATH/lib/libpng16.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a


cd /mylibs/
curl -L https://github.com/webmproject/libvpx/archive/refs/tags/v1.8.0.tar.gz --output v1.8.0.tar.gz
tar -xzf v1.8.0.tar.gz
cd libvpx-1.8.0/

NDK_ARCH="arm"
STANDALONE_TOOLCHAIN_PATH="/mylibs/gcc-$TOOLCHAIN_ARCHITECTURE-toolchain"
TARGET="armv7-android-gcc"

python3 ${ANDROID_NDK}/build/tools/make_standalone_toolchain.py --arch $NDK_ARCH --api 21 --stl libc++ --install-dir=${STANDALONE_TOOLCHAIN_PATH}

export CFLAGS="-D__ANDROID__ -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$ANDROID_NDK/sources/android/cpufeatures"
export LDFLAGS="-march=armv7-a"
export AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ar
export CC=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang
export CXX=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/armv7a-linux-androideabi21-clang++
export LD=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ld
export STRIP=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-strip
export RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-ranlib
export NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/arm-linux-androideabi-nm

./configure \
    --prefix=$TOOLCHAIN_PATH \
    --target=${TARGET} \
    --as=yasm \
    --enable-pic \
    --disable-docs \
    --enable-static \
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

rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvpx.a
cp $TOOLCHAIN_PATH/lib/libvpx.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libvpx.a

cd /openbor/engine/android
rm -R /mylibs
