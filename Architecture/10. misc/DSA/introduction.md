
# 概述

英特尔® DSA 是一款高性能**数据复制和转换加速器**, 将**集成**到未来的**英特尔®处理器**中, 旨在优化**高性能存储**、**网络**、**持久内存**和各种数据处理应用常见的**流数据移动和转换操作**.

英特尔® **DSA** 取代了英特尔® **QuickData** 技术, 后者是英特尔® **I/O 加速技术**的一部分. 目标是为**数据移动和转换操作**提供更高的整体系统性能, 同时释放 CPU 周期的资源以用于更高级别的功能.

## 数据移动和内存转换

英特尔® DSA 支持高性能**数据移动**功能, 使其能够往返于**易失性内存**、**持久内存**、**内存映射 I/O**, 并通过**非透明桥接**(NTB)**设备**与集群中**另一个节点**上的**远程易失性**和**持久内存**之间来回移动. **枚举**和**配置**是通过与操作系统(OS) 兼容的 **PCI Express 编程接口**完成的, 并且可以通过**设备驱动程序**进行**控制**.

除了基本的数据移动操作外, 英特尔® DSA 还支持**内存转换**. 例如:

* **数据移动**: 生成和测试 CRC 校验和或数据完整性字段 (DIF) 以支持存储和网络应用程序.
* **内存转换**: 内存比较和增量生成/合并, 以支持 **VM 迁移**、VM 快速检查指向和软件托管内存重复数据删除用法.

## 物理部件

**每个 SoC** 可以支持**任意数量**的英特尔® **DSA 设备实例**. 多插槽服务器平台可能支持**多个此类 SoC**.

从软件的角度来看, **每个实例**都公开为 **PCI-Express Root Complex 集成端点**.

每个实例都在 **DMA 重新映射硬件单元** [也称为输入-输出内存管理单元 (**IOMMU**)] 的**范围内**. 根据 SoC 设计, 不同的实例可以位于相同或不同的 DMA 重新映射硬件单元后面.

## 多种服务

英特尔® DSA 支持各种 **PCI-SIG** 定义的服务, 以提供高度可扩展的配置, 包括:

* 地址转换服务
* 进程地址空间 ID (PASID)
* 页面请求服务
* 消息信令中断扩展 (MSI-X)
* 高级错误报告

上述功能使英特尔® DSA 能够支持**共享虚拟内存**(SVM) 操作, 允许**设备**直接在应用程序的**虚拟地址空间中运行**, 而**无需固定内存**.

> 即设备直接使用 CPU 地址(virtual address)

英特尔® DSA 还支持英特尔®**可扩展 I/O 虚拟化** (英特尔® Scalable IOV) 以支持超大规模虚拟化. 除了传统的 `MSI-X` 之外, 它还支持**特定于设备**的**中断消息存储** (**IMS**).

![2022-09-27-11-08-26.png](./images/2022-09-27-11-08-26.png)

上图是 DSA 的抽象内部框图. I/O 结构接口用于接收来自客户端的下游工作请求以及上游读取、写入和地址转换操作.

**每个设备**都包含以下基本组件:

* Work Queues (WQ):  在设备存储上对设备的描述符进行排队. 通过使用新指令将请求写入与每个 WQ 关联的内存映射"门户", 将请求添加到 WQ 中. ‎
* Groups: 可以包含一个或多个引擎和工作队列的抽象容器. ‎
* Engines: **提取**提交到 WQ 的**工作**并对其进行**处理**. ‎

‎支持两种类型的 WQ:

* ‎专用 WQ (DWQ) - 单个客户端独占拥有此权限, 并且可以向其提交工作. ‎
* ‎共享 WQ (SWQ) - 多个客户端可以向 SWQ 提交工作. ‎

‎使用 DWQ 的客户端使用 ‎‎MOVDIR64B ‎‎指令提交工作描述符. 这是已提交的写入, 因此客户端必须跟踪提交的描述符数, 以确保它不会超过配置的工作队列长度, 因为任何其他描述符都将被删除. ‎

‎使用共享工作队列的客户端使用 ‎‎ENQCMDS‎‎(从主管模式)或 ‎‎ENQCMD‎‎(从用户模式)提交工作描述符. 这些指令通过电火花线指示. 采埃孚位请求是否被接受. ‎

‎请参阅‎‎英特尔®软件开发人员手册‎‎(SDM)SDM 或‎‎英特尔®指令集扩展‎‎(ISE)ISE 以获取有关这些说明的更多详细信息. ‎

# 软件架构

下图显示了软件体系结构. **内核驱动程序**(英特尔®数据加速器驱动程序, **IDXD**)是一个典型的内核驱动程序, 用于**标识系统中的设备实例**. 这也是英特尔®**可扩展 IOV 规范**中称为**虚拟设备组合模块** (`VDCM`) 的**组件**, 用于**创建实例**以方便向 VM 公开虚拟英特尔® DSA 实例.

软件体系结构:

![2022-09-27-11-23-03.png](./images/2022-09-27-11-23-03.png)

**内核驱动程序**提供以下服务:

* 每个配置的 WQ 的字符设备接口, 用于本机应用程序, 以在此设备上映射(2) 以访问 WQ 门户.
用于提供对 WQ 门户的访问以供内核内使用的 API.
VDCM 用于组合虚拟设备, 以便向来宾操作系统提供英特尔® DSA 实例.
用户界面通过 sysfs 文件系统, 允许工具发现拓扑和配置工作队列的能力.

系统管理员可以通过多种方式配置设备. 请参阅英特尔® DSA 规范用于将工作队列的所有编程和配置到不同的模式.

# 加速器配置器(加速配置)

accel-config 是一个实用程序, 允许系统管理员配置组、工作队列和引擎. 该实用程序解析通过 sysfs 公开的拓扑和功能, 并提供命令行界面来配置资源. 下面列出了 accel 配置的一些功能:

显示设备层次结构.
配置属性并为内核或应用程序提供访问权限.
使用应用程序可以链接到的 API 库 (libaccel) 通过标准"C"库执行操作.
控制设备停止、启动接口.
创建 VFIO 中介设备, 将虚拟英特尔® DSA 实例公开给客户机操作系统.

有关详细信息, 请参阅 [accel-config](https://github.com/intel/idxd).

# 在原生内核中使用英特尔® DSA

sysfs 属性允许系统管理员为每个 WQ 指定类型和名称. 这允许为特定目的保留 WQ. 驱动程序中支持三种类型:

Kernel - 保留供本机内核使用.
User - 为本机用户空间使用而保留, 用于 DPDK 等工具.
Mdev - 用于公开中介设备以支持向来宾操作系统提供英特尔® DSA 功能.
对于 User 和 Mdev 类型, 系统管理员可以指定一个字符串来标识系统管理员设置的工作队列. 例如, 字符串 mysql 或 DPDK 可用于唯一标识为特定用途保留的资源.

Figure 3: Using Intel® DSA in the Kernel

![2022-09-27-11-32-54.png](./images/2022-09-27-11-32-54.png)

‎IDXD 驱动程序利用 Linux* 内核 DMA 引擎子系统来处理内核工作请求. ‎

‎一些示例包括 ClearPage 引擎、非透明网桥 (NTB) 和处理持久内存. ‎

‎# 在 LINUX 中对英特尔® DSA 的上游支持‎

‎英特尔® DSA 使用多种新的 CPU 和平台功能, 它们都通过交互来提供所需的功能. 由于存在多个组件和复杂的交互, 因此代码和博客部分被分成几个小部分, 以方便在 Linux 中引入不同的技术及其支持. 以下是当前计划阶段的细分:

‎第 1 阶段: ‎裸机驱动程序, 用户空间工具. 面向内核内和本机用户空间使用情况. ‎
‎第 2 阶段: ‎支持对 ‎‎ENQCMD‎‎、中断消息存储 (IMS) 的本机支持. 这将显示共享工作队列配置的本机使用情况. ‎
‎第 3 阶段:  ‎‎在 QEMU 中构建英特尔® DSA 中介设备、guest 支持、虚拟 IOMMU (vIOMMU) 支持. ‎
‎第 4 阶段:  ‎‎在 guest OS 中处理 ENQCMD, 并在 KVM、QEMU 中处理相关的启用. ‎

‎对全貌感兴趣的人可以看看这个‎‎树‎‎以跟上每个阶段在社区中发布和讨论的开发进度. 我们将尽一切努力在开发过程中更新此博客的参考资料. ‎



# reference

https://blog.csdn.net/u011458874/article/details/124898895

Intel® DSA Specification: https://cdrdv2.intel.com/v1/dl/getContent/671116?explicitVersion=true&wapkw=DSA

Intel® Data Accelerator Driver GitHub* repository: https://github.com/intel/idxd-driver

Intel® Data Accelerator Driver Overview on GitHub.io: https://intel.github.io/idxd/

Intel® Data Accelerator Control Utility and Library: https://github.com/intel/idxd-config

Shared Virtual Memory: https://www.intel.com/content/www/us/en/developer/articles/technical/opencl-20-shared-virtual-memory-overview.html?wapkw=SVM

Intel® Scalable I/O Virtualization: https://cdrdv2.intel.com/v1/dl/getContent/671403?explicitVersion=true&wapkw=scalable

Intel® 64 and IA-32 Architectures Software Developer Manuals: https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html
