#!/bin/sh

set -e

APP_BASENAME="openbor"
APKTOOL_DECODED_PATH="/openbor-android"
RESOURCE_PREFIX="openbor"
ICON_BASENAME="icon"

source "/script/common.sh"

init_keystore_variables
remove_previous_build_files
validate_secrets_filled


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
printf "version: 2.12.1\napkFileName: OpenBOR.apk\nusesFramework:\n  ids:\n  - 1\nsdkInfo:\n  minSdkVersion: 21\n  targetSdkVersion: 35\npackageInfo:\n  forcedPackageId: 127\n  renameManifestPackage: "$GAME_APK_NAME"\nversionInfo:\n  versionCode: "$GAME_VERSION_CODE"\n  versionName: "$GAME_VERSION_NAME"\ndoNotCompress:\n- arsc\n- png\n- META-INF/androidx.appcompat_appcompat.version\n- META-INF/androidx.arch.core_core-runtime.version\n- META-INF/androidx.asynclayoutinflater_asynclayoutinflater.version\n- META-INF/androidx.coordinatorlayout_coordinatorlayout.version\n- META-INF/androidx.core_core.version\n- META-INF/androidx.cursoradapter_cursoradapter.version\n- META-INF/androidx.customview_customview.version\n- META-INF/androidx.documentfile_documentfile.version\n- META-INF/androidx.drawerlayout_drawerlayout.version\n- META-INF/androidx.fragment_fragment.version\n- META-INF/androidx.interpolator_interpolator.version\n- META-INF/androidx.legacy_legacy-support-core-ui.version\n- META-INF/androidx.legacy_legacy-support-core-utils.version\n- META-INF/androidx.lifecycle_lifecycle-livedata-core.version\n- META-INF/androidx.lifecycle_lifecycle-livedata.version\n- META-INF/androidx.lifecycle_lifecycle-runtime.version\n- META-INF/androidx.lifecycle_lifecycle-viewmodel.version\n- META-INF/androidx.loader_loader.version\n- META-INF/androidx.localbroadcastmanager_localbroadcastmanager.version\n- META-INF/androidx.print_print.version\n- META-INF/androidx.slidingpanelayout_slidingpanelayout.version\n- META-INF/androidx.swiperefreshlayout_swiperefreshlayout.version\n- META-INF/androidx.vectordrawable_vectordrawable-animated.version\n- META-INF/androidx.vectordrawable_vectordrawable.version\n- META-INF/androidx.versionedparcelable_versionedparcelable.version\n- META-INF/androidx.viewpager_viewpager.version" > /openbor-android/apktool.yml

# Copy bor.pak
cp /bor.pak /openbor-android/assets/bor.pak

build_aligned_apk
build_unsigned_aab
sign_apk_aab
remove_temp_files
