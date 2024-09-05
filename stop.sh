#!/bin/bash

REDROID="android-redroid8"
SCRCPY="android-scrcpy-web"
NGINX="android-nginx"

docker stop ${REDROID}
docker stop ${SCRCPY}
docker stop ${NGINX}