
# 用途

根据数据文件中的 build-id, 将所有被采样到的 ELF 文件打成压缩包. 利用此压缩包, 可以在任何机器上分析数据文件中的采样数据.

# 2. 使用方法


```
perf --help archive
```

```
perf archive -h
```

```
perf archive [file]
```

# 示例

1. 记录

```
perf record -ag -- ls
```

2. 压缩

```
# perf archive

Now please run:

$ tar xvf perf.data.tar.bz2 -C ~/.debug

wherever you need to run 'perf report' on.
```

最终生成一个文件 `perf.data.tar.bz2`, 你可以将其拷贝到任何机器上, 然后通过 `tar xvf perf.data.tar.bz2 -C ~/.debug` 解压, 就能分析了.

3. 复制

```
# scp perf.data root@XXX.XXX.XXX.XXX:/data/
# scp perf.data.tar.bz2 root@XXX.XXX.XXX.XXX:/data/
```

4. 在另外的机器上分析

先解压缩

```
# ssh root@XXX.XXX.XXX.XXX
# cd /data/
# tar xvf perf.data.tar.bz2 -C ~/.debug
.build-id/53/a8364be2bff3856c9ba03bd0a475b7da0b0562
data/build/linux/vmlinux/53a8364be2bff3856c9ba03bd0a475b7da0b0562/
data/build/linux/vmlinux/53a8364be2bff3856c9ba03bd0a475b7da0b0562/probes
data/build/linux/vmlinux/53a8364be2bff3856c9ba03bd0a475b7da0b0562/elf
.build-id/9c/a86fb4a7e898a887b620da78e519a1d299f1f7
data/build/linux/tools/perf/perf/9ca86fb4a7e898a887b620da78e519a1d299f1f7/
data/build/linux/tools/perf/perf/9ca86fb4a7e898a887b620da78e519a1d299f1f7/probes
data/build/linux/tools/perf/perf/9ca86fb4a7e898a887b620da78e519a1d299f1f7/elf
```

然后执行分析

```
perf report
```

会得到和原主机上一模一样的结果