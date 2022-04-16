#!/bin/bash

download_ce() {
    CHANNEL=$1
    DIR=$2
    [[ -z "$CHANNEL" ]] && echo "IITC CE channel not set" && exit 1
    [[ -z "$DIR" ]] && echo "target dir not set" && exit 1

    TMP=$(mktemp -d)

    rm -r "$DIR"
    curl -L -o "$TMP/$CHANNEL.zip" "https://iitc.app/build/$CHANNEL/IITC_Mobile-$CHANNEL.apk"
    unzip -o "$TMP/$CHANNEL.zip" "assets/*" -d "$TMP/$CHANNEL"
    mv "$TMP/$CHANNEL"/assets "$DIR"
    touch "$DIR/.keep"

    rm -r "$TMP"
}

download_ce release scripts/ce
download_ce test scripts/ce-test
download_ce beta scripts/ce-beta