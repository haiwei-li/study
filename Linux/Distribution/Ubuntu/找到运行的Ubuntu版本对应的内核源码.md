
首先, 按照下面链接里的内容, 下载对应的内核源码仓库.

https://wiki.ubuntu.com/Kernel/Dev/KernelGitGuide

如果觉得链接里的内容太长了, 可以试下如下命令.

```
git clone git://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/$(lsb_release -cs)

git clone https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/$(lsb_release -cs)
```


```
$ lsb_release -cs
jammy

$ lsb_release -a
LSB Version:    core-11.1.0ubuntu4-noarch:security-11.1.0ubuntu4-noarch
Distributor ID: Ubuntu
Description:    Ubuntu 22.04 LTS
Release:        22.04
Codename:       jammy

$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=22.04
DISTRIB_CODENAME=jammy
DISTRIB_DESCRIPTION="Ubuntu 22.04 LTS"
```

该命令会根据你当前的 Ubuntu 版本下载对应的内核代码.

如果这个命令没报错, 说明一切顺利, 只要等待下载完成就行了.

Ubuntu 内核代码下载完成之后, 默认为 master 分支. 该分支通常并不是精确对应到我们当前运行的 Ubuntu 版本, 所以我们要切换分支.

先通过如下命令, 找到当前运行的 Ubuntu 的精确版本号.

```
# cat /proc/version_signature
Ubuntu 5.15.0-27.28-generic 5.15.30
```

其中, `-generic` 之前的信息就对应为 Ubuntu 内核源码的 tag, 不过要把 Ubuntu 后的空格换成中划线. 比如上面命令输出对应的 tag 就是 `Ubuntu-5.15.0-27.28` .

然后, 我们进入到下载好的内核源码目录, 执行如下命令, 把源码切换到该 tag 对应的版本.

```
git checkout Ubuntu-4.15.0-45.48 HEAD is now at ffdd392b8196 UBUNTU: Ubuntu-4.15.0-45.48
```
