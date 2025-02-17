

https://www.linux-kvm.org/page/Tracing

kvm 专属工具:

* perf kvm: `linux_src/tools/perf/perf`
* kvm_stat: `src/tools/kvm/kvm_stat`, 这是分析整个 kvm trace event 的占比
* kvm trace event: `/sys/kernel/debug/tracing/events/kvm`