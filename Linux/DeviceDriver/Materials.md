Linux 设备模型: http://www.wowotech.net/sort/device_model


大家好, 本周分享的实践专题是: `<Linux 设备驱动合集>`, 这个合集基本包括了开发中遇到的各种外设驱动. 每个驱动文章通过从:  uboot, kernel, Userspace 三个角度出发, 提供源码和工具对驱动的实践. 文章入口:

https://biscuitos.github.io/blog/BiscuitOS_Catalogue/


一个设备驱动的主要任务有两个:

* 存取设备的内存
* 处理设备产生的中断

《深入 linux 设备驱动程序内核机制》, 陈学松, 2012-1,

《LDD》

《Linux 设备驱动开发详解: 基于最新的 Linux4.0 内核》, 宋宝华, 2015-08, 基于内核 4.0

《Linux 内核探秘: 深入解析文件系统和设备驱动的架构与设计》, 2014-01, x86, 基于内核 2.6.18


在 pcie 设备中找到 pcie 的 root port: https://blog.csdn.net/tiantao2012/article/details/78342433

PCIe 学习笔记之 MSI/MSI-x 中断及代码分析: https://www.codenong.com/cs106676560/

一文搞定 Linux 设备树 - 祁娥安的文章 - 知乎
https://zhuanlan.zhihu.com/p/425420889

bus 和 pci bus 的一些函数操作可以看 `NVMe` 目录下的代码分析

linux 设备驱动 device add 详解: https://blog.csdn.net/u012787604/article/details/122310671

内核驱动开发记录: https://blog.csdn.net/freedom1523646952/category_11767829.html

在分析一个 driver 时, 最好先看这个 driver 相关的 Kconfig 及 Makefile 文件, 了解其文件架构, 再阅读相关的 source code

一个简单的设备驱动的例子: `Virtualization\7. Device虚拟化\ivshmem设备\4. doorbell中断机制.md`

