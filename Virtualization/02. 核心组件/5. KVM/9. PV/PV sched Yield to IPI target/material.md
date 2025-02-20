https://lore.kernel.org/patchwork/patch/1086999/

推测持有锁的 vcpu, yield to 目标 vcpu, 让尽快执行, 释放锁

```cpp

int kvm_emulate_hypercall(struct kvm_vcpu *vcpu)
{
        ......
        case KVM_HC_KICK_CPU:
                if (!guest_pv_has(vcpu, KVM_FEATURE_PV_UNHALT))
                        break;

                kvm_pv_kick_cpu_op(vcpu->kvm, a0, a1);
                kvm_sched_yield(vcpu->kvm, a1);
                ret = 0;
                break;
        ......
}
```

通过 hypercall 实现

if the IPI target vCPU is preempted

如果 ipi 的目标 vcpu 被抢占了,


广播 ipi:

```cpp
smp_call_function_many(const struct cpumask *mask, smp_call_func_t func, void *info, bool wait)
```

通过 `smp_call_function_many()` 机制, 向其它核发送 ipi, 使其执行指定的函数(func), 最后一个入参表示是否 wait, 此处传入 1, 表示需要阻塞等待, 所有核都执行完成后才继续后面的流程.

```cpp
smp_call_function_many(cpu_online_mask, handle_ipi, NULL, 1);
```

向系统中所有的在线 cpu 发送 ipi.

> smp_call_function_many_cond() -> arch_send_call_function_ipi_mask() -> smp_ops.send_call_func_ipi(mask) -> kvm_smp_send_call_func_ipi() -> kvm_hypercall1(KVM_HC_SCHED_YIELD, per_cpu(x86_cpu_to_apicid, cpu))


单播发送给其它:

```cpp
cpu = cpumask_any_but(cpu_online_mask, get_cpu());
smp_call_function_single(cpu, handle_ipi, &time, 1);
```

`cpumask_any_but()`返回`cpu_online_mask`(当前系统中所有在线的 cpu mask)中一个随机的 id, 但是忽略`get_cpu()`(即自己)

发送给自己:

```cpp
smp_call_function_single(get_cpu(), handle_ipi, &time, 1);
```

单发 ipi, 使其执行`handle_ipi`


