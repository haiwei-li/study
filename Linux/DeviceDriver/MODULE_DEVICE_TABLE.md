
一般用在热插拔的设备驱动中

`pci_device_id`, **PCI 设备类型**的**标识符**. 在`include/linux/mod_devicetable.h`头文件中定义.

```cpp
// include/linux/mod_devicetable.h
struct pci_device_id {
        __u32 vendor, device;           /* Vendor and device ID or PCI_ANY_ID*/
        __u32 subvendor, subdevice;     /* Subsystem ID's or PCI_ANY_ID */
        __u32 class, class_mask;        /* (class,subclass,prog-if) triplet */
        kernel_ulong_t driver_data;     /* Data private to the driver */
};
```

PCI 设备的**vendor**、**device**和**class**的值都是**预先定义**好的, 通过这些参数可以**唯一确定设备厂商和设备类型**. 这些 PCI 设备的标准值在`include/linux/pci_ids.h`头文件中定义.

`pci_device_id`需要导出到**用户空间**, 使**模块装载系统**在**装载模块**时知道**什么模块**对应**什么硬件设备**. 宏`MODULE_DEVICE_TABLE()`完成该工作.

设备 id 一般用数组形式. 如:

```cpp
static struct pci_device_id rtl8139_pci_tbl[] = {
        {0x10ec, 0x8139, PCI_ANY_ID, PCI_ANY_ID, 0, 0, RTL8139 },
        ....
};
MODULE_DEVICE_TABLE(pci, rtl8139_pci_tbl);

static struct pci_device_id e1000_pci_tbl[] = {
    { PCI_DEVICE(PCI_VENDOR_ID_INTEL, 0x1000) },
    { PCI_DEVICE(PCI_VENDOR_ID_INTEL, 0x1001) },
    {0,}
};
MODULE_DEVICE_TABLE(pci, e1000_pci_tbl);
```

该宏生成一个名为`__mod_pci_device_table`的局部变量, 该变量指向**第二个参数**.

内核构建时, **depmod 程序**会在**所有模块**中搜索符号`__mod_pci_device_table`, 把数据(**设备列表**)从模块中抽出, 添加到映射文件`/lib/modules/KERNEL_VERSION/modules.pcimap`中, 当 depmod 结束之后, **所有的 PCI 设备**连同他们的**模块名字**都被**该文件列出**. 当内核告知**热插拔系统**一个**新的 PCI 设备被发现**时, 热插拔系统使用`modules.pcimap`文件来找寻恰当的驱动程序.

`MODULE_DEVICE_TABLE`的第一个参数是**设备的类型**, 如果是**USB 设备**, 那自然是**usb**(如果是 PCI 设备, 那将是 pci, 这两个子系统用同一个宏来注册所支持的设备). 后面一个参数是**设备表**, 这个设备表的**最后一个元素**是**空**的, 用于**标识结束**.

例: 假如代码定义了`USB_SKEL_VENDOR_ID`是 `0xfff0`, `USB_SKEL_PRODUCT_ID`是`0xfff0`, 也就是说, 当有**一个设备**接到**集线器**时, **usb 子系统**就会**检查**这个设备的 `vendor ID`和`product ID`, 如果他们的值是 0xfff0 时, 那么子系统就会调用这个模块作为设备的驱动.

http://www.ibm.com/developerworks/cn/linux/l-usb/index2.html

当 usb 设备插入时, 为了使`linux-hotplug`(Linux 中**PCI**、**USB**等**设备热插拔**支持)系统**自动装载驱动程序**, 你需要创建一个`MODULE_DEVICE_TABLE`. 代码如下(这个模块仅支持**某一特定设备**):

```cpp
// drivers/usb/usb-skeleton.c
/* table of devices that work with this driver */
static struct usb_device_id skel_table [] = {
    { USB_DEVICE(USB_SKEL_VENDOR_ID,
      USB_SKEL_PRODUCT_ID) },
    { }                      /* Terminating entry */
};
MODULE_DEVICE_TABLE (usb, skel_table);
```

`USB_DEVICE`宏利用**厂商 ID**和**产品 ID**为我们提供了一个**设备的唯一标识**. 当系统插入一个**ID 匹配**的**USB 设备**到**USB 总线**时, 驱动会在**USB core**中注册. 驱动程序中**probe 函数**也就会被调用. `usb_device` 结构指针、接口号和接口 ID 都会被传递到函数中.

```cpp
static void * skel_probe(struct usb_device *dev,
        unsigned int ifnum, const struct usb_device_id *id)
```

驱动程序需要确认插入的设备是否可以被接受, 如果不接受, 或者在初始化的过程中发生任何错误, probe 函数返回一个 NULL 值. 否则返回一个**含有设备驱动程序状态**的指针. 通过这个指针, 就可以访问所有结构中的回调函数.


例如

```cpp
static const struct x86_cpu_id vmx_cpu_id[] = {
    X86_FEATURE_MATCH(X86_FEATURE_VMX),
    {}
};
MODULE_DEVICE_TABLE(x86cpu, vmx_cpu_id);
```


# 参考

https://www.cnblogs.com/ancongliang/p/7838469.html

http://www.ibm.com/developerworks/cn/linux/l-usb/index2.html