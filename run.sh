#!/bin/sh

set -e

# Download Android command line tools
if [ ! -d "/android-sdk/cmdline-tools/latest" ]; then
  # Remove incomplete files
  rm -fR /android-sdk/cmdline-tools.zip /android-sdk/cmdline-tools-temp /android-sdk/cmdline-tools

  cd /android-sdk
  curl https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}.zip --output /android-sdk/cmdline-tools.zip
  unzip /android-sdk/cmdline-tools.zip
  mv cmdline-tools cmdline-tools-temp
  mkdir cmdline-tools
  mv cmdline-tools-temp /android-sdk/cmdline-tools/latest

  rm /android-sdk/cmdline-tools.zip
  touch /android-sdk/tools_not_downloaded
fi

if [ -f "/android-sdk/tools_not_downloaded" ]; then
  cd /android-sdk/cmdline-tools/latest/bin
  archlinux-java set java-17-openjdk
  echo "y" | ./sdkmanager --install "build-tools;29.0.3" "platform-tools" "platforms;android-29" "tools" "ndk-bundle"

  rm -f /android-sdk/tools_not_downloaded
fi

archlinux-java set java-11-openjdk

# Remove previous apk build
rm -f /output/openbor.apk

# Change APK name
sed -i "s|org\.openbor\.engine|$GAME_APK_NAME|g" /openbor/engine/android/app/build.gradle
sed -i "s|\"Openbor\"|\"$GAME_NAME\"|g" /openbor/engine/android/app/build.gradle

# Convert icons
convert /icon.png -resize 72x72 /openbor/engine/android/app/src/main/res/drawable-hdpi/icon.png
convert /icon.png -resize 36x36 /openbor/engine/android/app/src/main/res/drawable-ldpi/icon.png
convert /icon.png -resize 48x48 /openbor/engine/android/app/src/main/res/drawable-mdpi/icon.png

cd /openbor/engine/android
printf "storePassword=$KEYSTORE_STORE_PASSWORD\nkeyPassword=$KEYSTORE_KEY_PASSWORD\nkeyAlias=$KEYSTORE_NAME\nstoreFile=/game_certificate.jks\n" > keystore.properties

cp /bor.pak /openbor/engine/android/app/src/main/assets/bor.pak

./gradlew assembleRelease

mv /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk /output/OpenBOR.apk
