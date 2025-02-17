
https://blog.csdn.net/chuck_huang/article/details/78733543

https://blog.csdn.net/u010383937/article/details/78595874

## 1. memblock 介绍

memblock 内存管理机制主要用于 Linux Kernel 启动阶段(kernel 启动 -> kernel 通用内存管理初始化完成.)或者可以认为 `free_initmem` 为止.在启动阶段,内存分配器并不需要很复杂,memblock 是**基于静态数组**,采用的**逆向最先适配**的分配策略.

## 2. memblock 数据结构

### 2.1 memblock

memblock 内存管理的核心数据结构

```
struct memblock {
    bool bottom_up;  /* is bottom up direction? */
    phys_addr_t current_limit;
    struct memblock_type memory;
    struct memblock_type reserved;
#ifdef CONFIG_HAVE_MEMBLOCK_PHYS_MAP
    struct memblock_type physmem;
#endif
};
```

- `bottom_up` 内存分配的方向

- `current_limit` 内存分配最大限制值

memblock 的内存分为 3 类, memory, reserved, 和 physmem

- memory 可用的内存的集合

- reserved 已分配出去内存的集合

### 2.2 memblock_type

```
struct memblock_type {
    unsigned long cnt;  /* number of regions */
    unsigned long max;  /* size of the allocated array */
    phys_addr_t total_size; /* size of all regions */
    struct memblock_region *regions;
    char *name;
};
```

memblock_type 用于描述在当前的 memblock 中**此类型**的 memory region 的数量

