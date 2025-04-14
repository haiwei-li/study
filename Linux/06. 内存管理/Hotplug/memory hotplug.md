
# 概述

先看 doc.

`Documentation/admin-guide/mm/memory-hotplug.rst`

# hot add

# hot remove

然后要想 remove, 逻辑上是先 offline(drivers/base/memory.c 的 `memory_subsys_offline`), 再 remove(`mm/memory_hotplug.c` 的 remove_memory 调用).

## offline

### 整体流程

```cpp
memory_subsys_offline()
 ├─ struct memory_block mem= to_memory_block(dev);          // memory dev 转换成 memory_block
 ├─ memory_block_change_state(mem, MEM_OFFLINE, MEM_ONLINE);   // 从 online 转换成 offline
 |   └─ memory_block_action();
 |       ├─ nr_pages = PAGES_PER_SECTION * sections_per_block;  // 获取这个 block 包含的页数
 |       ├─ start_pfn = section_nr_to_pfn();                   // 获取起始 pfn
 |       └─ offline_pages(start_pfn, nr_pages);
 |           └─ __offline_pages(start_pfn, start_pfn + nr_pages);
 |               ├─ mem_hotplug_begin();
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               ├─ test_pages_in_a_zone(start_pfn, end_pfn);    // 所有页面必须在同一个 zone
 |               ├─ node = zone_to_nid(zone);    // 获取 node id
 |               ├─ start_isolate_page_range();    //
 |               ├─ node_states_check_changes_offline();    //
 |               ├─ memory_notify(MEM_GOING_OFFLINE, &arg);    //
 |               ├─ notify_to_errno();    //
 |               ├─ do {    //  循环处理
 |               ├─ for (pfn = start_pfn; pfn;) {    // 遍历
 |               ├─ pfn = scan_movable_pages(pfn, end_pfn);  // 扫描找到第一个 movable 的 page, 找不到返回 0
 |               ├─ do_migrate(pfn, end_pfn);  // 如果找到 movable 的 page, 则迁移
 |               ├─ }    //
 |               ├─ dissolve_free_huge_pages(start_pfn, end_pfn);    //
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               ├─ while(ret);    //
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               └─ mem_hotplug_done();
```

### 代码分析

```
```

```cpp
reset_init()
 ├─ kernel_thread(kernel_init, NULL, CLONE_FS | CLONE_SIGHAND);   // 调用 kernel_init
 |   └─ kernel_init_freeable()
 |       └─ do_basic_setup();  // 获取这个 block 包含的页数
 |           └─ driver_init();
 |              └─ memory_dev_init();
 |                  └─ subsys_system_register(&memory_subsys, memory_root_attr_groups);
 |       ├─ start_pfn = section_nr_to_pfn();                   // 获取起始 pfn
 |       └─ offline_pages(start_pfn, nr_pages);
 |           └─ __offline_pages(start_pfn, start_pfn + nr_pages);
 |               ├─ mem_hotplug_begin();
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               ├─ test_pages_in_a_zone(start_pfn, end_pfn);    // 所有页面必须在同一个 zone
 |               ├─ node = zone_to_nid(zone);    // 获取 node id
 |               ├─ start_isolate_page_range();    //
 |               ├─ node_states_check_changes_offline();    //
 |               ├─ memory_notify(MEM_GOING_OFFLINE, &arg);    //
 |               ├─ notify_to_errno();    //
 |               ├─ do {    //  循环处理
 |               ├─ for (pfn = start_pfn; pfn;) {    // 遍历
 |               ├─ pfn = scan_movable_pages(pfn, end_pfn);  // 扫描找到第一个 movable 的 page, 找不到返回 0
 |               ├─ do_migrate(pfn, end_pfn);  // 如果找到 movable 的 page, 则迁移
 |               ├─ }    //
 |               ├─ dissolve_free_huge_pages(start_pfn, end_pfn);    //
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               ├─ while(ret);    //
 |               ├─ walk_system_ram_range();    // memory blocks 有 hole(空洞)则不允许 offline
 |               └─ mem_hotplug_done();
reset_init()
```

```cpp
static struct bus_type memory_subsys = {
        .name = MEMORY_CLASS_NAME,
        .dev_name = MEMORY_CLASS_NAME,
        .online = memory_subsys_online,
        .offline = memory_subsys_offline,
};

static struct attribute *memory_root_attrs[] = {
#ifdef CONFIG_ARCH_MEMORY_PROBE
        &dev_attr_probe.attr,
#endif

#ifdef CONFIG_MEMORY_FAILURE
        &dev_attr_soft_offline_page.attr,
        &dev_attr_hard_offline_page.attr,
#endif

        &dev_attr_block_size_bytes.attr,
        &dev_attr_auto_online_blocks.attr,
        NULL
};

static struct attribute_group memory_root_attr_group = {
        .attrs = memory_root_attrs,
};

static const struct attribute_group *memory_root_attr_groups[] = {
        &memory_root_attr_group,
        NULL,
};
```



## remove


# 参考

`Documentation/admin-guide/mm/memory-hotplug.rst`

`/sys/devices/system/memory/block_size_bytes`这个值好像是 16 进制大小?

https://blog.51cto.com/weiguozhihui/1568258