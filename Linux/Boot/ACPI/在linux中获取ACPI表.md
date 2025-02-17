
**ACPI**, 全称又叫 `Advanced Configuration and Power Management Interface`,  高级配置和电源管理接口. BIOS 过程中就会生成这些表格, 然后 Linux 系统中很多时候需要访问 ACPI 表格来获得一些硬件的内存地址.

所有的 ACPI 表位于目录 "`/sys/firmware/acpi/tables/`"

1. 复制表到 `*.aml`

`sudo cat /sys/firmware/acpi/tables/DSDT > DSDT.aml`

2. 安装软件 iasl

`sudo apt-get install iasl acpica-tools`

3. 进行转换

`iasl -d DSDT.aml`

这样你就可以在当前目录下发现你所要的 ACPI 表文件

`DSDT.dsl`


