
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 背景简介](#1-背景简介)
- [2. 极速体验](#2-极速体验)
- [3. 原理分析](#3-原理分析)
  - [3.1. Makefile](#31-makefile)
  - [3.2. kernel/Makefile](#32-kernelmakefile)
  - [3.3. kernel/configs.c](#33-kernelconfigsc)
  - [3.4. scripts/extract-ikconfig](#34-scriptsextract-ikconfig)
- [4. 换个思路](#4-换个思路)
- [5. 小结](#5-小结)
- [6. 参考](#6-参考)

<!-- /code_chunk_output -->

# 1. 背景简介

最近两周在忙活 Linux Lab V0.2 RC1, 其中一个很重要的目标是添加国产龙芯处理器支持.

在添加龙芯 ls2k 平台的过程中, 来自龙芯的张老师已经准备了 **vmlinux** 和 **dtb**, 还需要添加**配置文件**和**源代码**, 但源码中**默认的配置编译完无法启动**, 所以需要找一个**可复用的内核配置文件**.

在张老师准备的内核 **vmlinux** 中, 确实有一个 /**proc/config.gz**, 说明**内核配置文件**已经**编译到内核**了, 但是由于内核**没有配置 nfs**, 尝试了几次没 dump 出来.

当然, 其实也可以用 `zcat /proc/config.gz` 打印到**控制台**, 然后再**复制出来**, 这个时候要把控制台的 scrollback lines 设置大一些, 但是没那么方便.

# 2. 极速体验

这里讨论另外一个方法, 这是张老师分享的一个小技巧, 那就是直接用 **Linux 内核源码**下的**小工具**: `script/extract-ikconfig`.

```
$ cd /path/to/linux-kernel
$ scripts/extract-ikconfig /path/to/vmlinux
```

执行完的结果跟 zcat 一致, 需要保存到文件, 可以这样:

```
$ scripts/extract-ikconfig /path/to/vmlinux > kconfig
```

需要注意的是, 这个前提是**配置内核**时要开启 `CONFIG_IKCONFIG` 选项. 而如果要拿到 `/proc/config.gz`, 还得打开 `CONFIG_IKCONFIG_PROC`.

```
-> General setup
    -> Kernel .config support (IKCONFIG [=y])
        -> Enable access to .config through /proc/config.gz (IKCONFIG_PROC [=y])
```

# 3. 原理分析

大概的原理我们来剖析一下.

## 3.1. Makefile

初始化 `KCONFIG_CONFIG`:

```
KCONFIG_CONFIG ?= .config
```

## 3.2. kernel/Makefile

把 `.config` 用 **gzip** 压缩了一份, 放到了 `kernel/config_data.gz`:

```
$(obj)/configs.o: $(obj)/config_data.gz
targets += config_data.gz
$(obj)/config_data.gz: $(KCONFIG_CONFIG) FORCE
	$(call if_changed,gzip)
```

## 3.3. kernel/configs.c

把 `kernel/config_data.gz` 放到 `.rodata section`, 并在**前后**加了**字符串标记**: `IKCFG_ST` 和 `IKCFG_ED`:

```cpp
/*
* "IKCFG_ST" and "IKCFG_ED" are used to extract the config data from
* a binary kernel image or a module. See scripts/extract-ikconfig.
*/
asm (
" .pushsection .rodata, \"a\" \n"
" .ascii \"IKCFG_ST\" \n"
" .global kernel_config_data \n"
"kernel_config_data: \n"
" .incbin \"kernel/config_data.gz\" \n"
" .global kernel_config_data_end \n"
"kernel_config_data_end: \n"
" .ascii \"IKCFG_ED\" \n"
" .popsection \n"
);
```

## 3.4. scripts/extract-ikconfig

通过 `grep -abo` 去找到 `kconfig data` 的位置. `-abo` 的意思是:

- -a 把二进制文件当 text 处理,
- -b 打印字节偏移,
- -o 只打印要匹配的字符串

```sh
dump_config()
{
        if      pos=`tr "$cf1\n$cf2" "\n$cf2=" &lt; "$1" | grep -abo "^$cf2"`
        then
                pos=${pos%%:*}
                tail -c+$(($pos+8)) "$1" | zcat &gt; $tmp1 2&gt; /dev/null
                if      [ $? != 1 ]
                then    # exit status must be 0 or 2 (trailing garbage warning)
                        cat $tmp1
                        exit 0
                fi
        fi
}
```

这个脚本写得有点晦涩, 大体意思是先找到 "IKCFG_ST", 算出 kconfig data 位置, 再用 tail 取出来.

# 4. 换个思路

先看看 `vmlinux` 和 `kernel/config_data.gz` 的布局:

```
"IKCFG_ST ..... IKCFG_ED"             --> vmlinux
         ^ kernel/config_data.gz ^                      --> kernel/config_data.gz
```

首先, 找出 `IKCFG_ST` 和 `IKCFG_ED` 的位置. 然后换算出 `kernel/config_data.gz` 的**前后位置**:

```
$ egrep -abo "IKCFG_ST|IKCFG_ED" boards/loongson/ls2k/bsp/kernel/v3.10/vmlinux
14508864:IKCFG_ST
14529536:IKCFG_ED
```

`kernel/config_data.gz` 的起始地址需要加上 "`IKCFG_ST`" 的长度, 即 `+8: $((14508864+8))`, 而结束地址刚好是 "`IKCFG_ED`" 的地址 `-1: $((14529536-1))`, 总的 size 是:

```
$ echo $(((14529536-1) - (14508864+8) + 1))
20664
```

这样, 我们就可以用 dd 命令截取出来:

```
$ dd if=boards/loongson/ls2k/bsp/kernel/v3.10/vmlinux bs=1 skip=$((14508864+8)) count=20664 of=kconfig.gz
$ file kconfig.gz
kconfig.gz: gzip compressed data, max compression, from Unix
$ zcat kconfig.gz
```

完美！逻辑上更清晰, 基于这个逻辑改写了一个自己的 `extract-ikconfig`, 见 Linux Lab 下的 `tools/kernel/extract-ikconfig`.

# 5. 小结

* 编译内核时, 打开 `CONFIG_IKCONFIG` 和 `CONFIG_IKCONFIG_PROC`.
* 从 **Runtime 内核**中抓取: `zcat /proc/config.gz`, 如果找不到了 vmlinux, 这个不失为一个好方法.
* 从**静态内核 vmlinux** 中抓取: `scripts/extract-ikconfig /path/to/vmlinux`.

注: `zcat /proc/config.gz` 等价于 `cat /proc/config.gz | gzip -d`

# 6. 参考

https://tinylab.org/extract-kernel-config-from-vmlinux/