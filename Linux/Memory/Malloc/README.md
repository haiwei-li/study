
malloc 源码分析: https://blog.csdn.net/conansonic/article/details/50186489

大家好, 今天给大家分享的是一个我参考 Linux 内核在用户空间实现的 VMLLOC 内存分配器, 该分配器的的特点就是分配虚拟地址连续而物理地址不连续. 这个项目实现了 VMALLOC 的核心逻辑, 包括了红黑树以及页表等. 在这个项目中我实现了一个软件虚拟的 mmu, 大家对 VMALLOC 内存分配器感兴趣的可以参考下面链接直接实践 https://github.com/BiscuitOS/HardStack/tree/master/Memory-Allocator/vmalloc/vmalloc_userspace

@All
大家好, 今天给大家分享的是我在用户空间实现的 Linux Kmap 内存分配器, 在内核中, kmap 用于将高端物理页映射到系统的虚拟地址上, 可映射的虚拟地址包括两部分, 一部分就是 PAGE_OFFSET 之前的 2M 虚拟地址, 另外一部分是 FIXMAP 虚拟地址区间内. 这次提供了 kmap/kunmap 和 kmap_atomic/kunmap_atomic 的实现逻辑以及使用实例. kmap() 是将高端页映射到 PAGE_OFFSET 之前的 2M 虚拟地址, 在驱动中经常使用. kmap_atomic() 函数则可以将高端页映射到 FIXMAP 区域的虚拟地址上, 有想研究其实现原理的童鞋可以参考 GITHUB: https://github.com/BiscuitOS/HardStack/tree/master/Memory-Allocator/Kmap/kmap_userspace