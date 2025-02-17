


# 用途

在运行内核中搜索符号

根据给定的符号, 在目前运行中的内核符号表中查找并打印相关信息, 包括 DSO(dynamic shared object, 动态共享对象), 内核符号的起始/结束地址以及ELF内核符号表的地址(对于内核模块而言)

# 2. 使用方法

```
// 这个更好
perf --help kallsyms


perf kallsyms -h
```

```
perf kallsyms [<options>] symbol_name[,symbol_name...]
```

# 输出格式


# 参数说明

```
 Usage: perf kallsyms [<options>] symbol_name

    -v, --verbose         be more verbose (show counter open errors, etc)
```


# 示例

```
# perf kallsyms cpu_startup_entry
cpu_startup_entry: [kernel] [kernel.kallsyms] 0xffffffffa0213e50-0xffffffffa0213e70 (0xffffffffa0213e50-0xffffffffa0213e70)

# perf kallsyms -v cpu_startup_entry
cpu_startup_entry: [kernel] [kernel.kallsyms] 0xffffffffa0213e50-0xffffffffa0213e70 (0xffffffffa0213e50-0xffffffffa0213e70)
```