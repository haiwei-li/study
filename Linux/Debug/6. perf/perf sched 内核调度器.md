
# 用途

调度模块分析

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
---------------------------------------------------------------------------------------------------------------
 Task                  |   Runtime ms  | Switches | Average delay ms | Maximum delay ms | Maximum delay at     |
---------------------------------------------------------------------------------------------------------------
 events/10:61          |      0.655 ms |       10 | avg:    0.045 ms | max:    0.161 ms | max at: 9804.958730 s
 sleep:11156           |      2.263 ms |        4 | avg:    0.052 ms | max:    0.118 ms | max at: 9804.865552 s
 edac-poller:1125      |      0.598 ms |       10 | avg:    0.042 ms | max:    0.113 ms | max at: 9804.958698 s
 events/2:53           |      0.676 ms |       10 | avg:    0.037 ms | max:    0.102 ms | max at: 9814.751605 s
 perf:11155            |      2.109 ms |        1 | avg:    0.068 ms | max:    0.068 ms | max at: 9814.867918 s
```

* TASK: 进程名和 pid.
* Runtime: 实际的运行时间.
* Switches: 进程切换的次数.
* Average delay: 平均的调度延迟.
* Maximum delay: 最大的调度延迟.
* Maximum delay at: 最大调度延迟发生的时刻.

# 参数说明

```
 Usage: perf sched [<options>] {record|latency|map|replay|script|timehist}

    -D, --dump-raw-trace  dump raw trace in ASCII
    -f, --force           don't complain, do it
    -i, --input <file>    input file name
    -v, --verbose         be more verbose (show symbol address, etc)
```

##


# 示例

```
# perf sched record sleep 10 // perf sched record <command>
# perf report latency --sort max
```

