

https://cloud.tencent.com/developer/article/1162147

https://blog.csdn.net/silvervi/article/details/77528916

https://blog.csdn.net/defeattroy/article/details/8849057


虚拟机加上串口

```
-chardev pty,id=charserial0 -device isa-serial,chardev=charserial0,id=serial0
```
启动虚拟机会有

char device redirected to /dev/pts/4 (label charserial0)

1. host 发, 查看 guest

host 写 guest:

echo "root" > /dev/pts/4

host 读 guest 重定向信息:

cat /dev/pts/4

2. guest 发, host 看

在 guest 中执行

echo love > /dev/ttyS0

在 host 中查看

cat /dev/pts/4


3. 通过串口工具访问虚拟机

minicom

https://blog.csdn.net/IOT_SONG/article/details/79767254

https://www.cnblogs.com/xiaofengkang/archive/2012/09/20/2695590.html

串口设备不可同时使用

4. 串口工具

ckermit

https://blog.csdn.net/qq_38880380/article/details/77669109