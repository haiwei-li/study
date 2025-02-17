
# 用途

slab 分配器的性能分析

# 2. 使用方法


```
perf --help sched
```

```
perf sched -h
```

```
perf sched [<options>] {record|latency|map|replay|script|timehist}
```

# 输出格式

```
------------------------------------------------------------------------------------------------------
 Callsite                           | Total_alloc/Per | Total_req/Per   | Hit      | Ping-pong | Frag
------------------------------------------------------------------------------------------------------
 perf_event_mmap+ec                 |    311296/8192  |    155952/4104  |       38 |        0 | 49.902%
 proc_reg_open+41                   |        64/64    |        40/40    |        1 |        0 | 37.500%
 __kmalloc_node+4d                  |      1024/1024  |       664/664   |        1 |        0 | 35.156%
 ext3_readdir+5bd                   |        64/64    |        48/48    |        1 |        0 | 25.000%
 load_elf_binary+8ec                |       512/512   |       392/392   |        1 |        0 | 23.438%
```

* Callsite: 内核代码中调用 kmalloc 和 kfree 的地方.
* Total_alloc/Per: 总共分配的内存大小, 平均每次分配的内存大小.
* Total_req/Per: 总共请求的内存大小, 平均每次请求的内存大小.
* Hit: 调用的次数.
* Ping-pong: kmalloc 和 kfree 不被同一个 CPU 执行时的次数, 这会导致 cache 效率降低.
* Frag: 碎片所占的百分比, 碎片 = 分配的内存 - 请求的内存, 这部分是浪费的.
有使用–alloc 选项, 还会看到 Alloc Ptr, 即所分配内存的地址.

最后还有一个 Summary:

```
SUMMARY
=======
Total bytes requested: 290544
Total bytes allocated: 447016
Total bytes wasted on internal fragmentation: 156472
Internal fragmentation: 35.003669%
Cross CPU allocations: 2/509
```

# 参数说明

```
--i <file>: 输入文件
--caller: show per-callsite statistics, 显示内核中调用 kmalloc 和 kfree 的地方.
--alloc: show per-allocation statistics, 显示分配的内存地址.
-l <num>: print n lines only, 只显示 num 行.
-s <key[,key2...]>: sort the output (default: frag,hit,bytes)
```

##


# 示例

```
# perf kmem record ls // 记录
# perf kmem stat --caller --alloc -l 20 // 报告
```

