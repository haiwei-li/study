


# 用途

列出 `perf.data` 文件(默认)中的 buildids, 其他工具从而可以用 buildid 来获取具有匹配到的符号表的软件包, 这样 `perf report` 便可以使用.

> 每个 ELF 文件都有一个唯一的 buildid. buildid 被 perf 用来关联性能数据与 ELF 文件.

# 2. 使用方法

```
// 这个更好
perf --help buildid-list


perf buildid-list -h
```

```
perf buildid-list <options>
```

# 输出格式


# 参数说明

```
 Usage: perf buildid-list [<options>]

    -f, --force           don't complain, do it
    -H, --with-hits       Show only DSOs with hits
    -i, --input <file>    input file name
    -k, --kernel          Show current kernel build id
    -v, --verbose         be more verbose
```

*
*

##


# 示例

```
# perf buildid-list
53a8364be2bff3856c9ba03bd0a475b7da0b0562 /lib/modules/5.12.0-tlinux2-0050/build/vmlinux
038a3c12367b97c468d700a41dac30ce5f9ca3ee [vdso]
3e0d89ca817824c1b1d40e58416ce67fa062de00 /usr/lib64/ld-2.28.so
```