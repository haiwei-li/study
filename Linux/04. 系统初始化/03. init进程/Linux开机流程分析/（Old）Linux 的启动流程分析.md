
```
1. Linux 的启动流程分析
　　1.1 启动流程一览
　　1.2 BIOS, boot loader 与 kernel 加载: lsinitrd
　　1.3 第一支程序 systemd 及配置档 default.target 进入开机程序分析
　　1.4 init 处理系统初始化流程 (/etc/rc.d/rc.sysinit)
　　1.5 启动系统服务与相关启动配置档 (/etc/rc.d/rc N & /etc/sysconfig)
　　1.6 使用者自订启动启动程序 (/etc/rc.d/rc.local)
　　1.7 根据 /etc/inittab 之配置, 加载终端机或 X-Window 介面
　　1.8 启动过程会用到的主要配置档:  /etc/modprobe.conf, /etc/sysconfig/*
　　1.9 Run level 的切换:  runlevel, init
```