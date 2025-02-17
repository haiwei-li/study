


# 用途

Filter to augment the events stream with additional information(用附加信息扩充事件流的过滤器)

该工具读取 perf record 工具记录的事件流, 并将其定向到标准输出. 在被分析代码中的任何一点, 都可以向事件流中注入其他事件.


# 2. 使用方法

```
// 这个更好
perf --help inject


perf inject -h
```

```
perf inject <options>
```

# 输出格式


# 参数说明

```
 Usage: perf inject [<options>]

    -b, --build-ids       Inject build-ids into the output stream
    -f, --force           don't complain, do it
    -i, --input <file>    input file name
    -j, --jit             merge jitdump files into perf.data file
    -o, --output <file>   output file name
    -s, --sched-stat      Merge sched-stat and sched-switch for getting events where and how long tasks slept
    -v, --verbose         be more verbose (show build ids, etc)
        --buildid-all     Inject build-ids of all DSOs into the output stream
        --itrace[=<opts>]
                          Instruction Tracing options
                                i[period]:              synthesize instructions events
                                b:                      synthesize branches events (branch misses for Arm SPE)
                                c:                      synthesize branches events (calls only)
                                r:                      synthesize branches events (returns only)
                                x:                      synthesize transactions events
                                w:                      synthesize ptwrite events
                                p:                      synthesize power events
                                o:                      synthesize other events recorded due to the use
                                                        of aux-output (refer to perf record)
                                e[flags]:               synthesize error events
                                                        each flag must be preceded by + or -
                                                        error flags are: o (overflow)
                                                                         l (data lost)
                                d[flags]:               create a debug log
                                                        each flag must be preceded by + or -
                                                        log flags are: a (all perf events)
                                f:                      synthesize first level cache events
                                m:                      synthesize last level cache events
                                t:                      synthesize TLB events
                                a:                      synthesize remote access events
                                g[len]:                 synthesize a call chain (use with i or x)
                                G[len]:                 synthesize a call chain on existing event records
                                l[len]:                 synthesize last branch entries (use with i or x)
                                L[len]:                 synthesize last branch entries on existing event records
                                sNUMBER:                skip initial number of events
                                q:                      quicker (less detailed) decoding
                                PERIOD[ns|us|ms|i|t]:   specify period to sample stream
                                concatenate multiple options. Default is ibxwpe or cewp

        --kallsyms <file>
                          kallsyms pathname
        --strip           strip non-synthesized events (use with --itrace)
```

*
*

##


# 示例

```

```