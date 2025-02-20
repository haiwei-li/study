
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. kvm forum 2017](#1-kvm-forum-2017)
- [2. 第一版 RFC](#2-第一版-rfc)
- [3. 设备描述](#3-设备描述)
  - [3.1. 整体介绍](#31-整体介绍)
  - [3.2. 虚拟拓扑的固件描述](#32-虚拟拓扑的固件描述)
  - [3.3. 设备探测和设备操作](#33-设备探测和设备操作)
    - [3.3.1. 概述](#331-概述)
    - [3.3.2. 功能位](#332-功能位)
    - [3.3.3. viommu 设备配置信息](#333-viommu-设备配置信息)
    - [3.3.4. 设备初始化](#334-设备初始化)
    - [3.3.5. 设备操作](#335-设备操作)
      - [3.3.5.1. attach device](#3351-attach-device)
      - [3.3.5.2. detach device](#3352-detach-device)
      - [3.3.5.3. map region](#3353-map-region)
      - [3.3.5.4. unmap region](#3354-unmap-region)
  - [3.4. 未来要进行的工作](#34-未来要进行的工作)
- [4. Linux driver](#4-linux-driver)
- [5. KVM tool](#5-kvm-tool)
  - [5.1. 实现 virtio-iommu](#51-实现-virtio-iommu)
  - [5.2. virtio 设备的 vIOMMU 支持](#52-virtio-设备的-viommu-支持)
  - [5.3. vfio 设备的支持](#53-vfio-设备的支持)
  - [5.4. debug 相关](#54-debug-相关)
- [6. 现有实现](#6-现有实现)
  - [description 变化](#description-变化)
  - [linux driver](#linux-driver)

<!-- /code_chunk_output -->

这里主要讲一下作者最初的思想和相关实现

# 1. kvm forum 2017

virtio-iommu 最早是 2017 年提出来的

[2017] vIOMMU/ARM: Full Emulation and virtio-iommu Approaches by Eric Auger: https://www.youtube.com/watch?v=7aZAsanbKwI ,

slide: https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf

# 2. 第一版 RFC

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步说明. 它包含设备描述, Linux 驱动程序和 kvmtool 中的粗略实现.

virtio-iommu: a paravirtualized IOMMU

* [RFC 0/3]: a paravirtualized IOMMU, [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/)
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: [spinics](https://www.spinics.net/lists/kvm/msg147991.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-2-jean-philippe.brucker__38031.8755437203$1491592803$gmane$org@arm.com/)
  * [RFC 2/3] virtio-iommu: device probing and operations: [spinice](https://www.spinics.net/lists/kvm/msg147992.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-3-jean-philippe.brucker@arm.com/)
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

* [RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/)

# 3. 设备描述

## 3.1. 整体介绍

> cover letter: a paravirtualized IOMMU

这是使用 virtio 传输(transport)的 paravirtualized IOMMU device 的初步建议. 它包含设备描述, Linux 驱动程序和 kvmtool 中的玩具实现.

使用此原型, 您可以将来自模拟设备(virtio) 或 pass-through 设备(VFIO) 的 DMA 转换为 guest 内存.

最简单地, viommu 处理来自 guest 的 `map/unmap` 请求. "RFC 3/3"中提议的未来扩展将来会将 page tables 绑定到设备上.

半虚拟化的 IOMMU 中, 与完全模拟 (full emulation) 相比, 有许多优点. 它是便携式的, 可以在不同的架构中重复使用. 它比完全模拟更容易实现, 因为状态跟踪更少. 在某些情况下, 它可能会更有效率, 上下文切换到host的更少, 并且内核模拟的可能性也更少.

在 kvmtool 实现中, 考虑了两个主要场景

Scenario 1: a hardware device passed through twice via VFIO

场景一: 硬件设备通过 VFIO 透传

```
   MEM____pIOMMU________PCI device________________________       HARDWARE
            |     (2b)                                    \
  ----------|-------------+-------------+------------------\-------------
            |             :     KVM     :                   \
            |             :             :                    \
       pIOMMU drv         :         _______virtio-iommu drv   \    KERNEL
            |             :        |    :          |           \
          VFIO            :        |    :        VFIO           \
            |             :        |    :          |             \
            |             :        |    :          |             /
  ----------|-------------+--------|----+----------|------------/--------
            |                      |    :          |           /
            | (1c)            (1b) |    :     (1a) |          / (2a)
            |                      |    :          |         /
            |                      |    :          |        /   USERSPACE
            |___virtio-iommu dev___|    :        net drv___/
                                        :
  --------------------------------------+--------------------------------
                 HOST                   :             GUEST
```

(1)
* a. 虚拟机用户态有一个 net driver(比如 DPDK). 它通过 mmap 申请一个 buffer, 得到了虚拟地址(VA). 它会发送 **vfio** 请求(`VFIO_IOMMU_MAP_DMA`, 将iova通过IOMMU映射到vaddr对应的物理地址上去) 到虚拟机内核态 virtio-iommu driver 将 VA **映射**到 IOVA(可能 VA = IOVA).
* b. 通过 **virtio** (VIRTIO_IOMMU_T_MAP), 虚拟机内核态 viommu driver 将该 mapping 请求转发到host端的 viommu(用户态后端, 比如qemu).
* c. 通过 **vfio**, 后端 viommu 将请求转发到物理 IOMMU 上.

(2)
* a. 虚拟机用户态 driver 指示设备现在可以通过 IOVA 直接访问 buffer 了
* b. 设备发出的 IOVA 被物理 IOMMU 翻译成 物理地址(PA)

Scenario 2: a virtual net device behind a virtual IOMMU.

场景二: vIOMMU后的虚拟网卡设备

```
  MEM__pIOMMU___PCI device                                     HARDWARE
         |         |
  -------|---------|------+-------------+-------------------------------
         |         |      :     KVM     :
         |         |      :             :
    pIOMMU drv     |      :             :
             \     |      :      _____________virtio-net drv      KERNEL
              \_net drv   :     |       :          / (1a)
                   |      :     |       :         /
                  tap     :     |    ________virtio-iommu drv
                   |      :     |   |   : (1b)
  -----------------|------+-----|---|---+-------------------------------
                   |            |   |   :
                   |_virtio-net_|   |   :
                         / (2)      |   :
                        /           |   :                      USERSPACE
              virtio-iommu dev______|   :
                                        :
  --------------------------------------+-------------------------------
                 HOST                   :             GUEST
```

(1)
* a. 虚拟机内核态的 virtio-net driver 发送请求给 viommu 来 map the virtio ring and a buffer
* b. 通过 virtio, mapping 请求被转发到 host 端

(2)
* virtio-net 设备可以通过 IOMMU 来访问虚拟机内存

物理 iommu 和 viommu 是完全分离的. net driver 通过 DMA/IOMMU API 来 mapping 它的 buffer, buffers 在 virtio-net 和 tap 互相拷贝.

几个名词:

* pIOMMU: 物理 IOMMU, 控制来自物理设备的 DMA 访问
* vIOMMU: 虚拟 IOMMU(virtio-iommu), 控制着虚拟设备和物理设备 DMA 访问虚拟机内存
* GVA, GPA, HVA, HPA
* IOVA: I/O 虚拟地址. 在 guest os 中是 GVA.

## 3.2. 虚拟拓扑的固件描述

> virtio-iommu: firmware description of the virtual topology

与其他 virtio 设备不同, virtio-iommu 设备不能独立工作, 它需要与其他虚拟或 assigned 设备相连. 因此, 在设备操作之前, 我们需要定义一种方法, 让 guest 能发现 virtio-iommu 以及它管理的设备.

host 必须通过 device-tree 或 ACPI 表给 guest 描述 IOMMU 和设备的关系.

vIOMMU 用 32 位 ID 来标识每个虚拟设备, 该文中称为"Device ID". "Device ID" 不一定是全系统唯一的, 但不会在单个 vIOMMU 中重复. 直通设备的 "Device ID" 不需要与物理 IOMMU 看到的 ID 一样.

> 这里的 "Device ID" 都是 vIOMMU 定义的

虚拟 IOMMU 仅使用 virtio-mmio 传输, 而不是 virtio-pci, 因为使用 PCI, IOMMU 接口本身就是一个 endpoint, 而现有的固件接口不允许描述 PCI endpoints 之间的 IOMMU <-> master 关系.

> The virtual IOMMU uses virtio-mmio transport exclusively, not virtio-pci, because with PCI the IOMMU interface would itself be an endpoint, and existing firmware interfaces don't allow to describe IOMMU<->master relations between PCI endpoints.

下图描述了系统中有两个 vIOMMU 翻译来自device请求的情况. vIOMMU 1 翻译两个 PCI domain, 其中每个 funciton 都有 16 位 requester ID.为了使 vIOMMU 能够区分针对每个域中的设备的 guest 请求, 其 "Device ID" 范围不能重叠. vIOMMU 2 翻译两个 PCI 域和一组平台设备.

为了能让 vIOMMU 区分出不同的 guest 请求, 这些请求的目标是某个 domain 中的设备. 单个 vIOMMU 中的 "Device ID" 不能重复.

```
                       Device ID    Requester ID
                  /       0x0           0x0      \
                 /         |             |        PCI domain 1
                /      0xffff           0xffff   /
        vIOMMU 1
                \     0x10000           0x0      \
                 \         |             |        PCI domain 2
                  \   0x1ffff           0xffff   /

                  /       0x0                    \
                 /         |                      platform devices
                /      0x1fff                    /
        vIOMMU 2
                \      0x2000           0x0      \
                 \         |             |        PCI domain 3
                  \   0x11fff           0xffff   /
```

> 物理平台上:
>
> 同一个 PCI domain, Requester ID(可以认为是设备 BDF) 是不同的; 不同 PCI domain, Requester ID 可以相同
>
> vIOMMU侧:
>
> 同一个 vIOMMU 中的 Device ID 不能相同, 某一个 Device ID 会和物理平台上一个设备对应
> 不同 vIOMMU 中的 Device ID 可以相同

Device-tree 已经提供了一种方法来描述这种拓扑关系. 以 vIOMMU2 举例:

```
	/* The virtual IOMMU is described with a virtio-mmio node */
	viommu2: virtio@10000 {
		compatible = "virtio, mmio";
		reg = <0x10000 0x200>;
		dma-coherent;
		interrupts = <0x0 0x5 0x1>;

		#iommu-cells = <1>
	};

	/* Some platform device has Device ID 0x5 */
	somedevice@20000 {
		...

		iommus = <&viommu2 0x5>;
	};

	/*
	 * PCI domain 3 is described by its host controller node, along
	 * with the complete relation to the IOMMU
	 */
	pci {
		...
		/* Linear map between RIDs and Device IDs for the whole bus */
		iommu-map = <0x0 &viommu2 0x10000 0x10000>;
	};
```

更多细节, 见 `DT-IOMMU`

* https://www.kernel.org/doc/Documentation/devicetree/bindings/iommu/iommu.txt
* https://www.kernel.org/doc/Documentation/devicetree/bindings/pci/pci-iommu.txt

对于 ACPI 来说, 我们希望在 IO Remapping Table specification (IORT) 中添加新的 node 类型, 从而通过 ACPI 表来提供类似的机制来描述这个translation.

IORT: IO Remapping Table, DEN0049B, http://infocenter.arm.com/help/topic/com.arm.doc.den0049b/DEN0049B_IO_Remapping_Table.pdf

以下不是规范, 只是节点可能是什么的示例.

```
         Field      | Len.  | Off.  | Description
    ----------------|-------|-------|---------------------------------
     Type           | 1     | 0     | 5: paravirtualized IOMMU
     Length         | 2     | 1     | The length of the node.
     Revision       | 1     | 3     | 0
     Reserved       | 4     | 4     | Must be zero.
     Number of ID   | 4     | 8     |
       mappings     |       |       |
     Reference to   | 4     | 12    | Offset from the start of the
       ID Array     |       |       | IORT node to the start of its
                    |       |       | Array ID mappings.
                    |       |       |
     Model          | 4     | 16    | 0: virtio-iommu
     Device object  | --    | 20    | ASCII Null terminated string
       name         |       |       | with the full path to the entry
                    |       |       | in the namespace for this IOMMU.
     Padding        | --    | --    | To keep 32-bit alignment and
                    |       |       | leave space for future models.
                    |       |       |
     Array of ID    |       |       |
       mappings     | 20xN  | --    | ID Array.
```

操作系统解析 IORT 表, 以构建 IOMMU 与设备之间的 ID 关系表. ID Array 用于查找 IOMMU ID 与 PCI 或平台设备之间的关系. 稍后, virtio-iommu 驱动程序通过"Device object name"字段找到相关的 LNRO0005 描述符, 并探测 virtio 设备以了解更多有关其功能的信息. 由于"IOMMU"的所有属性将在 virtio probe 期间获得, IORT 节点要尽量保持简单.

## 3.3. 设备探测和设备操作

> virtio-iommu: device probing and operations

在探测到了 virtio-iommu 设备并且 driver 知道要 IOMMU 管理的设备后, driver 可以开始向 virtio-iommu 设备发送请求.

此处描述的操作是简约的, 因此 vIOMMU 设备可以尽可能简单地实现, 并且可以通过功能位进行扩展.

1. 概述Overview
2. 功能位Feature bits
3. 设备配置信息Device configuration layout
4. 设备初始化Device initialization
5. 设备操作Device operations
   5.1. Attach device
   5.2. Detach device
   5.3. Map region
   5.4. Unmap region

### 3.3.1. 概述

requests 是 guest 往 request virtqueue 中添加的一堆小的 buffers. guest可以在 queue 中添加一批 requests, 并向设备发送通知(kick), 以便设备处理它们.

virtio-iommu 设备管理来自一个或多个 endpoint 的 DMA 操作. 它可以充当物理 IOMMU 的代理, 来管理分配给 guest 的设备; 也可以充当虚拟 IOMMU, 管理模拟设备和半虚设备.

驱动程序首先发现由 virtio-iommu 设备使用平台特定机制管理的 endpoints. 然后, 它会发送请求, 为这些 endpoints 创建 address space 和 GVA-> GPA 的映射.

一个操作流程的例子:

* `attach(address space, device), kick`: 创建一个 address space 并且将 attach 一个 device 给它. kick

> attach(endpoint = 0x8, domain = 1)

* `map(address space, virt, phys, size, flags)`: 给一段 GVA 和 GPA 创建一个 mapping 关系

> `map(domain = 1, virt_start = 0x1000, virt_end = 0x1fff, phys = 0xa000, flags = READ)`, Endpoint 0x8(假设对应的 PCI BDF 是 00:01.0), 现在能够**读** `0x1000 ~ 0x1fff` 范围. 这些会被 IOMMU 翻译成 系统物理地址(HPA?)

* map, map, map, kick
* ...在这里, guest 中设备可以执行 DMA 操作访问新映射的内存
* `unmap(address space, virt, size)`: unmap, 然后再kick

> `unmap(domain = 1, virt_start = 0x1000, virt_end = 0x1fff)`, endpoint 0x8 访问 `0x1000 ~ 0x1fff` 范围都会被拒绝.

* `detach(address space, device)`, kick

> detach(endpoint = 0x8, domain = 1)

以下描述尝试使用与其他 virtio 设备相同的格式. 我们不会详细了解 virtio 传输(transport), 请参阅 `[VIRTIO-v1.0]` 了解更多信息.

> [VIRTIO-v1.0] Virtual I/O Device (VIRTIO) Version 1.0.  03 December 2013. Committee Specification Draft 01 / Public Review Draft 01. http://docs.oasis-open.org/virtio/virtio/v1.0/csprd01/virtio-v1.0-csprd01.html

一个快速提醒(reminder), Virtio(1.0)运输可以用下面流程来描述:

```
                             HOST  :  GUEST
                     (3)           :
                    .----- [available ring] <-----. (2)
                   /               :               \
                  v   (4)          :          (1)   \
            [device] <--- [descriptor table] <---- [driver]
                  \                :                 ^
                   \               :                /
                (5) '-------> [used ring] ---------'
                                   :            (6)
                                   :
```

(1) driver 有一堆带有效载荷(payload)的 buffers 要通过 virtio 来发送. 一个 buffer 的 address 和 size 是一个 descriptor. 它会写 N 个 描述符(descriptors)来描述 N 个 sub-buffers, 并且将它们链接起来(形成描述符表), 第一个描述符(descriptor)就是这个链(chain)的头部(head).

(2) driver 将 head index 入队 "available ring".

(3) driver 通知设备. 由于 virtio-iommu 使用 MMIO, 通知是通过写消息给 doorbell 地址完成的. KVM 将其捕获并这个通知转发给 virtio 设备. 设备从 "available ring" 中出队 head index(头部索引).

(4) 设备读取链(chain)上的所有描述符, 处理 payload

(5) 设备将 head index 写入"used ring", 并且通过注入中断方式通知 guest

(6) driver 从 "used ring" 中 pop 这个 head, 然后选择性看是否读取 device 更新的 buffers.

### 3.3.2. 功能位

VIRTIO_IOMMU_F_INPUT_RANGE (0)

可用的虚拟地址范围在 input_range 中描述

VIRTIO_IOMMU_F_IOASID_BITS (1)

支持的 address space 数目在 ioasid_bits 中描述

VIRTIO_IOMMU_F_MAP_UNMAP (2)

map 和 unmap 请求是可用的. 这是为了让设备或驱动程序仅在我们引入该功能后实现页面表共享. 设备只能选择 F_MAP_UNMAP 或 F_PT_SHARING 之一. 目前, 必须始终设置此位.

VIRTIO_IOMMU_F_BYPASS (3)

当没有被 attach 到一个 address space时, IOMMU 管理的 device 能够访问虚拟机物理地址空间(GPA).

### 3.3.3. viommu 设备配置信息

```cpp
struct virtio_iommu_config {
     u64 page_size_mask;
     struct virtio_iommu_range {
          u64 start;
          u64 end;
     } input_range;
     u8 ioasid_bits;
};
```

### 3.3.4. 设备初始化

当 device 被 reset, endpoints 不会被 attach 到任何 address space.

1. 设置配置信息结构中 page_size_mask 包含了可以 map 的所有页面大小的 bitmap. 最低有效位集定义了 IOMMU map 的页面粒度. mask 中的其他位是描述 IOMMU 可以合并为单个映射(页面块)的页面大小的提示.

IOMMU 支持的最小页面粒度没有下限. 如果设备通告它(`page_size_mask[0]=1`), 驱动程序一次 map 一个字节是合法的.

page_size_mask 必须至少有一个 bit 设置

2. 如果有 VIRTIO_IOMMU_F_IOASID_BITS 功能, 则 ioasid_bits 包含 I/O Address space ID(map/unmap请求中使用的标识符)中支持的数目. 值等于 0 也是有效的, 仅仅表示支持单个地址空间(`2^0`? ).

如果没有 VIRTIO_IOMMU_F_IOASID_BITS 功能, address space ID 最多有 32 位(也就是说任何 address space ID 都是有效的).

3. 如果协商了 VIRTIO_IOMMU_F_INPUT_RANGE 功能, 则设置配置信息结构中 input_range 包含 IOMMU 能够 translate 的虚拟地址范围. 任何访问此范围之外的虚拟地址的映射请求都将失败.

如果不协商该功能, 虚拟映射将跨越整个 64 位地址空间(start = 0, end = 0xffffffffffffffff)

4. 如果协商了 VIRTIO_IOMMU_F_BYPASS 功能, 所有 unattached 设备发出的内存访问也会被 IOMMU 允许且被 IOMMU 用特定方法进行 translate. 如果没有这个功能, 任何 unattached 设备的内存访问都会失败.

> 允许设备绕过 iommu 的管理的意思, 所以这个功能支持的话, 没有被 attach 的设备也可以访问 guest physical address.

而如果通过 bypass 模式 attach 一个 device 到一个新的 address space, 那么这个设备的所有内存访问都会失败, 因为这时候 address space 还没有包含任何 mapping.

### 3.3.5. 设备操作

驱动程序在 request virtqueue (0) 上发送 requests, 通知设备并等待设备在 used ring 中返回具有状态的 request.

> 遵循 virtio transport 流程

所有请求被分成两部分: 一个 device-readable, 一个device-writeable.

因此, **每个请求**必须至少用**两个描述符**(descriptor)来描述, 如下图所示.

```
	31                       7      0
	+--------------------------------+ <------- RO descriptor
	|      0 (reserved)     |  type  |
	+--------------------------------+
	|                                |
	|            payload             |
	|                                | <------- WO descriptor
	+--------------------------------+
	|      0 (reserved)     | status |
	+--------------------------------+

	struct virtio_iommu_req_head {
		u8	type;
		u8	reserved[3];
	};

	struct virtio_iommu_req_tail {
		u8	status;
		u8	reserved[3];
	};
```

(关于格式选择的注意事项: 此格式强制将有效载荷(payload)拆分为两个 - 一个 read-only 的缓冲区, 一个 write-only. 这对于我们的目的来说是必要且充分的, 并且不会关闭未来扩展更复杂请求的大门, 例如夹在两个 RO 之间的 WO 字段. 由于 Virtio 1.0 ring 要求, 需要用两个描述链来描述一个这样的请求, 这些描述符可能更复杂, 无法高效实现, 但仍有可能. 设备和驱动程序都必须假定请求是分段的. )

type 字段可能是:

```
VIRTIO_IOMMU_T_ATTACH			1
VIRTIO_IOMMU_T_DETACH			2
VIRTIO_IOMMU_T_MAP			3
VIRTIO_IOMMU_T_UNMAP			4
```

下面定义了一些通用 status code. 对于无效请求, driver 不能假定返回一个特定的code. 除了总是意味着 "success" 的 0 之外, 其他返回值有助于故障排除.

```
VIRTIO_IOMMU_S_OK			0
 All good! Carry on.

VIRTIO_IOMMU_S_IOERR			1
 Virtio communication error

VIRTIO_IOMMU_S_UNSUPP			2
 Unsupported request

VIRTIO_IOMMU_S_DEVERR			3
 Internal device error

VIRTIO_IOMMU_S_INVAL			4
 Invalid parameters

VIRTIO_IOMMU_S_RANGE			5
 Out-of-range parameters

VIRTIO_IOMMU_S_NOENT			6
 Entry not found

VIRTIO_IOMMU_S_FAULT			7
 Bad address
```

#### 3.3.5.1. attach device

```cpp
struct virtio_iommu_req_attach {
	le32	address_space;
	le32	device;
	le32	flags/reserved;
};
```

将设备 attach 到 address space. 对 guest 来讲, 每个 "address_space" 都是一个唯一的标识符 ('address_space' is an identifier unique to the guest). 如果 IOMMU 设备中不存在这个 address space, 则创建一个.

> 也就是说, 一个 guest 中的 address_space 是不同的, 类似于 domain 的概念.

对于 IOMMU 来说, 每个 "device" 都是一个唯一的标识符('device' is an identifier unique to the IOMMU). host 在 guest boot 期间向 guest 传达(communicate)了唯一的 device ID. 用于传达此 ID 的方法不属于此规范的范围, 但必须适用以下规则:

* 从 IOMMU 的角度来看, device ID 是唯一的. DMA transaction (DMA 事务) 不是由同一 IOMMU translate 的多个设备可能具有相同的设备 ID(因为 iommu 不是同一个). DMA transaction 可能由同一 IOMMU 翻译的设备必须具有不同的 device ID.

* 有时 host 无法完全隔离两个设备. 例如, 在传统的 PCI 总线上, 设备可以窥探(snoop)来自其邻居(neighbour)的 DMA transaction(DMA 事务). 在这种情况下, 主机必须向 guest 传达它不能将这些设备彼此隔离. 用于传达这个的方法不在本规范的范围. IOMMU driver 必须确保无法被 host 隔离的设备具有相同的 address space(也就是多个device不能隔离则必须被同一个 iommu 管理).

多个设备可以添加到相同的 address space.一个设备不能被 attach 到多个 address space(即使用 map/unmap 接口). 对于 SVM, 请参阅 page table 和 context table 共享建议.

如果设备已经 attach 到另一个 address space "old", 则它将被从 "old" address space 分离并 attach 到新地址空间. 在此请求完成后, 设备无法访问旧地址空间的映射.

设备要么返回 VIRTIO_IOMMU_S_OK, 要么返回错误状态. 我们建议以下错误状态, 这将有助于调试驱动程序.

NOENT: 未找到设备.

RANGE: address space 超出了 ioasid_bits 允许的范围.

#### 3.3.5.2. detach device

```cpp
struct virtio_iommu_req_detach {
	le32	device;
	le32	flags/reserved;
};
```

从 address space 中 detach device. 当此请求完成时, 设备就不能再访问该 address space 中的任何映射. 如果 device 没有被 attach 到任何地址空间, 则请求将成功返回.

在所有设备从一个地址空间 detach 后, 驱动程序可以将其 address space ID 重用于另一个地址空间.

NOENT: 未找到设备.

INVAL: 设备未连接到任何地址空间.

#### 3.3.5.3. map region

```cpp
struct virtio_iommu_req_map {
	le32	address_space;
	le64	phys_addr;
	le64	virt_addr;
	le64	size;
	le32	flags;
};

VIRTIO_IOMMU_MAP_F_READ		0x1
VIRTIO_IOMMU_MAP_F_WRITE	0x2
VIRTIO_IOMMU_MAP_F_EXEC		0x4
```

将一系列连续的虚拟地址映射到一系列连续的物理地址. 大小必须始终是初始化期间协商的页面粒度的倍数. phys_addr 和 virt_addr 必须在页面粒度上对齐. address space 必须是用 VIRTIO_IOMMU_T_ATTACH 创建的.

(virt_addr, size) 所定义的范围必须在 input_range 规定的范围内. (phys_addr, size) 定义的范围必须在 guest 物理地址空间内. 这包括了上下限制, 以及任何 carving 的 guest physical address 供 host 使用(例如 MSI doorbell). 主机使用本规范范围之外的固件机制设置了 guest 物理边界.

(请注意, 此格式会阻止在单个请求(0x0 - 0xfff....ff) -> (0x0 - 0xfff...ff), 因为它将得到一个 零大小. 希望允许 VIRTIO_IOMMU_F_BYPASS 消除发出此类请求的需要. 也不太可能符合前一段的物理范围限制)

(另一个注意事项是 flags: 物理 IOMMU 不可能支持所有可能的 flag 组合. 例如, (W & !R) 或 (E & W) 可能无效. 我还没有花时间设计一个聪明的方法来宣传支持和隐含(例如 "W 暗示 R")标志或组合, 但我至少可以尝试研究共同的模型. 请记住, 我们可能很快就会想要添加更多的标志, 如 privileged, device, transient, shared等, 无论这些将意味着什么)

只有 VIRTIO_IOMMU_F_MAP_UNMAP 协商成功这个请求才是可用的

INVAL: 无效 flags.

RANGE: virt_addr, phys_addr 或 range 不在协商期间规定的范围内. 比如, 没有基于页粒度对齐.

NOENT: address space 不存在

#### 3.3.5.4. unmap region

```cpp
struct virtio_iommu_req_unmap {
	le32	address_space;
	le64	virt_addr;
	le64	size;
	le32	reserved;
};
```

unmap 一段用 VIRTIO_IOMMU_T_MAP 映射的地址范围. 这个 range 由virt_addr 和 size 定义, 必须完全覆盖通过 MAP 请求创建的一个或多个连续映射. 这个 range 覆盖的所有映射都已删除. 驱动程序不应发送覆盖未映射区域的请求.

通过单个 MAP 请求, 我们定义了一个 mapping 作为一片虚拟区域. virt_addr 应与现有映射的开始地址完全匹配. range 的 end(virt_addr + size - 1)应与现有映射的 end 完全匹配. 设备必须拒绝仅作用于部分映射区域的所有请求. 如果请求的范围溢出映射区域之外, 则设备的行为未定义.

规则定义如下:

```
	map(0, 10)
	unmap(0, 10) -> allowed

	map(0, 5)
	map(5, 5)
	unmap(0, 10) -> allowed

	map(0, 10)
	unmap(0, 5) -> forbidden

	map(0, 10)
	unmap(0, 15) -> undefined

	map(0, 5)
	map(10, 5)
	unmap(0, 15) -> undefined
```

(注意: 这里 unmap 的语义与 VFIO 的 type1 v2 IOMMU API 兼容. 这样, 充当 guest 和 VFIO 之间调解的设备就不必保留内部mapping tree. 它们比 VFIO 更严格一些, 因为它们不允许 unmap 到映射区域之外. 溢出(spilling)目前是"undefined", 因为它在大多数情况下应该有效, 但我不知道是否值得在不只是将请求传输到 VFIO 的设备中增加复杂性. 拆分映射是不允许的, 但请参阅 3/3 中的轻松建议, 以获得更宽松的语义)

此请求仅在 VIRTIO_IOMMU_F_MAP_UNMAP 已协商后提供.

NOENT: address space 不存在

FAULT: mapping 不存在

RANGE: 请求将拆分一个mapping

## 3.4. 未来要进行的工作

> virtio-iommu: future work



# 4. Linux driver

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

virtio IOMMU 是一个半虚设备, 可以通过 virtio-mmio transport 发送 IOMMU 请求, 比如 map/unmap. 这样就不用模拟 page fault 了.

这个 driver 会实现上面讲到的 virtio-iommu 最初方案. 它会处理 attach, detach, map 和 unmap 请求.

大部分代码是在创建请求并通过 virtio 发送它们. 实现 IOMMU API 是比较简单的, 因为 virtio-iommu 的 MAP/UNMAP 接口几乎相同. 我放到了一个自定义的 map_sg() 函数中. 核心函数将发送一系列的 map 请求, 并且等待每个请求的返回. 这个优化避免在每个 map 后 yield to host, 而是在 virtio ring 中准备一批请求, 并 kick host 一次.

It must be applied on top of the probe deferral work for IOMMU, currently under discussion. 这允许早期驱动程序检测和设备探测分割开: 早期解析 device tree 或 ACPI 从而发现 IOMMU 负责的设备, 但是 IOMMU 本身需要等核心 virtio 模块加载后才能被探测.

目前, 启用 DEBUG 使得非常冗长, 但在下一个版本中应该会更 calmer.

```diff
---
 drivers/iommu/Kconfig             |  11 +
 drivers/iommu/Makefile            |   1 +
 drivers/iommu/virtio-iommu.c      | 980 ++++++++++++++++++++++++++++++++++++++
 include/uapi/linux/Kbuild         |   1 +
 include/uapi/linux/virtio_ids.h   |   1 +
 include/uapi/linux/virtio_iommu.h | 142 ++++++
 6 files changed, 1136 insertions(+)
 create mode 100644 drivers/iommu/virtio-iommu.c
 create mode 100644 include/uapi/linux/virtio_iommu.h
```

* `drivers/iommu/Kconfig`, 增加了一个内核编译选项, guest kernel 启用
* `drivers/iommu/Makefile`, 使内核编译时增加一个 `.o` 文件
* `drivers/iommu/virtio-iommu.c`, 核心实现文件
* `include/uapi/linux/Kbuild`, linux-header 增加一个头文件
* `include/uapi/linux/virtio_ids.h`, 增加一个 virtio 类型
* `include/uapi/linux/virtio_iommu.h`, 头文件

几个核心结构体

```diff
diff --git a/drivers/iommu/virtio-iommu.c b/drivers/iommu/virtio-iommu.c
new file mode 100644
index 000000000000..1cf4f57b7817
--- /dev/null
+++ b/drivers/iommu/virtio-iommu.c
@@ -0,0 +1,980 @@
+#include <uapi/linux/virtio_iommu.h>
+
+struct viommu_dev {
+	struct iommu_device		iommu;
+	struct device			*dev;
+	struct virtio_device		*vdev;
+
+	struct virtqueue		*vq;
+	struct list_head		pending_requests;
+	/* Serialize anything touching the vq and the request list */
+	spinlock_t			vq_lock;
+
+	struct list_head		list;
+
+	/* Device configuration */
+	u64				pgsize_bitmap;
+	u64				aperture_start;
+	u64				aperture_end;
+};
+
+struct viommu_mapping {
+	phys_addr_t			paddr;
+	struct interval_tree_node	iova;
+};
+
+struct viommu_domain {
+	struct iommu_domain		domain;
+	struct viommu_dev		*viommu;
+	struct mutex			mutex;
+	u64				id;
+
+	spinlock_t			mappings_lock;
+	struct rb_root			mappings;
+
+	/* Number of devices attached to this domain */
+	unsigned long			attached;
+};
+
+struct viommu_endpoint {
+	struct viommu_dev		*viommu;
+	struct viommu_domain		*vdomain;
+};
+
+struct viommu_request {
+	struct scatterlist		head;
+	struct scatterlist		tail;
+
+	int				written;
+	struct list_head		list;
+};
+
+/* TODO: use an IDA */
+static atomic64_t viommu_domain_ids_gen;
+
+#define to_viommu_domain(domain) container_of(domain, struct viommu_domain, domain)
+
```

* `struct viommu_dev`: viommu 设备.
* `struct viommu_mapping`: 一个mapping, iova -> gpa.
* `struct viommu_domain`: 一个 address space(一个 group 对应一个). domain 指向 VM domain(per VM); viommu 指向 viommu 设备; mappings 是一棵 rb tree, 每个 node 是 viommu_mapping 中的 iova
* `struct viommu_endpoint`: 由 viommu 管理的一个设备. `viommu` 指向所属的 viommu 设备; `vdomain` 指向所 attached 的 address space
* `struct viommu_request`: viommu 请求.

```diff
diff --git a/include/uapi/linux/virtio_iommu.h b/include/uapi/linux/virtio_iommu.h
new file mode 100644
index 000000000000..ec74c9a727d4
--- /dev/null
+++ b/include/uapi/linux/virtio_iommu.h
+#ifndef _UAPI_LINUX_VIRTIO_IOMMU_H
+#define _UAPI_LINUX_VIRTIO_IOMMU_H

+__packed
+struct virtio_iommu_config {
+	/* Supported page sizes */
+	__u64					page_sizes;
+	struct virtio_iommu_range {
+		__u64				start;
+		__u64				end;
+	} input_range;
+	__u8 					ioasid_bits;
+};
+
+__packed
+struct virtio_iommu_req_head {
+	__u8					type;
+	__u8					reserved[3];
+};
+
+__packed
+struct virtio_iommu_req_tail {
+	__u8					status;
+	__u8					reserved[3];
+};
+
+__packed
+struct virtio_iommu_req_attach {
+	struct virtio_iommu_req_head		head;
+
+	__le32					address_space;
+	__le32					device;
+	__le32					reserved;
+
+	struct virtio_iommu_req_tail		tail;
+};
+
......
+
+union virtio_iommu_req {
+	struct virtio_iommu_req_head		head;
+
+	struct virtio_iommu_req_attach		attach;
+	struct virtio_iommu_req_detach		detach;
+	struct virtio_iommu_req_map		map;
+	struct virtio_iommu_req_unmap		unmap;
+};
+
+#endif
```

* `struct virtio_iommu_config`: viommu 配置信息. page_sizes 表示 viommu 支持 map 的页面大小; input_range 表示 viommu 能够 translate 的虚拟地址范围; ioasid_bits 表示支持的 address space 的数目.
* `struct virtio_iommu_req_XXX`: 某种类型的请求. 按照前面说的格式组织.

virtio-iommu driver 模块初始化相关代码

```diff
diff --git a/drivers/iommu/virtio-iommu.c b/drivers/iommu/virtio-iommu.c
new file mode 100644
index 000000000000..1cf4f57b7817
--- /dev/null
+++ b/drivers/iommu/virtio-iommu.c
@@ -0,0 +1,980 @@
+static struct virtio_driver virtio_iommu_drv = {
+	.driver.name		= KBUILD_MODNAME,
+	.driver.owner		= THIS_MODULE,
+	.id_table		= id_table,
+	.feature_table		= features,
+	.feature_table_size	= ARRAY_SIZE(features),
+	.probe			= viommu_probe,
+	.remove			= viommu_remove,
+	.config_changed		= viommu_config_changed,
+};
+
+module_virtio_driver(virtio_iommu_drv);
+
+IOMMU_OF_DECLARE(viommu, "virtio,mmio", NULL);
+
+MODULE_DESCRIPTION("virtio-iommu driver");
+MODULE_AUTHOR("Jean-Philippe Brucker <jean-philippe.brucker@arm.com>");
+MODULE_LICENSE("GPL v2");
```

利用了原本的virtio框架. 重点在两个: `viommu_probe` 和 `viommu_remove`.

当注册一个 viommu 设备(也是一个 virtio 设备), 调用 `viommu_probe()`

1. `struct viommu_dev *viommu = kzalloc(sizeof(*viommu), GFP_KERNEL);`, 生成 viommu 设备对象
2. `viommu_init_vq(viommu);`, 查找 virt queue, 应该是 virtio 框架给每个 virtio device 都实现了 vq, 确保存在. 这里的回调函数也是 NULL.
3. `virtio_cread(vdev, struct virtio_iommu_config, page_sizes, &viommu->pgsize_bitmap);`, 获取 page_sizes 配置
4. `virtio_cread_feature()`, 获取 input_range 的 start 和 end
5. `iommu_device_sysfs_add()`, 初始化 `viommu->iommu` (`struct iommu_device`), 并添加到 sysfs
6. `iommu_device_set_ops()`, 设置了 `viommu->iommu` (`struct iommu_device`) 的ops, viommu_ops.
7. `iommu_device_set_fwnode()`,
8. `iommu_device_register()`, 注册 `viommu->iommu` 到全局 `iommu_device_list` 链表
9. `bus_set_iommu(&pci_bus_type, &viommu_ops)`, 设置 pci bus, 下面细讲
10. `bus_set_iommu(&platform_bus_type, &viommu_ops);`, 设置 platform bus, 下面细讲

```diff
diff --git a/drivers/iommu/virtio-iommu.c b/drivers/iommu/virtio-iommu.c
new file mode 100644
index 000000000000..1cf4f57b7817
--- /dev/null
+++ b/drivers/iommu/virtio-iommu.c
@@ -0,0 +1,980 @@
+static struct iommu_ops viommu_ops = {
+	.capable		= viommu_capable,
+	.domain_alloc		= viommu_domain_alloc,
+	.domain_free		= viommu_domain_free,
+	.attach_dev		= viommu_attach_dev,
+	.map			= viommu_map,
+	.unmap			= viommu_unmap,
+	.map_sg			= viommu_map_sg,
+	.iova_to_phys		= viommu_iova_to_phys,
+	.add_device		= viommu_add_device,
+	.remove_device		= viommu_remove_device,
+	.device_group		= viommu_device_group,
+	.of_xlate		= viommu_of_xlate,
+	.get_resv_regions	= viommu_get_resv_regions,
+	.put_resv_regions	= viommu_put_resv_regions,
+};
```

```cpp
bus_set_iommu()
 ├─ bus->iommu_ops = ops; 设置 bus 的 iommu ops
 └─ iommu_bus_init(bus, ops); iommu 的总线相关初始化.
   ├─ nb->notifier_call = iommu_bus_notifier;
   ├─ bus_register_notifier(bus, nb); 注册 bus notifier, 回调是 `iommu_bus_notifier()`
   └─ bus_for_each_dev(bus, NULL, &group_list, add_iommu_group); 遍历总线下所有设备, 给每个设备调用 `add_iommu_group()`, 将设备添加到 iommu group 中
      └─ iommu_ops->add_device(struct device dev);, 添加设备, 调用了 `viommu_add_device()`
         ├─ struct viommu_endpoint *vdev = kzalloc(sizeof(*vdev), GFP_KERNEL); 分配了 viommu_endpoint 并初始化
         ├─ dev->iommu->iommu_dev = iommu_dev; 设置 device 的 iommu device
         └─ group = iommu_group_get_for_dev(dev); 最后一步会创建一个 domain 并 attach 这个 device
            ├─ 查找 group, 没有则创建一个 iommu group, `dev->bus->iommu_ops->device_group(dev)`, 会调用 `viommu_device_group()` 分配一个 group
            │  └─ pci_device_group(dev); / generic_device_group(dev);
            ├─ struct iommu_domain *dom = __iommu_domain_alloc(dev->bus, iommu_def_domain_type); 给每个 iommu group 分配 IOMMU_DOMAIN_DMA 类型的 domain
	    │  ├─ struct iommu_domain *domain = bus->iommu_ops->domain_alloc(type); 调用 viommu_domain_alloc, 主要是分配空间并初始化
            │  │  ├─ struct viommu_domain *vdomain = kzalloc(sizeof(struct viommu_domain), GFP_KERNEL); 生成新的 vdomain
            │  │  ├─ vdomain->id = atomic64_inc_return_relaxed(&viommu_domain_ids_gen); 分配新 id
            │  │  ├─ vdomain->mappings = RB_ROOT; 每个 vdomain 的所有 mappings 构成 rb tree
	    │  ├─ domain->ops  = bus->iommu_ops;
	    │  ├─ domain->type = type;
	    │  └─ domain->pgsize_bitmap  = bus->iommu_ops->pgsize_bitmap;
	    ├─ group->default_domain = dom;
	    ├─ group->domain = dom;
            └─ iommu_group_add_device(group, dev); 将这个 device 添加到这个 iommu group
	       ├─ sysfs_create_link(&dev->kobj, &group->kobj, "iommu_group"); 创建软链接(`/sys/devices/pci总线ID/设备号/iommu_group -> `/sys/kernel/iommu_groups/xx`)
	       ├─ sysfs_create_link_nowarn(group->devices_kobj, &dev->kobj, device->name); 创建软链接(`/sys/kernel/iommu_groups/xx/devices/设备PCI号` -> `/sys/devices/pci总线ID/设备号`
	       ├─ dev->iommu_group = group; device 结构中包含的 iommu_group 对象会指向其所在的 group
	       ├─ iommu_group_create_direct_mappings(group), 给设备做DMA映射. 将设备对应的虚拟机地址空间段映射到物理地址空间
	       │  ├─ pg_size = 1UL << __ffs(domain->pgsize_bitmap); domain page size
	       │  ├─ iommu_get_resv_regions(dev, &mappings);, 获取设备的 mappings(iova), 调用 `viommu_ops.viommu_get_resv_regions`
	       │  │  ├─ struct iommu_resv_region *msi = iommu_alloc_resv_region(MSI_IOVA_BASE, MSI_IOVA_LENGTH, prot, IOMMU_RESV_MSI); 初始化这个一个 region 结构体, arm 上面需要这个 region 用于 map doorbell
      	       │  └─ list_for_each_entry(entry, &mappings, list), 遍历设备映射的地址段
	       │     ├─ start/end = ALIGN(entry->start/end, pg_size);, 根据 page size 对齐
	       │     └─ for (addr = start; addr < end; addr += pg_size), 每个 domain page 逐个 map
	       │        ├─ phys_addr = iommu_iova_to_phys(domain, addr), 看是否已经有了 iova -> pa 的 map, 如果得到物理地址, 说明已经有了 map, 则继续处理下一个 page. 会调用 viommu_iova_to_phy
	       │        │  ├─ interval_tree_iter_first(&viommu_domain->mappings, iova, iova); 在 vdomain rb tree 中查找 iova 所在的 node
	       │        │  ├─ struct viommu_mapping *mapping = container_of(node, struct viommu_mapping, iova); 得到对应的 vmapping
	       │        │  └─ paddr = mapping->paddr + (iova - mapping->iova.start);
	       │        └─ iommu_map(domain, addr, addr, pg_size, entry->prot), 没有 map 的则需要 map 下, 将每段虚拟地址空间都映射到相应的物理内存页上(va->pa), iova = paddr = addr, 所以初始化的 msi iova = pa
	       │           └─ domain->ops->map(domain, iova, paddr, pgsize, prot); 根据 iommu pgsize(pgsize), 逐个 page 进行map(当然这里是一个 page), 调用 viommu_map
	       │              ├─ struct viommu_domain *vdomain = to_viommu_domain(domain); 获取 vdomain
	       │              ├─ struct virtio_iommu_req_map req; 构建 map request 并初始化
	       │              ├─ address_space	= cpu_to_le32(vdomain->id); group 初始化时候分配的
	       │              ├─ viommu_tlb_map(vdomain, iova, paddr, size); (iova, size) 和 paddr 的 mapping 关系缓存起来
	       │              │  ├─ struct viommu_mapping *mapping = kzalloc(sizeof(*mapping), GFP_ATOMIC);
	       │              │  ├─ mapping->paddr = paddr; mapping->iova.start = iova; mapping->iova.last = iova + size - 1;
	       │              │  └─ interval_tree_insert(&mapping->iova, &vdomain->mappings); 插入树
	       │              └─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 map request, 忙等返回
	       ├─ list_add_tail(&device->list, &group->devices); 将 device 添加到 group 的 list 中
	       ├─ __iommu_attach_device(group->domain, dev); 调用 domain->ops->attach_dev(domain, dev), viommu_attach_dev
	       │  ├─ struct virtio_iommu_req_attach req; 创建 attach 请求
	       │  └─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 attach request, 忙等返回
	       └─ blocking_notifier_call_chain(&group->notifier, IOMMU_GROUP_NOTIFY_ADD_DEVICE, dev); group notifier
```

初始化 virtio-iommu 中会涉及到两个 command, map 和 attach, backend 实现可以看 kvm tool 部分

疑问 1: 会先有 map request, 再 attach request?

??

疑问 2: `struct iommu_ops viommu_ops` 中没有 `detach_dev`, 也就没有 detach request, why?

 `iommu_detach_device()` -> `__iommu_detach_group` -> `iommu_group_do_attach_device()`

detach 的场景:

* device delete: unhot-plug
* group delete:
* vfio release domain: 走下面逻辑

首先, 每个 device 肯定属于某个 group, 而 group 有两个属性, default_domain 和 domain.

其次, detach 操作其实都是通过 re-attach 到 default domain 实现的. 而 attach request 中会将原有 domain 给 detach 掉

最后, group 可能没有任何 device, 但是本身是不会删除的, 所以不需要一个因为从 group 删除而发出的 detach request.


Discussion 1: Same physical address is mapped with two different virtual address

取决于是哪个驱动调用了 viommu. 任何设备驱动可以调用 DMA API, 进而调用了 iommu_map. 同一个 address space 中, 多个 IOVA 指向同一个 PA 是允许的.

https://lore.kernel.org/all/c19161b2-b32f-4039-67a2-633ee57bcd07@arm.com/

```
 virtnet_open
 try_fill_recv
 add_recvbuf_mergeable
 virtqueue_add_inbuf_ctx
 vring_map_one_sg
 dma_map_page
 __iommu_dma_map
```

# 5. KVM tool

[RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/)

实现 virtio-iommu 设备并转换来自 vfio 和 virtio 设备的 DMA 流量. Virtio 需要一些 rework 来支持以页面粒度对 vring 和缓冲区进行分散-聚集访问. patch 3 实现了实际的 virtio-iommu 设备.

添加了 `--viommu` 参数可以给所有 virtio 和 vfio 设备添加一个 viommu

1. virtio: synchronize virtio-iommu headers with Linux
2. FDT: (re)introduce a dynamic phandle allocator
3. virtio: add virtio-iommu
4. Add a simple IOMMU
5. iommu: describe IOMMU topology in device-trees
6. irq: register MSI doorbell addresses
7. virtio: factor virtqueue initialization
8. virtio: add vIOMMU instance for virtio devices
9. virtio: access vring and buffers through IOMMU mappings
10. virtio-pci: translate MSIs with the virtual IOMMU
11. virtio: set VIRTIO_F_IOMMU_PLATFORM when necessary
12. vfio: add support for virtual IOMMU
13. virtio-iommu: debug via IPC
14. virtio-iommu: implement basic debug commands
15. virtio: use virtio-iommu when available

## 5.1. 实现 virtio-iommu

**patch 1**, virtio: synchronize virtio-iommu headers with Linux

从 Linux 同步了 virtio-iommu 相关的头文件

**patch 2**, FDT: (re)introduce a dynamic phandle allocator



**patch 3**, virtio: add virtio-iommu

实现一个简单的 viommu 来处理虚拟机中的设备 address space.

四种操作:

* attach/detach: 虚拟机创建一个 address space, 使用一个唯一的 IOASID 来标识, 并且 attach 这个设备.
* map/unmap: 虚拟机在一个 address space 中创建一个 GVA-> GPA 映射. attach 到这个 address space 的设备能够访问这个 GVA.

每个子系统可以通过调用 register/unregister 来注册自己的 IOMMU. 为每个 IOMMU 分配了一个独有的 device-tree phandle. IOMMU 通过 virtqueue 接收 driver 的命令, 并为**每个设备**提供一系列回调函数, 允许为 pass-through 设备和 emulated 设备实行不同的 map/unmap 操作.

请注意, 一个 guest 对应一个 vIOMMU 就足够了, 这个的多个 viommu 模型只是在这里进行实验, 从而允许不同的子系统提供不同的 vIOMMU 功能.



给 device 增加 `iommu_ops`, 从而每个设备都能有自己的 iommu 回调函数.

```diff
--- a/include/kvm/devices.h
+++ b/include/kvm/devices.h
@@ -11,11 +11,15 @@ enum device_bus_type {
 	DEVICE_BUS_MAX,
 };

+struct iommu_ops;
+
 struct device_header {
 	enum device_bus_type	bus_type;
 	void			*data;
 	int			dev_num;
 	struct rb_node		node;
+	struct iommu_ops	*iommu_ops;
+	void			*iommu_data;
 };

 int device__register(struct device_header *dev);
```

```cpp
static int viommu_handle_attach(struct viommu_dev *viommu,
				struct virtio_iommu_req_attach *attach)
{
    // 从 request 中获取 deviceid 和 ioasid
    u32 device_id	= le32_to_cpu(attach->device);
    u32 ioasid	= le32_to_cpu(attach->address_space);
    struct device_header *device = iommu_get_device(device_id);

    // 如果 ioas 不存在则创建一个
    ioas = viommu_find_ioas(viommu, ioasid);
    if (!ioas) ioas = viommu_alloc_ioas(viommu, device, ioasid);

    // 如果设备之前已经关联了 ioas, 则从原有 detach
    if (vdev->ioas) ret = viommu_detach_device(viommu, vdev);

    // 每种设备自定义的 attach 方法
    ret = device->iommu_ops->attach(ioas->priv, device, 0);

    // 将设备添加到 ioas 的链表中
    viommu_ioas_add_device(ioas, vdev);

    // ioas 没有设备则释放掉这个 ioas
    if (ret && ioas->nr_devices == 0) viommu_free_ioas(viommu, ioas);
}
```

```cpp
viommu_handle_attach(viommu, *req_attach)
 ├─ u32 device_id = le32_to_cpu(attach->device);
 ├─ u32 ioasid	= le32_to_cpu(attach->address_space);
 ├─ viommu_alloc_ioas(viommu, device, ioasid);
 ├─ viommu_detach_device(viommu, vdev);
 ├─ device->iommu_ops->attach(ioas->priv, device, 0);
 └─ viommu_ioas_add_device(ioas, vdev);
```

`viommu_command` -> `viommu_dispatch_commands` -> `viommu_handle_attach(viommu, &req->attach);`

概述:  生成 viommu_ioas, 并加入到 viommu device 的 rb tree 中; 生成 viommu_endpoint, 并将 endpoint 添加到 ioas 链表; 初始化 vfio container, 并和 ioas 关联起来

```cpp
viommu_handle_attach(struct viommu_dev *viommu, struct virtio_iommu_req_attach *attach)
 ├─ u32 device_id = le32_to_cpu(attach->device); 从 request 中获取 deviceid
 ├─ u32 ioasid	= le32_to_cpu(map->address_space); 解析 request, 获取 ioasid, 即上面的 vdomain->id, 每个 group 一个
 ├─ struct device_header *device = iommu_get_device(device_id); 根据 device_id 获取 device
 │  ├─ enum device_bus_type bus = ((device_id) / BUS_SIZE)
 │  ├─ u32 dev_num = ((device_id) % BUS_SIZE)
 │  └─ return device__find_dev(bus, dev_num);
 ├─ struct viommu_endpoint *vdev = viommu_alloc_device(device); 获取 endpoint
 ├─ viommu_alloc_device(device); 没有 endpoint, 那就分配一个
 ├─ struct viommu_ioas *ioas = viommu_find_ioas(viommu, ioasid); 获取 address space
 │  └─ struct rb_node *node = viommu->address_spaces.rb_node; 从 rb tree 中查找 node
 ├─ ioas = viommu_alloc_ioas(viommu, device, ioasid); ioas 不存在, 那就创建一个(per group), 并加入 rb tree
 │  ├─ struct viommu_ioas *new_ioas = calloc(1, sizeof(*new_ioas));
 │  ├─ INIT_LIST_HEAD(&new_ioas->devices);
 │  ├─ new_ioas->id = ioasid;
 │  ├─ new_ioas->ops = device->iommu_ops;
 │  ├─ new_ioas->priv = device->iommu_ops->alloc_address_space(device); 不同设备, 不同的 ops, 以 vfio 设备为例, 调用 vfio_viommu_alloc
 │  │  ├─ struct vfio_device *vdev = container_of(dev_hdr, struct vfio_device, dev_hdr);
 │  │  ├─ struct vfio_guest_container *container = vdev->group->container; 获取 group->container(per group)
 │  │  ├─ container->msi_doorbells = iommu_alloc_address_space(NULL); 主要是 msi doorbells 分配
 │  │  └─ return container; 会将 vfio container 返回, 作为 ioas 的 private 数据
 │  ├─ struct rb_node **node = &viommu->address_spaces.rb_node;
 │  ├─ rb_link_node(&new_ioas->node, parent, node); 插入 rb tree
 │  └─ rb_insert_color(&new_ioas->node, &viommu->address_spaces);
 ├─ viommu_detach_device(viommu, vdev); 从原有的 as 做 detach
 │  ├─ device->iommu_ops->detach(ioas->priv, device); 不同设备不同ops, 以 vfio 设备为例, 调用 vfio_viommu_detach
 │  │  └─ return 0; 什么都没做, 对应的 attach 没做什么
 │  ├─ viommu_ioas_del_device(ioas, vdev); 从 ioas 中删除 viommu_endpoint
 │  │  ├─ list_del(&vdev->list); 从 ioas->devices 链表删除
 │  │  ├─ ioas->nr_devices--;
 │  │  └─ vdev->ioas = NULL;
 │  └─ viommu_free_ioas(viommu, ioas); ioas->nr_devices 没有设备的话, 则删除 ioas(domain)
 │  │  ├─ ioas->ops->free_address_space(ioas->priv); 释放 as, 上面 alloc 的逆操作
 │  │  ├─ rb_erase(&ioas->node, &viommu->address_spaces);
 │  │  └─ free(ioas);
 ├─ device->iommu_ops->attach(ioas->priv, device, 0); 不同设备不同ops, 以 vfio 设备为例, 调用 vfio_viommu_attach
 │  └─ 一些判断, 其他没做什么事情, 对应的 detach 没做什么
 └─ viommu_ioas_add_device(ioas, vdev);
    ├─ list_add_tail(&vdev->list, &ioas->devices); 设备添加到 ioas->devices 链表中
    ├─ ioas->nr_devices++;
    └─ vdev->ioas = ioas;
```

`viommu_command` -> `viommu_dispatch_commands` -> `viommu_handle_map(viommu, &req->map);`

概述: 解析请求, 调用 MAP_DMA 类型的 ioctl (ioas 的 vfio container), GVA -> GPA

```cpp
viommu_handle_map(struct viommu_dev *viommu, struct virtio_iommu_req_map *map)
 ├─ u32 ioasid	= le32_to_cpu(map->address_space); 解析 request
 ├─ u64 virt_addr = le64_to_cpu(map->virt_addr);
 ├─ u64 phys_addr = le64_to_cpu(map->phys_addr);
 ├─ u64 size = le64_to_cpu(map->size);
 ├─ prot |= IOMMU_PROT_READ/IOMMU_PROT_WRITE/IOMMU_PROT_EXEC; map region 的属性
 ├─ struct viommu_ioas *ioas = viommu_find_ioas(viommu, ioasid); 获取 address space
 │  └─ struct rb_node *node = viommu->address_spaces.rb_node; 从 rb tree 中查找 node
 └─ ioas->ops->map(ioas->priv, virt_addr, phys_addr, size, prot); 不同设备不同ops, 以 vfio 设备为例, 调用 vfio_viommu_map
    ├─ struct vfio_guest_container *container = priv; 获取到 attach 阶段的 vfio container
    ├─ struct vfio_iommu_type1_dma_map map = { .iova = virt_addr, .size	= size, };
    ├─ map.vaddr = (u64)guest_flat_to_host(container->kvm, phys_addr); 获取 hva
    ├─ if (irq__addr_is_msi_doorbell(container->kvm, phys_addr)) iommu_map(container->msi_doorbells, virt_addr, phys_addr, size, prot); hva 不存在则需要 map msi doorbell 的 virt_addr -> phys_addr
    └─ return ioctl(container->fd, VFIO_IOMMU_MAP_DMA, &map); IOVA -> HPA?
```

```cpp
viommu_handle_map(viommu, *req_map)
 ├─ u32 ioasid	= le32_to_cpu(map->address_space);
 ├─ u64 virt_addr = le64_to_cpu(map->virt_addr);
 ├─ u64 phys_addr = le64_to_cpu(map->phys_addr);
 ├─ u64 size = le64_to_cpu(map->size);
 ├─ prot |= IOMMU_PROT_READ/IOMMU_PROT_WRITE/IOMMU_PROT_EXEC;
 ├─ struct viommu_ioas *ioas = viommu_find_ioas(viommu, ioasid);
 │  └─ struct rb_node *node = viommu->address_spaces.rb_node;
 └─ ioas->ops->map(ioas->priv, virt_addr, phys_addr, size, prot);
    ├─ struct vfio_guest_container *container = priv;
    ├─ map = { .iova = virt_addr, .size	= size, };
    ├─ map.vaddr = (u64)guest_flat_to_host(container->kvm, phys_addr);
    └─ return ioctl(container->fd, VFIO_IOMMU_MAP_DMA, &map); IOVA -> HPA?
```


patch 4, Add a simple IOMMU



patch 6, irq: register MSI doorbell addresses

对于 vIOMMU 管理的 pass-through 设备, 我们需要将 writes 翻译为 MSI vectors. 让 IRQ 代码注册 MSI doorbells, 并添加一个简单的方法, 让其他系统检查一个地址是否是 doorbell.



**patch 7**, virtio: factor virtqueue initialization

所有 virtio 设备在初始化其 virtqueue 时都执行相同的少数操作. 将这些操作移动到 virtio core, 因为在实施 vIOMMU 时, 我们必须使 vring 初始化复杂化.

## 5.2. virtio 设备的 vIOMMU 支持

**patch 8**, virtio: add vIOMMU instance for virtio devices

> 给 virtio 设备添加 vIOMMU 实例

Virtio 设备现在可以通过设置 use_iommu 选项来选择是否使用 IOMMU. 这些都不能在当前状态下工作, 因为 virtio 设备仍然以线性的方式访问内存. 后续的 patch 会实现 sg 访问.

两种类型:

* virtio_pci
* virtio_mmio

以 virtio_pci 为例

```diff
diff --git a/include/kvm/virtio-pci.h b/include/kvm/virtio-pci.h
index b70cadd8..26772f74 100644
--- a/include/kvm/virtio-pci.h
+++ b/include/kvm/virtio-pci.h
@@ -22,6 +22,7 @@ struct virtio_pci {
 	struct pci_device_header pci_hdr;
 	struct device_header	dev_hdr;
 	void			*dev;
+	struct virtio_device	*vdev;
 	struct kvm		*kvm;

 	u16			port_addr;
```

```cpp
static struct iommu_ops virtio_pci_iommu_ops = {
	.get_properties		= virtio__iommu_get_properties,
	.alloc_address_space	= iommu_alloc_address_space,
	.free_address_space	= iommu_free_address_space,
	.attach			= virtio_pci_iommu_attach,
	.detach			= virtio_pci_iommu_detach,
	.map			= iommu_map,
	.unmap			= iommu_unmap,
};
```

virtio 设备初始化时候, `virtio_pci__init`, 初始化了 ops

```diff
@@ -416,6 +440,7 @@ int virtio_pci__init(struct kvm *kvm, void *dev, struct virtio_device *vdev,

 	vpci->kvm = kvm;
 	vpci->dev = dev;
+	vpci->vdev = vdev;

 	r = ioport__register(kvm, IOPORT_EMPTY, &virtio_pci__io_ops, IOPORT_SIZE, vdev);
 	if (r < 0)
@@ -461,6 +486,7 @@ int virtio_pci__init(struct kvm *kvm, void *dev, struct virtio_device *vdev,
 	vpci->dev_hdr = (struct device_header) {
 		.bus_type		= DEVICE_BUS_PCI,
 		.data			= &vpci->pci_hdr,
+		.iommu_ops		= vdev->use_iommu ? &virtio_pci_iommu_ops : NULL,
 	};
```

**patch 9**, virtio: access vring and buffers through IOMMU mappings

> 通过 iommu mappings 访问 vring 和 buffers

教 virtio core 如何访问分散的 vring 结构. 当在 virtio 设备前向 guest 呈现了 vIOMMU, virtio ring 和 buffer 将分散在不连续的 guest 物理页面中. vIOMMU 设备必须将所有 IOVA 转换为 host 虚拟地址, 并在访问任何结构之前收集这些页面(gather the pages).

vring.desc 描述的 buffers 信息已经通过 iovec 返回给设备. 我们仅仅需要用更精细的粒度填充这些 buffers, 并希望:

1. 驱动程序不会一次性提供太多的描述符 descriptors, 因为 iovec 只有描述符数目一样大, 而现在可能出现溢出.
2. 设备不会对来自 vectors 的消息框架做出假设(即, 信息现在可以被包含在比以前更多的 vectors 中). 这是virtio 1.0所禁止的(以及 legacy with ANY_LAYOUT), 但我们的 virtio-net, 例如, 假设第一个 vector 总是包含一个完整的vnet header. 实际上, 这很好, 但仍然非常脆弱.

为了访问 vring 和间接描述表, 我们现在分配一个 iovec 来描述 IOMMU 结构的 mapping, 并通过此 iovec 进行所有访问.

更优雅的方法是每个 address-space 创建一个子进程, 并以连续的方式 remap guest 内存片段 fragments:

```
                                .---- virtio-blk process
                               /
           viommu process ----+------ virtio-net process
                               \
                                '---- some other device
```

(0) 最初, viommu 为每个模拟设备都 fork 一个进程. 每个子进程都通过 `mmap(base)` 保留一大块虚拟内存, 代表了 IOVA 空间, 但不会填充它.

(1) virtio-dev 想要访问 guest 内存, 比如读 vring. 它通过 pipe 或 socket 给父进程(viommu  process)发送一个 IOVA 的 TLB miss.

(2) 父 iommu 会检查它的转换表(translation tables), 并返回 guest memory 的 offset.

(3) 子进程在它的 IOVA 空间进行 mmap, 使用 `mmap(base + iova, pgsize, SHARED|FIXED, fd, offset)`

这真的很酷, 但我怀疑它增加了很多复杂性, 因为不清楚哪些设备是完全自成一体的, 哪些设备需要访问父内存. 因此, 请暂缓使用散射收集访问.



**patch 10**, virtio-pci: translate MSIs with the virtual IOMMU

> 使用 viommu 翻译 MSI

当 virtio 设备位于 vIOMMU 后面时, guest 写入 MSI-X table 的 doorbell 地址是 IOVA, 而不是物理地址.  注入 MSI 时, KVM 需要物理地址来识别 doorbell 和相关的 IRQ 芯片. 将 guest 提供的地址转换为物理地址, 并将其存储在辅助表中, 以便于访问.


**patch 11**, virtio: set VIRTIO_F_IOMMU_PLATFORM when necessary

> 当一个设备被 viommu 管理, 则启用这个功能位

Virtio 中的其他功能位不依赖于设备类型, 针对 viommu, 我们也可以这样. 例如, 我们的 vring 实现始终支持间接描述(VIRTIO_RING_F_INDIRECT_DESC), 因此我们可以同时为所有设备(目前只有 net、scsi 和 blk)进行 advertise. 但是, 这可能会改变guest的行为: 在 Linux 中, 每当驱动尝试添加一系列描述符时, 它都会分配一个间接表并使用单个 ring 描述符, 这可能会稍微降低性能.

VIRTIO_RING_F_EVENT_IDX 是 vring 的另一个功能, 但需要设备在向 guest 发出信号之前调用 virtio_queue__should_signal. 可以说, 我们可以考虑所有对 signal_vq 的调用, 但让我们保持这个 patch 简单.

```cpp
/*
 * If clear - device has the platform DMA (e.g. IOMMU) bypass quirk feature.
 * If set - use platform DMA tools to access the memory.
 *
 * Note the reverse polarity (compared to most other features),
 * this is for compatibility with legacy systems.
 */
#define VIRTIO_F_ACCESS_PLATFORM	33
#ifndef __KERNEL__
/* Legacy name for VIRTIO_F_ACCESS_PLATFORM (for compatibility with old userspace) */
#define VIRTIO_F_IOMMU_PLATFORM		VIRTIO_F_ACCESS_PLATFORM
#endif /* __KERNEL__ */
```

上面注释也说了:

* 清位, 设备具有平台 DMA(例如 IOMMU)旁路功能.
* 置位, 使用平台 DMA 工具(vIOMMU)访问内存

```diff
--- a/virtio/core.c
+++ b/virtio/core.c
@@ -1,3 +1,4 @@
+#include <linux/virtio_config.h>
 #include <linux/virtio_ring.h>
 #include <linux/types.h>
 #include <sys/uio.h>
@@ -266,6 +267,11 @@ bool virtio_queue__should_signal(struct virt_queue *vq)
 	return false;
 }

+u32 virtio_get_common_features(struct kvm *kvm, struct virtio_device *vdev)
+{
+	return vdev->use_iommu ? VIRTIO_F_IOMMU_PLATFORM : 0;
+}
+
```

`virtio/mmio.c`, guest 中 mmio read device config 时候会 trap 到 kvmtool, 选择是否返回这个 feature bit

```diff
--- a/virtio/mmio.c
+++ b/virtio/mmio.c
@@ -127,9 +127,11 @@ static void virtio_mmio_config_in(struct kvm_cpu *vcpu,
 		ioport__write32(data, *(u32 *)(((void *)&vmmio->hdr) + addr));
 		break;
 	case VIRTIO_MMIO_HOST_FEATURES:
-		if (vmmio->hdr.host_features_sel == 0)
+		if (vmmio->hdr.host_features_sel == 0) {
 			val = vdev->ops->get_host_features(vmmio->kvm,
 							   vmmio->dev);
+			val |= virtio_get_common_features(vmmio->kvm, vdev);
+		}
 		ioport__write32(data, val);
 		break;
```

`virtio/pci.c` 同理

```diff
--- a/virtio/pci.c
+++ b/virtio/pci.c
@@ -126,6 +126,7 @@ static bool virtio_pci__io_in(struct ioport *ioport, struct kvm_cpu *vcpu, u16 p
 	switch (offset) {
 	case VIRTIO_PCI_HOST_FEATURES:
 		val = vdev->ops->get_host_features(kvm, vpci->dev);
+		val |= virtio_get_common_features(kvm, vdev);
 		ioport__write32(data, val);
 		break;
```

所以在 guest 中可以看 device 的 config 可以知道它是否 attach 到了 vIOMMU 上

> 最新的代码中没有这个....

## 5.3. vfio 设备的支持

**patch 12**, vfio: add support for virtual IOMMU

目前, 所有的 pass-through 设备必须访问到相同的 guest 物理地址空间. 注册 IOMMU, 从而为每个设备提供单独的地址空间. 方法是通过给每个 group 分配一个 container, 并按需添加 mappings.

由于 guest 不能访问设备, 除非这个设备被 attach 到 container, 并且我们不能在运行时不重置设备就更改 container, 因此此实现是有限的. 要实现 bypass 模式, 我们需要首先 map 整个 guest 物理内存, 并在 attach 到新 address space 时 unmap 所有内容. 设备也不可能被 attach 到相同的地址空间, 它们都有不同的 page tables.

数据结构方面, 每个 vfio 设备都是属于某个一个 vfio group, 再给每个 group 定义了一个 container

```diff
--- a/include/kvm/vfio.h
+++ b/include/kvm/vfio.h
@@ -55,6 +55,7 @@ struct vfio_device {
 	struct device_header		dev_hdr;

 	int				fd;
+	struct vfio_group		*group;
 	struct vfio_device_info		info;
 	struct vfio_irq_info		irq_info;
 	struct vfio_region		*regions;
@@ -65,6 +66,7 @@ struct vfio_device {
 struct vfio_group {
 	unsigned long			id; /* iommu_group number in sysfs */
 	int				fd;
+	struct vfio_guest_container	*container;
 };

--- a/vfio.c
+++ b/vfio.c
+struct vfio_guest_container {
+	struct kvm		*kvm;
+	int			fd;
+
+	void			*msi_doorbells;
+};
+
+static void *viommu = NULL;
```

```cpp
struct vfio_guest_container {
    struct kvm  *kvm;
    int         fd;
    void        *msi_doorbells;
};

struct vfio_device {
    struct vfio_group *group;
}

struct vfio_group {
    struct vfio_guest_container *container;
}
```

```cpp
vfio__init()
 ├─ vfio_container_init(kvm);
 │  ├─ vfio_container = open(VFIO_DEV_NODE, O_RDWR);
 │  ├─ ioctl(vfio_container, VFIO_GET_API_VERSION);
 │  ├─ vfio_device_init(kvm, &vfio_devices[i]);
 │  │  ├─ group = vfio_group_get_for_dev(kvm, vdev);
 │  │  │  ├─ group->fd = open(group_node, O_RDWR);
 │  │  │  └─ ioctl(group->fd, VFIO_GROUP_SET_CONTAINER, &vfio_container)
 │  │  └─vdev->group = group;
 │  ├─ ioctl(vfio_container, VFIO_SET_IOMMU, iommu_type);
 │  └─ ioctl(vfio_container, VFIO_IOMMU_MAP_DMA, &dma_map)
 ├─ vfio_configure_groups(kvm);
 │  └─ ioctl(kvm->vm_fd, KVM_SET_USER_MEMORY_REGION, &mem)
 └─ vfio_configure_devices(kvm);
    ├─ ioctl(group->fd, VFIO_GROUP_GET_DEVICE_FD,vdev->params->name)
    ├─ ioctl(vdev->fd, VFIO_DEVICE_RESET)
    └─ vfio_pci_setup_device()
       ├─ vfio_pci_configure_dev_regions(kvm, vdev);
       │  ├─ vfio_pci_create_msix_table();
       │     └─ kvm__register_mmio();
       ├─ device__register(&vdev->dev_hdr);
       └─ vfio_pci_configure_dev_irqs(kvm, vdev);
```

原有逻辑中, vfio 初始化阶段, `vfio__init()` 中

1. vfio_container_init() 初始化 container
* 初始化一个全局 vfio container(一个 vm 对应一个), 调用 `vfio_container = open(VFIO_DEV_NODE, O_RDWR)`; 打开 `/dev/vfio/vfio`
* 循环初始化每个设备, `vfio_device_init(kvm, &vfio_devices[i])`;
  * 根据 device 的 sysfs_path 中的 group_id, 遍历 vfio_groups 链表查找 group, `list_for_each_entry(group, &vfio_groups, list)`
  * 找不到则创建一个新的 group 并将其加入到 container 中, `vfio_group_create(kvm, group_id)` -> `group->fd = open(group_node, O_RDWR);` && `ioctl(group->fd, VFIO_GROUP_SET_CONTAINER, &vfio_container)`, `group->fd` 是 `/dev/vfio/XX(ID)`
  * 将 vfio_group 添加到 `vfio_groups` 链表, `	list_add(&group->list, &vfio_groups)`
* 设置 iommu type 到 container, `ioctl(vfio_container, VFIO_SET_IOMMU, iommu_type)`
* 将虚拟机中所有 `KVM_MEM_TYPE_RAM` 类型(也就是vm内存)的内存块 map 用来 DMA (`iova<gpa> -> hva`), `ioctl(vfio_container, VFIO_IOMMU_MAP_DMA, &dma_map)`
2. vfio_configure_groups() 配置 vfio groups, 遍历每一个 vfio group
* 将 `/sys/kernel/iommu_groups/ID/reserved_regions` 中每一行内存地址范围(gpa)进行保留, `ioctl(kvm->vm_fd, KVM_SET_USER_MEMORY_REGION, &mem)`
3. vfio_configure_devices() 配置所有 devices, 遍历每一个 vfio device
* 获取 fd, 调用 `ioctl(group->fd, VFIO_GROUP_GET_DEVICE_FD,vdev->params->name)`, vfio 从`group->device_list` 中查找device, 并通过匿名node和fd建立关系
* reset device, `ioctl(vdev->fd, VFIO_DEVICE_RESET)`
* bus 相关初始化, PCI 类型的调用 `vfio_pci_setup_device(kvm, vdev)`; MMIO 类型的调用 `vfio_plat_setup_device(kvm, vdev)`
  * PCI 类型:
    * 配置 regions, `vfio_pci_configure_dev_regions(kvm, vdev)`;
      * config space 信息获取, `vfio_pci_parse_cfg_space(vdev)`
      * 创建 msix table, `vfio_pci_create_msix_table(kvm, pdev)`, 会将 msix table 和 msix pba 调用 `kvm__register_mmio` 注册为 mmio, guest 调用会发生 vm-exit 并被相应的回调处理
      * 创建 msi capability, `vfio_pci_create_msi_cap(kvm, pdev)`
      * 配置 bar space, `vfio_pci_configure_bar(kvm, vdev, i)`
      * `vfio_pci_fixup_cfg_space(vdev)`
    * 注册 vfio 设备, `device__register(&vdev->dev_hdr)`;
    * 配置 IRQs, `vfio_pci_configure_dev_irqs(kvm, vdev)`.

对 viommu 的支持, 将所有 contianer 替换成 viommu 的 container, iommu ops 也被替换成 viommu ops

首先, 将新 vfio group 加到 container 之前, 生成新的 container, 这样一个 group 一个 container, 即 1.2.2

```diff
@@ -1066,6 +1242,25 @@ static int vfio_group_init(struct kvm *kvm, struct vfio_group *group)
 	snprintf(group_node, VFIO_PATH_MAX_LEN, VFIO_DEV_DIR "/%lu",
 		 group->id);
+	if (kvm->cfg.viommu) {
+		container = open(VFIO_DEV_NODE, O_RDWR);
+		if (container < 0) {
+			ret = -errno;
+			pr_err("cannot initialize private container\n");
+			return ret;
+		}
+
+		group->container = malloc(sizeof(struct vfio_guest_container));
+		if (!group->container)
+			return -ENOMEM;
+
+		group->container->fd = container;
+		group->container->kvm = kvm;
+		group->container->msi_doorbells = NULL;
+	} else {
+		container = vfio_host_container;
+	}
+
 	group->fd = open(group_node, O_RDWR);
 	if (group->fd == -1) {
 		ret = -errno;
```

给每个 vfio group 都进行 open 操作, 从而创建了一个新的私有 container; 再添加这个私有 container 到 group. 这样一个 group 一个 container

同时将 type v2 也设置到这个 container, 因为 `unmap-all` 需要

```diff
+	if (container != vfio_host_container) {
+		struct vfio_iommu_type1_info info = {
+			.argsz = sizeof(info),
+		};
+
+		/* We really need v2 semantics for unmap-all */
+		ret = ioctl(container, VFIO_SET_IOMMU, VFIO_TYPE1v2_IOMMU);
+		if (ret) {
+			ret = -errno;
+			pr_err("Failed to set IOMMU");
+			return ret;
+		}
+
+		ret = ioctl(container, VFIO_IOMMU_GET_INFO, &info);
+		if (ret)
+			pr_err("Failed to get IOMMU info");
+		else if (info.flags & VFIO_IOMMU_INFO_PGSIZES)
+			vfio_viommu_props.pgsize_mask = info.iova_pgsizes;
+	}
+
```

其次, 在配置 groups 之前, 即 2.

如果配置整体使用 vIOMMU, 则关闭全局 vfio container, 同时调用 `viommu_register` 注册了 viommu.

```diff
--- a/vfio.c
+++ b/vfio.c
@@ -870,6 +894,154 @@ static int vfio_configure_dev_irqs(struct kvm *kvm, struct vfio_device *device)
 	return ret;
 }

+static struct iommu_properties vfio_viommu_props = {
+	.name				= "viommu-vfio",
+
+	.input_addr_size		= 64,
+};
-static int vfio_container_init(struct kvm *kvm)
+static int vfio_groups_init(struct kvm *kvm)
 {
 	int api, i, ret, iommu_type;;

-	/* Create a container for our IOMMU groups */
-	vfio_container = open(VFIO_DEV_NODE, O_RDWR);
-	if (vfio_container == -1) {
+	/*
+	 * Create a container for our IOMMU groups. Even when using a viommu, we
+	 * still use this one for probing capabilities.
+	 */
+	vfio_host_container = open(VFIO_DEV_NODE, O_RDWR);
+	if (vfio_host_container == -1) {
 		ret = errno;
 		pr_err("Failed to open %s", VFIO_DEV_NODE);
 		return ret;
 	}

-	api = ioctl(vfio_container, VFIO_GET_API_VERSION);
+	api = ioctl(vfio_host_container, VFIO_GET_API_VERSION);
 	if (api != VFIO_API_VERSION) {
 		pr_err("Unknown VFIO API version %d", api);
 		return -ENODEV;
@@ -1119,15 +1337,20 @@ static int vfio_container_init(struct kvm *kvm)
 		return iommu_type;
 	}

-	/* Sanity check our groups and add them to the container */
 	for (i = 0; i < kvm->cfg.num_vfio_groups; ++i) {
 		ret = vfio_group_init(kvm, &kvm->cfg.vfio_group[i]);
 		if (ret)
 			return ret;
 	}

+	if (kvm->cfg.viommu) {
+		close(vfio_host_container);
+		vfio_host_container = -1;
+		return 0;
+	}
 	/* Finalise the container */
@@ -1147,10 +1370,16 @@ static int vfio__init(struct kvm *kvm)
 	if (!kvm->cfg.num_vfio_groups)
 		return 0;

-	ret = vfio_container_init(kvm);
+	ret = vfio_groups_init(kvm);
 	if (ret)
 		return ret;

+	if (kvm->cfg.viommu) {
+		viommu = viommu_register(kvm, &vfio_viommu_props);
+		if (!viommu)
+			pr_err("could not register viommu");
+	}
+
 	ret = vfio_configure_iommu_groups(kvm);
 	if (ret)
 		return ret;
```

最后, 在配置 devices 之前, 即 3.3.3 设置 `vfio_device->dev_hdr` 中的 `iommu_ops` 为 `&vfio_iommu_ops`

```diff
--- a/vfio.c
+++ b/vfio.c
@@ -912,6 +1084,8 @@ static int vfio_configure_device(struct kvm *kvm, struct vfio_group *group,
 		return -ENOMEM;
 	}

+	device->group = group;
+
 	device->fd = ioctl(group->fd, VFIO_GROUP_GET_DEVICE_FD, dirent->d_name);
 	if (device->fd < 0) {
 		pr_err("Failed to get FD for device %s in group %lu",
@@ -945,6 +1119,7 @@ static int vfio_configure_device(struct kvm *kvm, struct vfio_group *group,
 	device->dev_hdr = (struct device_header) {
 		.bus_type	= DEVICE_BUS_PCI,
 		.data		= &device->pci.hdr,
+		.iommu_ops	= viommu ? &vfio_iommu_ops : NULL,
 	};
```

这些 `vfio_iommu_ops` 自定义了 iommu 的相关操作

```diff
--- a/vfio.c
+++ b/vfio.c

+static struct iommu_ops vfio_iommu_ops = {
+	.get_properties		= vfio_viommu_get_properties,
+	.alloc_address_space	= vfio_viommu_alloc,
+	.free_address_space	= vfio_viommu_free,
+	.attach			= vfio_viommu_attach,
+	.detach			= vfio_viommu_detach,
+	.map			= vfio_viommu_map,
+	.unmap			= vfio_viommu_unmap,
+};
+
```

```cpp
static struct iommu_ops vfio_iommu_ops = {
	.get_properties		= vfio_viommu_get_properties,
	.alloc_address_space	= vfio_viommu_alloc,
	.free_address_space	= vfio_viommu_free,
	.attach			= vfio_viommu_attach,
	.detach			= vfio_viommu_detach,
	.map			= vfio_viommu_map,
	.unmap			= vfio_viommu_unmap,
};
```

同时, 需要处理

* 对 pci_msix_pba 的访问
* 对 pci_msix_table 的访问

当访问 msix_table 时候会发生 VM-exit, 进而返回给 kvmtool 处理. 如果 container 存在, 说明独立, 调用 `iommu_translate_msi`,

```diff
--- a/vfio.c
+++ b/vfio.c
@@ -68,11 +81,13 @@ static void vfio_pci_msix_pba_access(struct kvm_cpu *vcpu, u64 addr, u8 *data,
 static void vfio_pci_msix_table_access(struct kvm_cpu *vcpu, u64 addr, u8 *data,
 				       u32 len, u8 is_write, void *ptr)
 {
+	struct msi_msg msg;
 	struct kvm *kvm = vcpu->kvm;
 	struct vfio_pci_device *pdev = ptr;
 	struct vfio_pci_msix_entry *entry;
 	struct vfio_pci_msix_table *table = &pdev->msix_table;
 	struct vfio_device *device = container_of(pdev, struct vfio_device, pci);
+	struct vfio_guest_container *container = device->group->container;

 	u64 offset = addr - table->guest_phys_addr;

@@ -88,11 +103,16 @@ static void vfio_pci_msix_table_access(struct kvm_cpu *vcpu, u64 addr, u8 *data,

 	memcpy((void *)&entry->config + field, data, len);

-	if (field != PCI_MSIX_ENTRY_VECTOR_CTRL)
+	if (field != PCI_MSIX_ENTRY_VECTOR_CTRL || entry->config.ctrl & 1)
+		return;
+
+	msg = entry->config.msg;
+
+	if (container && iommu_translate_msi(container->msi_doorbells, &msg))
 		return;

 	if (entry->gsi < 0) {
```

同理, 写 pci_msi 时候也需要处理

```diff
--- a/vfio.c
+++ b/vfio.c
@@ -122,6 +142,7 @@ static void vfio_pci_msi_write(struct kvm *kvm, struct vfio_device *device,
 	struct msi_msg msi;
 	struct vfio_pci_msix_entry *entry;
 	struct vfio_pci_device *pdev = &device->pci;
+	struct vfio_guest_container *container = device->group->container;
 	struct msi_cap_64 *msi_cap_64 = (void *)&pdev->hdr + pdev->msi.pos;

 	/* Only modify routes when guest sets the enable bit */
@@ -144,6 +165,9 @@ static void vfio_pci_msi_write(struct kvm *kvm, struct vfio_device *device,
 		msi.data = msi_cap_32->data;
 	}

+	if (container && iommu_translate_msi(container->msi_doorbells, &msi))
+		return;
+
 	for (i = 0; i < nr_vectors; i++) {
 		u32 devid = device->dev_hdr.dev_num << 3;
```

## 5.4. debug 相关

**patch 13**, virtio-iommu: debug via IPC


**patch 14**, virtio-iommu: implement basic debug commands







# 6. 现有实现

> todo

## description 变化

之前的 address space, 现在叫 domain.

## linux driver

`virtio-iommu driver` 模块初始化相关代码

利用了原本的virtio框架. 重点在两个: `viommu_probe` 和 `viommu_remove`.

当注册一个 viommu 设备(也是一个 virtio 设备), 调用 `viommu_probe(struct virtio_device *vdev)`

1. `struct viommu_dev *viommu = devm_kzalloc(struct *device, sizeof(*viommu), GFP_KERNEL);`, 生成 viommu 设备对象
2. `viommu_init_vq(viommu);`, 查找 virt queue, 应该是 virtio 框架给每个 virtio device 都实现了 vq, 确保存在. 这里的回调函数也是 NULL.
3. `virtio_cread_le(vdev, struct virtio_iommu_config, page_size_mask, &viommu->pgsize_bitmap);`, 获取 page_sizes 配置
4. `virtio_cread_le_feature()`, 获取 input_range 的 start 和 end
5. `virtio_cread_le_feature()`, 获取 domain_range 的 first_domain 和 last_domain
6. `virtio_cread_le_feature()`, 获取 probe 的 probe_size
7. `viommu_fill_evtq(viommu)`, 用 buffers 填充 event queue
8. `iommu_device_sysfs_add()`, 初始化 `viommu->iommu` (`struct iommu_device`), 并添加到 sysfs
9.  `iommu_device_register()`, 设置了 `viommu->iommu` (`struct iommu_device`) 的ops, viommu_ops; 注册 `viommu->iommu` 到全局 `iommu_device_list` 链表
10. `bus_set_iommu(&pci_bus_type, &viommu_ops)`, 设置 pci bus, 下面细讲
11. `bus_set_iommu(&platform_bus_type, &viommu_ops);`, 设置 platform bus, 下面细讲

设置总线iommu的回调操作函数以及为该总线类型的iommu做一些特别的设定

```cpp
viommu_probe()
 ├─ alloc a viommu_dev;
 ├─ initialize from configuration.
 ├─ iommu_device_sysfs_add();
 └─ bus_set_iommu(&pci_bus_type, &viommu_ops);
    ├─ LIST_HEAD(group_list);
    ├─ bus_for_each_dev(..,probe_iommu_group);
    │  ├─ iommu_ops->probe_device();
    │  ├─ group = iommu_group_get_for_dev(dev);
    │  ├─ list_add_tail(&group->entry, group_list);
    │  └─ iommu_device_link(iommu_dev, dev);
    └─ list_for_each_entry_safe(..,&group_list,..)
       ├─ probe_alloc_default_domain();
       └─ __iommu_group_dma_attach();
```

```cpp
bus_set_iommu()
 ├─ bus->iommu_ops = ops; 设置 bus 的 iommu ops
 └─ iommu_bus_init(bus, ops);, iommu 的总线相关初始化. 注册了 bus notifier, 回调是 `iommu_bus_notifier`; 然后调用 `bus_iommu_probe(bus)`
   ├─ LIST_HEAD(group_list); 生成一个 group_list 链表
   ├─ bus_for_each_dev(bus, NULL, &group_list, probe_iommu_group); 遍历总线下所有设备, 给每个设备调用回调函数 `probe_iommu_group`, 将设备添加到 iommu group(`iommu_init` 中初始化) 中. 会调用`__iommu_probe_device()`
   │  ├─ iommu_dev = dev->bus->iommu_ops->probe_device(struct device dev);, 添加设备, 调用了`viommu_probe_device()`
   │  │  ├─ struct viommu_endpoint *vdev = kzalloc(sizeof(*vdev), GFP_KERNEL); 结构体分配
   │  │  ├─ vdev->viommu = viommu;
   │  │  ├─ INIT_LIST_HEAD(&vdev->resv_regions);
   │  │  └─ viommu_probe_endpoint(viommu, dev); viommu->probe_size 存在则会调用这个获取额外信息
   │  │     ├─ struct virtio_iommu_req_probe *probe; 初始化 probe request
   │  │     ├─ viommu_send_req_sync(viommu, probe, probe_len);
   │  ├─ dev->iommu->iommu_dev = iommu_dev; 设置 device 的 iommu device
   │  ├─ group = iommu_group_get_for_dev(dev); 为设备查找或创建一个 iommu group
   │  │  ├─ 查找或创建一个 iommu group, `dev->bus->iommu_ops->device_group(dev)`, 会调用 `viommu_device_group()` 分配一个 group
   │  │  │  └─ pci_device_group(dev); / generic_device_group(dev);
   │  │  └─ iommu_group_add_device(group, dev); 将这个 device add 到这个 group, 分配 sruct group_device;
   │  │     ├─ sysfs_create_link(&dev->kobj, &group->kobj, "iommu_group"); 创建 iommu group 和设备关联的软链接(`/sys/devices/pci总线ID/设备号/iommu_group -> `/sys/kernel/iommu_groups/xx`)
   │  │     ├─ sysfs_create_link_nowarn(group->devices_kobj, &dev->kobj, device->name); 创建 iommu group 和设备关联的软链接(`/sys/kernel/iommu_groups/xx/devices/设备PCI号` -> `/sys/devices/pci总线ID/设备号`
   │  │     ├─ dev->iommu_group = group;
   │  │     ├─ if (group->domain) __iommu_attach_device(group->domain, dev); 有 domain 就 attach(这时候当然没有)
   │  │     └─ blocking_notifier_call_chain(&group->notifier, IOMMU_GROUP_NOTIFY_ADD_DEVICE, dev); group notifier, vfio_create_group 会注册
   │  ├─ list_add_tail(&group->entry, group_list); 将 group 添加到 group_list
   │  └─ iommu_device_link(iommu_dev, dev); sys 文件系统添加一些 软链接
   │      ├─ sysfs_add_link_to_group(&iommu->dev->kobj, "devices", &link->kobj, dev_name(link)); 创建 iommu 和 设备 关联的软链接(`/sys/devices/pci总线ID/iommu设备号/virtio0/iommu/iommu设备号/devices/endpoint设备号 -> `/sys/devices/pci总线ID/endpoint设备号`), 在 iommu device 的 devices 下面创建软链接
   │      └─ sysfs_create_link_nowarn(&link->kobj, &iommu->dev->kobj, "iommu"); 创建iommu 和 设备 关联的软链接(`/sys/devices/pci总线ID/endpoint设备号/iommu` -> `/sys/devices/pci总线ID/设备号/virtio0/iommu/设备号/`)
   └─ list_for_each_entry_safe(group, next, &group_list, entry), 遍历整个 group_list
      ├─ probe_alloc_default_domain(bus, group);, 给每个 iommu group 分配 default domain, 会调用 viommu_domain_alloc, 主要是分配空间并初始化
      │  ├─ __iommu_group_for_each_dev(group, &gtype, probe_get_default_domain_type); 遍历 group 中的 device, 获取每个 device 的 default domain type(一般是 IOMMU_DOMAIN_DMA)
      │  └─ iommu_group_alloc_default_domain(bus, group, gtype.type);
      │     ├─ struct iommu_domain *dom = __iommu_domain_alloc(dev->bus, iommu_def_domain_type); 给每个 iommu group 分配 domain
      │     │  ├─ struct iommu_domain *domain = bus->iommu_ops->domain_alloc(type); 调用 viommu_domain_alloc, 主要是分配空间并初始化
      │     │  │  ├─ struct viommu_domain *vdomain = kzalloc(sizeof(struct viommu_domain), GFP_KERNEL); 生成新的 vdomain
      │     │  │  ├─ vdomain->id = atomic64_inc_return_relaxed(&viommu_domain_ids_gen); 分配新 id
      │     │  │  └─ vdomain->mappings = RB_ROOT; 每个 vdomain 的所有 mappings 构成 rb tree
      │     │  ├─ domain->ops  = bus->iommu_ops;
      │     │  ├─ domain->type = type;
      │     │  └─ domain->pgsize_bitmap  = bus->iommu_ops->pgsize_bitmap;
      │     ├─ group->default_domain = dom;
      │     └─ group->domain = dom;
      ├─ iommu_group_create_direct_mappings(group), 给设备做DMA映射. 将设备对应的虚拟机地址空间段映射到物理地址空间. 遍历 group 中的所有设备, 每个调用 iommu_create_device_direct_mappings(struct iommu_group *group, struct device *dev)
      │  ├─ pg_size = 1UL << __ffs(domain->pgsize_bitmap); page size
      │  ├─ iommu_get_resv_regions(dev, &mappings);, 获取设备的 mappings(iova), 调用 `viommu_ops.viommu_get_resv_regions`
      │  │  ├─ struct iommu_resv_region *msi = iommu_alloc_resv_region(MSI_IOVA_BASE, MSI_IOVA_LENGTH, prot, IOMMU_RESV_MSI); 初始化这个一个 region 结构体, arm 上面需要这个 region 用于 map doorbell
      │  ├─ list_for_each_entry(entry, &mappings, list), 遍历设备映射的地址段
      │  │  ├─ start/end = ALIGN(entry->start/end, pg_size);, 根据 page size 对齐
      │  │  ├─ if (entry->type != IOMMU_RESV_DIRECT) continue; mapping 类型, 这里肯定不是 direct
      │  │  ├─ for (addr = start; addr < end; addr += pg_size), 每个 page 逐个 map
      │  │  │  ├─ phys_addr = iommu_iova_to_phys(domain, addr), 看是否已经有了 iova -> pa 的 map. 调用 viommu_iova_to_phys
      │  │  │  │  ├─ interval_tree_iter_first(&viommu_domain->mappings, iova, iova); 在 vdomain 中查找 iova 所在的 node
      │  │  │  │  ├─ struct viommu_mapping *mapping = container_of(node, struct viommu_mapping, iova); 得到对应的 vmapping
      │  │  │  │  └─ paddr = mapping->paddr + (iova - mapping->iova.start);
      │  │  │  ├─ map_size += pg_size; 如果没有得到物理地址, 说明已经还没有 map, 准备map_size, 继续处理下一个 page
      │  │  │  ├─ iommu_map(domain, addr - map_size, addr - map_size, map_size, entry->prot), map_size 大于 0, 即有需要map的, 则将每段虚拟地址空间都映射到相应的物理内存页上, iova = paddr = addr - map_size, 所以初始化的 msi iova = pa
      │  │  │  │  ├─ domain->ops->map(domain, iova, paddr, pgsize, prot); 根据 iommu pgsize(pgsize), 逐个 page 进行map, 调用 viommu_map
      │  │  │  │  │  ├─ struct viommu_domain *vdomain = to_viommu_domain(domain); 获取 vdomain
      │  │  │  │  │  ├─ struct virtio_iommu_req_map req; 构建 map request 并初始化
      │  │  │  │  │  ├─ address_space	= cpu_to_le32(vdomain->id); group 初始化时候分配的
      │  │  │  │  │  ├─ viommu_tlb_map(vdomain, iova, paddr, size); (iova, size) 和 paddr 的 mapping 关系缓存起来
      │  │  │  │  │  │  ├─ struct viommu_mapping *mapping = kzalloc(sizeof(*mapping), GFP_ATOMIC);
      │  │  │  │  │  │  ├─ mapping->paddr = paddr; mapping->iova.start = iova; mapping->iova.last = iova + size - 1;
      │  │  │  │  │  │  ├─ interval_tree_insert(&mapping->iova, &vdomain->mappings); 插入树
      │  │  │  │  │  ├─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 map request, 忙等返回
      ├─ __iommu_group_dma_attach(group);
      │  └─ __iommu_group_for_each_dev(group, group->default_domain, iommu_group_do_dma_attach); 遍历group中所有device, 调用 iommu_group_do_dma_attach
      │     └─ __iommu_attach_device(group, dev), 调用 domain->ops->attach_dev(domain, dev), viommu_attach_dev
      │        ├─ struct virtio_iommu_req_attach req; 创建 attach 请求
      │        ├─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 attach request, 忙等返回
      └─ __iommu_group_dma_finalize(group);
```

```cpp
viommu_map(domain, iova, paddr, size, prot)
 ├─ struct viommu_domain *vdomain = to_viommu_domain(domain);
 ├─ viommu_add_mapping(vdomain, iova, paddr, size);
 │  ├─ alloc viommu_mapping and init
 │  └─ interval_tree_insert(&mapping->iova, &vdomain->mappings);
 ├─ struct virtio_iommu_req_map req;
 └─ viommu_send_req_sync(vdomain->viommu, &req);
    ├─ __viommu_add_req(viommu, buf, len, true);
    └─ __viommu_sync_req(viommu);
```

```cpp
bus_set_iommu()
 ├─ if (bus->iommu_ops != NULL) return -EBUSY, bus 已经有iommu_ops
 ├─ bus->iommu_ops = ops;, 设置 bus 的 iommu ops
 └─ iommu_bus_init(bus, ops);, iommu 的总线相关初始化.
   ├─ nb->notifier_call = iommu_bus_notifier;
   ├─ bus_register_notifier(bus, nb); 注册 bus notifier, 回调是 `iommu_bus_notifier()`
   └─ bus_for_each_dev(bus, NULL, &group_list, add_iommu_group); 遍历总线下所有设备, 给每个设备调用 `add_iommu_group()`, 将设备添加到 iommu group 中
      └─ iommu_ops->add_device(struct device dev);, 添加设备, 调用了 `viommu_add_device()`
         ├─ struct viommu_endpoint *vdev = kzalloc(sizeof(*vdev), GFP_KERNEL); 分配了 viommu_endpoint 并初始化
         ├─ dev->iommu->iommu_dev = iommu_dev; 设置 device 的 iommu device
         └─ group = iommu_group_get_for_dev(dev); 最后一步会创建一个 domain 并 attach 这个 device
            ├─ 查找 group, 没有则创建一个 iommu group, `dev->bus->iommu_ops->device_group(dev)`, 会调用 `viommu_device_group()` 分配一个 group
            │  └─ pci_device_group(dev); / generic_device_group(dev);
            ├─ struct iommu_domain *dom = __iommu_domain_alloc(dev->bus, iommu_def_domain_type); 给每个 iommu group 分配 IOMMU_DOMAIN_DMA 类型的 domain
	    │  ├─ struct iommu_domain *domain = bus->iommu_ops->domain_alloc(type); 调用 viommu_domain_alloc, 主要是分配空间并初始化
            │  │  ├─ struct viommu_domain *vdomain = kzalloc(sizeof(struct viommu_domain), GFP_KERNEL); 生成新的 vdomain
            │  │  ├─ vdomain->id = atomic64_inc_return_relaxed(&viommu_domain_ids_gen); 分配新 id
            │  │  ├─ vdomain->mappings = RB_ROOT; 每个 vdomain 的所有 mappings 构成 rb tree
	    │  ├─ domain->ops  = bus->iommu_ops;
	    │  ├─ domain->type = type;
	    │  └─ domain->pgsize_bitmap  = bus->iommu_ops->pgsize_bitmap;
	    ├─ group->default_domain = dom;
	    ├─ group->domain = dom;
            └─ iommu_group_add_device(group, dev); 将这个 device 添加到这个 iommu group
	       ├─ sysfs_create_link(&dev->kobj, &group->kobj, "iommu_group"); 创建软链接(`/sys/devices/pci总线ID/设备号/iommu_group -> `/sys/kernel/iommu_groups/xx`)
	       ├─ sysfs_create_link_nowarn(group->devices_kobj, &dev->kobj, device->name); 创建软链接(`/sys/kernel/iommu_groups/xx/devices/设备PCI号` -> `/sys/devices/pci总线ID/设备号`
	       ├─ dev->iommu_group = group; device 结构中包含的 iommu_group 对象会指向其所在的 group
	       ├─ iommu_group_create_direct_mappings(group), 给设备做DMA映射. 将设备对应的虚拟机地址空间段映射到物理地址空间
	       │  ├─ pg_size = 1UL << __ffs(domain->pgsize_bitmap); domain page size
	       │  ├─ iommu_get_resv_regions(dev, &mappings);, 获取设备的 mappings(iova), 调用 `viommu_ops.viommu_get_resv_regions`
	       │  │  ├─ struct iommu_resv_region *msi = iommu_alloc_resv_region(MSI_IOVA_BASE, MSI_IOVA_LENGTH, prot, IOMMU_RESV_MSI); 初始化这个一个 region 结构体, arm 上面需要这个 region 用于 map doorbell
      	       │  └─ list_for_each_entry(entry, &mappings, list), 遍历设备映射的地址段
	       │     ├─ start/end = ALIGN(entry->start/end, pg_size);, 根据 page size 对齐
	       │     └─ for (addr = start; addr < end; addr += pg_size), 每个 domain page 逐个 map
	       │        ├─ phys_addr = iommu_iova_to_phys(domain, addr), 看是否已经有了 iova -> pa 的 map, 如果得到物理地址, 说明已经有了 map, 则继续处理下一个 page. 会调用 viommu_iova_to_phy
	       │        │  ├─ interval_tree_iter_first(&viommu_domain->mappings, iova, iova); 在 vdomain rb tree 中查找 iova 所在的 node
	       │        │  ├─ struct viommu_mapping *mapping = container_of(node, struct viommu_mapping, iova); 得到对应的 vmapping
	       │        │  └─ paddr = mapping->paddr + (iova - mapping->iova.start);
	       │        └─ iommu_map(domain, addr, addr, pg_size, entry->prot), 没有 map 的则需要 map 下, 将每段虚拟地址空间都映射到相应的物理内存页上(va->pa), iova = paddr = addr, 所以初始化的 msi iova = pa
	       │           └─ domain->ops->map(domain, iova, paddr, pgsize, prot); 根据 iommu pgsize(pgsize), 逐个 page 进行map(当然这里是一个 page), 调用 viommu_map
	       │              ├─ struct viommu_domain *vdomain = to_viommu_domain(domain); 获取 vdomain
	       │              ├─ struct virtio_iommu_req_map req; 构建 map request 并初始化
	       │              ├─ address_space	= cpu_to_le32(vdomain->id); group 初始化时候分配的
	       │              ├─ viommu_tlb_map(vdomain, iova, paddr, size); (iova, size) 和 paddr 的 mapping 关系缓存起来
	       │              │  ├─ struct viommu_mapping *mapping = kzalloc(sizeof(*mapping), GFP_ATOMIC);
	       │              │  ├─ mapping->paddr = paddr; mapping->iova.start = iova; mapping->iova.last = iova + size - 1;
	       │              │  └─ interval_tree_insert(&mapping->iova, &vdomain->mappings); 插入树
	       │              └─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 map request, 忙等返回
	       ├─ list_add_tail(&device->list, &group->devices); 将 device 添加到 group 的 list 中
	       ├─ __iommu_attach_device(group->domain, dev); 调用 domain->ops->attach_dev(domain, dev), viommu_attach_dev
	       │  ├─ struct virtio_iommu_req_attach req; 创建 attach 请求
	       │  └─ viommu_send_req_sync(vdomain->viommu, &req); 同步给 back end 发送 attach request, 忙等返回
	       └─ blocking_notifier_call_chain(&group->notifier, IOMMU_GROUP_NOTIFY_ADD_DEVICE, dev); group notifier
```

初始化 virtio-iommu 中会涉及到两个 command, map 和 attach, backend 实现可以看 kvm tool 部分










qemu:

` virtio_iommu_device_reset()` -> `virtio_iommu_put_endpoint(VirtIOIOMMUEndpoint)` -> `virtio_iommu_detach_endpoint_from_domain(VirtIOIOMMUEndpoint); g_free(VirtIOIOMMUEndpoint)`