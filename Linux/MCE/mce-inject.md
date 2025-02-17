使用 mce-inject 工具, 但是您需要加载 mce_inject 内核模块.

```
modprobe mce_inject
```

内核选项是

```
CONFIG_X86_MCE_INJECT
```

接下来, 您需要下载 mce_inject 工具的源代码, 安装依赖项并编译它:

```
$ git clone https://github.com/andikleen/mce-inject.git
$ sudo yum install flex bison
$ cd mce-inject
$ make
```

在 mce-inject 目录下, 添加文件, 注意修改 address 即可

```
#correct
CPU 0
BANK 18
STATUS 0x8c000000001000c0
#ADDR 0x40001000
ADDR 0x100003000
#ADDR 0x100002001
MISC 0x80
```

然后执行

```
./mce-inject ./correct
```



# 参考

https://www.cnblogs.com/muahao/p/6003910.html

https://www.oracle.com/technetwork/cn/articles/servers-storage-admin/fault-management-linux-2005816-zhs.html

https://stackoverflow.com/questions/38496643/how-can-we-generate-mcemachine-check-errors
