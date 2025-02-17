
可信任启动——Tboot

1.TXT 和 Tboot 简介

现在越来越多的公司开始使用虚拟化技术来提高物理资源的利用率和系统可管理性, 客户机都运行在 Hypervisor 之上, 所以通常会把 Hypervisor 作为安全可信的基础, 这就要求 Hypervisor 本身是可信任的. Hhypervisor 的可信启动是一个可信 Hypervisor 的基础, 也是整个虚拟化环境的安全可信的基础. 由于 Hypervisor 是和系统物理硬件接触最紧密的软件层, 它直接依赖于系统的固件(如 BIOS)和硬件(如 CPU、内存), 所以可以利用一些硬件技术来保证 hypervisor 的可信启动.

(1)TXT 简介

TXT 是 Intel 公司开发的 Trusted Execution Technology(可信执行技术)的简称, 是可信计算(Trusted Computing)在 Intel 平台上的实现, 它是在 PC 或服务器系统启动时对系统的关键部件进行验证的硬件解决方案. TXT 的主要目标在于: 证明一个平台和运行于它之上的操作系统的可靠性; 确保一个可靠的操作系统是启动在可信任的环境中的, 进而成为一个可信的操作系统; 提供给可信任操作系统比被证实的系统更多的安全特性.

TXT 提供了动态可信根(dynamic root of trust)的机制以增强平台的安全性, 为建立可信计算环境和可信链提供必要的支持. 动态可信根, 依靠一些已知正确的序列来检查系统启动时的配置和行为的一致性. 使用这样的基准测试, 系统可以很快地评估当前这次启动过程中是否有改变或篡改已设置的启动环境的意图.

恶意软件是对 IT 基础架构的一个重要威胁, 而且也是日益严重的威胁. 尽管恶意软件的原理不尽相同, 但是它们都试图去污染系统、扰乱正常商业活动、盗取数据、夺取平台的控制权, 等等. 由于现在的公司都越来越多地使用虚拟的、共享的、多租户的 IT 基础架构模型, 因此传统的网络基础架构就看起来更加的分散, 暴露了更多的安全漏洞. 同样, 传统的安全技术(反病毒和反蠕虫软件)采用的主要方式是对已知的病毒或蠕虫的攻击行为来进行防护和阻止, 今天随着各种安全公司的规模扩大和复杂性的增强, 传统安全技术也只能是部分的有效, 效果并不尽如人意. Intel 的 TXT 技术提供了一种不同的方法——使用已知是正确的数据和流程来检查系统或普通软件的启动.

Intel 的 TXT 技术主要通过三个方面来提供安全和信任: 首先将数字指纹软件保存在一个称为"可信用平台模块"(Trusted Platform Module, TMP)的受保护区域内. 每次软件启动时, 都会检测并确保数字指纹吻合, 从而判断系统是否存在风险; 其次, 它能阻止其他应用程序、操作系统或硬件修改某个应用程序的专用内存区; 再次, 如果某个应用程序崩溃, TXT 将清除它在内存中的数据和芯片缓存区, 避免攻击软件嗅探其残余数据.

基于 Intel TXT 技术建立的可信平台, 主要由三个部分组成: 安全模式指令扩展(Safe Mode Externtions, SMX)、认证代码模块(Authenticated Code Module, AC 模块)、度量过的安全启动环境(Measured Launched Environment, MLE). 安全模式指令扩展, 是对现有指令集进行扩展, 引入了一些与安全技术密切相关的指令, 通过执行这些指令, 系统能够进入和退出安全隔离环境. 认证代码模块, 是由芯片厂商提供的, 经过数字签名认证的, 与芯片完全绑定的一段认证代码. 当系统接入安全隔离环境时, 最先被执行的就是这段认证代码, 它被认为是可信的, 它的作用是检测后续安全启动环境的可信性. 安全启动环境是用于检测内核(或 Hypervisor)以及启动内核(或 Hypervisor)的软件, 它不仅需要对即将启动的内核(或 Hypervisor)进行检测, 同时还需要保证这种检测过程是受保护的, 以及它自身所运行的代码不会被篡改.

(2)Tboot 简介

Tboot 即"可信启动"(Trusted Boot), 是使用 TXT 技术的在内核或 Hypervisor 启动之前的一个软件模块, 用于度量和验证操作系统或 Hypervisor 的启动过程. Tboot 利用 TXT 技术能够对"动态可信根"在进入安全隔离环境时进行一系列可信检测, 与保存在可信平台模块(TPM)的存储空间中的目标检测值进行比较. 可信平台模块(通常是一个硬件芯片)利用自身的安全性使这些值不会被恶意代码获取和篡改. Tboot 能够利用可信平台模块中的平台配置寄存器(PCR)来保护和控制启动顺序, 使非法应用不能跳过这些检测步骤直接进入到可信链的后续环节. 同时, Tboot 还能在系统关闭或休眠前清除敏感信息以防泄漏, 使可信环境在安全可控制的过程中退出. 除此之外, Tboot 还利用支持 TXT 技术的芯片中自带的 DMA 受保护区域(DMA Protected Range, PTR)和 VT-d 的受保护内存区域(Protected Memory Region, PMR)来防止恶意代码通过 DMA 跳过检测过程而直接访问内存中的敏感区域.

关于 TXT 和 Tboot 的实现细节, 这里并不做详细的介绍, 读者可以查看本章参考阅读中提到的 Intel 关于 TXT 技术规范的手册. 在使用 Tboot 的情况下, 一个可信的内核或 Hypervisor 的启动过程大致如图 5-26 所示.


图　5-26　在 Tboot 支持下的可信任启动过程
Tboot 目前也是由 Intel 的开源软件工程师发起的一个开源的项目, 其项目主页是: http://sourceforge.net/projects/tboot/和 http://tboot.sourceforge.net/

目前的一些开源操作系统内核和 Hypervisor 都对 Tboot 有较好支持, Xen 从 3.4 版本开始支持 Tboot, 而 Linux 内核从 2.6.35 版本开始支持 Tboot(在 3.0 版本中加入了一部分和 VT-d 相关的修复). 一些主流的 Linux 发行版(如 RHEL、Fedora、Ubuntu 等)也支持 Tboot, 并提供了 Tboot 的软件安装包.

2.使用 Tboot 的示例

在介绍了 Intel TXT 和 Tboot 技术之后, 本节将介绍如何配置系统的软硬件来让 Tboot 真正地工作起来. 关于配置和使用 Tboot, 笔者根据在一台使用 Intel Westmere-EP 处理器的 Xeon(R)X5670 服务器的实际操作来介绍如下几个操作步骤.

(1)硬件配置及 BIOS 设置

并非 Intel 平台的任何一个机器都支持 TXT, 在 Intel 中, 有 vPro 标识的桌面级硬件平台一般都支持 TXT, 另外也有部分服务器平台支持 TXT 技术. 因为 Intel TXT 技术依赖于 Intel VT 和 VT-d 技术, 所以在 BIOS 中不仅需要打开 TXT 技术的支持, 还需要打开 Intel VT 和 VT-d 的支持. 在 BIOS 中设置如下项目(不同 BIOS 在选项命令和设置位置上有些差别).

打开 TXT 技术的支持, BIOS 选项位于: Advanced -> Processor Configuration -> Intel(R)TXT 或 Intel(R)Trusted Excution Technology, 需要将其设置为"[Enabled]"状态.

打开 Intel VT 和 VT-d 技术的支持, BIOS 选项位于: Advanced -> Processor Configuration -> Intel(R)Virtualization Technology 和 Intel(R)VT-for Direct I/O, 将这两者都设置为"[Enabled]"状态.

可信平台模块(TPM)需要在主板上由一个 TPM 模块芯片支持, 打开 TPM 支持的 BIOS 选项位于: Security -> TPM Administrative Control. 有几个选项, 分别是: No Operation、Turn ON、Turn OFF、Clear Ownership, 应该选择"Turn ON"(打开). 重启系统后, 可以看到 BIOS 设置中的: Security -> TPM State 的值为"Enabled＆Activated". 当然, 如果 TPM 状态一开始就是"Enabled＆Activated", 那么说明 TPM 处于打开状态, 不需要重复打开了.

(2)编译支持 Tboot 的 Linux 内核

要支持 Tboot, 需要在宿主机的 Linux 内核中配置 TXT 和 TCG[15] (Trusted Computing Group)相关的配置. 由于 Tboot 还需要 Intel VT 和 VT-d 技术的支持, 在内核中也要有支持 VT(配置关键字为 VT)和 VT-d(配置文件中关键字为 IOMMU)的配置, 查看这些配置命令行如下:



如果缺少这些配置, 则需要添加上这些配置, 然后重新编译内核. 这里不再重复编译内核的步骤, 在 3.3 节"编译和安装 KVM"中对内核的配置和编译已经做过详细的介绍.

(3)编译和安装 Tboot

在一些主流的 Linux 发行版中, Tboot 已经作为一个单独的软件包发布了, 这些发行版包括: Fedora 14、RHEL 6.1、SELS 11 SP2、Ubuntu 12.04 等, 以及比它们更新的版本. 在已经有 Tboot 支持的系统上, 只需要安装 tboot 这个软件包即可, 如在 RHEL 6.3 中可以用"yum install tboot"来安装 Tboot, 一般也会同时安装 trousers 软件包(可提供 tcsd 这个用于管理可信计算资源的守护程序).

如果没有现成的软件包可用, 可到 sourceforge 上 tboot 的项目页面下载其源代码的 tar.gz 包进行编译. Tboot 项目主页是: http://sourceforge.net/projects/tboot/和 http://tboot.sourceforge.net/, 同时也可以在线查看该项目的修改记录和代码, 见 http://tboot.hg.sourceforge.net/hgweb/tboot/tboot.

tboot 的编译和运行会依赖 openssl-devel、zlib-devel、trousers-devel、trousers 等软件包, 在编译 tboot 之前需要将它们安装好(如果有的依赖软件包不存在, 编译时会有报错提示, 安装上相应的软件包即可). 获取最新的 tboot 开发源代码仓库(目前是使用 Mercurial[16] 工具管理的), 并进行编译, 然后查看编译后生成的所需要的二进制文件, 命令行操作如下:


由上面的输出信息可知, 通过源代码编译和安装 Tboot 及其用户空间管理工具的过程是比较简单的, 默认会将 Tboot 的内核文件 tboot.gz 安装到/boot/目录下, 将 Tboot 相关的用户空间管理工具安装到/usr/sbin/目录下.

(4)修改 GRUB, 让 tboot.gz 先于 Linux 内核启动

在修改 GRUB 之前, 还需要获取当前系统的 SINIT AC 模块(它是芯片厂商提供的经过数字签名的一段认证代码), 并将其配置到 GRUB 中使其对系统后续启动过程进行可信的认证. 可以从硬件供应商那里去索取 SINIT AC 模块, 也可以到 Intel 公司官方网站中关于 TXT 技术的网页[17] 去查看哪些平台支持 TXT 和下载对应的 SINIT 二进制代码模块. 这里已经将 SINIT 模块下载放到/boot/WSM_SINIT_100407_rel.bin 位置.

在使用 Tboot 之时, 在 GRUB 等引导程序中, 需要将 tboot.gz 文件设置为内核(kernel)以便最先启动, 而原本的 Linux 内核(或 Xen 等 Hypervisor)、初始化内存镜像(initramfs、initrd)和 SINIT 模块都设置为模块启动. 一个配置有 Tboot 的 GRUB 入口条目示例如下:


其中, tboot.gz 行的"logging=vga,serial,memory"配置表示将 Tboot 内核启动的信息同时记录在显示器、串口和内存中; WSM_SINIT_100407_rel.bin 就是用于支持笔者使用的 Westmere-EP 平台的 SINIT AC 模块.

(5)获取可信平台模块(TPM)的所有权

通过上一步修改好的 Tboot 启动的 GRUB 入口条目重新启动系统, 在系统中获取可信平台模块(TPM)的所有权, 步骤如下:

1)加载 tpm_tis 内核模块.

tpm_tis 模块是可信平台模块(TPM)硬件的驱动程序, 加载和检查 tpm_tis 的命令行操作如下:


由上面的输出信息可知, tpm_tis 模块依赖于 tpm 模块, 而 tpm 模块又依赖于 tpm_bios 模块. 如果加载 tpm_tis 时不成功, 可以添加一些参数, 通过用如下命令来加载 tpm_tis 模块:


2)启动 tcsd 守护进程.

tcsd 是 trousers 软件包中的一个命令行工具, 是一个管理可信平台模块(TPM)资源的守护程序, 它也负责处理来自本地和远程的可信服务提供者(TSP)的请求. tcsd 应该是唯一的到达 TPM 设备驱动程序的一个用户空间守护进程. 启动和查询 tcsd 守护程序的命令行操作如下:


3)设置系统的可信平台模块(TPM)的所有者.

tpm_takeownership 也是 trousers 软件包中的一个命令行工具, 它通过 TPM_TakeOwnership 应用程序接口在当前系统的可信平台模块(TPM)上建立一个所有者(owner). 该命令在执行时会要求设置所有者的密码和存储根密钥(Storage Root Key, SRK)的密码和确认.


另外, 可以添加-y 参数将所有者的密码设置为 20 个"0"而不需要交互式的输出, 也可以用-z 参数将存储根密钥(SRK)的密码设置为 20 个"0", 示例如下:


(6)启动系统, 检查 Tboot 的启动情况

从前面修改的 Grub 的 Tboot 入口条目启动系统, 在显示器或串口信息上都可以看到 Tboot 启动时的信息, 示例如下:



在系统启动之后, 通过 dmesg 命令可以找到 Tboot 正在使用的一些信息, 如下:


(7)使用 txt-stat 工具检查本次启动的可信状态

对于 Tboot 是否正常工作, 本次操作系统启动是否可信, 可以使用 Tboot 源码中自带的 txt-stat 命令行工具来查看 TXT 当前的工作状态. 如果在 txt-stat 中看到如下的输出信息, 则表明本次是一次安全可信的启动.



使用 txt-stat 工具查看 TXT 工作状态, 该工具的输出结果如下:



如果看到在 Tboot 的保护下正常启动操作系统, 也查询到当前系统的 TXT 是正常工作的, 那么就可以证明本次启动是一次可信任的启动.