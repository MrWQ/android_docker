## 一· 检查内核
首先查看一下你的内核版本是否>=5.0,根据介绍，如果内核在此版本之下，许多指令无法适配，为了不出错还是升级一下内核，如果不升级内核该镜像issue也给出解决方案，我懒得看，有兴趣自己研究去。
```
uname -r
5.15.0-1013-oracle #这里最好>=5.0
```
##二. 安装模块
```
apt install linux-modules-extra-`uname -r`
modprobe binder_linux devices="binder,hwbinder,vndbinder" #进程通信模块
modprobe ashmem_linux #内存共享模块
 
#后两条命令不提示错误 / Enter后没有任何反应说明启动成功
```
上面两个模块都是Android运行所必须的依赖，必须启动成功，否则虚拟化失败，如果这里出错请不要下面的步骤，请自己先解决模块启动失败的问题，如果你是用的oracle 原生镜像，这里应该是没问题的，如果是已经通过网络dd系统发生的错误，这里不给出解决办法请自己查询。(oracle 自带的ubuntu 20.04正常，其他自测)

## 三. docker启动redroid
```
docker run -itd --name=redroid8\
    --memory-swappiness=0 \
    --privileged --pull always \
    -v /root/tools/redroid/data:/data \
    -p 5555:5555 \
    redroid/redroid:8.1.0-latest \
    androidboot.hardware=mt6891 ro.secure=0 ro.boot.hwc=GLOBAL    ro.ril.oem.imei=861503068361145 ro.ril.oem.imei1=861503068361145 ro.ril.oem.imei2=861503068361148 ro.ril.miui.imei0=861503068361148 ro.product.manufacturer=Xiaomi ro.build.product=chopin \
    redroid.width=720 redroid.height=1280 \
    redroid.gpu.mode=guest
```
- --memory-swappiness=0 禁止swap，防止I/O成为性能瓶颈，甲骨文Arm给的内存挺多的，满配24g内存，不用担心用得完<br>
- --privileged 启动特权模式，使用该参数，container内的root拥有真正的root权限。防止奇奇怪怪的毛病<br>
- -v /root/test/data:/data 映射目录，你可以把/root/test/data换成其他的目录，方便你备份<br>
- redroid/redroid:13.0.0-latest(底层是Android13) 使用的镜像tag，这里我选择这个tag，群友说redroid:8.1.0-arm64(底层是Android8)这个资源占用最少，性能最好，出问题概率最低。
- androidboot.hardware=mt6891 ro.secure=0 ro.boot.hwc=GLOBAL ro.ril.oem.imei=861503068361145 ro.ril.oem.imei1=861503068361145 ro.ril.oem.imei2=861503068361148 ro.ril.miui.imei0=861503068361148 ro.product.manufacturer=Xiaomi ro.build.product=chopin 这部分是白嫖群友的，据他说是红米Note10的参数，这个是为了模拟一下手机型号，某些游戏检测到不合法的手机型号会封号，感兴趣自己抓一下build.prop参数，替换掉。方法：https://www.jianshu.com/p/098b8809d85d
- redroid.width=720 redroid.height=1280 这个是设置分辨率，对于这种远程ADB来说，这个参数是最好的，如果非常卡可以适当调小
- redroid.gpu.mode=guest 强制选择这个容器的软解（如果不加这条参数就是硬解），区别在于：软解更占资源，奇奇怪怪的问题少；硬解性能高、资源占用率低。能用硬解就用硬解，不同版本硬解/软解问题不同，硬解不能用时再开软解，一般没多大问题。欢迎下方评论区反馈，这个就自测了

此时就可以用adb测试连接了<br>
下载 scrcpy-win64（https://github.com/Genymobile/scrcpy/releases），解压
使用目录里的open_a_terminal_here.bat 在本目录打开一个窗口
```
adb.exe connect 你的ip:你的端口
然后打开scrcpy.exe会自动显示画面
```
## 四. docker运行scrcpy-ws获得web端
目前ws-scrcpy没有官方镜像，有人提了pr但是都一年多了都没有合并，看原作者的意思是不希望维护docker镜像，需要该pr的人维护，但是提该pr的人可能也觉得麻烦不想维护.....

所以我自己打包了个scrcpy-web镜像push到dockerhub上去了，支持amd64和arm64(其他架构貌似需求不大所以没加)，随缘更新，保证可用就行。
```
# 启动容器
docker run --rm -itd  -v /root/tools/scrcpy-web/data:/data --name scrcpy-web -p 48000:8000/tcp  --link redroid8:myphone1 emptysuns/scrcpy-web:v0.1
# scrcpy-web容器连接adb端口
docker exec -it scrcpy-web adb connect myphone1:5555
connected to myphone1:5555 #出现这个说明启动成功
```
- -p 127.0.0.1:48000:8000/tcp 这里只映射127.0.0.1，因为我们下面需要用nginx做密码登录，所以只允许本机访问，防止有人扫描抓取，如果你有其他玩法，就改变这个映射端口。
- --name scrcpy-web 这里最好加个名称，因为后面连接adb要用到，比如这个名称就叫scrcpy-web
- -v /root/scrcpy-web/data:/data 映射一个目录进去，方便到时候用adb install 安装本地apk，因为启动的安卓容器只能由这个scrcpy-web访问，方便以后本地向容器里传数据。
- --link redroid8:myphone1 意思是本容器连接到其他容器，<你需要连接的容器名称>:<自定义别名>,这里这么写就是为了只需要scrcpy-web容器能连接改adb端口，其他都是拒绝，为了安全。
- 等待容器启动成功后，用curl访问一下127.0.0.1:48000查看是否启动成功
## 五.  nginx反代scrcpy-web端口，增加密码登录
用openssl生成账号密码文件
```
echo -n "test:" > /etc/nginx/passwd_scrcpy_web #生成一个用户名，将test改成自己的用户名
openssl passwd qwert1234 >> /etc/nginx/passwd_scrcpy_web #加密密文，qwert1234改成自己的密码
```
配置nginx auth模块
```
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
upstream websocket {
 
     #这里是scrcpy-web的ip+端口，docker ps可以查看
     #你是如上操作的就是127.0.0.1:48000,因为这里要代理websocket
    server 127.0.0.1:48000; 
}
 
server {
	listen 80;
	server_name test.com;
	#root /usr/share/nginx/html;
	auth_basic "Please input password:"; #这里是输入密码的提示信息
        auth_basic_user_file /etc/nginx/passwd_scrcpy_web; #这里是密码文件位置
	location / {
 
		add_header Access-Control-Allow-Origin *;
    		add_header Access-Control-Allow-Methods 'GET, POST, OPTIONS';
    		add_header Access-Control-Allow-Headers 'DNT,X-Mx-ReqToken,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization';
	     if ($request_method = 'OPTIONS') {
        		return 204;
    		}
		proxy_pass http://websocket;
		proxy_set_header Host $host; 
		proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
}
其实如上加了一群header是为了做一些简单的防护和允许跨站请求，方便你把这个网页插入其他站点做内嵌网页，最关键的就是以下三点 + 转发ws的部分:

proxy_pass http://websocket;
proxy_set_header Host $host; 
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
```


## 参考：
https://blog.imoeq.com/oracle-arm-run-android-by-docker/<br>
https://blog.imoeq.com/scrcpy-run-a-android-web-page/