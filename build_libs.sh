#!/bin/sh

set -e

export ANDROID_SDK_ROOT=/android-sdk
export ANDROID_NDK=/android-sdk/ndk/21.4.7075529
TOOLCHAIN_ARCHITECTURE="armeabi-v7a"
TOOLCHAIN_PATH="/mylibs/$TOOLCHAIN_ARCHITECTURE-toolchain"
ADDITIONAL_ARCHITECTURE_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3"

mkdir /mylibs
cd /mylibs/

curl https://sitsa.dl.sourceforge.net/project/libpng/libpng16/older-releases/1.6.36/libpng-1.6.36.tar.xz?viasf=1 --output libpng-1.6.36.tar.xz
tar -xf libpng-1.6.36.tar.xz
cd libpng-1.6.36

/android-sdk/cmake/3.22.1/bin/cmake . -Bbuild -DCMAKE_BUILD_TYPE=RelWithDebInfo -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-no-integrated-as -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$TOOLCHAIN_PATH/include -I$ANDROID_NDK/sources/android/cpufeatures" -DCMAKE_CXX_FLAGS="-no-integrated-as -g0 -O2 -fPIC $ADDITIONAL_ARCHITECTURE_FLAGS -I$TOOLCHAIN_PATH/include -I$ANDROID_NDK/sources/android/cpufeatures" -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_AR=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar -DCMAKE_NM=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm -DCMAKE_RANLIB=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ranlib  -DCMAKE_INSTALL_PREFIX=$TOOLCHAIN_PATH -DCMAKE_SYSTEM_NAME=Android -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_PREFIX_PATH=$TOOLCHAIN_PATH -DCMAKE_ANDROID_ARCH_ABI=$TOOLCHAIN_ARCHITECTURE -DCMAKE_ANDROID_API=16 -DCMAKE_FIND_ROOT_PATH=$TOOLCHAIN_PATH -DPNG_SHARED=OFF -DPNG_EXECUTABLES=OFF -DPNG_TESTS=OFF

/android-sdk/cmake/3.22.1/bin/cmake --build build --target clean
/android-sdk/cmake/3.22.1/bin/cmake --build build
/android-sdk/cmake/3.22.1/bin/cmake --build build --target install

rm /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a
cp $TOOLCHAIN_PATH/lib/libpng16.a /openbor/engine/android/app/jni/openbor/lib/$TOOLCHAIN_ARCHITECTURE/libpng.a


cd /openbor/engine/android
rm -R /mylibs
