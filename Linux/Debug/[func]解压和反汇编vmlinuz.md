https://blog.packagecloud.io/how-to-extract-and-disassmble-a-linux-kernel-image-vmlinuz/

通过 extract-vmlinux 脚本进行

# 下载

可以获取最新的

```
wget -O extract-vmlinux https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/scripts/extract-vmlinux
```

也可以安装

```
sudo apt-get install linux-headers-$(uname -r)
```

# 使用

decompress and extract 内核

复制

```
$ mkdir /tmp/kernel-extract
$ sudo cp /boot/vmlinuz-$(uname -r) /tmp/kernel-extract/
```

extract

```
$ cd /tmp/kernel-extract/
$ sudo /usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux vmlinuz-$(uname -r) > vmlinux
```

# 反汇编

```
$ cd /tmp/kernel-extract/
$ objdump -D vmlinux | less
```

#