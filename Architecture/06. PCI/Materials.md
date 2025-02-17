

# 书籍

深入浅出 SSD: https://book.douban.com/subject/30240853/

《PCI Experss 体系结构导读》(2010 年):

PCI Express 系统体系结构标准教材: https://book.douban.com/subject/1446120/

PCI Express Technology(2012 年, 好像更好): Mike Jackson, Ravi Budruk

PCI Express System Architecture(2008 年): Ravi Budruk, Don Anderson, Tom Shanley

存储随笔《PCIe 科普教程》: https://mp.weixin.qq.com/s?__biz=MzIwNTUxNDgwNg==&mid=2247484352&idx=1&sn=2ac7ca9c6f745256734aa5d8e2c0f615&chksm=972ef299a0597b8f1224432f8d65094a20d2bde20aa7b46f9ef9710b8a003c08976ddb9c0083&scene=21

summay:

不要直接看 spec, spec 没有任何计算机体系结构相关内容(看《PCI Experss 体系结构导读》前言)

先看《深入浅出 SSD》, 这个更通俗简单(在 SSD 目录下)

再看《PCI Experss 体系结构导读》

再《PCI Express Technology》

# Blog

PCIe 扫盲系列博文连载目录篇(第一阶段): http://blog.chinaaet.com/justlxy/p/5100053251

PCIe 资料汇总: http://blog.csdn.net/abcamus/article/details/72812507

https://blog.csdn.net/mao0514/article/category/1518607


Linux 下的 PCI 总线驱动: http://blog.chinaunix.net/uid-24148050-id-101021.html


PCI 学习笔记: http://blog.csdn.net/weiqing1981127/article/details/8031541

Linux PCI 网卡驱动的详细分析

http://soft.chinabyte.com/os/13/12304513.shtml

Linux kernel 中网络设备的管理

http://www.linuxidc.com/Linux/2013-08/88472.htm

PCI 驱动初始化流程–基于 POWERPC85xx 架构的 Linux 内核 PCI 初始化

http://blog.csdn.net/luwei860123/article/details/38816473

PowerPC 的 PCI 总线的 dts 配置【转】

http://blog.163.com/liuqiang_mail@126/blog/static/10996887520126192504668/

IOMMU 是如何划分 PCI device group 的?: https://zhuanlan.zhihu.com/p/341895948

PCIe 初始化枚举和资源分配流程分析: `Linux\Device Driver\PCIe\pcie 初始化枚举和资源分配流程代码分析`

PCI Express Port Bus Driver: https://zhuanlan.zhihu.com/p/380414834

# 工具

PCIe 工具:

(better)TeleScan PE(Windows & Linux): 扫描系统中的 PCI/PCIe 设备, 并提供了读写其配置空间中的寄存器的功能, https://teledynelecroy.com/protocolanalyzer/pci-express/telescan-pe-software/resources/analysis-software

Mindshare Arbor, 主要用于 PCI/PCI-X/PCIe/Hyper Transport 系统的分析与调试. 支持主流的 Windows 和 Linux 系统(最新的已经不支持 Linux 了). https://www.mindshare.com/software/?section=132B0BA21710

硬件信息查看工具: RW-everything, http://rweverything.com/
