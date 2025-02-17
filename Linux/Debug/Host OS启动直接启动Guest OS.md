
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 操作步骤](#1-操作步骤)
  - [1.1 修改/etc/rc.d/rc.local](#11-修改etcrcdrclocal)
  - [1.2 创建/root/.xinitrc](#12-创建rootxinitrc)

<!-- /code_chunk_output -->

## 1 操作步骤

### 1.1 修改/etc/rc.d/rc.local

添加以下内容

```
a. export HOME=/root
b. xinit &
```

修改权限

```
chmod +x /etc/rc.d/rc.local
```

### 1.2 创建/root/.xinitrc

```
#!/bin/sh
#
# ~/.xinitrc
#
## Executed by startx (run your window manager from here)
#timeout()
#{
#waitfor=10
#command=$*
#$command &
#commandpid=$!
#echo "sleep $waitfor seconds\n"
#(sleep $waitfor ; kill -9 $commandpid >/dev/null 2>&1) &
#watchdogpid=$!
#sleeppid=`ps $ppid $watchdogpid | awk '{print $1}'`
#wait $commandpid
#kill $sleeppid >/dev/null 2>&1
#}
#runsetup()
#{
#read ans
#
##	pcm_oss_setup
#echo "PCM/OSS Setup Utilities\n"
#}
#runoss()
#{
	#qemu-system-x86_64 --enable-kvm -sdl -hda /root/centos72.qcow2 -m 2048
qemu-system-x86_64 --enable-kvm -sdl -hda /root/centos72.qcow2 -m 2048 --full-screen
#}
#timeout runsetup
#runoss
#
```

