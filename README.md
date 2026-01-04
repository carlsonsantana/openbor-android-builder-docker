# OpenBOR Android Builder on Docker

This project allows you to build **OpenBOR** games for **Android** using **Docker**.

## Install

To install this **Docker image**, you must have **Docker** installed on your machine and in the terminal execute the following command:

```sh
docker pull carlsonsantana/openbor-android-builder:latest
```

Or build it yourself executing the following command on the terminal:

```sh
docker build -t openbor-android-builder
```

### Volumes

You must mount the following volumes when running the Docker image. These mounts provide the necessary input files and define the location for the final output.

* `/bor.pak` your compiled OpenBOR game;
* `/icon.png` the icon for your Android game;
* `/icon_background.png` the background icon for your Android game;
* `/output` the directory where the aligned or signed `.apk` will be created;
* **(Optional)** `/game_certificate.key` the keystore file used to [sign the `.apk`](https://developer.android.com/build/building-cmdline#sign_manually), if passed you must pass the following environment variables `GAME_KEYSTORE_PASSWORD`, `GAME_KEYSTORE_KEY_ALIAS` and `GAME_KEYSTORE_KEY_PASSWORD`.

### Environment Variables

* `GAME_APK_NAME` the [Application ID](https://developer.android.com/build/configure-app-module#set-application-id) (e.g., `com.mycompany.mygame`) of your Android game;
* `GAME_NAME` the name displayed beneath the app icon on the device;
* `GAME_VERSION_NAME` the version showed to the user that allows use letters and dots (example: "1.0.0");
* `GAME_METADATA_SITE` the website showed on the side menu;
* `GAME_KEYSTORE_PASSWORD` the keystore password, required when `/game_certificate.key` volume is filled;
* `GAME_KEYSTORE_KEY_ALIAS` the key alias in keystore, required when `/game_certificate.key` volume is filled;
* `GAME_KEYSTORE_KEY_PASSWORD` the key password in keystore, required when `/game_certificate.key` volume is filled.
