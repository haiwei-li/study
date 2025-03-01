https://richardweiyang-2.gitbook.io/understanding_qemu

* 设备模型
  * 设备类型注册
  * 设备类型初始化
  * 设备实例化
  * DeviceClass实例化细节
  * 面向对象的设备模型
  * 接口
  * 类型、对象和接口之间的转换
  * PCDIMM
    * PCDIMM类型
    * PCDIMM实例
    * 插入系统
    * 创建ACPI表
    * NVDIMM
* 地址空间
  * 从初始化开始
  * MemoryRegion
  * AddressSpace Part1
  * FlatView
  * RAMBlock
  * AddressSpace Part2](address_space/06-AddressSpace2.md)
  * 眼见为实
  * 添加MemoryRegion
* APIC
  * 纯Qemu模拟
  * Qemu/kernel混合模拟
  * APICV
* Live Migration
  * 从用法说起
  * 整体架构
  * VMStateDescription
  * 内存热迁移
  * postcopy
* FW_CFG
  * 规范解读
  * Linux Guest
  * SeaBios
* Machine
  * MachineType
  * PCMachine
* CPU
  * TYPE_CPU
  * X86_CPU
* MemoryBackend
  * MemoryBackend类层次结构
  * MemoryBackend初始化流程
