#!/bin/sh

set -e

# Remove previous apk build
rm -f /tmp/openbor-unsigned.apk /tmp/openbor-aligned.apk /output/openbor-aligned.apk /output/openbor-signed.apk

if [ -f "/game_certificate.key" ]; then
  if [ -z "$GAME_KEYSTORE_PASSWORD" ] || [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] || [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ]; then
    echo "ERROR: Partial keystore configuration detected."
    echo "You must provide ALL THREE variables, when pass '/game_certificate.key' VOLUME."
    echo "Missing values for: "
    [ -z "$GAME_KEYSTORE_PASSWORD" ] && echo "- GAME_KEYSTORE_PASSWORD"
    [ -z "$GAME_KEYSTORE_KEY_ALIAS" ] && echo "- GAME_KEYSTORE_KEY_ALIAS"
    [ -z "$GAME_KEYSTORE_KEY_PASSWORD" ] && echo "- GAME_KEYSTORE_KEY_PASSWORD"
    exit 1
  fi
fi

mipmap_resize_icon() {
  OUTPUT_PATH_ICON_ROUND="/openbor-android/res/$2/ic_launcher_round.png"
  OUTPUT_PATH_ICON_BACKGROUND="/openbor-android/res/$2/ic_launcher_background.png"
  OUTPUT_PATH_ICON_FOREGROUND="/openbor-android/res/$2/ic_launcher_foreground.png"
  OUTPUT_PATH_ICON_MONOCHROME="/openbor-android/res/$2/ic_launcher_monochrome.png"

  TEMP_CIRCLE_MASK=$(mktemp /tmp/XXXXXXX.png)
  TEMP_RESIZED_IMAGE=$(mktemp /tmp/XXXXXXX.png)

  magick -size $1"x"$1 xc:none -fill white -draw "roundrectangle 0,0,$1,$1,$1,$1" $TEMP_CIRCLE_MASK
  magick /icon.png -resize $1"x"$1 $TEMP_RESIZED_IMAGE
  magick $TEMP_RESIZED_IMAGE -alpha Set $TEMP_CIRCLE_MASK -compose DstIn -composite $OUTPUT_PATH_ICON_ROUND && oxipng -o 6 --strip safe $OUTPUT_PATH_ICON_ROUND

  magick /icon_background.png -resize $1"x"$1 $OUTPUT_PATH_ICON_BACKGROUND && oxipng -o 6 --strip safe $OUTPUT_PATH_ICON_BACKGROUND
  magick /icon.png -resize $1"x"$1 $OUTPUT_PATH_ICON_FOREGROUND && oxipng -o 6 --strip safe $OUTPUT_PATH_ICON_FOREGROUND
  magick /icon.png -resize $1"x"$1 $OUTPUT_PATH_ICON_MONOCHROME && oxipng -o 6 --strip safe $OUTPUT_PATH_ICON_MONOCHROME

  rm $TEMP_CIRCLE_MASK $TEMP_RESIZED_IMAGE
}

# Convert icons
mipmap_resize_icon "36" "mipmap-ldpi"
mipmap_resize_icon "48" "mipmap-mdpi"
mipmap_resize_icon "72" "mipmap-hdpi"
mipmap_resize_icon "96" "mipmap-xhdpi"
mipmap_resize_icon "144" "mipmap-xxhdpi"
mipmap_resize_icon "192" "mipmap-xxxhdpi"

# Rename APK name and application ID
sed -i "s|ZZZZZ|$GAME_NAME|g" /openbor-android/res/values/strings.xml
sed -i "s|\"aaaaa\.bbbbb\.ccccc\"|\"$GAME_APK_NAME\"|g" /openbor-android/AndroidManifest.xml
printf "version: 2.12.1\napkFileName: OpenBOR.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 14\n  targetSdkVersion: 28\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/android.arch.lifecycle_runtime.version\n- META-INF/com.android.support_support-compat.version\n- META-INF/com.android.support_support-core-ui.version\n- META-INF/com.android.support_support-core-utils.version\n- META-INF/com.android.support_support-fragment.version\n- META-INF/com.android.support_support-media-compat.version\n- META-INF/com.android.support_support-v4.version\n- assets/bor.pak" > /openbor-android/apktool.yml

# Copy bor.pak
cp /bor.pak /openbor-android/assets/bor.pak

# Build an aligned version of the Android app
java -jar /apktool/apktool.jar b /openbor-android -o /tmp/openbor-unsigned.apk
zipalign -v -p 4 /tmp/openbor-unsigned.apk /tmp/openbor-aligned.apk

if [ -f "/game_certificate.key" ]; then
  java -jar /opt/signmyapp.jar -ks /game_certificate.key -ks-pass "$GAME_KEYSTORE_PASSWORD" -ks-key-alias "$GAME_KEYSTORE_KEY_ALIAS" -key-pass "$GAME_KEYSTORE_KEY_PASSWORD" -in /tmp/openbor-aligned.apk -out /output/openbor-signed.apk
  rm /tmp/openbor-aligned.apk
else
  mv /tmp/openbor-aligned.apk /output/openbor-aligned.apk
fi

rm /tmp/openbor-unsigned.apk
