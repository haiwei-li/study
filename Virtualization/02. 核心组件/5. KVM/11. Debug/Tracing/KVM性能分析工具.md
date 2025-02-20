


# 事件相关

这部分说明了怎么统计和追踪 KVM 模块性能事件.

两种工具, `kvm_stat` 和 `kvm_trace`.

## 跟踪 KVM 事件

使用 ftrace 能够生成详细事件跟踪记录.

```
# echo 1 >/sys/kernel/debug/tracing/events/kvm/enable
# cat /sys/kernel/debug/tracing/trace_pipe
[...]
             kvm-5664  [000] 11906.220178: kvm_entry: vcpu 0
             kvm-5664  [000] 11906.220181: kvm_exit: reason apic_access rip 0xc011518c
             kvm-5664  [000] 11906.220183: kvm_mmio: mmio write len 4 gpa 0xfee000b0 val 0x0
             kvm-5664  [000] 11906.220183: kvm_apic: apic_write APIC_EOI = 0x0
             kvm-5664  [000] 11906.220184: kvm_ack_irq: irqchip IOAPIC pin 11
             kvm-5664  [000] 11906.220185: kvm_entry: vcpu 0
             kvm-5664  [000] 11906.220188: kvm_exit: reason io_instruction rip 0xc01e4473
             kvm-5664  [000] 11906.220188: kvm_pio: pio_read at 0xc13e size 2 count 1
             kvm-5664  [000] 11906.220193: kvm_entry: vcpu 0
^D
# echo 0 >/sys/kernel/debug/tracing/events/kvm/enable
```

## 统计 KVM 事件

通常是执行 benchmark 统计性能事件

这个`perf`工具在 linux 源码的`tools/perf`.

build 工具:

```
make -C <kernel source root directory>/tools/perf
```

使用:

```
$ sudo mount -t debugfs none /sys/kernel/debug
$ sudo ./perf stat -e 'kvm:*' -a sleep 1h
^C
 Performance counter stats for 'sleep 1h':

           8330  kvm:kvm_entry            #      0.000 M/sec
              0  kvm:kvm_hypercall        #      0.000 M/sec
           4060  kvm:kvm_pio              #      0.000 M/sec
              0  kvm:kvm_cpuid            #      0.000 M/sec
           2681  kvm:kvm_apic             #      0.000 M/sec
           8343  kvm:kvm_exit             #      0.000 M/sec
            737  kvm:kvm_inj_virq         #      0.000 M/sec
              0  kvm:kvm_page_fault       #      0.000 M/sec
              0  kvm:kvm_msr              #      0.000 M/sec
            664  kvm:kvm_cr               #      0.000 M/sec
            872  kvm:kvm_pic_set_irq      #      0.000 M/sec
              0  kvm:kvm_apic_ipi         #      0.000 M/sec
            738  kvm:kvm_apic_accept_irq  #      0.000 M/sec
            874  kvm:kvm_set_irq          #      0.000 M/sec
            874  kvm:kvm_ioapic_set_irq   #      0.000 M/sec
              0  kvm:kvm_msi_set_irq      #      0.000 M/sec
            433  kvm:kvm_ack_irq          #      0.000 M/sec
           2685  kvm:kvm_mmio             #      0.000 M/sec

    3.493562100  seconds time elapsed
```

## 记录事件

将事件记录下来, 然后报告和分析. 详细可以参照 `Linux/Tools/Perf/KVM`

# 参考

事件: http://www.linux-kvm.org/page/Perf_events