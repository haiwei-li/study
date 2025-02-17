处理器间中断允许一个 CPU 向系统其他的 CPU 发送中断信号, 处理器间中断(IPI)不是通过 IRQ 线传输的, 而是作为信号直接放在连接所有 CPU 本地 APIC 的总线上. 在多处理器系统上, Linux 定义了下列三种处理器间中断:

`CALL_FUNCTION_VECTOR` (向量 0xfb)

发往所有的 CPU, 但不包括发送者, 强制这些 CPU 运行发送者传递过来的函数, 相应的中断处理程序叫做 call_function_interrupt(), 例如, 地址存放在群居变量 call_data 中来传递的函数, 可能强制其他所有的 CPU 都停止, 也可能强制它们设置内存类型范围寄存器的内容. 通常, 这种中断发往所有的 CPU, 但通过 smp_call_function() 执行调用函数的 CPU 除外.

RESCHEDULE_VECTOR (向量 0xfc)

当一个 CPU 接收这种类型的中断时, 相应的处理程序限定自己来应答中断, 当从中断返回时, 所有的重新调度都自动运行.

INVALIDATE_TLB_VECTOR (向量 0xfd)

发往所有的 CPU, 但不包括发送者, 强制它们的转换后援缓冲器 TLB 变为无效. 相应的处理程序刷新处理器的某些 TLB 表项.

处理器间中断处理程序的汇编语言代码是由 `BUILD_INTERRUPT` 宏产生的, 它保存寄存器, 从栈顶押入向量号减 256 的值, 然后调用高级 C 函数, 其名字就是第几处理程序的名字加前缀 `smp_`, 例如 `CALL_FUNCTION_VECTOR` 类型的处理器间中断的低级处理程序时 `call_function_interrupt()`, 它调用名为 `smp_call_function_interrupt()` 的高级处理程序, 每个高级处理程序应答本地 APIC 上的处理器间中断, 然后执行由中断触发的特定操作.

Linux 有一组函数使得发生处理器间中断变为一件容易的事:

函数 | 说明
---|---
send_IPI_all() | 发送一个 IPI 到所有 CPU, 包括发送者
send_IPI_allbutself() | 发送一个 IPI 到所有 CPU, 不包括发送者
send_IPI_self() | 发送一个 IPI 到发送者的 CPU
send_IPI_mask() | 发送一个 IPI 到位掩码指定的一组 CPU