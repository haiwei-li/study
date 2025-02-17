
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. qemu-kvm 相关程序图](#1-qemu-kvm-相关程序图)
- [2. qemu-kvm 创建的三种文件描述符: kvm_fd, vm_fd, vcpu_fd](#2-qemu-kvm-创建的三种文件描述符-kvm_fd-vm_fd-vcpu_fd)
- [3. qemu-kvm 虚拟设备创建流程](#3-qemu-kvm-虚拟设备创建流程)
- [4. qemu-kvm 网络虚拟化](#4-qemu-kvm-网络虚拟化)
- [5. qemu-kvm 网络虚拟化流程](#5-qemu-kvm-网络虚拟化流程)
- [6. qemu-kvm 网络数据流走向](#6-qemu-kvm-网络数据流走向)
- [7. qemu_kvm_guest 之间切换流程](#7-qemu_kvm_guest-之间切换流程)
- [8. vE1000 流程](#8-ve1000-流程)
- [9. virtio-net 依赖关系](#9-virtio-net-依赖关系)
- [10. virtio-net 前端驱动实现流程](#10-virtio-net-前端驱动实现流程)
- [11. qemu-kvm 虚拟机热迁移](#11-qemu-kvm-虚拟机热迁移)
- [12. ksm 合并内存页实现流程](#12-ksm-合并内存页实现流程)
- [13. 参考](#13-参考)

<!-- /code_chunk_output -->

阅读 qemu-kvm 代码过程中, 作了一点总结, 画成流程图, 如下(后续还会画 qemu-kvm 中断虚拟化, 内存虚拟化等一些流程图):

# 1. qemu-kvm 相关程序图

![2020-02-21-15-22-28.png](./images/2020-02-21-15-22-28.png)

# 2. qemu-kvm 创建的三种文件描述符: kvm_fd, vm_fd, vcpu_fd

![2020-02-21-15-22-45.png](./images/2020-02-21-15-22-45.png)

# 3. qemu-kvm 虚拟设备创建流程

![2020-02-21-15-23-02.png](./images/2020-02-21-15-23-02.png)

# 4. qemu-kvm 网络虚拟化

![2020-02-21-15-24-40.png](./images/2020-02-21-15-24-40.png)

# 5. qemu-kvm 网络虚拟化流程

![2020-02-21-15-24-58.png](./images/2020-02-21-15-24-58.png)

# 6. qemu-kvm 网络数据流走向

![2020-02-21-15-26-53.png](./images/2020-02-21-15-26-53.png)

# 7. qemu_kvm_guest 之间切换流程

![2020-02-21-15-27-12.png](./images/2020-02-21-15-27-12.png)

# 8. vE1000 流程

![2020-02-21-15-28-14.png](./images/2020-02-21-15-28-14.png)

# 9. virtio-net 依赖关系

![2020-02-21-15-28-29.png](./images/2020-02-21-15-28-29.png)

# 10. virtio-net 前端驱动实现流程

![2020-02-21-15-30-15.png](./images/2020-02-21-15-30-15.png)

# 11. qemu-kvm 虚拟机热迁移

![2020-02-21-15-30-38.png](./images/2020-02-21-15-30-38.png)

# 12. ksm 合并内存页实现流程

![2020-02-21-15-30-54.png](./images/2020-02-21-15-30-54.png)

# 13. 参考

https://blog.csdn.net/u010375747/article/details/8870054