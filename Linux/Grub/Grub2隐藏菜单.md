
# 1 相关配置选项概述

## 1.1 GRUB_TIMEOUT

在开机选择菜单项的超时时间, 超过该时间将使用默认的菜单项来引导对应的操作系统. 默认值为 5 秒. 等待过程中, 按下任意按键都可以中断等待.

设置为 0 时, 将不列出菜单直接使用默认的菜单项引导.
设置为"-1"时将永久等待选择.
是否显示菜单, 和"GRUB\_TIMEOUT\_STYLE"的设置有关.

## 1.2 GRUB\_TIMEOUT\_STYLE

如果该 key 未设置值或者设置的值为"menu", 则列出启动菜单项, 并等待"GRUB\_TIMEOUT"指定的超时时间.

如果设置为"countdown"和"hidden", 则不显示启动菜单项, 而是直接等待"GRUB\_TIMEOUT"指定的超时时间, 如果超时了则启动默认菜单项并引导.

在等待过程中, 按下"ESC"键可以列出启动菜单. 设置为 countdown 和 hidden 的区别是 countdown 会显示超时时间的剩余时间, 而 hidden 则完全隐藏超时时间.

# 2 修改 Grub 配置文件

## 2.1 直接修改配置文件

将 grub2 配置文件修改如下样式:

```
terminal_output console
if [ x$feature_timeout_style = xy ] ; then
  set timeout_style=hidden
  set timeout=0
# Fallback normal timeout code in case the timeout_style feature is
# unavailable.
else
  set timeout=0
fi
```

## 2.2 使用 grub2\-mkconfig 命令生成

修改 grub 系统配置文件:

```
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
```