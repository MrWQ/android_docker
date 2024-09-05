## 一· 检查内核
首先查看一下你的内核版本是否>=5.0,根据介绍，如果内核在此版本之下，许多指令无法适配，为了不出错还是升级一下内核。
```
uname -r
5.15.0-1013-oracle #这里最好>=5.0
```
## 二. 安装模块
```
apt install linux-modules-extra-`uname -r`
modprobe binder_linux devices="binder,hwbinder,vndbinder" #进程通信模块
modprobe ashmem_linux #内存共享模块
 
#后两条命令不提示错误 Enter 后没有任何反应说明启动成功
```
上面两个模块都是Android运行所必须的依赖，必须启动成功，否则虚拟化失败，如果这里出错请不要下面的步骤，请自己先解决模块启动失败的问题，如果你是用的oracle 原生镜像，这里应该是没问题的，如果是已经通过网络dd系统发生的错误，这里不给出解决办法请自己查询。(oracle 自带的ubuntu 20.04正常，其他自测)
## 三. 安装docker、创建容器
1.安装docker步骤这里就省略了

2.克隆本项目
```
git clone https://github.com/MrWQ/android_docker
```
3.修改nginx/passwd_scrcpy_web内的账号和密码<br>
现在nginx/passwd_scrcpy_web内账号密码为（admin:admin）,强烈建议自己修改一下
```
生成密码
openssl passwd your_password
```
4.启动脚本
```
start.sh        #启动并创建容器，自动安装scrcpy-web/apk下的安装包
stop.sh         #关闭容器
restart.sh      #重启容器
stop_and_rm.sh  #关闭并删除容器
```
5.查看Android

访问your_ip:8888端口，然后输入自己创建的账号密码（nginx/passwd_scrcpy_web内的账号和密码）

## 四. 说明
目前在arm64架构下测试没问题，amd64应该也可以。（需自测）<br>
我当前使用环境为，使用目前没问题：<br>
1.arm64、4 CPU、24G MEM<br>
2.Ubuntu 20.04<br>

后续可以考虑将安装模块、安装docker放到1个install.sh中，目前就先这样吧，随缘更新
