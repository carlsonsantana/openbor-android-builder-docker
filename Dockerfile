FROM debian:bullseye-20251117-slim as android-sdk-builder

# Build arguments
ARG SDK_VERSION="9477386_latest"
ARG NDK_VERSION="21.4.7075529"
ARG CMAKE_VERSION="3.22.1"
ARG APKTOOL_VERSION="2.12.1"

# Install dependencies
RUN apt update && apt upgrade -y && \
  apt install -y curl unzip openjdk-17-jdk make file xz-utils && \
  apt-get clean -y && \
  apt-get autoremove -y && \
  apt-get autoclean -y && \
  rm -rf /tmp/* && \
  rm -rf /var/lib/apt/lists/*
RUN mkdir /apktool && \
  curl -L "https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_""$APKTOOL_VERSION"".jar" --output /apktool/apktool.jar

# Copy OpenBOR repository
COPY openbor /openbor
COPY build_libs.sh /opt/build_libs.sh

# Create version header file
WORKDIR /openbor/engine
RUN /bin/bash ./version.sh && \
  sed -i "s|org\.openbor\.engine|aaaaa.bbbbb.ccccc|g" /openbor/engine/android/app/build.gradle && \
  sed -i "s|\"Openbor\"|\"ZZZZZ\"|g" /openbor/engine/android/app/build.gradle

# Create source builder
WORKDIR /
RUN export ANDROID_SDK_ROOT=/android-sdk && \
  mkdir /android-sdk && \
  curl -L https://dl.google.com/android/repository/commandlinetools-linux-${SDK_VERSION}.zip --output /android-sdk/cmdline-tools.zip && \
  unzip /android-sdk/cmdline-tools.zip && \
  mkdir -p /android-sdk/cmdline-tools && \
  mv cmdline-tools /android-sdk/cmdline-tools/latest && \
  cd /android-sdk/cmdline-tools/latest/bin && \
  echo "y" | ./sdkmanager --install "build-tools;36.0.0" "platform-tools" "platforms;android-36" "tools" "ndk;${NDK_VERSION}" "cmake;${CMAKE_VERSION}" && \
  cd /openbor/engine/android && \
  keytool -genkey -noprompt -v \
    -keystore game_certificate.jks \
    -storepass 123456 \
    -keypass 123456 \
    -alias a \
    -keyalg RSA \
    -dname "CN=gamename.mycompany.com, OU=O, O=O, L=O, S=O, C=US" && \
  printf "storePassword=123456\nkeyPassword=123456\nkeyAlias=a\nstoreFile=/openbor/engine/android/game_certificate.jks\n" > keystore.properties && \
  touch /openbor/engine/android/app/src/main/assets/bor.pak && \
  bash /opt/build_libs.sh && \
  ./gradlew assembleRelease --no-daemon --no-build-cache && \
  java -jar /apktool/apktool.jar d /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk -o /openbor-android && \
  mkdir /openbor-android/res/mipmap-ldpi && \
  rm keystore.properties game_certificate.jks /openbor/engine/android/app/build/outputs/apk/release/OpenBOR.apk && \
  rm /openbor/engine/android/app/src/main/assets/bor.pak && \
  rm -R /android-sdk ~/.gradle ~/.android && \
  unset ANDROID_SDK_ROOT


# Another image with only used resources
FROM eclipse-temurin:17.0.17_10-jdk-alpine-3.23

# Install dependencies
RUN apk --update --no-cache add curl imagemagick oxipng abseil-cpp-hash gtest libprotobuf fmt && \
  apk --update --no-cache add android-build-tools --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN curl -L "https://github.com/carlsonsantana/signmyapp/releases/download/1.1.0/signmyapp.jar" --output /opt/signmyapp.jar && \
  curl -L "https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar" --output /opt/bundletool.jar && \
  curl -L "https://github.com/Sable/android-platforms/raw/f2ca864c44f277bbc09afda0ba36437ce22105f0/android-36/android.jar" --output /opt/android.jar

# Copy files from previous build
RUN mkdir /apktool
COPY --from=android-sdk-builder /apktool/apktool.jar /apktool/apktool.jar
COPY --from=android-sdk-builder /openbor-android /openbor-android

# Volumes
RUN mkdir /output
VOLUME /bor.pak
VOLUME /icon.png
VOLUME /icon_background.png
VOLUME /output
VOLUME /game_certificate.key

# Environment variables
ENV GAME_APK_NAME "com.mycompany.gamename"
ENV GAME_NAME "Game Name"
ENV GAME_VERSION_CODE "100"
ENV GAME_VERSION_NAME "1.0.0"
ENV GAME_KEYSTORE_PASSWORD ""
ENV GAME_KEYSTORE_KEY_ALIAS ""
ENV GAME_KEYSTORE_KEY_PASSWORD ""

# Run build
WORKDIR /
COPY script /script
CMD ["sh", "/script/run.sh"]
