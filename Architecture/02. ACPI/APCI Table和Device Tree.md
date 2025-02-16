
ACPI Table 与 Windows 的关系 犹如 Device Tree 与 embedded-Linux 的关系.

ACPI SPEC 定义了 `ACPI-compatible OS` 与 **BIOS** 之间的接口, ACPI Tables 就是 BIOS 提供给 OS 的硬件配置数据包括系统硬件的电源管理和配置管理.

BIOS 在 **POST 过程**中将 RSDP 存在 0xE0000 -- 0xFFFFF 的内存空间中然后 Move RSDT/XSDT, FADT, DSDT 到 ACPI Recleam Area, Move FACS 到 ACPI NVS Area 最后填好表的 Entry 链接和 Checksum.

控制权交给 OS 之后由 OS 来开启 ACPI Mode 首先在内存中搜寻 ACPI Table 然后写 ACPI_Enable 到 SMI_CMDSCI_EN 也会被 HW 置起来.

ACPI Tables 根据存储的位置可以分为:

1) RSDP 位于 F 段用于 OSPM 搜索 ACPI TableRSDP 可以定位其他所有 ACPI Table

2) FACS 位于 ACPI NVS 内存用于系统进行 S3 保存的恢复指针内存为 NV Store

3) 剩下所有 ACPI Table 都位于 ACPI Reclaim 内存进入 OS 后内存可以释放

ACPI Table 根据版本又分为 1.0B2.03.04.0.

2.0 以后支持了 64-bit 的地址空间因此几个重要的 Table 会不大一样比如: RSDPRSDTFADTFACS. 简单的列举一下不同版本的 ACPI Table:

1) ACPI 1.0B: RSDP1RSDTFADT1FACS1DSDTMADTSSDTHPETMCFG 等

2) ACPI 3.0 : RSDP3RSDTXSDTFADT3FACS3DSDTMADTHPETMCFGSSDT 等

以系统支持 ACPI3.0 为例子说明系统中 ACPI table 之间的关系如图:

