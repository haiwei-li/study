
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 目录结构](#1-目录结构)
- [2 阅读顺序](#2-阅读顺序)
- [3 System Startup and Initialization(系统启动和初始化)](#3-system-startup-and-initialization系统启动和初始化)
- [4 Memory Management (内存管理)](#4-memory-management-内存管理)
- [5 Kernel](#5-kernel)
- [6 PCI](#6-pci)
- [7 Interprocess Communication](#7-interprocess-communication)
- [8 Interrupt Handling](#8-interrupt-handling)
- [9 Device Drivers (设备驱动程序)](#9-device-drivers-设备驱动程序)
- [10 File Systems (文件系统)](#10-file-systems-文件系统)
- [11 Network (网络)](#11-network-网络)
- [12 Modules (模块)](#12-modules-模块)
- [13 参考](#13-参考)

<!-- /code_chunk_output -->

# 1 目录结构

通常 Linux 会有以下目录

- arch: 子目录包括所有和体系结构相关的核心代码. 它还有更深的子目录, 每一个代表一种支持的体系结构

- include: 子目录包括编译核心所需要的大部分 include 文件. 它也有更深的子目录, 每一个支持的体系结构一个.  include/asm 是这个体系结构所需要的真实的 include 目录的软链接, 例如 include/asm-i386 . 为了改变体系结构, 你需要编辑核心的 makefile , 重新运行 Linux 的核心配置程序

- init: 这个目录包含核心的初始化代码, 这时研究核心如何工作的一个非常好的起点

- mm: 这个目录包括所有的内存管理代码. 和体系结构相关的内存管理代码位于 arch/\*/mm/

- drivers: 系统所有的设备驱动程序在这个目录. 它们被划分成设备驱动程序类

- ipc: 这个目录包含核心的进程间通讯的代码

- modules: 这只是一个用来存放建立好的模块的目录

- fs: 所有的文件系统代码. 被划分成子目录, 每一个支持的文件系统一个

- kernel: 主要的核心代码. 同样, 和体系相关的核心代码放在 arch/\*/kernel

- net: 核心的网络代码

- lib: 这个目录放置核心的库代码. 和体系结构相关的库代码在 arch/\*/lib/

- scripts: 这个目录包含脚本(例如 awk 和 tk 脚本), 用于配置核心

# 2 阅读顺序

按照以下顺序阅读源代码会轻松点

- 核心功能(kernel)
- 内存管理(mm)
- 文件系统(fs)
- 进程通讯(ipc)
- 网络(net)
- 系统启动和初始化(init/main 和 head.S)
- 其他等等

# 3 System Startup and Initialization(系统启动和初始化)

在一个 Intel 系统上, 当 loadlin.exe 或 LILO 把核心加载到内存并把控制权交给它的时候, 核心开始启动. 这一部分看 arch/i386/kernel/head.S .  head.S 执行一些和体系结构相关的设置工作并跳到 init/main.c 中的 main() 例程.

# 4 Memory Management (内存管理)

代码大多在 mm 但是和体系结构相关的代码在 arch/*/mm .  Page fault 处理代码在 mm/memory.c 中, 内存映射和页缓存代码在 mm/filemap.c 中.  Buffer cache 在 mm/buffer.c 中实现, 交换缓存在 mm/swap_state.c 和 mm/swapfile.c 中.

# 5 Kernel

大部分相对通用的代码在 kernel , 和体系结构相关的代码在 arch/\*/kernel . 调度程序在 kernel/sched.c ,  fork 代码在 kernel/fork.c .  bottom half 处理代码在 include/linux/interrupt.h .  task_struct 数据结构可以在 include/linux/sched.h 中找到

# 6 PCI

PCI 伪驱动程序在 drivers/pci/pci.c , 系统范围的定义在 include/linux/pci.h . 每一种体系结构都有一些特殊的 PCI BIOS 代码,  Alpha AXP 的位于 arch/alpha/kernel/bios32.c

# 7 Interprocess Communication

全部在 ipc 目录. 所有系统 V IPC 对象都包括 ipc_perm 数据结构, 可以在 include/linux/ipc.h 中找到. 系统 V 消息在 ipc/msg.c 中实现, 共享内存在 ipc/shm.c 中, 信号灯在 ipc/sem.c . 管道在 ipc/pipe.c 中实现.

# 8 Interrupt Handling

核心的中断处理代码几乎都是和微处理器(通常也和平台)相关.  Intel 中断处理代码在 arch/i386/kernel/irq.c 它的定义在 incude/asm-i386/irq.h .

# 9 Device Drivers (设备驱动程序)

Linux 核心源代码的大部分代码行在它的设备驱动程序中.  Linux 所有的设备驱动程序源代码都在 drivers 中, 但是它们被进一步分类:

- /block 块设备驱动程序比如 ide ( ide.c ). 如果你希望查看所有可能包含文件系统的设备是如何初始化的, 你可以看 drivers/block/genhd.c 中的 device\_setup() . 它不仅初始化硬盘, 也初始化网络, 因为你安装 nfs 文件系统的时候需要网络. 块设备包括基于 IDE 和 SCSI 设备.

- /char 这里可以查看基于字符的设备比如 tty , 串行口等.
/cdrom Linux 所有的 CDROM 代码. 在这里可以找到特殊的 CDROM 设备(比如 Soundblaster CDROM ). 注意 ide CD 驱动程序是 drivers/block 中的 ide-cd.c , 而 SCSI CD 驱动程序在 drivers/scsi/scsi.c 中
- /pci PCI 伪驱动程序. 这是一个观察 PCI 子系统如何被映射和初始化的好地方.  Alpha AXP PCI 整理代码也值得在 arch/alpha/kernel/bios32.c 中查看
- /scsi 在这里不但可以找到所有的 Linux 支持的 scsi 设备的驱动程序, 也可以找到所有的 SCSI 代码
- /net 在这里可以找到网络设备驱动程序比如 DEC Chip 21040 PCI 以太网驱动程序在 tulip.c 中
- /sound 所有的声卡驱动程序的位置

# 10 File Systems (文件系统)

EXT2 文件系统的源程序都在 fs/ext2/ 子目录, 数据结构的定义在 include/linux/ext2_fs.h,ext2\_fs\_i.h 和 ext2\_fs\_sb.h 中. 虚拟文件系统的数据结构在 include/linux/fs.h 中描述, 代码是 fs/* .  Buffer cache 和 update 核心守护进程都是用 fs/buffer.c 实现的

# 11 Network (网络)

网络代码放在 net 子目录, 大部分的 include 文件在 include/net .  BSD socket 代码在 net/socket.c ,  Ipv4 INET socket 代码在 net/ipv4/af_inet.c 中. 通用协议的支持代码(包括 sk_buff 处理例程)在 net/core 中,  TCP/IP 网络代码在 net/ipv4 . 网络设备驱动程序在 drivers/net

# 12 Modules (模块)

核心模块代码部分在核心, 部分在 modules 包中. 核心代码全部在 kernel/modules.c , 数据结果和核心守护进程 kerneld 的消息则分别在 include/linux/module.h 和 include/linux/kerneld.h 中. 你可能也希望在 include/linux/elf.h 中查看一个 ELF 目标文件的结构

# 13 参考

- https://www.cnblogs.com/preacher/p/4647573.html
- Linux 内核源代码: http://www.kernel.org/
- 深入分心 Linux 内核源代码: http://oss.org.cn/kernel-book/
- Linux 的有关参考资料: http://www.oldlinux.org/index_cn.html