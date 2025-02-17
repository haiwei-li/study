

# 用途

内核锁的性能分析

# 相关编译选项

需要编译选项的支持: CONFIG_LOCKDEP、CONFIG_LOCK_STAT

* CONFIG_LOCKDEP defines acquired and release events.
* CONFIG_LOCK_STAT defines contended and acquired lock events

# 2. 使用方法


```
perf --help lock
```

```
perf lock -h
```

```
perf lock [<options>] {record|report|script|info}
```

# 输出格式

```
               Name   acquired  contended total wait (ns)   max wait (ns)   min wait (ns)

&mm->page_table_...        382          0               0               0               0
&mm->page_table_...         72          0               0               0               0
          &fs->lock         64          0               0               0               0
        dcache_lock         62          0               0               0               0
      vfsmount_lock         43          0               0               0               0
&newf->file_lock...         41          0               0               0               0
```

* Name: 内核锁的名字.
* aquired: 该锁被直接获得的次数, 因为没有其它内核路径占用该锁, 此时不用等待.
* contended: 该锁等待后获得的次数, 此时被其它内核路径占用, 需要等待.
* total wait: 为了获得该锁, 总共的等待时间.
* max wait: 为了获得该锁, 最大的等待时间.
* min wait: 为了获得该锁, 最小的等待时间.

最后还有一个 Summary:

```
=== output for debug===

bad: 10, total: 246
bad rate: 4.065041 %
histogram of events caused bad sequence
    acquire: 0
   acquired: 0
  contended: 0
    release: 10
```

# 参数说明

```
 Usage: perf lock [<options>] {record|report|script|info}

    -D, --dump-raw-trace  dump raw trace in ASCII
    -f, --force           don't complain, do it
    -i, --input <file>    input file name
    -v, --verbose         be more verbose (show symbol address, etc)
```

* `-i`: 输入文件
* `-k`: 排序的 key, 默认为 acquired, 还可以按 contended、wait_total、wait_max 和 wait_min 来排序

##


# 示例

```
# perf lock record ls // 记录
# perf lock report // 报告
```

