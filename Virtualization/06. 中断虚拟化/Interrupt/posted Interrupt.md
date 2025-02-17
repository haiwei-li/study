
KVM: Posted Interrupt

https://zhuanlan.zhihu.com/p/51018597

https://kernelgo.org/posted-interrupt.html


Posted Interrupt 允许 APIC 中断直接注入到 guest 而不需要 VM-Exit

-  需要给 guest 传递中断的时候, 如果 vcpu 正在运行, 那么更新 posted-intrrupt 请求位图, 并向 vcpu 发送通知, vcpu 自动处理该中断, 不需要软件干预

-  如果 vcpu 没有在运行或者已经有通知事件 pending, 那么什么都不做, 中断会在下次 VM-Entry 的时候处理

-  Posted Interrupt 需要一个特别的 IPI 来给 Guest 传递中断, 并且有较高的优先级, 不能被阻塞

-  "acknowledge interrupt on exit"允许中断 CPU 运行在 non-root 模式产生时, 可以被 VMX 的 handler 处理, 而不是 IDT 的 handler 处理


KVM: x86: add method to test PIR bitmap vector
* v3: https://www.spinics.net/lists/kvm/msg111674.html
* v4: https://www.spinics.net/lists/kvm/msg111881.html



`vcpu_vmx`是 vcpu 的一个运行环境

```cpp
// arch/x86/kvm/vmx/vmx.h
struct vcpu_vmx {
    ......

    struct pi_desc pi_desc;
    ......
}
```

```cpp
// arch/x86/kvm/vmx/posted_intr.h
/* Posted-Interrupt Descriptor */
struct pi_desc {
        u32 pir[8];     /* Posted interrupt requested */
        union {
                struct {
                                /* bit 256 - Outstanding Notification */
                        u16     on      : 1,
                                /* bit 257 - Suppress Notification */
                                sn      : 1,
                                /* bit 271:258 - Reserved */
                                rsvd_1  : 14;
                                /* bit 279:272 - Notification Vector */
                        u8      nv;
                                /* bit 287:280 - Reserved */
                        u8      rsvd_2;
                                /* bit 319:288 - Notification Destination */
                        u32     ndst;
                };
                u64 control;
        };
        u32 rsvd[6];
} __aligned(64);
```

