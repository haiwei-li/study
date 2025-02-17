1.首先有 OS 基础, 随便操作系统书籍

2.对 Linux kernel 有全面了解, 关键模块有理解(走读 kernel 源码, 对流程有印象). 推荐书籍: 深入 Linux 内核架构(+1)或者深入理解 LINUX 内核.

3.hypervisor 虚拟化, Intel 的《系统虚拟化》, 很老很实用, 看 Qemu, KVM, Xen 代码

某个部分有疑问, 可以多个 hypervisor 代码对比着看:

* kvm:

* xen:

* ACRN: https://github.com/projectacrn/acrn-hypervisor

4.容器虚拟化, 读 cgroup,lxc,docker 代码.

Linux 虚拟化技术: http://tinylab.org/tiny-salon-phase-ii-virtualization-technology/

VT 源码: https://github.com/zzhouhe/VT_Learn

VT 源码学习: https://github.com/tandasat/HyperPlatform

虚拟化技术入门: https://edu.aliyun.com/course/38?spm=5176.8764728.aliyun-edu-course-tab.1.5a852addFAVPBd&previewAs=member

<操作系统与虚拟化安全>: https://www.coursera.org/learn/os-virtsecurity/home/welcome

维基百科: https://zh.wikipedia.org/wiki/%E8%99%9B%E6%93%AC%E5%8C%96

- Intel 虚拟化技术: https://www.intel.com/content/www/us/en/virtualization/virtualization-technology/intel-virtualization-technology.html


KVM 网站: http://www.linux-kvm.org/page/Main_Page

KVM 博客: http://blog.csdn.net/RichardYSteven/article/category/841588


KVM 介绍: http://www.cnblogs.com/sammyliu/p/4543110.html

https://www.bbsmax.com/R/B0zqPN73dv/


https://kernelgo.org/categories.html#virtualization-ref


Kvm 代码解析连载: http://www.aiuxian.com/article/p-2337268.html

虚拟化: https://blog.csdn.net/wanthelping/category_5682983.html

KVM(Kernel-based Virtual Machine)是 Linux 下基于 X86 硬件(包含虚拟化扩展<Intel VT 或 AMD-V>)的全虚拟化解决方案. KVM 包含一个可加载的内核模块(kvm.ko), 这个模块提供了核心的虚拟化基础架构和一个特定的处理器模块(kvm-intel.ko 或 kvm-amd.ko)

使用 KVM, 可以运行多个虚拟机, 这些虚拟机是未修改过的 Linux 或 Windows 镜像. 每个虚拟机都有独自的虚拟硬件: 网卡、磁盘、图形适配器等.

KVM 是一个开源软件. KVM 的核心组件被包含在 Linux 的主线版本中(2.6.20). KVM 的用户空间组件包含在 QEMU 的主线版本(1.3).

活跃在 KVM 相关虚拟化发展的人们的博客被组织在 http://planet.virt-tools.org/ 这个网站.

1. 先学习关于 KVM 实践相关的, 比如 <任永杰>的相关的书, 目前 2019 年最新的是<KVM 实战: 原理、进阶与性能调优>



以 kvm unit test/简单 benchmark 为例, 通过 ftrace 查看流程

虚拟化系列, 偏 ARM: https://www.cnblogs.com/LoyenWang/tag/%E8%99%9A%E6%8B%9F%E5%8C%96/

虚拟化很多系列: https://kernelgo.org/archives.html

https://github.com/luohao-brian/interrupt-virtualization

https://www.blogsebastian.cn/?cat=1

逻辑很清晰: https://blog.csdn.net/huang987246510/category_6939709.html (左边分类专栏)



