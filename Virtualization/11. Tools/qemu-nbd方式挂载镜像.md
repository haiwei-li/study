<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 查看 NBD(Network Block Device)信息](#1-查看-nbdnetwork-block-device信息)
- [2. 将镜像映射为网络设备(NBD)](#2-将镜像映射为网络设备nbd)
- [3. 挂载镜像中的分区](#3-挂载镜像中的分区)
- [4. umount 分区, 解除镜像与 nbd 设备的关联](#4-umount-分区-解除镜像与-nbd-设备的关联)
- [5. 参考](#5-参考)

<!-- /code_chunk_output -->

# 1. 查看 NBD(Network Block Device)信息

```
# modinfo nbd
filename:       /lib/modules/3.11.10-301.fc20.x86_64/kernel/drivers/block/nbd.ko
license:        GPL
description:    Network Block Device
depends:
intree:         Y
vermagic:       3.11.10-301.fc20.x86_64 SMP mod_unload
signer:         Fedora kernel signing key
sig_key:        03:59:1D:C5:7A:69:07:41:40:1A:1C:20:2E:2B:3D:9F:4F:ED:2A:0E
sig_hashalgo:   sha256
parm:           nbds_max:number of network block devices to initialize (default: 16) (int)
parm:           max_part:number of partitions per device (default: 0) (int)
parm:           debugflags:flags for controlling debug output (int)

# modprobe nbd max_part=16

# lsmod | grep nbd
nbd                    17554  0
```

# 2. 将镜像映射为网络设备(NBD)

```
# qemu-nbd -c /dev/n
nbd0                nbd11               nbd14               nbd3                nbd6                nbd9                network_throughput
nbd1                nbd12               nbd15               nbd4                nbd7                net/                null
nbd10               nbd13               nbd2                nbd5                nbd8                network_latency     nvram

# qemu-nbd -c /dev/nbd0 /var/lib/libvirt/images/ubuntu.img

# ll /dev/nbd0*
brw-rw----. 1 root disk 43, 0 Jun 23 15:16 /dev/nbd0
brw-rw----. 1 root disk 43, 1 Jun 23 15:16 /dev/nbd0p1
brw-rw----. 1 root disk 43, 2 Jun 23 15:16 /dev/nbd0p2
brw-rw----. 1 root disk 43, 5 Jun 23 15:16 /dev/nbd0p5
```

# 3. 挂载镜像中的分区

```
# mount /dev/nbd0p1 /imgage/
# ll /imgage/
total 92
drwxr-xr-x.  2 root root  4096 May 27 08:53 bin
drwxr-xr-x.  3 root root  4096 May 27 08:59 boot
drwxr-xr-x.  3 root root  4096 May 26 18:24 dev
drwxr-xr-x. 89 root root  4096 Jun 23 14:48 etc
drwxr-xr-x.  3 root root  4096 May 27 08:59 home
lrwxrwxrwx.  1 root root    33 May 26 18:25 initrd.img -> boot/initrd.img-3.13.0-24-generic
drwxr-xr-x. 21 root root  4096 May 27 08:53 lib
drwxr-xr-x.  2 root root  4096 May 26 18:24 lib64
drwx------.  2 root root 16384 May 26 18:24 lost+found
drwxr-xr-x.  3 root root  4096 May 26 18:24 media
drwxr-xr-x.  2 root root  4096 Apr 11 06:12 mnt
drwxr-xr-x.  2 root root  4096 Apr 17 05:02 opt
drwxr-xr-x.  2 root root  4096 Apr 11 06:12 proc
drwx------.  3 root root  4096 May 27 09:28 root
drwxr-xr-x.  2 root root  4096 May 27 09:07 run
drwxr-xr-x.  2 root root  4096 May 27 09:07 sbin
drwxr-xr-x.  2 root root  4096 Apr 17 05:02 srv
drwxr-xr-x.  2 root root  4096 Mar 13 09:41 sys
drwxrwxrwt.  2 root root  4096 Jun 23 15:17 tmp
drwxr-xr-x. 10 root root  4096 May 26 18:24 usr
drwxr-xr-x. 12 root root  4096 May 27 08:55 var
lrwxrwxrwx.  1 root root    30 May 26 18:25 vmlinuz -> boot/vmlinuz-3.13.0-24-generic
```

# 4. umount 分区, 解除镜像与 nbd 设备的关联

```
# umount /imgage
# qemu-nbd -d /dev/nbd0
/dev/nbd0 disconnected
```

# 5. 参考

https://blog.csdn.net/cnyyx/article/details/33732709