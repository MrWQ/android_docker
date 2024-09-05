#!/bin/bash

REDROID="android-redroid8"
SCRCPY="android-scrcpy-web"
NGINX="android-nginx"

echo -e "\n 1.create ${REDROID}"
docker run -itd --name=${REDROID} \
    --memory-swappiness=0 \
    --privileged --pull always \
    -v ./redroid/data:/data \
    redroid/redroid:8.1.0-latest \
    androidboot.hardware=mt6891 ro.secure=0 ro.boot.hwc=GLOBAL    ro.ril.oem.imei=861503068361145 ro.ril.oem.imei1=861503068361145 ro.ril.oem.imei2=861503068361148 ro.ril.miui.imei0=861503068361148 ro.product.manufacturer=Xiaomi ro.build.product=chopin \
    redroid.width=720 redroid.height=1280 \
    redroid.gpu.mode=guest

echo -e "\n 2.create android:scrcpy-web "
docker run -itd  -v ./scrcpy-web/data:/data -v ./scrcpy-web/apk:/apk --name ${SCRCPY} --link ${REDROID} emptysuns/scrcpy-web:v0.1

sleep 3
echo -e "\n 3.${SCRCPY} adb connect ${REDROID}"
docker exec -it ${SCRCPY} adb connect ${REDROID}:5555

echo -e "\n 4.create android:nginx"
docker run -d -v ./nginx/nginx.conf:/etc/nginx/nginx.conf -v ./nginx/passwd_scrcpy_web:/etc/nginx/passwd_scrcpy_web -v ./nginx/conf.d:/etc/nginx/conf.d -p 8888:80 --name ${NGINX} --link ${SCRCPY} nginx:1.24

sleep 5
echo -e "\n 5.install APK"
for file in ` ls ./scrcpy-web/apk`
do
    if [[ -f "./scrcpy-web/apk/"$file ]]; then
      echo "installing $file"
      docker exec -it ${SCRCPY} adb install /apk/$file
    fi
done
