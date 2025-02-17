
所有的 pv features: https://www.qemu.org/docs/master/system/i386/kvm-pv.html

头文件:

arch/x86/include/uapi/asm/kvm_para.h


pv 的入口和相关数据结构在 arch/x86/kernel/kvm.c , 很明显, 这不是 kvm 模块的范畴, 因为这也是 pv 下的虚拟机操作系统部分

```cpp
const __initconst struct hypervisor_x86 x86_hyper_kvm = {
        .name                   = "KVM",
        .detect                 = kvm_detect,
        .type                   = X86_HYPER_KVM,
        .init.guest_late_init   = kvm_guest_init,
        .init.x2apic_available  = kvm_para_available,
        .init.init_platform     = kvm_init_platform,
};
```

可以看到重新的几个初始化函数


pv 的 feature 大多数给超卖用的, 会有大量 kick, 让出 cpu 或抢占 cpu, 造成 vm-exit, 但是有些的 vm-exit 减少, 比如 virtio.


通过 cpuid 判断 feature

Documentation/virtual/kvm/cpuid.rst

qemu-system-x86_64 -cpu ?


PV 很多都是可以通过启动参数控制的


xen 的 smp pv 操作在

```cpp
// arch/x86/xen/smp_pv.c
static const struct smp_ops xen_smp_ops __initconst = {
        ......
}
```