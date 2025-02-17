
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 Systemd 和 Systemctl 基础](#1-systemd-和-systemctl-基础)
  - [1.1 版本](#11-版本)
  - [1.2 二进制文件和库文件](#12-二进制文件和库文件)
  - [1.3 systemd 是否运行](#13-systemd-是否运行)
  - [1.4 分析 systemd 启动进程](#14-分析-systemd-启动进程)
  - [1.5 分析启动时各个进程花费的时间](#15-分析启动时各个进程花费的时间)
  - [1.6 分析启动时的关键链](#16-分析启动时的关键链)
  - [1.7 列出所有可用单元](#17-列出所有可用单元)
  - [1.8 列出所有运行中单元](#18-列出所有运行中单元)
  - [1.9 列出所有失败单元](#19-列出所有失败单元)
  - [1.10 检查某个单元(如 cron.service)是否启用](#110-检查某个单元如-cronservice 是否启用)
  - [1.11 检查某个单元或服务是否运行](#111-检查某个单元或服务是否运行)
- [2 使用 Systemctl 控制并管理服务](#2-使用-systemctl-控制并管理服务)
  - [2.1 列出所有服务(包括启用的和禁用的)](#21-列出所有服务包括启用的和禁用的)
  - [2.2 启动、重启、停止、重载服务以及检查服务](#22-启动-重启-停止-重载服务以及检查服务)
  - [2.3 如何激活服务并在启动时启用或禁用服务(即系统启动时自动启动服务)](#23-如何激活服务并在启动时启用或禁用服务即系统启动时自动启动服务)
  - [2.4 如何屏蔽(让它不能启动)或显示服务](#24-如何屏蔽让它不能启动或显示服务)
  - [2.5 使用 systemctl 命令杀死服务](#25-使用-systemctl-命令杀死服务)
- [3 使用 Systemctl 控制并管理挂载点](#3-使用-systemctl-控制并管理挂载点)
  - [3.1 列出所有系统挂载点](#31-列出所有系统挂载点)
  - [3.2 挂载、卸载、重新挂载、重载系统挂载点并检查系统中挂载点状态](#32-挂载-卸载-重新挂载-重载系统挂载点并检查系统中挂载点状态)
  - [3.3 在启动时激活、启用或禁用挂载点(系统启动时自动挂载)](#33-在启动时激活-启用或禁用挂载点系统启动时自动挂载)
  - [3.4 在 Linux 中屏蔽(让它不能启用)或可见挂载点](#34-在-linux-中屏蔽让它不能启用或可见挂载点)
- [4 使用 Systemctl 控制并管理套接口](#4-使用-systemctl-控制并管理套接口)
  - [4.1 列出所有可用系统套接口](#41-列出所有可用系统套接口)
  - [4.2 在 Linux 中启动、重启、停止、重载套接口并检查其状态](#42-在-linux-中启动-重启-停止-重载套接口并检查其状态)
  - [4.3 在启动时激活套接口, 并启用或禁用它(系统启动时自启动)](#43-在启动时激活套接口-并启用或禁用它系统启动时自启动)
  - [4.4 屏蔽(使它不能启动)或显示套接口](#44-屏蔽使它不能启动或显示套接口)
- [5 服务的 CPU 利用率](#5-服务的-cpu-利用率)
  - [5.1 获取当前某个服务的 CPU 分配额](#51-获取当前某个服务的-cpu-分配额)
  - [5.2 将某个服务(httpd.service)的 CPU 分配份额限制为 2000 CPUShares\/](#52-将某个服务 httpdservice 的-cpu-分配份额限制为-2000-cpushares)
  - [5.3 检查某个服务的所有配置细节](#53-检查某个服务的所有配置细节)
  - [5.4 分析某个服务的关键链](#54-分析某个服务的关键链)
  - [5.5 获取某个服务的依赖性列表](#55-获取某个服务的依赖性列表)
  - [5.6 按等级列出控制组](#56-按等级列出控制组)
  - [5.7 按 CPU、内存、输入和输出列出控制组](#57-按-cpu-内存-输入和输出列出控制组)
- [6 控制系统运行等级](#6-控制系统运行等级)
  - [6.1 启动系统救援模式](#61-启动系统救援模式)
  - [6.2 进入紧急模式](#62-进入紧急模式)
  - [6.3 列出当前使用的运行等级](#63-列出当前使用的运行等级)
  - [6.4 启动运行等级 5, 即图形模式](#64-启动运行等级-5-即图形模式)
  - [6.5 启动运行等级 3, 即多用户模式(命令行)](#65-启动运行等级-3-即多用户模式命令行)
  - [6.6 设置多用户模式或图形模式为默认运行等级](#66-设置多用户模式或图形模式为默认运行等级)
  - [6.7 重启、停止、挂起、休眠系统或使系统进入混合睡眠](#67-重启-停止-挂起-休眠系统或使系统进入混合睡眠)
- [7 参考](#7-参考)

<!-- /code_chunk_output -->
Systemctl 是一个 systemd 工具, 主要负责控制 systemd 系统和服务管理器.

Systemd 是一个系统管理守护进程、工具和库的集合, 用于取代 System V 初始进程. Systemd 的功能是用于集中管理和配置类 UNIX 系统.

在 Linux 生态系统中, Systemd 被部署到了大多数的标准 Linux 发行版中, 只有为数不多的几个发行版尚未部署. Systemd 通常是所有其它守护进程的父进程, 但并非总是如此.

# 1 Systemd 和 Systemctl 基础

## 1.1 版本

首先检查你的系统中是否安装有**systemd**并确定当前安装的版本

```
[root@gerrylee ~]# systemctl --version
systemd 219
+PAM +AUDIT +SELINUX +IMA -APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 -SECCOMP +BLKID +ELFUTILS +KMOD +IDN
```

## 1.2 二进制文件和库文件

检查 systemd 和 systemctl 的二进制文件和库文件的安装位置

```
[root@gerrylee ~]# whereis systemd
systemd: /usr/lib/systemd /etc/systemd /usr/share/systemd /usr/share/man/man1/systemd.1.gz
[root@gerrylee ~]# whereis systemctl
systemctl: /usr/bin/systemctl /usr/share/man/man1/systemctl.1.gz
```

## 1.3 systemd 是否运行

```
[root@gerrylee ~]# ps -eaf | grep [s]ystemd
root         1     0  0 5 月 21 ?       00:02:54 /usr/lib/systemd/systemd --switched-root --system --deserialize 22
root      2656     1  0 5 月 21 ?       00:00:04 /usr/lib/systemd/systemd-journald
root      2692     1  0 5 月 21 ?       00:00:00 /usr/lib/systemd/systemd-udevd
dbus      5466     1  7 5 月 21 ?       16:21:20 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation
root      5501     1  0 5 月 21 ?       00:00:07 /usr/lib/systemd/systemd-logind
```

注意: systemd 是作为父进程(PID=1)运行的. 在上面带(\-e)参数的 ps 命令输出中, 选择所有进程, (\-a)选择除会话前导外的所有进程, 并使用(\-f)参数输出完整格式列表(即 \-eaf).

## 1.4 分析 systemd 启动进程

```
[root@gerrylee project]# systemd-analyze
Startup finished in 12.824s (firmware) + 3.846s (loader) + 798ms (kernel) + 1.862s (initrd) + 26.028s (userspace) = 45.361s
```

## 1.5 分析启动时各个进程花费的时间

```
[root@gerrylee project]# systemd-analyze blame
         18.211s kdump.service
          6.331s NetworkManager-wait-online.service
          5.034s bolt.service
           656ms fwupd.service
           563ms systemd-udev-settle.service
           484ms dev-mapper-centos\x2droot.device
           461ms lvm2-monitor.service
...
```

## 1.6 分析启动时的关键链

```
[root@gerrylee project]# systemd-analyze critical-chain
The time after the unit is active or started is printed after the "@" character.
The time the unit takes to start is printed after the "+" character.

graphical.target @26.024s
└─multi-user.target @26.024s
  └─tuned.service @7.800s +291ms
    └─network.target @7.793s
      └─network.service @7.505s +287ms
        └─NetworkManager-wait-online.service @1.173s +6.331s
          └─NetworkManager.service @1.121s +44ms
            └─dbus.service @1.088s
              └─basic.target @1.082s
                └─paths.target @1.082s
                  └─cups.path @1.082s
                    └─sysinit.target @1.077s
                      └─systemd-update-utmp.service @1.066s +9ms
                        └─auditd.service @919ms +144ms
                          └─systemd-tmpfiles-setup.service @902ms +16ms
                            └─rhel-import-state.service @889ms +12ms
                              └─local-fs.target @887ms
                                └─run-user-42.mount @11.469s
                                  └─swap.target @800ms
                                    └─dev-mapper-centos\x2dswap.swap @784ms +15ms
                                      └─dev-mapper-centos\x2dswap.device @718ms
```

重要: Systemctl 接受服务(.service), 挂载点(.mount), 套接口(.socket)和设备(.device)作为单元.

## 1.7 列出所有可用单元

```
[root@gerrylee project]# systemctl list-unit-files
UNIT FILE                                     STATE
proc-sys-fs-binfmt_misc.automount             static
dev-hugepages.mount                           static
dev-mqueue.mount                              static
proc-fs-nfsd.mount                            static
proc-sys-fs-binfmt_misc.mount                 static
sys-fs-fuse-connections.mount                 static
sys-kernel-config.mount                       static
sys-kernel-debug.mount                        static
tmp.mount                                     disabled
var-lib-nfs-rpc_pipefs.mount                  static
brandbot.path                                 disabled
cups.path                                     enabled
systemd-ask-password-console.path             static
systemd-ask-password-plymouth.path            static
...
```

## 1.8 列出所有运行中单元

```
[root@gerrylee project]# systemctl list-units
  UNIT                                                  LOAD   ACTIVE SUB       DESCRIPTION
  proc-sys-fs-binfmt_misc.automount                     loaded active running   Arbitrary Executable File Formats File System Automou
  sys-devices-pci0000:00-0000:00:01.0-0000:01:00.1-sound-card1.device loaded active plugged   GP106 High Definition Audio Controller
  sys-devices-pci0000:00-0000:00:17.0-ata1-host0-target0:0:0-0:0:0:0-block-sda-sda1.device loaded active plugged   ST2000DM005-2CW102
  sys-devices-pci0000:00-0000:00:17.0-ata1-host0-target0:0:0-0:0:0:0-block-sda.device loaded active plugged   ST2000DM005-2CW102
  sys-devices-pci0000:00-0000:00:17.0-ata3-host2-target2:0:0-2:0:0:0-block-sdb-sdb1.device loaded active plugged   INTEL_SSDSC2KW512G
  sys-devices-pci0000:00-0000:00:1f.6-net-enp0s31f6.device loaded active plugged   Ethernet Connection (2) I219-V
  sys-devices-platform-serial8250-tty-ttyS1.device      loaded active plugged   /sys/devices/platform/serial8250/tty/ttyS1
  sys-devices-platform-serial8250-tty-ttyS2.device      loaded active plugged   /sys/devices/platform/serial8250/tty/ttyS2
  sys-devices-platform-serial8250-tty-ttyS3.device      loaded active plugged   /sys/devices/platform/serial8250/tty/ttyS3
...
```

## 1.9 列出所有失败单元

```
root@gerrylee project]# systemctl --failed
  UNIT            LOAD   ACTIVE SUB    DESCRIPTION
● ipmievd.service loaded failed failed Ipmievd Daemon

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.

1 loaded units listed. Pass --all to see loaded but inactive units, too.
To show all installed unit files use 'systemctl list-unit-files'.
```

## 1.10 检查某个单元(如 cron.service)是否启用

```
[root@gerrylee project]# systemctl is-enabled crond.service
enabled
```

## 1.11 检查某个单元或服务是否运行

```
[root@gerrylee project]# systemctl is-enabled crond.service
enabled
[root@gerrylee project]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
```

# 2 使用 Systemctl 控制并管理服务

## 2.1 列出所有服务(包括启用的和禁用的)

```
[root@gerrylee project]# systemctl list-unit-files --type=service
UNIT FILE                                     STATE
abrt-oops.service                             enabled
abrt-pstoreoops.service                       disabled
abrt-vmcore.service                           enabled
abrt-xorg.service                             enabled
abrtd.service                                 enabled
accounts-daemon.service                       enabled
alsa-restore.service                          static
alsa-state.service                            static
anaconda-direct.service                       static
anaconda-nm-config.service                    static
...
```

## 2.2 启动、重启、停止、重载服务以及检查服务

```
systemctl start httpd.service
systemctl restart httpd.service
systemctl stop httpd.service
systemctl reload httpd.service
systemctl status httpd.service
```

## 2.3 如何激活服务并在启动时启用或禁用服务(即系统启动时自动启动服务)

```
systemctl is-active httpd.service
systemctl enable httpd.service
systemctl disable httpd.service
```

## 2.4 如何屏蔽(让它不能启动)或显示服务

```
# systemctl mask httpd.service
ln -s '/dev/null' '/etc/systemd/system/httpd.service'

# systemctl unmask httpd.service
rm '/etc/systemd/system/httpd.service'
```

## 2.5 使用 systemctl 命令杀死服务

```
systemctl kill httpd
```

# 3 使用 Systemctl 控制并管理挂载点

## 3.1 列出所有系统挂载点

```
systemctl list-unit-files --type=mount
```

## 3.2 挂载、卸载、重新挂载、重载系统挂载点并检查系统中挂载点状态

```
systemctl start tmp.mount
systemctl stop tmp.mount
systemctl restart tmp.mount
systemctl reload tmp.mount
systemctl status tmp.mount
```

## 3.3 在启动时激活、启用或禁用挂载点(系统启动时自动挂载)

```
systemctl is-active tmp.mount
systemctl enable tmp.mount
systemctl disable  tmp.mount
```

## 3.4 在 Linux 中屏蔽(让它不能启用)或可见挂载点

```
# systemctl mask tmp.mount
ln -s '/dev/null' '/etc/systemd/system/tmp.mount'

# systemctl unmask tmp.mount
rm '/etc/systemd/system/tmp.mount'
```

# 4 使用 Systemctl 控制并管理套接口

## 4.1 列出所有可用系统套接口

```
systemctl list-unit-files --type=socket
```

## 4.2 在 Linux 中启动、重启、停止、重载套接口并检查其状态

```
# systemctl start cups.socket
# systemctl restart cups.socket
# systemctl stop cups.socket
# systemctl reload cups.socket
# systemctl status cups.socket
```

## 4.3 在启动时激活套接口, 并启用或禁用它(系统启动时自启动)

```
# systemctl is-active cups.socket
# systemctl enable cups.socket
# systemctl disable cups.socket
```

## 4.4 屏蔽(使它不能启动)或显示套接口

```
# systemctl mask cups.socket
ln -s '/dev/null' '/etc/systemd/system/cups.socket'

# systemctl unmask cups.socket
rm '/etc/systemd/system/cups.socket'
```

# 5 服务的 CPU 利用率

## 5.1 获取当前某个服务的 CPU 分配额

```
# systemctl show -p CPUShares httpd.service
CPUShares=1024
```

注意: 各个服务的默认 CPU 分配份额=1024, 你可以增加/减少某个进程的 CPU 分配份额.

## 5.2 将某个服务(httpd.service)的 CPU 分配份额限制为 2000 CPUShares\/

```
# systemctl set-property httpd.service CPUShares=2000
# systemctl show -p CPUShares httpd.service
CPUShares=2000
```

注意: 当你为某个服务设置 CPUShares, 会自动创建一个以服务名命名的目录(如 httpd.service), 里面包含了一个名为 90-CPUShares.conf 的文件, 该文件含有 CPUShare 限制信息, 你可以通过以下方式查看该文件:

```
# vi /etc/systemd/system/httpd.service.d/90-CPUShares.conf

[Service]
CPUShares=2000
```

## 5.3 检查某个服务的所有配置细节

```
# systemctl show httpd
```

## 5.4 分析某个服务的关键链

```
# systemd-analyze critical-chain httpd.service
```

## 5.5 获取某个服务的依赖性列表

```
# systemctl list-dependencies httpd.service
```

## 5.6 按等级列出控制组

```
# systemd-cgls
```

## 5.7 按 CPU、内存、输入和输出列出控制组

```
# systemd-cgtop
```

# 6 控制系统运行等级

## 6.1 启动系统救援模式

```
# systemctl rescue
```

## 6.2 进入紧急模式

```
# systemctl emergency
```

## 6.3 列出当前使用的运行等级

```
# systemctl get-default
```

## 6.4 启动运行等级 5, 即图形模式

```
# systemctl isolate runlevel5.target
或
# systemctl isolate graphical.target
```

## 6.5 启动运行等级 3, 即多用户模式(命令行)

```
# systemctl isolate runlevel3.target
或
# systemctl isolate multiuser.target
```

## 6.6 设置多用户模式或图形模式为默认运行等级

```
# systemctl set-default runlevel3.target

# systemctl set-default runlevel5.target
```

## 6.7 重启、停止、挂起、休眠系统或使系统进入混合睡眠

```
# systemctl reboot
# systemctl halt
# systemctl suspend
# systemctl hibernate
# systemctl hybrid-sleep
```

运行等级:

- Runlevel 0 : 关闭系统
- Runlevel 1 : 救援?维护模式
- Runlevel 3 : 多用户, 无图形系统
- Runlevel 4 : 多用户, 无图形系统
- Runlevel 5 : 多用户, 图形化系统
- Runlevel 6 : 关闭并重启机器

# 7 参考

https://linux.cn/article-5926-1.html