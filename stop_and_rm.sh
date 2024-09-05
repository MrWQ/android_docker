#!/bin/bash

REDROID="android-redroid8"
SCRCPY="android-scrcpy-web"
NGINX="android-nginx"

docker stop ${REDROID} && docker rm ${REDROID}
docker stop ${SCRCPY} && docker rm ${SCRCPY}
docker stop ${NGINX} && docker rm ${NGINX}