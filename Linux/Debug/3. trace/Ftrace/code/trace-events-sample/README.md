http://blog.csdn.net/arethe/article/details/6293505]

http://lxr.free-electrons.com/source/Documentation/trace/tracepoints.txt

https://lwn.net/Articles/410200/

# 驱动安装

sudo insmod trace-events-sample.ko

# 检查驱动

```
cat /sys/kernel/debug/tracing/available_events | grep sample-trace

cd /sys/kernel/debug/tracing/events/sample-trace
```

# 列出所有的events

```
find /sys/kernel/debug/tracing/events -type d

cat /sys/kernel/debug/tracing/available_events

trace-cmd list

perf list 2>&1 | grep Tracepoint
```

# trace-cmd

```
sudo trace-cmd reset

sudo trace-cmd record -e sample-trace:foo_with_template_print

sudo trace-cmd report
```

# 文档中的错误

http://lxr.free-electrons.com/source/Documentation/trace/events.txt?v=4.10#L278

all events but those that have not a prev_pid field retain their old filters
