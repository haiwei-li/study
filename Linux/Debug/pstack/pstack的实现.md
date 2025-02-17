
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. pstack 的简介](#1-pstack-的简介)
- [2. pstack 的实现](#2-pstack-的实现)
- [3. pstack 的 shell](#3-pstack-的-shell)
  - [3.1. 基本命令的使用](#31-基本命令的使用)
  - [3.2. Here Document](#32-here-document)
- [4. pstack 里的 GDB](#4-pstack-里的-gdb)
- [5. pstack 里 procfs](#5-pstack-里-procfs)

<!-- /code_chunk_output -->

# 1. pstack 的简介

Linux 下有时候我们需要知道一个进程在做什么, 比如说程序不正常的时候, 他到底在干吗?最直接的方法就是打印出他所有线程的调用栈, 这样我们从栈再配合程序代码就知道程序在干吗了.

Linux 下这个工具叫做 pstack. 使用方法是

```
# pstack
Usage: pstack <process-id>
```

# 2. pstack 的实现

当然这个**被调查的程序**需要有**符号信息**.

```bash
#!/bin/sh

if test $# -ne 1; then
    echo "Usage: `basename $0 .sh` <process-id>" 1>&2
    exit 1
fi

if test ! -r /proc/$1; then
    echo "Process $1 not found." 1>&2
    exit 1
fi

# GDB doesn't allow "thread apply all bt" when the process isn't
# threaded; need to peek at the process to determine if that or the
# simpler "bt" should be used.

backtrace="bt"
if test -d /proc/$1/task ; then
    # Newer kernel; has a task/ directory.
    if test `/bin/ls /proc/$1/task | /usr/bin/wc -l` -gt 1 2>/dev/null ; then
        backtrace="thread apply all bt"
    fi
elif test -f /proc/$1/maps ; then
    # Older kernel; go by it loading libpthread.
    if /bin/grep -e libpthread /proc/$1/maps > /dev/null 2>&1 ; then
        backtrace="thread apply all bt"
    fi
fi

GDB=${GDB:-/usr/bin/gdb}

if $GDB -nx --quiet --batch --readnever > /dev/null 2>&1; then
    readnever=--readnever
else
    readnever=
fi

# Run GDB, strip out unwanted noise.
$GDB --quiet $readnever -nx /proc/$1/exe $1 <<EOF 2>&1 |
$backtrace
EOF
/bin/sed -n \
    -e 's/^(gdb) //' \
    -e '/^#/p' \
    -e '/^Thread/p'
```

pstack 其实是个 Shell 脚本, 核心原理是**GDB**的**thread apply all bt**命令.

基本逻辑是通过**进程号**`process-id`来分析**是否使用了多线程**, 同时使用**GDB Attach**到在跑进程上, 最后**调用 bt 子命令**后**简单格式化输出**

在`/usr/bin/pstack`文件最前面添加`set -x`, 最后面加上`set +x`查看执行的命令

```
+ test 1 -ne 1
+ test '!' -r /proc/29298
+ backtrace=bt
+ test -d /proc/29298/task
++ /bin/ls /proc/29298/task
++ /usr/bin/wc -l
+ test 20 -gt 1
+ backtrace='thread apply all bt'
+ GDB=/usr/bin/gdb
+ /usr/bin/gdb --quiet -nx /proc/29298/exe 29298
+ /bin/sed -n -e 's/^\((gdb) \)*//' -e '/^#/p' -e '/^Thread/p'
Thread 20 (Thread 0x7f67b494a700 (LWP 29305)):
......
```

# 3. pstack 的 shell

## 3.1. 基本命令的使用

* `test -d`, 检查目录是否存在
* `test -f`, 检查文件是否存在
* `grep -e`, 用`grep -q -e`更好一些
* `sed -e s`, sed 的替换命令

## 3.2. Here Document

Here Document 也是一种 IO 重定向, IO 结束时会发 EOF 给 GDB.

# 4. pstack 里的 GDB

GDB 的东西内容非常多, 这里不展开, pstack 里最核心的就是**调用 GDB**, **attach 到对应进程**, 然后**执行 bt 命令**, 如果程序是**多线程**就执行`thread apply all bt`命令, 最后 quit 退出.

附带 GDB 文档的两个说明, 第一个是关于 attach 的:

>The first thing GDB does after arranging to debug the specified process is to stop it.

看了这个应该就很容易明白为什么**不能随便**在生产环境中去**attach 一个正在运行的程序**, 如果 attach 上以后待着不动, 程序就暂停了.

那为什么用 pstack 没啥事儿呢, 原因是**pstack**执行了一个**GDB 的 bt 子命令**后立即**退出**了, 可是源代码里面没有执行 quit, 它是怎么退出的呢, 看这个文档说明:

>To exit GDB, use the quit command (abbreviated q), or type an end-of-file character (usually Ctrl-d).

Here Document IO 重定向结束的标志是 EOF, GDB 读到了 EOF 自动退出了.

# 5. pstack 里 procfs

pstack 里面检查进程是否支持多线程的方法是检查进程对应的 proc 目录, 方法没什么可说的, 其中 Older kernel 下是通过检查/proc/pid/maps 是否加载 libpthread 来搞的, 这种是动态的, 类似于静态的 ldd. 这种方法其实不太严谨, 但由于 GDB 的 thread apply all bt 对多线程的支持也不是特别完美, 所以也无可厚非. 这里简单说说 Linux 的 procfs.

虽然并不是所有的 UNIX-Like 操作系统都支持 procfs, 也不是 Linux 首创了这种虚拟文件系统, 但绝对是 Linux 将其发扬光大的, 早起内核中甚至达到了滥用的程度, 内核开发者喊了好多年, 说 procfs 即将被淘汰, 但依然很火, 主要是因为太方便了, 比如 procfs 可以很容易的进行应用层与内核态进行通信.

procfs 在 Linux 中的应用不止是进程信息导出, 详细的应用与内核模块联动, 后续会写专门的文章介绍, 如有兴趣, 可以参考《深入理解 Linux 内核架构》和《Linux 设备驱动程序》, 关于进程的, 以下信息可以了解一下:

* /proc/PID/cmdline, 启动该进程的命令行.
* /proc/PID/cwd, 当前工作目录的符号链接.
* /proc/PID/environ 影响进程的环境变量的名字和值.
* /proc/PID/exe, 最初的可执行文件的符号链接, 如果它还存在的话.
* /proc/PID/fd, 一个目录, 包含每个打开的文件描述符的符号链接.
* /proc/PID/fdinfo, 一个目录, 包含每个打开的文件描述符的位置和标记
* /proc/PID/maps, 一个文本文件包含内存映射文件与块的信息.
* /proc/PID/mem, 一个二进制图像(image)表示进程的虚拟内存, 只能通过 ptrace 化进程访问.
* /proc/PID/root, 该进程所能看到的根路径的符号链接. 如果没有 chroot 监狱, 那么进程的根路径是/.
* /proc/PID/status 包含了进程的基本信息, 包括运行状态、内存使用.
* /proc/PID/task, 一个目录包含了硬链接到该进程启动的任何任务