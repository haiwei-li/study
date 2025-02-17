伙伴系统的初始化
=======

| 日期 | 内核版本 | 架构| 作者 | GitHub| CSDN |
| ------- |:-------:|:-------:|:-------:|:-------:|:-------:|
| 2016-06-14 | [Linux-4.7](http://lxr.free-electrons.com/source/?v=4.7) | X86 & arm | [gatieme](http://blog.csdn.net/gatieme) | [LinuxDeviceDrivers](https://github.com/gatieme/LDD-LinuxDeviceDrivers) | [Linux 内存管理](http://blog.csdn.net/gatieme/article/category/6225543) |


#1	前景回顾
------


##1.1	启动阶段的内存初始化
-------

之前我们讲解了系统内存管理初始化的第二阶段(buddy 的初始化), 但是我们讲解的很粗糙, 我们仅仅讲解了内存管理的主要流程创建


```cpp
start_kernel()
    |---->page_address_init()
    |     考虑支持高端内存
    |     业务: 初始化 page_address_pool 链表;
    |          将 page_address_maps 数组元素按索引降序插入
    |          page_address_pool 链表;
    |          初始化 page_address_htable 数组.
    |
    |---->setup_arch(&command_line);
    |     初始化特定体系结构的内容
    	  |
    	  |---->arm64_memblock_init( );
          |     初始化引导阶段的内存分配器 memblock
          |
          |---->paging_init();
          |     分页机制初始化
          |
          |---->bootmem_init();
          |     始化内存数据结构包括内存节点, 内存域和页帧 page
                |
                |---->arm64_numa_init();
                |     支持 numa 架构
                |
                |---->zone_sizes_init(min, max);
                    来初始化节点和管理区的一些数据项
                    |
                    |---->free_area_init_node
                    |   初始化内存节点
                    |
                        |---->free_area_init_core
                            |	初始化 zone
                            |
                            |---->memmap_init
                            |	初始化 page 页面
                |
                |---->memblock_dump_all();
                |   初始化完成, 显示 memblock 的保留的所有内存信息
         	   |
    |---->build_all_zonelist()
    |     为系统中的 zone 建立后备 zone 的列表.
    |     所有 zone 的后备列表都在
    |     pglist_data->node_zonelists[0]中;
    |
    |     期间也对 per-CPU 变量 boot_pageset 做了初始化.
    |
```


```cpp
    |---->page_alloc_init()
         |---->hotcpu_notifier(page_alloc_cpu_notifier, 0);
         |     不考虑热插拔 CPU
         |
    |---->pidhash_init()
    |     详见下文.
    |     根据低端内存页数和散列度, 分配 hash 空间, 并赋予 pid_hash
    |
    |---->vfs_caches_init_early()
          |---->dcache_init_early()
          |     dentry_hashtable 空间, d_hash_shift, h_hash_mask 赋值;
          |     同 pidhash_init();
          |     区别:
          |         散列度变化了(13 - PAGE_SHIFT);
          |         传入 alloc_large_system_hash 的最后参数值为 0;
          |
          |---->inode_init_early()
          |     inode_hashtable 空间, i_hash_shift, i_hash_mask 赋值;
          |     同 pidhash_init();
          |     区别:
          |         散列度变化了(14 - PAGE_SHIFT);
          |         传入 alloc_large_system_hash 的最后参数值为 0;
          |解 buddy 的内部机理,

```



我们只在特定于体系结构的代码中看到了内核如何检测系统中的可用内存. 与高层数据结构(如内存域和结点)的关联, 则需要根据该信息构建. 我们知道, 体系结构相关代码需要在启动期间建立以下信息:

*	系统中各个内存域的页帧边界, 保存在 max_zone_pfn 数组

*	各结点页帧的分配情况, 保存在全局变量 early_node_map 中



##1.2	内存节点的初始化
-------




##1.3	今日内容(buddy 的初始化)
-------


