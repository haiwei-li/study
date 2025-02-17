

linux下提供了多个pci库以供应用程序访问. 下面就以最常见的为例, 从安装、使用和编译的角度分别进行说明. 

centos 中, pci 访问相关的库有:

```
libpciaccess.i686 : PCI access library
libpciaccess.x86_64 : PCI access library
libpciaccess-devel.i686 : PCI access library development package
libpciaccess-devel.x86_64 : PCI access library development package
pciutils.x86_64 : PCI bus related utilities
pciutils-devel.i686 : Linux PCI development library
pciutils-devel.x86_64 : Linux PCI development library
pciutils-devel-static.i686 : Linux PCI static library
pciutils-devel-static.x86_64 : Linux PCI static library
pciutils-libs.i686 : Linux PCI library
pciutils-libs.x86_64 : Linux PCI library
```

由于实际系统是 64bit 的, 并且以**静态库**的形式进行使用, 可以用下面的命令安装 pci lib 库: 

```
yum install libpciaccess.x86_64 libpciaccess-devel.x86_64 pciutils-devel-static.x86_64
```

安装完后, 可以看到相应的头文件已经最 `/usr/include` 下面了: 

```
[root@localhost include]# find ./ -name "pci"
./linux/pci.h
./linux/pci_regs.h
./linux/virtio_pci.h
./sys/pci.h
./pci
./pci/pci.h
./pciaccess.h
```

并且静态库也已经存在了: 

```
[root@localhost lib64]# find ./ -name "pci"
./kde4/kcm_pci.so
./pkgconfig/libpci.pc
./pkgconfig/pciaccess.pc
./libpci.so.3
./libpci.so.3.2.1
./libpciaccess.so.0
./libpciaccess.so.0.11.1
./libpci.so
./libpci.a
./libpciaccess.so
```

通过上面的输出可以看到, libpciaccess 只有动态库的形式, 而 libpci 既有动态库也有静态库, 这个和我们输入的 `yum install libpciaccess.x86_64 libpciaccess-devel.x86_64 pciutils-devel-static.x86_64` 命令是吻合的. 

使用

打开 `/usr/include/pci/pci.h`, 可以找到我们需要的函数: 

```cpp
u8 pci_read_byte(struct pci_dev , int pos) PCI_ABI; / Access to configuration space */
u16 pci_read_word(struct pci_dev *, int pos) PCI_ABI;
u32 pci_read_long(struct pci_dev *, int pos) PCI_ABI;
int pci_read_block(struct pci_dev *, int pos, u8 *buf, int len) PCI_ABI;
int pci_read_vpd(struct pci_dev *d, int pos, u8 *buf, int len) PCI_ABI;
int pci_write_byte(struct pci_dev *, int pos, u8 data) PCI_ABI;
int pci_write_word(struct pci_dev *, int pos, u16 data) PCI_ABI;
int pci_write_long(struct pci_dev *, int pos, u32 data) PCI_ABI;
int pci_write_block(struct pci_dev *, int pos, u8 *buf, int len) PCI_ABI;
```

打开 `/usr/include/pciaccess.h`, 也有可以访问配置空间的函数: 

```cpp
struct pci_io_handle *pci_device_open_io(struct pci_device *dev, pciaddr_t base,
pciaddr_t size);
struct pci_io_handle *pci_legacy_open_io(struct pci_device *dev, pciaddr_t base,
pciaddr_t size);
void pci_device_close_io(struct pci_device *dev, struct pci_io_handle *handle);
uint32_t pci_io_read32(struct pci_io_handle *handle, uint32_t reg);
uint16_t pci_io_read16(struct pci_io_handle *handle, uint32_t reg);
uint8_t pci_io_read8(struct pci_io_handle *handle, uint32_t reg);
void pci_io_write32(struct pci_io_handle *handle, uint32_t reg, uint32_t data);
void pci_io_write16(struct pci_io_handle *handle, uint32_t reg, uint16_t data);
void pci_io_write8(struct pci_io_handle *handle, uint32_t reg, uint8_t data);
```

从上面的两组函数接口来看, 可以看到 pciutils 需要初始化 `struct pci_dev`, 而 pciasscess 库需要初始化 `struct pci_io_handle *handle`. 那么该如何使用 pciutils 静态库呢, 通过继续阅读 `/usr/include/pci/pci.h`, 可以看到下面的函数声明和注释: 

```cpp
/* Initialize PCI access */
struct pci_access *pci_alloc(void) PCI_ABI;
void pci_init(struct pci_access *) PCI_ABI;
void pci_cleanup(struct pci_access *) PCI_ABI;

/* Scanning of devices */
void pci_scan_bus(struct pci_access *acc) PCI_ABI;
struct pci_dev pci_get_dev(struct pci_access *acc, int domain, int bus, int dev, int func) PCI_ABI; / Raw access to specified device */
void pci_free_dev(struct pci_dev *) PCI_ABI;
```

据此我们不难猜测出使用 pciutils 的代码流程, 并且根据头文件说明实现一个测试代码 `test_pcilib.c`:

```cpp
int main(void)
{
    int i = 0;
    int ret = 0;
    struct pci_access * myaccess;
    struct pci_dev * mydev;

    myaccess = pci_alloc();
    pci_init(myaccess);

    mydev = pci_get_dev(myaccess, 0, 6, 0, 0);

    for (i = 0; i < 256; i++) {
            ret = pci_read_byte(mydev, i);
            printf("%d: %02x\n", i, ret);
    }

    pci_free_dev(mydev);

    pci_cleanup(myaccess);

    return 0;
}
```

编译

因为已经知道上面的代码依赖于libpci.a静态库, 为此可用用下面的gcc命令进行简单编译: 

```
[root@localhost testcases]# gcc -c -o test_pci.o test_pcilib.c
[root@localhost testcases]# gcc -Wall -o test_pci test_pci.o /usr/lib64/libpci.a
[root@localhost testcases]# ./test_pci
0: b5
```