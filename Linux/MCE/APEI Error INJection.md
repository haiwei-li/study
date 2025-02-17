

echo 0 4 1 7 > /proc/sys/kernel/printk

CONFIG_DEBUG_FS
CONFIG_ACPI_APEI
CONFIG_ACPI_APEI_EINJ


modprobe mce_inject
modprobe einj

echo 0x69000000 > param1

echo $((-1 << 12)) > param2

echo 0x8 > error_type

echo 1 > error_inject

https://www.kernel.org/doc/html/latest/firmware-guide/acpi/apei/einj.html

