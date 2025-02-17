


# 用途

简单的包装内核的 ftrace 功能

不过当前仅仅支持单线程, 并且仅仅是从 `trace_pipe` 以文本方式读然后写到标准输出.

# 2. 使用方法


```
// 更好
perf --help ftrace

perf ftrace -h
```

```
perf ftrace [<options>] [<command>]
perf ftrace [<options>] -- <command> [<options>]
```

# 输出格式


# 参数说明

```
-t, --tracer=
    Tracer to use: function_graph or function.

-v, --verbose=
    Verbosity level.

-p, --pid=
    Trace on existing process id (comma separated list).

-a, --all-cpus
    Force system-wide collection. Scripts run without a <command> normally use -a
    by default, while scripts run with a <command> normally don't - this option
    allows the latter to be run in system-wide mode.

-C, --cpu=
    Only trace for the list of CPUs provided. Multiple CPUs can be provided as a
    comma separated list with no space like: 0,1. Ranges of CPUs are specified
    with -: 0-2. Default is to trace on all online CPUs.

-T, --trace-funcs=
    Only trace functions given by the argument. Multiple functions can be given by
    using this option more than once. The function argument also can be a glob
    pattern. It will be passed to set_ftrace_filter in tracefs.

-N, --notrace-funcs=
    Do not trace functions given by the argument. Like -T option, this can be used
    more than once to specify multiple functions (or glob patterns). It will be
    passed to set_ftrace_notrace in tracefs.

-G, --graph-funcs=
    Set graph filter on the given function (or a glob pattern). This is useful for
    the function_graph tracer only and enables tracing for functions executed from
    the given function. This can be used more than once to specify multiple
    functions. It will be passed to set_graph_function in tracefs.

-g, --nograph-funcs=
    Set graph notrace filter on the given function (or a glob pattern). Like -G
    option, this is useful for the function_graph tracer only and disables tracing
    for function executed from the given function. This can be used more than once
    to specify multiple functions. It will be passed to set_graph_notrace in
    tracefs.

-D, --graph-depth=
    Set max depth for function graph tracer to follow
```

*
*

##


# 示例

perf ftrace -t function_graph usleep 123456

perf ftrace -t function_graph -a -- insmod ipi_benchmark.ko > after_perf_ftrace


参考:

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=d01f4e8db22cf4d04f6c86351d959b584eb1f5f7

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=b05d1093987a78695766b71a2d723aa65b5c25c5

https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=ec347870a9d423a4b88657d6a85b5163b3f949ee
