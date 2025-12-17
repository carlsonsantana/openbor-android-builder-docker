# OpenBOR Android Builder on Docker

This project allows you to build **OpenBOR** games for **Android** using **Docker**.

> **⚠️ Important:** The build process generates an **unsigned** `*.apk` file. You must still [align and sign your app](https://developer.android.com/build/building-cmdline#sign_manually) before it can be installed on an Android device.

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
* `/output` the directory where the unsigned `.apk` will be created.

### Environment Variables

* `GAME_APK_NAME` the [Application ID](https://developer.android.com/build/configure-app-module#set-application-id) (e.g., `com.mycompany.mygame`) of your Android game;
* `GAME_NAME` the name displayed beneath the app icon on the device;
* `GAME_VERSION_NAME` the version showed to the user that allows use letters and dots (example: "1.0.0");
* `GAME_METADATA_SITE` the website showed on the side menu.
