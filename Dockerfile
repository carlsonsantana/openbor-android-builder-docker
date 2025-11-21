FROM archlinux:base-devel-20251019.0.436919

# Environment variables
ENV SDK_VERSION "9477386_latest"
ENV ANDROID_SDK_ROOT /android-sdk
ENV KEYSTORE_NAME keystore_name
ENV KEYSTORE_KEY_PASSWORD keystore_password
ENV KEYSTORE_STORE_PASSWORD keystore_password
ENV GAME_APK_NAME "com.mycompany.gamename"
ENV GAME_NAME "Game Name"

# Install operational system dependencies
RUN pacman -Syu --noconfirm && \
  pacman -S jdk11-openjdk jdk17-openjdk unzip imagemagick --noconfirm

# Copy OpenBOR repository
COPY openbor /openbor

# Create version header file
WORKDIR /openbor/engine
RUN ./version.sh && \
  sed -i "s|org\.openbor\.engine|aaaa.bbbbb.ccccc|g" /openbor/engine/android/app/build.gradle && \
  sed -i "s|\"Openbor\"|\"ZZZZZ\"|g" /openbor/engine/android/app/build.gradle

RUN mkdir /apktool && \
  curl -L https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.12.1.jar --output /apktool/apktool_2.12.1.jar

# Install Android Command-line tools
WORKDIR /
RUN mkdir /android-sdk && \
  curl -L https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}.zip --output /android-sdk/cmdline-tools.zip && \
  unzip /android-sdk/cmdline-tools.zip && \
  mkdir -p /android-sdk/cmdline-tools && \
  mv cmdline-tools /android-sdk/cmdline-tools/latest && \
  cd /android-sdk/cmdline-tools/latest/bin && \
  archlinux-java set java-17-openjdk && \
  echo "y" | ./sdkmanager --install "build-tools;29.0.3" "platform-tools" "platforms;android-29" "tools" "ndk-bundle" && \
  cd /openbor/engine/android && \
  archlinux-java set java-11-openjdk && \
  keytool -genkey -noprompt -v \
    -keystore game_certificate.jks \
    -storepass 123456 \
    -keypass 123456 \
    -alias a \
    -keyalg RSA \
    -dname "CN=gamename.mycompany.com, OU=O, O=O, L=O, S=O, C=US" && \
  printf "storePassword=123456\nkeyPassword=123456\nkeyAlias=a\nstoreFile=/openbor/engine/android/game_certificate.jks\n" > keystore.properties && \
  touch /openbor/engine/android/app/src/main/assets/bor.pak && \
  ./gradlew assembleRelease --no-daemon --no-build-cache && \
  archlinux-java set java-17-openjdk && \
  java -jar /apktool/apktool_2.12.1.jar d /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk -o /openbor-android && \
  rm keystore.properties game_certificate.jks /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk && \
  rm /openbor/engine/android/app/src/main/res/drawable-hdpi/icon.png && \
  rm /openbor/engine/android/app/src/main/res/drawable-ldpi/icon.png && \
  rm /openbor/engine/android/app/src/main/res/drawable-mdpi/icon.png && \
  rm /openbor/engine/android/app/src/main/assets/bor.pak && \
  rm -R /android-sdk ~/.gradle ~/.android

# Volumes
RUN mkdir /output
VOLUME /game_certificate.jks
VOLUME /bor.pak
VOLUME /icon.png
VOLUME /output

# Run build
WORKDIR /
COPY run.sh /
CMD ["bash", "/run.sh"]
