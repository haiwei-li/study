
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [KVM 里 CentOS 7 虚拟机的网络设置](#kvm-里-centos-7-虚拟机的网络设置)

<!-- /code_chunk_output -->

http://www.lenky.info/archives/2018/12/2667

# KVM 里 CentOS 7 虚拟机的网络设置

1. 宿主机是 CentOS 7, KVM 虚拟机也是 CentOS 7

2. 在宿主机上有物理网卡 eth0, 配置有 ip: 192.168.1.2/24

有网桥 virbr0, 配置有 ip: 192.168.122.1/24

该 virbr0 绑定在 virbr0\-nic 接口上, 而 virbr0\-nic 貌似是一个 tun/tap 设备, 因此性能非常差.

**所有 KVM 虚拟机**挂在这个**virbr0 网桥**上, 然后通过 virbr0\-nic 进行相互通信.

如果虚拟机要访问外部主机, 则通过 virbr0\-nic 做 NAT 出去.

如果外部主机要访问虚拟机, 则比较麻烦, 或许可能不行.

```
# brctl show
bridge name	bridge id	STP enabled	interfaces
virbr0	8000.52540098e452	yes	virbr0-nic
vnet0
```

vnet0 是 KVM 虚拟机网卡在宿主机上对应的 tap 设备, 如果还有其他 KVM 虚拟机, 则都接到这个 virbr0.

3, 在上一步中, 看到**网桥**是绑定在**virbr0\-nic 虚拟设备**上的, 其实可以直接绑定在宿主机的物理网卡 eth0 上.

a, 新增网桥 br0 以及配置

```
# brctl addbr br0
# vi /etc/sysconfig/network-scripts/ifcfg-br0
# cat /etc/sysconfig/network-scripts/ifcfg-br0
TYPE=bridge
BOOTPROTO=none
IPADDR=192.168.1.205
NETMASK=255.255.0.0
GATEWAY=192.168.1.254
NM_CONTROLLED=no
DEFROUTE=yes
PEERDNS=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no

NAME=br0
DEVICE=br0
ONBOOT=yes
```

b, 修改 eth0 网卡配置, 在最后一行加上 BRIDGE=br0, 表示将 eth0 桥接到 br0:

```
# cat /etc/sysconfig/network-scripts/ifcfg-enp4s0f0
TYPE=Ethernet
BOOTPROTO=static
IPADDR=192.168.1.208
NETMASK=255.255.0.0
GATEWAY=192.168.1.254
NM_CONTROLLED=no
DEFROUTE=yes
PEERDNS=yes
IPV4_FAILURE_FATAL=no
IPV6INIT=yes
IPV6_AUTOCONF=yes
IPV6_DEFROUTE=yes
IPV6_FAILURE_FATAL=no
NAME=enp4s0f0
DEVICE=enp4s0f0
ONBOOT=yes
BRIDGE=br0
```

c, 重启网络, 务必多执行一次 start, 因为 eth0 启用依赖于 br0, 有可能第一次启动会失败. 如果恰好 eth0 是用来做远程的, 则可能导致网络断掉.

```
# service network restart; service network start;
```

把启动的虚拟机在宿主机上的对应网卡绑定到这个 br0 上:

```
# brctl show
bridge name	bridge id	STP enabled	interfaces
br0	8000.000d48064198	no	enp6s0f0
virbr0	8000.52540098e452	yes	virbr0-nic
vnet0
# brctl delif virbr0 vnet0
# brctl show
bridge name	bridge id	STP enabled	interfaces
br0	8000.000d48064198	no	enp6s0f0
virbr0	8000.52540098e452	yes	virbr0-nic
# brctl addif br0 vnet0
# brctl show
bridge name	bridge id	STP enabled	interfaces
br0	8000.000d48064198	no	enp6s0f0
vnet0
virbr0	8000.52540098e452	yes	virbr0-nic
```

这种设置的虚拟机网络性能相比上一种要好, 而性能更好的设置方式就是直接把物理网卡 pass through 到虚拟机.

当然可以基于 ovs 网桥去做, 见其他文章

4, 做物理网卡 pass through 需要宿主机的硬件支持和一些准备工作

a, 确认宿主机的硬件支持, 主要是 cpu 和主板, 这可以查看官方的硬件支持列表, 或者在 BIOS 中查看相关选项. 以 Intel 硬件为例, 主要就是:

VT-x: 处理器技术, 提供内存以及虚拟机的硬件隔离, 所涉及的技术有页表管理以及地址空间的保护.

VT-d: 处理有关芯片组的技术, 它提供一些针对虚拟机的特殊应用, 如支持某些特定的虚拟机应用跨过处理器 I/O 管理程序, 直接调用 I/O 资源, 从而提高效率, 通过直接连接 I/O 带来近乎完美的 I/O 性能.

VT-c: 针对网络提供的管理, 它可以在一个物理网卡上, 建立针对虚拟机的设备队列.

VT-c 是后面将提到的 SR-IOV 关系比较大, 本小节只需验证 VT-x 和 VT-d, 一般在 BIOS 中 Advanced 下 CPU 和 System 或相关条目中设置, 都设置为 Enabled:

VT: Intel Virtualization Technology

VT-d: Intel VT for Directed I/O

VT-c: I/O Virtualization

b, 修改内核启动参数, 使 IOMMU 生效, CentOS7 上修改稍微不同:

```
# cat /etc/default/grub
...
GRUB_CMDLINE_LINUX="crashkernel=auto rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet intel_iommu=on"
...
```

在 GRUB_CMDLINE_LINUX 后加上 intel_iommu=on, 其他的不动. 先备份, 再重新生成 grub.cfg:

```
# cp /boot/grub2/grub.cfg ~/grub.cfg.bak
# grub2-mkconfig -o /boot/grub2/grub.cfg
# diff /boot/grub2/grub.cfg ~/grub.cfg.bak
```

可以 diff 比较一下参数是否正确加上.

重启机器后执行如下两条命令进行确认:

```
# find /sys/kernel/iommu_groups/ -type l
# dmesg | grep -e DMAR -e IOMMU
```

如果有输出, 那就说明 ok 了. 如果没有, 那再验证 BIOS、内核编译项、内核启动参数等是否没有正确配置. 比如内核是否已经编译了 IOMMO:

```
# cat /boot/config-3.10.0-862.el7.x86_64 |grep IOMMU
CONFIG_GART_IOMMU=y
# CONFIG_CALGARY_IOMMU is not set
CONFIG_IOMMU_HELPER=y
CONFIG_VFIO_IOMMU_TYPE1=m
CONFIG_VFIO_NOIOMMU=y
CONFIG_IOMMU_API=y
CONFIG_IOMMU_SUPPORT=y
CONFIG_IOMMU_IOVA=y
CONFIG_AMD_IOMMU=y
CONFIG_AMD_IOMMU_V2=m
CONFIG_INTEL_IOMMU=y
```

c, 找一个没用的网卡设备, 因为 pass through 是虚拟机独占, 所以肯定不能用远程 ip 所对应的网卡设备, 否则远程网络就断了. 比如我的远程网卡为 enp4s0f0, 那么我这里拿 enp8s0f0 作为 pass through 网卡.

通过 ethtool 查看网卡的 bus 信息:

```
# ethtool -i enp8s0f0 | grep bus
bus-info: 0000:08:00.0
```

解除绑定(注意里面的 0000:08:00.0 是上一步获得的 bus 信息):

```
# lspci -s 0000:08:00.0 -n
08:00.0 0200: 8086:10c9 (rev 01)
# modprobe pci_stub
# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind
# echo "8086 10c9″ > /sys/bus/pci/drivers/pci-stub/new_id
```

驱动确认(注意里面的: **Kernel driver in use: pci-stub**):

```
# lspci -s 0000:08:00.0 -k
08:00.0 Ethernet controller: Intel Corporation 82576 Gigabit Network Connection (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: pci-stub
Kernel modules: igb
```

启动虚拟机:

```
kvm -name centos7 -smp 4 -m 8192 \
-drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
-drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
-nographic -vnc :2 \
-net none \
-device pci-assign,host=0000:08:00.0
```

注意最后两个参数:

- '-net none': 告诉 qemu 不用模拟网卡设备
- '-device pci-assign,host=0000:08:00.0': 直接指定一个 pci 设备, 对应的地址为宿主机上 pci 地址 0000:08:00.0

执行上面命令, 我这里出现一个错误:
```
kvm: -device pci-assign,host=0000:08:00.0: No IOMMU found. Unable to assign device "(null)"
kvm: -device pci-assign,host=0000:08:00.0: Device initialization failed.
kvm: -device pci-assign,host=0000:08:00.0: Device 'kvm-pci-assign' could not be initialized
```

然后我前面的配置都 ok 啊, 经过搜索, 问题在于最新的内核里, 已建议废除 KVM_ASSIGN 机制, 而只支持 vfio, 我这里查看 CentOS 7 的内核编译选项也果真如此:

```
# cat /boot/config-3.10.0-862.el7.x86_64 | grep KVM_DEVICE
# CONFIG_KVM_DEVICE_ASSIGNMENT is not set
```

所以换用**vfio 驱动**. VFIO 可以用于实现高效的用户态驱动. 在虚拟化场景可以用于 device passthrough. 通过**用户态配置 IOMMU 接口**, 可以将 DMA 地址空间映射限制在进程虚拟空间中. 这对高性能驱动和虚拟化场景 device passthrough 尤其重要. 相对于传统方式, VFIO 对 UEFI 支持更好. VFIO 技术实现了用户空间直接访问设备. 无须 root 特权, 更安全, 功能更多.

重新解除绑定和再绑定:

```
# modprobe vfio
# modprobe vfio-pci
# lspci -s 0000:08:00.0 -n
08:00.0 0200: 8086:10c9 (rev 01)
# echo "8086 10c9″ > /sys/bus/pci/drivers/vfio-pci/new_id
# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind
# echo 0000:08:00.0 > /sys/bus/pci/drivers/vfio-pci/bind
# lspci -s 0000:08:00.0 -k
08:00.0 Ethernet controller: Intel Corporation 82576 Gigabit Network Connection (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: vfio-pci
Kernel modules: igb
```

启动虚拟机:

```
kvm -name centos7 -smp 4 -m 8192 \
-drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
-drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
-nographic -vnc :2 \
-net none \
-device vfio-pci,host=0000:08:00.0
```

这次一切 OK, 顺利启动并进入到 CentOS 7 虚拟机.

https://blog.csdn.net/leoufung/article/details/52144687

https://www.linux-kvm.org/page/10G_NIC_performance:_VFIO_vs_virtio

http://www.linux-kvm.org/page/How_to_assign_devices_with_VT-d_in_KVM

5, 虚拟机独占物理网卡总是资源浪费, 而且如果虚拟机比较多, 又到哪有找那么多物理网卡. 因此为了实现多个虚机共享一个物理设备, 并且达到直接分配的目的, PCI-SIG 组织发布了 SR-IOV(Single Root I/O Virtualization and sharing)规范, 它定义了一个标准化的机制用以原生地支持实现多个客户机共享一个设备. 当前 SR-IOV(单根 I/O 虚拟化)最广泛地应用还是网卡上.

SR-IOV 使得一个单一的功能单元(比如, 一个以太网端口)能看起来像多个独立的物理设备. 一个带有 SR-IOV 功能的物理设备能被配置为多个功能单元.

SR-IOV 使用两种功能(function):

- 物理功能(Physical Functions, PF): 这是完整的带有 SR-IOV 能力的 PCIe 设备. PF 能像普通 PCI 设备那样被发现、管理和配置.

- 虚拟功能(Virtual Functions, VF): 简单的 PCIe 功能, 它只能处理 I/O. 每个 VF 都是从 PF 中分离出来的. 每个物理硬件都有一个 VF 数目的限制. 一个 PF, 能被虚拟成多个 VF 用于分配给多个虚拟机.
Hypervisor 能将一个或者多个 VF 分配给一个虚机. 在某一时刻, 一个 VF 只能被分配给一个虚机. 一个虚机可以拥有多个 VF. 在虚机的操作系统看来, 一个 VF 网卡看起来和一个普通网卡没有区别. **SR-IOV 驱动是在内核**中实现的.

a, 检查设备是否支持 SR-IOV:

```
# lspci -s 0000:08:00.0 -vvv | grep -i "Single Root I/O Virtualization"
Capabilities: [160 v1] Single Root I/O Virtualization (SR-IOV)
```

看来我这个设备上的这个网卡是支持的.

b, 重新绑定到 igb 驱动:

```
# echo 0000:08:00.0 > /sys/bus/pci/devices/0000\:08\:00.0/driver/unbind
# echo "8086 10c9″ > /sys/bus/pci/drivers/igb/new_id
bash: echo: write error: File exists
# echo "8086 10c9″ > /sys/bus/pci/drivers/igb/bind
bash: echo: write error: No such device
```

出现上面这些错误, 当前还不知道怎么回事, 可能是因为我关闭 kvm 都是直接在宿主机里 kill 掉进程的, 导致 bus 信息未释放?待进一步分析.

```
# echo igb > /sys/bus/pci/devices/0000\:08\:00.0/driver_override
# echo 0000:08:00.0 > /sys/bus/pci/drivers_probe
# lspci -s 0000:08:00.0 -k
08:00.0 Ethernet controller: Intel Corporation 82576 Gigabit Network Connection (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: igb
Kernel modules: igb
```

c, 创建 VF, 可以通过重新加载内核模块参数来创建 VF:

```
# modprobe -r igb; modprobe igb max_vfs=7
```

如果远程网卡也是用的 igb, 则会导致断网. 因此还是直接只对 0000:08:00.0 网卡开启 VF:

```
# lspci -nn | grep "Virtual Function"
# echo 2 > /sys/bus/pci/devices/0000\:08\:00.0/sriov_numvfs
# lspci -nn | grep "Virtual Function"
08:10.0 Ethernet controller [0200]: Intel Corporation 82576 Virtual Function [8086:10ca] (rev 01)
08:10.2 Ethernet controller [0200]: Intel Corporation 82576 Virtual Function [8086:10ca] (rev 01)
# echo 0 > /sys/bus/pci/devices/0000\:08\:00.0/sriov_numvfs
# lspci -nn | grep "Virtual Function"
```


也就是对 sriov_numvfs 进行数字写入, 表示创建几个 VF, 写入 0 则删除所有 VF.

如果要**重启生效**, 那还是在**模块加载时指定参数**:

```
# echo "options igb max_vfs=2″ >>/etc/modprobe.d/igb.conf
```


d, 接下来就可以把 VF 当做普通网卡给虚拟机独占使用了

```
# lshw -c network -businfo
Bus info Device Class Description
========================================================
...
pci@0000:08:10.0 enp8s16 network 82576 Virtual Function
pci@0000:08:10.2 enp8s16f2 network 82576 Virtual Function
...
# ethtool -i enp8s16 | grep bus
bus-info: 0000:08:10.0
# lspci -s 0000:08:10.0 -n
08:10.0 0200: 8086:10ca (rev 01)
# modprobe vfio
# modprobe vfio-pci
# echo 0000:08:10.0 > /sys/bus/pci/devices/0000\:08\:10.0/driver/unbind
# echo "8086 10ca" > /sys/bus/pci/drivers/vfio-pci/new_id
# echo 0000:08:10.0 > /sys/bus/pci/drivers/vfio-pci/bind
# lspci -s 0000:08:10.0 -k
08:10.0 Ethernet controller: Intel Corporation 82576 Virtual Function (rev 01)
Subsystem: Intel Corporation Device 0000
Kernel driver in use: vfio-pci
Kernel modules: igbvf
# kvm -name centos7 -smp 4 -m 8192 \
-drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
-drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
-nographic -vnc :2 \
-net none -device vfio-pci,host=0000:08:10.0
```

进入虚拟机后查看网卡的驱动信息, 可以看到是用的 igbvf:

```
# ethtool -i eth0
driver: igbvf
version: 2.4.0-k
...
```

5, pass through 的麻烦之处在于**需要指定具体的 pci 地址**, 比较麻烦, 比如在虚拟机要做迁移的场景.

因此另外一种据说性能也非常好的方式是通过**Virtio 网卡**. 首先需要在内核打开如下选项:

```
CONFIG_VIRTIO=m
CONFIG_VIRTIO_RING=m
CONFIG_VIRTIO_PCI=m
CONFIG_VIRTIO_BALLOON=m
CONFIG_VIRTIO_BLK=m
CONFIG_VIRTIO_NET=m
```

CentOS 7 自带内核默认已经打开, 因此可以直接使用.
```
# cat /boot/config-3.10.0-862.el7.x86_64 | grep VIRTIO
CONFIG_VIRTIO_VSOCKETS=m
CONFIG_VIRTIO_VSOCKETS_COMMON=m
CONFIG_VIRTIO_BLK=m
CONFIG_SCSI_VIRTIO=m
CONFIG_VIRTIO_NET=m
CONFIG_VIRTIO_CONSOLE=m
CONFIG_HW_RANDOM_VIRTIO=m
CONFIG_DRM_VIRTIO_GPU=m
CONFIG_VIRTIO=m
CONFIG_VIRTIO_PCI=m
CONFIG_VIRTIO_PCI_LEGACY=y
CONFIG_VIRTIO_BALLOON=m
CONFIG_VIRTIO_INPUT=m
# CONFIG_VIRTIO_MMIO is not set
```

执行 kvm:

```
kvm -name centos7 -smp 4 -m 8192 \
-drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
-drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
-nographic -vnc :2 \
-device virtio-net-pci,netdev=net0 -netdev tap,id=net0,script=/home/vmhome/qemu-ifup,downscript=no
```

注意最后一行的网卡设置:
- \-device virtio-net-pci: 指定了一个使用**virtio-net-pci 的设备**, 而 netdev=net0: 和后面的 id=net0 关联起来, net0 是任意值, 只要一致就可以.
- \-netdev tap,id=net0,script=/home/vmhome/qemu-ifup,downscript=no: 宿主机上对应桥接到交换机上的端口

进入虚拟机, 查看网卡驱动, 可以看到如下:

```
# ethtool -i eth0
driver: virtio_net
version: 1.0.0
...
```

根据注 1, 如果采用如下命令, 性能会非常差:

```
kvm -name centos7 -smp 4 -m 8192 \
-drive file=/home/vmhome/centos7.qcow2,if=virtio,media=disk,index=0,format=qcow2 \
-drive file=/home/lenky/CentOS-7-x86_64-DVD-1804.iso,media=cdrom,index=1 \
-nographic -vnc :2 \
-net nic,model=virtio -net tap,script=/home/vmhome/qemu-ifup,downscript=no
```

但是根据注 2, 这两种写法应该是一样的, 只不过-net nic,model=virtio 是旧语法(old -net..-net syntax), 实践验证后一种 kvm 启动的虚拟机里通过 ethtool 查看网卡的驱动也是 virtio_net. 难道是另外的某些原因还不得而知.

ps: 通过如下命令可以查看当前 qemu 支持的网卡类型

```
# kvm -net nic,model=?
qemu: Supported NIC models: ne2k_pci,i82551,i82557b,i82559er,rtl8139,e1000,pcnet,virtio
```

注:
1, https://www.linux-kvm.org/page/10G_NIC_performance:_VFIO_vs_virtio
2, http://www.linux-kvm.org/page/Virtio
3, https://www.cnblogs.com/sammyliu/p/4548194.html
4, https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_host_configuration_and_guest_installation_guide/sect-virtualization_host_configuration_and_guest_installation_guide-sr_iov-how_sr_iov_libvirt_works
5, https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/drivers/pci/pci-driver.c?h=v3.16&id=782a985d7af26db39e86070d28f987cad21313c0



