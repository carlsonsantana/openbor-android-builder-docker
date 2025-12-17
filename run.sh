#!/bin/sh

set -e

# Remove previous apk build
rm -f /output/openbor-unsigned.apk

# Convert icons
magick /icon.png -resize 36x36 /openbor-android/res/drawable-ldpi/icon.png
magick /icon.png -resize 48x48 /openbor-android/res/drawable-mdpi/icon.png
magick /icon.png -resize 72x72 /openbor-android/res/drawable-hdpi/icon.png

# Rename APK name and application ID
sed -i "s|ZZZZZ|$GAME_NAME|g" /openbor-android/res/values/strings.xml
sed -i "s|\"aaaaa\.bbbbb\.ccccc\"|\"$GAME_APK_NAME\"|g" /openbor-android/AndroidManifest.xml
printf "version: 2.12.1\napkFileName: OpenBOR.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 14\n  targetSdkVersion: 28\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/android.arch.lifecycle_runtime.version\n- META-INF/com.android.support_support-compat.version\n- META-INF/com.android.support_support-core-ui.version\n- META-INF/com.android.support_support-core-utils.version\n- META-INF/com.android.support_support-fragment.version\n- META-INF/com.android.support_support-media-compat.version\n- META-INF/com.android.support_support-v4.version\n- assets/bor.pak" > /openbor-android/apktool.yml

# Copy bor.pak
cp /bor.pak /openbor-android/assets/bor.pak

# Build an unsigned version of the Android app
java -jar /apktool/apktool.jar b /openbor-android -o /output/openbor-unsigned.apk
