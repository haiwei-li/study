
当用户态程序需要使用pci设备的相关接口时, 可借助于libpciaccess这一库函数. 

# 源码

https://gitlab.freedesktop.org/xorg/lib/libpciaccess.git/

# 使用



# demo

## pci_device_map_range

Map the specified memory range so that it can be accessed by the CPU.

已知 IGD(Intel Graphix Device) bar0 的前 2MB 空间为 mmio. 当需要在用户态程序读写 mmio 寄存器时, 可以借助于pci_device_map_range, 将物理上的 2MB mmio 空间映射到 2MB 的用户虚拟地址空间. 最终, 通过读写用户虚拟地址空间, 就可以操作真实的 mmio 寄存器了. 

具体用法可以参考 passthrough.c 中 init_msix_table. 其中, msix_table_read 与 msix_table_write 需要重点关注. 