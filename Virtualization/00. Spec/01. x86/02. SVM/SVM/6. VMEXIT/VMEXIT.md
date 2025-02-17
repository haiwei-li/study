
当触发拦截器(intercept), 处理器会发生`#VMEXIT`, 即从guest mode退回到host上下文.

当发生`#VMEXIT`, 处理器: 
* 通过**清除GIF禁用中断**, 以便在`#VMEXIT`之后, VMM软件可以**原子完成状态切换**. 
* 将当前guest状态写回VMCB - 与**VMRUN指令**加载的处理器状态**相同的子集**, 包括`V_IRQ`, `V_TPR`和`INTERRUPT_SHADOW`位. 
* 将**退出guest的原因**保存在VMCB的`EXITCODE`字段中; 根据拦截器操作的情况, 其他**附加信息！！！** 可能会保存在**EXITINFO1**或**EXITINFO2**字段中. 请注意, 对于未指示使用的拦截器, 未定义EXITINFO1和EXITINFO2字段的内容. 
* **清除所有拦截**. 
* 将**当前的ASID**寄存器重置为零(**主机ASID**). 
* **清除**处理器内部的`V_IRQ`和`V_INTR_MASKING`位. 
* **清除**处理器内部的`TSC_OFFSET`. 
* 重新**加载**先前由VMRUN指令保存的**主机状态**. 处理器将重新加载**主机**的`CS`, `SS`, `DS`和`ES`段寄存器, 并根据需要从主机的**段描述符表**中重新读取描述符. 段描述符表必须由主机的页表映射为当前表和可写表. 执行VMRUN指令时, 软件应使主机的段描述符表与段寄存器保持一致. 在#VMEXIT之后, 处理器仍立即包含LDTR的guest值. 因此, 对于CS, SS, DS和ES, VMM必须仅使用全局描述符表中的段描述符.  (VMSAVE指令可用于更完整的上下文切换, 允许VMM然后将LDTR和其他未由#VMEXIT保存的寄存器加载到所需的值; 有关详细信息, 请参见`5.2. VMSAVE和VMLOAD指令`)重新加载主机段时遇到的任何异常导致关机. 
* 如果**主机**处于**PAE模式**, 则处理器会从**主机CR3**指示的页表中重新加载主机的**PDPE**. 如果PDPE包含非法状态, 则处理器将**导致关机**. 
* 强制`CR0.PE = 1`, `RFLAGS.VM = 0`. 
* 将主机**CPL**设置为零. 
* 禁用主机DR7寄存器中的所有断点. 
* 检查重新加载的主机状态的一致性; **任何错误**都会导致**处理器关闭**(shutdown). 如果通过`#VMEXIT`重新加载的**主机的rIP**超出了**主机代码段的限制**或host rIP是**non-canonical形式**(在长模式下), 则在主机内部会传递`#GP`故障. 

具体指令过程以及伪代码, 见AMD手册`3- General Purpose and System Instructions`的`VMRUN`指令部分