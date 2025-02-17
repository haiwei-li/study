


# 用途

管理 perf 的 buildid 缓存.

> 每个 ELF 文件都有一个唯一的 buildid. buildid 被 perf 用来关联性能数据与 ELF 文件.

它可以用来给缓存中添加, 删除, 更新和清除文件.  将来, 它还应该为缓存等使用的空间设置上限.

这还会扫描目标二进制文件的 SDT(静态定义的跟踪), 并将其与 buildid-cache 一起记录下来, 这将由 perf probe.  有关更多详细信息, 请参见 perf-probe(1).

# 2. 使用方法

```
// 这个更好
perf --help buildid-cache


perf buildid-cache -h
```

```
perf buildid-cache <options>
```

# 输出格式


# 参数说明

```
 Usage: perf buildid-cache [<options>]

    -a, --add <file list>
                          file(s) to add
    -f, --force           don't complain, do it
    -k, --kcore <file>    kcore file to add
    -l, --list            list all cached files
    -M, --missing <file>  to find missing build ids in the cache
    -p, --purge <file list>
                          file(s) to remove (remove old caches too)
    -P, --purge-all       purge all cached files
    -r, --remove <file list>
                          file(s) to remove
    -u, --update <file list>
                          file(s) to update
    -v, --verbose         be more verbose
        --debuginfod <debuginfod url>
                          set debuginfod url
        --target-ns <n>   target pid for namespace context
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