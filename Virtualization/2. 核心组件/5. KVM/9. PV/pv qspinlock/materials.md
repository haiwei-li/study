https://lore.kernel.org/lkml/556B5316.6010201@hp.com/t/


代码入口在 arch/x86/kernel/kvm.c 的 kvm_spinlock_init 函数, 会调用 kernel/locking/qspinlock_paravirt.h 的 `__pv_init_lock_hash` 函数

,+kvm-pv-unhalt


dmesg:

```
PV qspinlock hash table entries: 256 (order: 0, 4096 bytes
```