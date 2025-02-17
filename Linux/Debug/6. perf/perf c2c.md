

# 用途

从一个配置文件中设置和读取变量, 可以通过这个命令来管理变量

# 2. 使用方法


```
// 这个更好
perf --help daemon


perf daemon -h
```

```
perf daemon
perf daemon [<options>
perf daemon start [<options>]]
perf daemon stop [<options>]]
perf daemon signal [<options>]]
perf daemon ping [<options>]]
```

# 输出格式


# 参数说明

```
 Usage: perf diff [<options>] [old_file] [new_file]

    -b, --baseline-only   Show only items with match in baseline
    -C, --comms <comm[,comm...]>
                          only consider symbols in these comms
    -c, --compute <delta,delta-abs,ratio,wdiff:w1,w2 (default delta-abs),cycles>
                          Entries differential computation selection
    -d, --dsos <dso[,dso...]>
                          only consider symbols in these dsos
    -D, --dump-raw-trace  dump raw trace in ASCII
    -f, --force           don't complain, do it
    -F, --formula         Show formula.
    -m, --modules         load module symbols - WARNING: use only with -k and LIVE kernel
    -o, --order <n>       Specify compute sorting.
    -p, --period          Show period values.
    -q, --quiet           Do not show any message
    -s, --sort <key[,key2...]>
                          sort by key(s): pid, comm, dso, symbol, parent, cpu, srcline, ... Please refer the man page for the comple>
    -S, --symbols <symbol[,symbol...]>
                          only consider these symbols
    -t, --field-separator <separator>
                          separator for columns, no spaces will be added between columns '.' is reserved.
    -v, --verbose         be more verbose (show symbol address, etc)
        --cpu <cpu>       list of cpus to profile
        --cycles-hist     Show cycles histogram and standard deviation - WARNING: use only with -c cycles.
        --kallsyms <file>
                          kallsyms pathname
        --percentage <relative|absolute>
                          How to display percentage of filtered entries
        --pid <pid[,pid...]>
                          only consider symbols in these pids
        --stream          Enable hot streams comparison.
        --symfs <directory>
                          Look for files with symbols relative to this directory
        --tid <tid[,tid...]>
                          only consider symbols in these tids
        --time <str>      Time span (time percent or absolute timestamp)
```

*
*

##


# 示例





http://oliveryang.net/2018/01/cache-false-sharing-debug/


https://kernel.taobao.org/2017/10/C2C-False-Sharing-Detection-in-Linux-Perf/

https://joemario.github.io/blog/2016/09/01/c2c-blog/


只支持 Intel???