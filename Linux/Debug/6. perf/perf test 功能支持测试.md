


# 用途

Runs sanity tests. 健全性/完整性 测试

该命令最初通过链接的例程进行各种健全性测试(assorted sanity tests), 但还将以脚本的形式查找包含更多测试的目录.

要获得可用测试的列表, 请使用`perf test list`, 指定测试名称片段将显示具有该名称的所有测试.

要仅运行特定测试, 请告知测试名称片段或从性能测试列表中获得的编号.

# 2. 使用方法

```
// 这个更好
perf --help test
man perf test


perf test -h
```

```
perf test [<options>] [{list <test-name-fragment>|[<test-name-fragments>|<test-numbers>]}]
```

# 输出格式


# 参数说明

```
 Usage: perf test [<options>] [{list <test-name-fragment>|[<test-name-fragments>|<test-numbers>]}]

    -F, --dont-fork       Do not fork for testcase
    -s, --skip <tests>    tests to skip
    -v, --verbose         be more verbose (show symbol address, etc)
```

*
*

##


# 示例

查看所有可测试的功能列表

```
# perf test list
 1: vmlinux symtab matches kallsyms
 2: Detect openat syscall event
 3: Detect openat syscall event on all cpus
 4: Read samples using the mmap interface
 5: Test data source output
 6: Parse event definition strings
 7: Simple expression parser
 8: PERF_RECORD_* events & perf_sample fields
 9: Parse perf pmu format
10: PMU events
10:1: PMU event table sanity
10:2: PMU event map aliases
10:3: Parsing of PMU event table metrics
10:4: Parsing of PMU event table metrics with fake PMUs
11: DSO data read
12: DSO data cache
13: DSO data reopen
14: Roundtrip evsel->name
15: Parse sched tracepoints fields
16: syscalls:sys_enter_openat event fields
17: Setup struct perf_event_attr
18: Match and link multiple hists
19: 'import perf' in python
20: Breakpoint overflow signal handler
21: Breakpoint overflow sampling
22: Breakpoint accounting
23: Watchpoint
23:1: Read Only Watchpoint
23:2: Write Only Watchpoint
23:3: Read / Write Watchpoint
23:4: Modify Watchpoint
24: Number of exit events of a simple workload
25: Software clock events period values
26: Object code reading
27: Sample parsing
28: Use a dummy software event to keep tracking
29: Parse with no sample_id_all bit set
30: Filter hist entries
31: Lookup mmap thread
32: Share thread maps
33: Sort output of hist entries
34: Cumulate child hist entries
35: Track with sched_switch
36: Filter fds with revents mask in a fdarray
37: Add fd to a fdarray, making it autogrow
38: kmod_path__parse
39: Thread map
40: LLVM search and compile
40:1: Basic BPF llvm compile
40:2: kbuild searching
40:3: Compile source for BPF prologue generation
40:4: Compile source for BPF relocation
41: Session topology
42: BPF filter
42:1: Basic BPF filtering
42:2: BPF pinning
43: Synthesize thread map
44: Remove thread map
45: Synthesize cpu map
46: Synthesize stat config
47: Synthesize stat
48: Synthesize stat round
49: Synthesize attr update
50: Event times
51: Read backward ring buffer
52: Print cpu map
53: Merge cpu map
54: Probe SDT events
55: is_printable_array
56: Print bitmap
57: perf hooks
58: builtin clang support
59: unit_number__scnprintf
60: mem2node
61: time utils
62: Test jit_write_elf
63: Test libpfm4 support
64: Test api io
65: maps__merge_in
66: Demangle Java
67: Demangle OCaml
68: Parse and process metrics
69: PE file support
70: Event expansion for cgroups
71: Convert perf time to TSC
72: x86 rdpmc
73: DWARF unwind
74: x86 instruction decoder - new instructions
75: Intel PT packet decoder
76: x86 bp modify
77: x86 Sample parsing
```

DWARF unwind 功能是否支持测试:

```
# perf test 73
73: DWARF unwind                               : Ok
failed to open shell test directory: /root/libexec/perf-core/tests/shell
```