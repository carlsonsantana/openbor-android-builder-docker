#!/bin/sh

set -e

# Remove previous build files
rm -f /tmp/openbor-unsigned.apk /tmp/openbor-aligned.apk /tmp/openbor-unsigned.aab
rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip /tmp/openbor-android-res-aab
rm -f /output/openbor-aligned.apk /output/openbor-signed.apk /output/openbor-unsigned.aab /output/openbor-signed.aab

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

get_sigalg() {
  RAW_INFO=$(keytool -list -v -keystore /game_certificate.key -alias "$GAME_KEYSTORE_KEY_ALIAS" -storepass "$GAME_KEYSTORE_PASSWORD" | grep "Signature algorithm name")

  case "$RAW_INFO" in
    *RSA*) echo "SHA256withRSA" ;;
    *ECDSA*) echo "SHA256withECDSA" ;;
    *EC*) echo "SHA256withECDSA" ;;
    *DSA*) echo "SHA256withDSA" ;;
    *) echo "Unknown or unsupported key type."; exit 1 ;;
  esac
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
printf "version: 2.12.1\napkFileName: OpenBOR.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 21\n  targetSdkVersion: 35\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/androidx.appcompat_appcompat.version\n- META-INF/androidx.arch.core_core-runtime.version\n- META-INF/androidx.asynclayoutinflater_asynclayoutinflater.version\n- META-INF/androidx.coordinatorlayout_coordinatorlayout.version\n- META-INF/androidx.core_core.version\n- META-INF/androidx.cursoradapter_cursoradapter.version\n- META-INF/androidx.customview_customview.version\n- META-INF/androidx.documentfile_documentfile.version\n- META-INF/androidx.drawerlayout_drawerlayout.version\n- META-INF/androidx.fragment_fragment.version\n- META-INF/androidx.interpolator_interpolator.version\n- META-INF/androidx.legacy_legacy-support-core-ui.version\n- META-INF/androidx.legacy_legacy-support-core-utils.version\n- META-INF/androidx.lifecycle_lifecycle-livedata-core.version\n- META-INF/androidx.lifecycle_lifecycle-livedata.version\n- META-INF/androidx.lifecycle_lifecycle-runtime.version\n- META-INF/androidx.lifecycle_lifecycle-viewmodel.version\n- META-INF/androidx.loader_loader.version\n- META-INF/androidx.localbroadcastmanager_localbroadcastmanager.version\n- META-INF/androidx.print_print.version\n- META-INF/androidx.slidingpanelayout_slidingpanelayout.version\n- META-INF/androidx.swiperefreshlayout_swiperefreshlayout.version\n- META-INF/androidx.vectordrawable_vectordrawable-animated.version\n- META-INF/androidx.vectordrawable_vectordrawable.version\n- META-INF/androidx.versionedparcelable_versionedparcelable.version\n- META-INF/androidx.viewpager_viewpager.version" > /openbor-android/apktool.yml

# Copy bor.pak
cp /bor.pak /openbor-android/assets/bor.pak

# Build an aligned version of the Android app
java -jar /apktool/apktool.jar b /openbor-android -o /tmp/openbor-unsigned.apk
zipalign -v -p 4 /tmp/openbor-unsigned.apk /tmp/openbor-aligned.apk

# Build the Android App Bundle (.aab)
cp -r /openbor-android/res/ /tmp/openbor-android-res-aab
cd /tmp/openbor-android-res-aab
find . -type f -name '$*' | while read -r file; do
    # Get the directory name and the base filename
    dir=$(dirname "$file")
    base=$(basename "$file")

    # Remove the $ (first char) and add the prefix
    new_name="openbor_${base#\$}"

    # Perform the move
    mv -v "$file" "$dir/$new_name"

    find . -type f -name '*.xml' -exec sed -i "s/"${base%.*}"/"${new_name%.*}"/g" {} +
done
cd /
unzip /tmp/openbor-unsigned.apk -d /tmp/apk
aapt2 compile --dir /tmp/openbor-android-res-aab -o /tmp/res.zip
aapt2 link --proto-format -o /tmp/_base.zip -I /opt/android.jar --manifest /openbor-android/AndroidManifest.xml --min-sdk-version 21 --target-sdk-version 36 --version-code "$GAME_VERSION_CODE" --version-name "$GAME_VERSION_NAME" -R /tmp/res.zip --auto-add-overlay
unzip /tmp/_base.zip -d /tmp/base
cp -r /openbor-android/assets/ /openbor-android/lib/ /openbor-android/unknown/ /tmp/base
mkdir /tmp/base/manifest /tmp/base/dex
mv /tmp/base/AndroidManifest.xml /tmp/base/manifest/AndroidManifest.xml
mv /tmp/base/unknown /tmp/base/root
mv /tmp/apk/*.dex /tmp/base/dex
cd /tmp/base
jar cMf /tmp/base.zip manifest dex res root lib assets resources.pb
cd /
java -jar /opt/bundletool.jar build-bundle --modules=/tmp/base.zip --output=/tmp/openbor-unsigned.aab
chmod 644 /tmp/openbor-unsigned.aab

if [ -f "/game_certificate.key" ]; then
  java -jar /opt/signmyapp.jar -ks /game_certificate.key -ks-pass "$GAME_KEYSTORE_PASSWORD" -ks-key-alias "$GAME_KEYSTORE_KEY_ALIAS" -key-pass "$GAME_KEYSTORE_KEY_PASSWORD" -in /tmp/openbor-aligned.apk -out /output/openbor-signed.apk

  SIGALG=$(get_sigalg)
  jarsigner -verbose -sigalg $SIGALG -digestalg SHA-256 -signedjar /output/openbor-signed.aab -keystore /game_certificate.key -storepass "$GAME_KEYSTORE_PASSWORD" /tmp/openbor-unsigned.aab "$GAME_KEYSTORE_KEY_ALIAS"

  rm /tmp/openbor-aligned.apk /tmp/openbor-unsigned.aab
else
  mv /tmp/openbor-aligned.apk /output/openbor-aligned.apk
  mv /tmp/openbor-unsigned.aab /output/openbor-unsigned.aab
fi

rm /tmp/openbor-unsigned.apk
rm -fr /tmp/apk /tmp/res.zip /tmp/_base.zip /tmp/base /tmp/base.zip /tmp/openbor-android-res-aab
