KVM高级功能详解

这些功能包括半虚拟化驱动、VT-d、SR-IOV、热插拔、动态迁移、KSM、AVX、cgroups、从物理机或虚拟机中迁移到KVM, 以及QEMU监控器和qemu-kvm命令行各种选项使用. 

```
第5章　KVM高级功能详解
5.1　半虚拟化驱动
5.1.1　virtio概述(Qemu模拟I/O设备的基本原理和优缺点, virtio的基本原理和优缺点
5.1.2　安装virtio驱动(Linux、Windows中virtion驱动程序的安装、使用)
5.1.3　使用virtio_balloon(1.ballooning简介; 2.KVM中balloning的原理及优劣势; 3.KVM中ballooning使用示例; 4.通过ballooning过载使用内存)
5.1.4　使用virtio_net(半虚拟化网络设备--1.配置和使用; 2.宿主机中的TSO和GSO设置; 3.用vhost_net后端驱动)
5.1.5　使用virtio_blk(使用virtio API为客户机提供访问块设备的IO方法)
5.1.6　kvm_clock配置(半虚拟化时钟, 为客户机提供精准的System time和Wall time)
5.2　设备直接分配(VT-d)
5.2.1　VT-d概述
     Emulated device: QEMU纯软件模拟的设备
     Virtio device: 实现virtio API的半虚拟化驱动的设备
     PCI device assignment: PCI设备直接分配(VT-d)
5.2.2　VT-d环境配置
     (1.硬件支持和BIOS设置; 2.宿主机内核的配置; 3.在宿主机中隐藏设备; 4.通过Qemu命令行分配设备给客户机)
5.2.3　VT-d操作示例
      (1.网卡直接分配; 2.硬盘直接分配; 3.USB直接配置; 4.VGA显卡直接分配)
5.2.4　SR-IOV技术——多个虚拟机共享一个物理设备资源, 达到设备直接分配的性能. 
      (1.SR-IOV概述, 物理功能, 虚拟功能)
      (2.SR-IOV操作示例)
      (3.SR-IOV使用问题解析)

5.3　热插拔——电脑运行时(不关闭电源)插上或拔除硬件
5.3.1　PCI设备热插拔
5.3.2　PCI设备热插拔示例(1.网卡的热插拔; 2.USB的热插拔; 3.SATA硬盘的热插拔)
5.3.3　CPU和内存的热插拔

5.4　动态迁移
5.4.1　动态迁移的概念
      (迁移概念, 静态迁移, 动态迁移. )
5.4.2　动态迁移的效率和应用场景
       (衡量条件: 整体迁移时间, 服务器停机时间, 对服务器性能的影响)
5.4.3　KVM动态迁移原理和实践
       (先迁移内存、后迁移配置; KVM动态迁移应该注意的事项, 在KVM上具体进行的操作步骤)
5.4.4　VT-d/SR-IOV的动态迁移

5.5　嵌套虚拟化
5.5.1　嵌套虚拟化的基本概念(Xen On Xen和KVM On Xen, VMware on VMware 和KVM on KVM等等)
5.5.2　KVM嵌套KVM(主要步骤)

5.6　KSM技术—写实复制. 
5.6.1　KSM基本原理—内核同页合并. 
    KSM允许内核在两个或多个进程(包括虚拟机客户机)之间共享完全相同的内存页. 
5.6.2　KSM操作实践
    配置文件
5.7　KVM其他特性简介
    5.7.1　1GB大页
       (2MB->1GB,减少内存页表数量, 提高TLB缓存的效率, 从而提高了系统的内存访问性能. 
         1GB大页的使用步骤)
    5.7.2　透明大页
        (提高系统内存的使用效率和性能. 
          使用透明大页的步骤)
5.7.3　AVX和XSAVE——高级矢量扩展. 
5.7.4　AES新指令——指令的配置、测试
5.7.5　完全暴露宿主机CPU特性——CPU模型特性、CPU信息查看. 
5.8　KVM安全
5.8.1　SMEP—安全渗透, 监督模式执行保护
5.8.2　控制客户机的资源使用-cgroups—linux内核中的一个特性, 用于限制、记录和隔离进程组对系统物理资源的使用. 
       cgroups的功能—资源限制, 优先级控制, 记录, 隔离, 控制. 
       cgroups子系统. 
       cgroups操作示例: 通过cgroups的blkio子系统来设置2个客户机对磁盘I/O读写的优先级. 
5.8.3　SELinux和sVirt
       SELinux—linux内核中的安全访问体系(MAC, 强制访问控制模式), 为每一个应用程序提供一个"沙箱", 只允许应用程序执行它设计需要的且在安全策略中明确允许的任务, 对每个应用程序只分配它正常工作所需要的对应权限. 
       sVirt—对虚拟化客户机使用强制访问控制来提高安全性, 阻止因为Hypervisor的bug而导致的从一台客户机向宿主机或其他服务器的攻击. 
       SELinux和sVirt的配置和操作示例. 
5.8.4　可信任启动-Tboot
       TXT—在PC或服务器系统启动是对系统关键部位进行验证的硬件解决方案. 
       TBoot—可信启动, 是使用TXT技术在内核或Hypervisor启动之前的一个软件模块, 用于度量和验证操作系统或Hypervisor的启动过程. 
       使用TBoot的示例. 
5.8.5　其他安全策略
       1.镜像文件加密
       2.虚拟网络的安全
       3.远程管理的安全
       4.普通Linux系统的安全准则

5.9　QEMU监控器
5.9.1　QEMU monitor的切换和配置
5.9.2　常用命令介绍
      help, info,info version ,info ,commit,cont,change,balloon,cup index,log,sendkey keys,x和xp, p或print fmt expt
5.10　qemu-kvm命令行参数
      qemu-system-x86_64[options] [disk_images]
      cpu的相关参数—-cpu参数, -smp参数
      磁盘相关的参数
      网络相关的参数
      图形显示相关的参数
      Vt-d和SR-IOV相关参数
      动态迁移的参数
      已用过的其他参数
5.10.1　回顾已用过的参数
5.10.2　其他常用参数

5.11　迁移到KVM虚拟化环境
5.11.1　virt-v2v工具介绍—将虚拟客户机从一些Hypervisor(也包括KVM自身)迁移到KVM环境中去. 
5.11.2　从Xen迁移到KVM
      virt-v2v-ic xen+ssh://root@xen0.demo.com -os pool -b brnamevm-name
5.11.3　从VMware迁移到KVM
      virt-v2v-ic esx://esx.demo.com/ -os pool --bridege brame vm-name
5.11.4　从VirtualBox迁移到KVM
      virt-v2v -ic vbox+ssh://root@vbox.demo.com -os pool -b bramevm-name
5.11.5　从物理机迁移到KVM虚拟化环境(P2V)
      
5.12　本章小结
5.13　注释和参考阅读
```