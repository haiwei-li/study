1. 为什么要学习 Linux 内核

大多数程序员可能一辈子都没有机会从事 Linux 内核开发, 也可能不会去从事 Linux 驱动开发的工作, 那么为什么我们仍然需要学习 Linux 内核?Linux 的源码和架构都是开放的, 我们可以从中学到很多操作系统的概念和实现原理, Linux 的设计哲学体系继承自 UNIX, 现在整个设计体系已经相当稳定, 化繁为简, 这也是大部分服务器都使用 Linux 的重要原因.

2. Linux 内核学习线路

  ● How Does a Computer Work?

https://www.shiyanlou.com/courses/reports/192073

通过反汇编一个简单的 C 程序, 分析汇编代码理解计算机是如何工作的

  ● How Does a Operating System Work?

https://www.shiyanlou.com/courses/reports/192075

完成一个简单的时间片轮转多道程序内核代码

  ● Linux Kernel Initialization

https://www.shiyanlou.com/courses/reports/986686

跟踪分析 Linux 内核的启动过程

  ● 分析 Linux 系统调用过程

https://www.shiyanlou.com/courses/reports/1011473

使用库函数 API 和 C 代码中嵌入汇编代码两种方式使用同一个系统调用

  ● 分析 Linux 中断处理过程

https://www.shiyanlou.com/courses/reports/1029839

分析 system_call 中断处理过程

  ● 分析 Linux 操作系统如何创建一个进程

https://www.shiyanlou.com/courses/reports/1040235

分析 Linux 内核创建一个新进程的过程

  ● 分析 Linux 操作系统如何装载链接并执行程序

https://www.shiyanlou.com/courses/reports/1066981

Linux 内核如何装载和启动一个可执行程序

  ● 分析 Linux 操作系统进程上下切换过程

https://www.shiyanlou.com/courses/reports/1085363

理解进程调度时机跟踪分析进程调度与进程切换的过程

3.Linux 内核重点

1.计算机是如何工作的?

  ● 存储程序计算机工作模型

2.操作系统是如何工作的?

  ● 函数调用堆栈

3.构造一个简单的 Linux 系统 MenuOS

  ● 跟踪调试 Linux 内核的启动过程

4.扒开系统调用的三层皮

  ● 用户态、内核态和中断处理过程

  ● 系统调用概述

  ● 使用库函数 API 和 C 代码中嵌入汇编代码触发同一个系统调用

5.进程的描述和进程的创建

  ● 进程的描述和创建

  ● 使用 GDB 跟踪创建新进程的过程

6.可执行程序的装载

  ● 预处理、编译、链接和目标文件的格式

  ● 可执行程序、共享库和动态加载

  ● 可执行程序的装载

7.进程的切换和系统的一般执行过程

  ● 进程切换的关键代码 switch_to 分析

  ● Linux 系统架构和一般执行过程