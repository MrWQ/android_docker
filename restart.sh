#!/bin/bash

REDROID="android-redroid8"
SCRCPY="android-scrcpy-web"
NGINX="android-nginx"

docker restart ${REDROID}
docker restart ${SCRCPY}
docker restart ${NGINX}