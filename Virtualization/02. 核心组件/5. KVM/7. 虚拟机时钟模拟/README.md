关于 KVM 时钟

参考:

时钟模拟之 PIT(8254): http://blog.chinaunix.net/uid-25739055-id-4093065.html

kvmclock 时钟虚拟化源代码分析: http://oenhan.com/kvm-pv-kvmclock-tsc

时钟虚拟化: http://blog.csdn.net/wanthelping/article/details/47069085

Qemu-KVM 模拟 APIC Timer 中断: https://www.iyunv.com/thread-125093-1-1.html

KVM time 虚拟: https://tcbbd.moe/linux/qemu-kvm/kvm-time/



```
From: Wanpeng Li <wanpengli@tencent.com>

per-vCPU timer_advance_ns should be set to 0 if timer mode is not tscdeadline
otherwise we waste cpu cycles in the function lapic_timer_int_injected(),
especially on AMD platform which doesn't support tscdeadline mode. We can
reset timer_advance_ns to the initial value if switch back to tscdealine
timer mode.

Signed-off-by: Wanpeng Li <wanpengli@tencent.com>
---
 arch/x86/kvm/lapic.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/x86/kvm/lapic.c b/arch/x86/kvm/lapic.c
index 654649b..abc296d 100644
--- a/arch/x86/kvm/lapic.c
+++ b/arch/x86/kvm/lapic.c
@@ -1499,10 +1499,16 @@ static void apic_update_lvtt(struct kvm_lapic *apic)
 			kvm_lapic_set_reg(apic, APIC_TMICT, 0);
 			apic->lapic_timer.period = 0;
 			apic->lapic_timer.tscdeadline = 0;
+			if (timer_mode == APIC_LVT_TIMER_TSCDEADLINE &&
+				lapic_timer_advance_dynamic)
+				apic->lapic_timer.timer_advance_ns = LAPIC_TIMER_ADVANCE_NS_INIT;
 		}
 		apic->lapic_timer.timer_mode = timer_mode;
 		limit_periodic_timer_frequency(apic);
 	}
+	if (timer_mode != APIC_LVT_TIMER_TSCDEADLINE &&
+		lapic_timer_advance_dynamic)
+		apic->lapic_timer.timer_advance_ns = 0;
 }

 /*
--
2.7.4
```


timer_advance_ns 针对 tscdeadline 模式


