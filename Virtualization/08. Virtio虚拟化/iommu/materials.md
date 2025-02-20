
Virtio-IOMMU 驱动程序现在使用 Linux 5.14 内核的 x86/x86_64硬件工作.  是 Virtio - Iommu 驱动程序 (合并在 Linux 5.3),  在几年前在树外工作后,  最初专注于 AArch64 的准虚拟 Iommu 硬件. 现在, 2021 年 Linux 5.14 的 VirtIO-IOMMU 代码也已调整为适用于 x86 英特尔/AMD 硬件. Virtio-IOMMU 可以处理模拟和准虚拟化设备的管理. ACPI 虚拟 I/O 翻译表 (VIOT) 用于描述准虚拟平台的拓扑, 在此案例中, x86 用于描述 virtio-iommu 和端点之间的关系.  Linux 5.14 的 IOMMU 更改还包括 Arm SMMU 更新、英特尔 VT-d 现在支持异步嵌套功能以及各种其他改进. 还有一个新的是"amd_iommu=force_enable"内核启动选项, 用于在通常有问题的平台上强制 IOMMU.


Virtio IOMMU 是一种半虚拟化设备, 允许通过 virtio-mmio 发送 IOMMU 请求, 如map/unmap.

使用VirtIO标准实现不同虚拟化组件的跨管理程序兼容性, 有一个虚拟IOMMU设备现在由Linux 5.3内核中的工作驱动程序支持.


VirtIO规范提供了v0.8规范中的虚拟IOMMU设备, 该规范与平台无关, 并以有效的方式管理来自仿真或物理设备的直接存储器访问.


Linux VirtIO-IOMMU驱动程序的修补程序自去年以来一直在浮动, 而本周最后一个Linux 5.3内核合并窗口已经排队等待登陆.  这个VirtIO IOMMU驱动程序将作为下一个内核的VirtIO/Vhost修复/功能/性能工作的一部分.

QEMU正在等待补丁来支持这个VirtIO IOMMU功能.


# Paper

vIOMMU: Efficient IOMMU Emulation, 2011

https://www.usenix.org/conference/usenixatc11/viommu-efficient-iommu-emulation

https://www.usenix.org/legacy/events/atc11/tech/final_files/Amit.pdf

# KVM Forum

https://kvmforum2017.sched.com/event/BnoZ/viommuarm-full-emulation-and-virtio-iommu-approaches-eric-auger-red-hat-inc


virtio-iommu 最早是 2017 年提出来的

[2017] vIOMMU/ARM: Full Emulation and virtio-iommu Approaches by Eric Auger: https://www.youtube.com/watch?v=7aZAsanbKwI ,

https://events.static.linuxfound.org/sites/events/files/slides/viommu_arm_upload_1.pdf


# Linux

KVM patchsets: https://patchwork.kernel.org/project/kvm/list/?submitter=Jean-Philippe%20Brucker&state=*&archive=both&param=2&page=3

virtio-iommu: a paravirtualized IOMMU

* [RFC 0/3]: a paravirtualized IOMMU, [spinics](https://www.spinics.net/lists/kvm/msg147990.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-1-jean-philippe.brucker__33550.5639938221$1491592770$gmane$org@arm.com/)
  * [RFC 1/3] virtio-iommu: firmware description of the virtual topology: [spinics](https://www.spinics.net/lists/kvm/msg147991.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-2-jean-philippe.brucker__38031.8755437203$1491592803$gmane$org@arm.com/)
  * [RFC 2/3] virtio-iommu: device probing and operations: [spinice](https://www.spinics.net/lists/kvm/msg147992.html), [lore kernel](https://lore.kernel.org/all/20170407191747.26618-3-jean-philippe.brucker@arm.com/)
  * [RFC 3/3] virtio-iommu: future work: https://www.spinics.net/lists/kvm/msg147993.html

* [RFC PATCH linux] iommu: Add virtio-iommu driver, [lore kernel](https://lore.kernel.org/all/20170407192314.26720-1-jean-philippe.brucker@arm.com/), [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/)

* [RFC PATCH kvmtool 00/15] Add virtio-iommu, [lore kernel](https://lore.kernel.org/all/20170407192455.26814-1-jean-philippe.brucker@arm.com/)


* RFC 0.4: https://www.spinics.net/lists/kvm/msg153881.html
  * [RFC] virtio-iommu v0.4 - IOMMU Device: https://www.spinics.net/lists/kvm/msg153882.html
  * [RFC] virtio-iommu v0.4 - Implementation notes: https://www.spinics.net/lists/kvm/msg153883.html






Add virtio-iommu driver

> (2017 ~ 2019): 前几个版本在 kvm 中, 后面的在 pci 中

* RFC: [patchwork](https://patchwork.kernel.org/project/kvm/patch/20170407192314.26720-1-jean-philippe.brucker@arm.com/),
* RFC v2: [patchwork](https://patchwork.kernel.org/project/kvm/patch/20171117185211.32593-2-jean-philippe.brucker@arm.com/),
* v1: https://www.spinics.net/lists/kvm/msg164322.html , https://patchwork.kernel.org/project/kvm/patch/20180214145340.1223-2-jean-philippe.brucker@arm.com/
* v2: https://www.spinics.net/lists/kvm/msg170655.html , https://patchwork.kernel.org/project/kvm/patch/20180621190655.56391-3-jean-philippe.brucker@arm.com/
* v3: https://patchwork.kernel.org/project/linux-pci/cover/20181012145917.6840-1-jean-philippe.brucker@arm.com/
* v4: https://patchwork.kernel.org/project/linux-pci/cover/20181115165234.43990-1-jean-philippe.brucker@arm.com/
* v5: https://patchwork.kernel.org/project/linux-pci/cover/20181122193801.50510-1-jean-philippe.brucker@arm.com/
* v6: https://patchwork.kernel.org/project/linux-pci/cover/20181211182104.18241-1-jean-philippe.brucker@arm.com/
* v7: [patchwork](https://patchwork.kernel.org/project/linux-pci/patch/20190115121959.23763-6-jean-philippe.brucker@arm.com/),
* v8(Final version): [patchwork](https://patchwork.kernel.org/project/linux-pci/patch/20190530170929.19366-6-jean-philippe.brucker@arm.com/),



Add virtio-iommu device specification(virtio-spce, https://github.com/oasis-tcs/virtio-spec/blob/master/virtio-iommu.tex):

* https://lists.oasis-open.org/archives/virtio-comment/201901/msg00017.html




virtio-iommu on non-devicetree platforms/virtio-iommu on x86 and non-devicetree platforms/Add virtio-iommu built-in topology

> (2019 ~ 2020):
>
> Hardware platforms usually describe the IOMMU topology using either device-tree pointers or vendor-specific ACPI tables.

* RFC: [virtio-iommu on non-devicetree platforms](https://patchwork.kernel.org/project/linux-pci/cover/20191122105000.800410-1-jean-philippe@linaro.org/),
* v1: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200214160413.1475396-1-jean-philippe@linaro.org/),
* v2: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200228172537.377327-1-jean-philippe@linaro.org/),
* v3: [patchwork](https://patchwork.kernel.org/project/linux-pci/cover/20200821131540.2801801-1-jean-philippe@linaro.org/),



Add support for ACPI VIOT

> (2021, linux-acpi), 给 acpi viot table 添加一个driver, 从而可以在non-devicetree 平台(比如x86)使用 virtio-iommu
* RFC:
* V1: https://patchwork.kernel.org/project/linux-acpi/cover/20210316191652.3401335-1-jean-philippe@linaro.org/
* V2: https://patchwork.kernel.org/project/linux-acpi/cover/20210423113836.3974972-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/linux-acpi/cover/20210602154444.1077006-1-jean-philippe@linaro.org/
* v4: https://patchwork.kernel.org/project/linux-acpi/cover/20210610075130.67517-1-jean-philippe@linaro.org/
* v5: https://patchwork.kernel.org/project/linux-acpi/cover/20210618152059.1194210-1-jean-philippe@linaro.org/
* v6:




# qemu

https://patchwork.kernel.org/project/qemu-devel/list/?state=*&q=virtio-iommu&archive=both&param=2&page=3


VIRTIO-IOMMU device

> 2017 ~ 2020, implements the QEMU virtio-iommu device.
> 必须 virtio-iommu on non-devicetree platforms 的 kernel patchset 合入才生效

* RFC v7: https://patchwork.kernel.org/project/qemu-devel/cover/1533586484-5737-1-git-send-email-eric.auger@redhat.com/
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20190730172137.23114-1-eric.auger@redhat.com/
* v15: https://patchwork.kernel.org/project/qemu-devel/cover/20200208120022.1920-1-eric.auger@redhat.com/
* v16: https://patchwork.kernel.org/project/qemu-devel/cover/20200214132745.23392-1-eric.auger@redhat.com/





virtio-iommu: VFIO integration

> 2017 ~ 2020.
> This patch series allows PCI pass-through using virtio-iommu.

* RFC: https://patchwork.kernel.org/project/qemu-devel/patch/1499927922-32303-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v2: https://patchwork.kernel.org/project/qemu-devel/patch/1500017104-3574-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v3: https://patchwork.kernel.org/project/qemu-devel/patch/1503312534-6642-3-git-send-email-Bharat.Bhushan@nxp.com/
* RFC v5: https://patchew.org/QEMU/20181127064101.25887-1-Bharat.Bhushan@nxp.com/
*
* v10: https://patchwork.kernel.org/project/qemu-devel/cover/20201008171558.410886-1-jean-philippe@linaro.org/
* v11: https://patchwork.kernel.org/project/qemu-devel/cover/20201030180510.747225-1-jean-philippe@linaro.org/




virtio-iommu: Built-in topology and x86 support (还未合入)

> 2020

v1: https://patchwork.kernel.org/project/qemu-devel/cover/20200821162839.3182051-1-jean-philippe@linaro.org/




virtio-iommu: Add ACPI support (还未合入)

> 2021

* v1: https://patchwork.kernel.org/project/qemu-devel/cover/20210810084505.2257983-1-jean-philippe@linaro.org/
* v2: https://patchwork.kernel.org/project/qemu-devel/cover/20210903143208.2434284-1-jean-philippe@linaro.org/
* v3: https://patchwork.kernel.org/project/qemu-devel/cover/20210914142004.2433568-1-jean-philippe@linaro.org/
* v4: https://patchwork.kernel.org/project/qemu-devel/cover/20211001173358.863017-1-jean-philippe@linaro.org/
* v5: https://patchwork.kernel.org/project/qemu-devel/cover/20211020172745.620101-1-jean-philippe@linaro.org/
*








Add dynamic iommu backed bounce buffers

https://lwn.net/Articles/865617/

https://lwn.net/ml/linux-kernel/20210806103423.3341285-1-stevensd@google.com/

device add, 触发

`iommu_bus_notifier()`("drivers/iommu/iommu.c") -> `iommu_probe_device()` -> `ops->probe_finalize` -> `iommu_setup_dma_ops()` -> `iommu_dma_init_domain`




# cloud-hypervisor

可以参见 cloud-hypervisor 的代码

https://github.com/cloud-hypervisor/cloud-hypervisor.git

# maintainer info

Jean-Philippe Brucker

author personal site: https://jpbrucker.net/

qemu branch: https://jpbrucker.net/git/qemu/log/?h=virtio-iommu/acpi

SPEC: https://jpbrucker.net/virtio-iommu/spec/


# other

IOMMU(八)-vIOMMU: https://zhuanlan.zhihu.com/p/403727428










# 6. virtio-iommu on non-devicetree platforms

IOMMU 用来管理来自设备的内存访问. 所以 guest 需要在 endpoint 发起 DMA 之前初始化 IOMMU.

这是一个已解决的问题: firmware 或 hypervisor 通过 DT 或 ACPI 表描述设备依赖关系, 并且 endpoint 的探测(probe)被推迟到 IOMMU 被 probe 后. 但是:

1. ACPI 每个 vendor 有一张表(DMAR 代表 Intel, IVRS 代表 AMD, IORT 代表 Arm). 在我看来, IORT 更容易扩展, 因为我们只需要引入一个新的 node type. Linux IORT 驱动程序中没有对 Arm 架构的依赖, 因此它可以很好地与 CONFIG_X86 配合使用.

然而, 有一些其他担心. 其他操作系统供应商觉得有义务实施这个新的节点, 所以Arm建议引入另一个ACPI表, 可以包装任何 DMAR, IVRS 和 IORT 扩展它与新的虚拟 node.此 VIOT 表规格的草稿可在 http://jpbrucker.net/virtio-iommu/viot/viot-v5.pdf

而且这可能会增加碎片化, 因为 guest 需要实施或修改他们对所有 DMAR , IVRS 和 IORT 的支持. 如果我们最终做 VIOT, 我建议把它限制在 IORT .

2. virtio 依赖 ACPI 或 DT. 目前 hypervisor (Firecracker, QEMU microsvm, kvmtool) 并没有实现.

建议将拓扑描述嵌入设备中.


# 7. VIOT

Virtual I/O Translation table (VIOT) 描述了半虚设备的 I/O 拓扑信息.

目前描述了 virtio-iommu 和它管理的设备的拓扑信息.

经过讨论:

* 对于 non-devicetree 平台, 应该使用 ACPI Table.
* 对于既没有 devicetree, 又没有 ACPI 的 platform, 可以在设备中内置一个使用大致相同格式的结构

# 8. virtio-iommu spec

virtio-iommu 设备管理多个 endpoints 的 DMA 操作.

它既可以作为物理 IOMMU 的代理来管理分配给虚拟机的物理设备(透传), 也可以作为一个虚拟 IOMMU 来管理模拟设备和半虚拟化设备.

virtio-iommu 驱动程序首先使用特定于平台的机制发现由 virtio-iommu 设备管理的 endpoints.然后 virtio-iommu 驱动发送请求为这些 endpoints 创建虚拟地址空间和虚拟地址到物理地址映射关系.

在最简单的形式中, virtio-iommu 支持四种请求类型:

1. 创建一个 domain 并且 attach 一个 endpoint 给它.

`attach(endpoint=0x8, domain=1)`

2. 创建 guest-visual address 到 guest-physical address 的 mapping 关系

`map(domain=1, virt_start=0x1000, virt_end=0x1fff, phys=0xa000, flags=READ)`

> Endpoint 0x8, 一个硬件 PCI endpoint, 假设 BDF 是 `00: 01.0`, 能够读取的一个虚拟机 GVA 范围是 `0x1000 ~ 0x1fff`, 而在这个范围的访问会被 vIOMMU 翻译到 HPA 范围是 `0xa000 ~`.

3. 移除 mapping 关系

`unmap(domain=1, virt_start=0x1000, virt_end=0x1fff)`

> Endpoint 0x8 对地址 `0x1000 ~ 0x1fff` 的访问会被拒绝.

4. detach 一个 endpoint 并且删除 domain

`detach(endpoint=0x8, domain=1)`

> 这里的 domain 就是一个 viommu, 类似于 vfio_domain 概念, 就是最初的 RFC 中的 vIOMMU 1/2