
init 进程是用户空间的第一个进程, 负责启动用户程序. Linux 系统常用的 init 程序有 sysvinit, busybox init, upstart, systemd 和 procd. 本节选择 sysvinit 进行说明. sysvinit 是 UNIX 系统 5(System V) 风格的 init 程序, 启动配置文件是 "/etc/inittab", 用来指定要执行的程序以及在哪些运行级别执行这些程序. 文件 "/etc/inittab" 如下:

```
# inittab for SysV init

# The default runlevel

# Boot-time system configuration/initilization script.
si::sysinit:/etc/rc.d/init.d/rc S

# Runlevel 0 is halt.
# Runlevel 1 is single-user.
# Runlevels 2-5 are multi-user.
# Runlevel 6 is reboot.

c0:125:respawn:/bin/sh

10:0:once:/etc/rc.d/init.d/rc 0
11:1:once:/etc/rc.d/init.d/rc 1
12:2:once:/etc/rc.d/init.d/rc 2
13:3:once:/etc/rc.d/init.d/rc 3
14:4:once:/etc/rc.d/init.d/rc 4
15:5:once:/etc/rc.d/init.d/rc 5
16:6:once:/etc/rc.d/init.d/rc 6
```

配置行的格式: id:runlevels:action:process.

其中 id 是配置行的标识符, runlevel 是运行级别, action 是要执行的动作, process 是要执行的程序.

sysvinit 使用运行级别定义系统运行模式, 分 8 个运行级别: 前 7 个是数字 0～6, 第 8 个的名称是 "S" 或者 "s". 有 3 个基本的运行级别, 如下表所示.

基本运行级别:

级别 | 目的
---------|----------
 0 | 关机
 1 | 单用户系统
 6 | 重启

不同的 Linux 发行版本对其他运行级别的定义不同, 常见的定义如下表所示.

其他运行级别:

级别 | 目的
---------|----------
 2 | 没有联网的多用户模式
 3 | 联网并且使用命令行界面的多用户模式
 5 | 联网并且使用图形用户界面的多用户模式

```
si::sysinit:/etc/rc.d/init.d/rc S
```

执行 shell 脚本 "/etc/rc.d/init.d/rc", 参数是 "S". shell 脚本 rc 将会遍历执行目录 "/etc/rc.d/rcS.d" 下的每个 shell 脚本, 这些脚本用来初始化系统.

```
13:3:once:/etc/rc.d/init.d/rc 3
```

如果运行级别是 3, 那么执行 shell 脚本 "`/etc/rc.d/init.d/rc`", 参数是 "3". shell 脚本 rc 将会遍历执行目录 "`/etc/rc.d/rc3.d`" 下的每个 shell 脚本.

怎么让一个程序在设备启动的时候自动启动? 写一个启动脚本, 放在目录 "/etc/rc.d/init.d" 下, 然后在目录 "`/etc/rc.d/rc3.d`" 下创建一个软链接, 指向这个启动脚本. 假设程序的名称是 "hello.elf", 启动脚本如下:

```
#!/bin/sh

PROG=hello.elf

case "${1}" in
    start)
        /sbin/${PROG} &
        ;;
    stop)
        pkill ${PROG}
        ;;
    reload)
        ;;

    restart)
        ${0} stop
        sleep 1
        ${0} start
        ;;

    status)
        ;;
    *)

        echo "Usage: ${0} {start|stop|reload|restart|status}"
        exit 1
        ;;
esac
```
