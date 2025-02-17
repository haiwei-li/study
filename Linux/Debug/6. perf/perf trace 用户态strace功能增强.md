



# 用途

perf trace 类似于 strace, 但增加了其他系统事件的分析, 比如 pagefaults、task lifetime 事件、scheduling 事件等.

# 2. 使用方法

```
// 这个更好
perf --help trace
man perf trace


perf trace -h
```

```
perf trace [<options>] [<command>]
perf trace [<options>] -- <command> [<options>]
perf trace record [<options>] [<command>]
perf trace record [<options>] -- <command> [<options>]
```

# 输出格式


# 参数说明

```
 Usage: perf trace [<options>] [<command>]
    or: perf trace [<options>] -- <command> [<options>]
    or: perf trace record [<options>] [<command>]
    or: perf trace record [<options>] -- <command> [<options>]

    -a, --all-cpus        system-wide collection from all CPUs
    -C, --cpu <cpu>       list of cpus to monitor
    -D, --delay <n>       ms to wait before starting measurement after program start
    -e, --event <event>   event/syscall selector. use 'perf list' to list available events
    -f, --force           don't complain, do it
    -F, --pf <all|maj|min>
                          Trace pagefaults
    -G, --cgroup <name>   monitor event in cgroup name only
    -i, --input <file>    Analyze events in file
    -m, --mmap-pages <pages>
                          number of mmap data pages
    -o, --output <file>   output file name
    -p, --pid <pid>       trace events on existing process id
    -s, --summary         Show only syscall summary with statistics
    -S, --with-summary    Show all syscalls and summary with statistics
    -t, --tid <tid>       trace events on existing thread id
    -T, --time            Show full timestamp, not time relative to first start
    -u, --uid <user>      user to profile
    -v, --verbose         be more verbose
        --call-graph <record_mode[,record_size]>
                          setup and enables call-graph (stack chain/backtrace):

                                record_mode:    call graph recording mode (fp|dwarf|lbr)
                                record_size:    if record_mode is 'dwarf', max size of stack recording (<bytes>)
                                                default: 8192 (bytes)

                                Default: fp
        --comm            show the thread COMM next to its id
        --duration <float>
                          show only events with duration > N.M ms
        --errno-summary   Show errno stats per syscall, use with -s or -S
        --expr <expr>     list of syscalls/events to trace
        --failure         Show only syscalls that failed
        --filter <filter>
                          event filter
        --filter-pids <CSV list of pids>
                          pids to filter (by the kernel)
        --kernel-syscall-graph
                          Show the kernel callchains on the syscall exit path
        --libtraceevent_print
                          Use libtraceevent to print the tracepoint arguments.
        --map-dump <BPF map>
                          BPF map to periodically dump
        --max-events <n>  Set the maximum number of events to print, exit after that is reached.
        --max-stack <n>   Set the maximum stack depth when parsing the callchain, anything beyond the specified depth will be ignored. Default: kernel.perf_event_max_stack or>
        --min-stack <n>   Set the minimum stack depth when parsing the callchain, anything below the specified depth will be ignored.
        --no-inherit      child tasks do not inherit counters
        --print-sample    print the PERF_RECORD_SAMPLE PERF_SAMPLE_ info, for debugging
        --proc-map-timeout <n>
                          per thread proc mmap processing timeout in ms
        --sched           show blocking scheduler events
        --show-on-off-events
                          Show the on/off switch events, used with --switch-on and --switch-off
        --sort-events     Sort batch of events before processing, use if getting out of order events
        --switch-off <event>
                          Stop considering events after the ocurrence of this event
        --switch-on <event>
                          Consider events after the ocurrence of this event
```

*
*


# 示例


```

```

