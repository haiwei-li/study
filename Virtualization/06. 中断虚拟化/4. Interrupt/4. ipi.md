
这个是纯 QEMU??

对于多核 CPU 需要 IPI 机制进行通知或者唤醒, 当 CPU 接收到的中断不是本地中断的时候, 需要通过 IPI 唤醒对端 CPU, 然后进行中断的传递

那么 QEMU 中如何实现不同 VCPU 通知的呢

在 QEMU 中, 注册了核间通信处理函数, 这个函数完成了 IPI 的功能

```cpp
// include/hw/core/cpu.h
typedef void (*CPUInterruptHandler)(CPUState *, int);

// hw/core/cpu.c
CPUInterruptHandler cpu_interrupt_handler = generic_handle_interrupt;
// CPU 的 IPI 通信接口
static void generic_handle_interrupt(CPUState *cpu, int mask)
{
    /*记录中断请求号*/
    cpu->interrupt_request |= mask;
    /*如果不是本地 CPU, 启动相应的 VCPU 接收中断*/
    if (!qemu_cpu_is_self(cpu)) {
        qemu_cpu_kick(cpu);
    }
}
```

```cpp
/*
* 启动指定的 VCPU
*/
void qemu_cpu_kick(CPUState *cpu)
{
    // 唤醒所有等待在 cpu->halt_cond 上的 VCPU 线程, 关于 QEMUCond, 请参考《QEMU VCPU 线程同步机制之 QemuCond》
    qemu_cond_broadcast(cpu->halt_cond);
    // 是 TCG 的
    if (tcg_enabled()) {
        if (qemu_tcg_mttcg_enabled()) {
            cpu_exit(cpu);
        } else {
            qemu_cpu_kick_rr_cpus();
        }
    } else {
        if (hax_enabled()) {
            /*
             * FIXME: race condition with the exit_request check in
             * hax_vcpu_hax_exec
             */
            cpu->exit_request = 1;
        }
        // 不是 TCG 的唤醒
        qemu_cpu_kick_thread(cpu);
    }
}
```

```cpp
static void qemu_cpu_kick_thread(CPUState *cpu)
{
#ifndef _WIN32
    int err;
    // 已被唤醒则返回
    if (cpu->thread_kicked) {
        return;
    }
    // 标明指定的 VCPU 线程已被唤醒
    cpu->thread_kicked = true;
    // 通过 pthread_kill 将 SIG_IPI 信号发送到指定的 VCPU 线程, 将其唤醒
    err = pthread_kill(cpu->thread->thread, SIG_IPI);
    if (err && err != ESRCH) {
        fprintf(stderr, "qemu:%s: %s", __func__, strerror(err));
        exit(1);
    }
#else /* _WIN32 */
    // 忽略
    if (!qemu_cpu_is_self(cpu)) {
        if (whpx_enabled()) {
            whpx_vcpu_kick(cpu);
        } else if (!QueueUserAPC(dummy_apc_func, cpu->hThread, 0)) {
            fprintf(stderr, "%s: QueueUserAPC failed with error %lu\n",
                    __func__, GetLastError());
            exit(1);
        }
    }
#endif
}
```

我们下面来看一下 IPI 的使用示例,

`pic_irq_request`是通过`pc_init->pc_i8259_create->i8259_init(isa_bus, x86_allocate_cpu_irq())`, 注册的 irq 的 handler

pic_irq_request
-> cpu_interrupt
-> cpu_interrupt_handler //这里调用 generic_handle_interrupt
-> generic_handle_interrupt //唤醒指定 VCPU 的线程, 发送中断


