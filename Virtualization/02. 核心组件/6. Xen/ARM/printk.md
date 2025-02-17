
# 介绍

只有在 `CONFIG_DEBUG=y` 或者处于专家（EXPERT）模式时，才能启用早期打印（Early printk）功能。如果你正在调试在控制台初始化之前执行的代码，那么可能需要启用该功能。

请注意，选择此选项会将 Xen 限制为仅使用单个 UART 定义。尝试在不同平台上启动 Xen 镜像将无法成功，因此对于打算具备可移植性的 Xen 而言，不应启用此选项。

# 如何启用早期printk

在 Kconfig 的调试选项中，从早期打印（Early printk）的可选方案里选择通过 UART 实现早期打印的选项。之后，你需要根据所选的驱动程序来设置其他选项。

更多信息请参考：xen.git:docs/misc/arm/early-printk.txt。

## 平台预定义的配置

当你不确定时，可以参考以下预定义的平台配置列表来设置早期打印功能。

### CONFIG_EARLY_UART_BASE_ADDRESS



### EARLY_UART_PL011_BAUD_RATE


### EARLY_UART_8250_REG_SHIFT


# reference

https://wiki.xenproject.org/wiki/Xen_on_ARM_Early_Printk
