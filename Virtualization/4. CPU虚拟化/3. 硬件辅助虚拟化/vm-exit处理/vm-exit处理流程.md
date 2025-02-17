之前讲过QEMU、KVM和Guest OS三种层次以及对应的三种模式. 如下: 

![三种模式](images/1.png)

下面从代码角度讲这三层是如何配合的. 

前面讲过, 首先QEMU层用户发起启动虚拟机命令后会通过ioctl调用进入到kvm内核层, 完成相关初始化工作后就运行虚拟机. 

在kvm内核层中, 当接收到ioctl的KVM_RUN命令后, 实际调用的是kvm_arch_vcpu_ioctl_run()函数. 

```
case KVM_RUN:    //在文件virt/kvm/kvm_main.c
       r = -EINVAL;  
       if (arg)  
                goto out;  
       r =kvm_arch_vcpu_ioctl_run(vcpu, vcpu->run);//  
       trace_kvm_userspace_exit(vcpu->run->exit_reason,r);  
       break; 
```

随后依次调用__vcpu_run(), vcpu_enter_guest(), kvm_x86_ops->run(), vmx_vcpu_run(), 在vmx_vcpu_run()函数中有一段汇编语言被调用, 这段汇编中执行了ASM_VMX_VMLAUNCH或者ASM_VMX_VMRESUME指令进入到客户模式. 

```
asm(  
                   .........//省略部分代码  
                   /* Enter guest mode */  
                   "jne 1f \n\t"  
                   __ex(ASM_VMX_VMLAUNCH)"\n\t"  
                   "jmp 2f \n\t"  
                   "1: "__ex(ASM_VMX_VMRESUME) "\n\t"  
        ........//省略部分代码  
);  
```

执行汇编指令进入到客户模式能够实现是因为KVM采用了硬件虚拟化的技术, 比如Intel的芯片上提供了硬件支持并提供了相关一系列指令. 再具体我也不知道了, 查看Intel手册吧. 那么进入到客户模式后, 客户模式因为一些异常需要退出到KVM内核进行处理, 这个是怎么实现的呢?

首先我们要说一下一个与异常处理相关的重要的数据结构VMCS. VMCS是虚拟机控制结构, 他分为三部分: 版本信息; 终止标识符; VMCS数据域. 其中VMCS数据域包含六类信息: 客户状态域, 宿主机状态域, VM-Entry控制域, VM-Execution控制域, VM-Exit控制域以及VM-Exit信息域. 

宿主机状态域保存了基本的寄存器信息, 其中CS:RIP指向KVM中异常处理程序的入口地址, VM-Exit信息域中存放异常退出原因等信息. 实际上, 在KVM内核初始化vcpu时就将异常处理程序入口地址装载进VMCS中CS:RIP寄存器结构, 当客户机发生异常时, 就根据这个入口地址退出到内核模式执行异常处理程序. 
KVM内核中异常处理总入口函数是vmx_handle_exit()函数. 

```cpp
static int vmx_handle_exit(struct kvm_vcpu *vcpu)  
{  
         struct vcpu_vmx *vmx = to_vmx(vcpu);  
         u32 exit_reason = vmx->exit_reason;  
         ........//一些处理, 省略这部分代码  
         if (exit_reason <kvm_vmx_max_exit_handlers  
            && kvm_vmx_exit_handlers[exit_reason])  
                   returnkvm_vmx_exit_handlers[exit_reason](vcpu);  
         else {  
                   vcpu->run->exit_reason= KVM_EXIT_UNKNOWN;  
                   vcpu->run->hw.hardware_exit_reason= exit_reason;  
         }  
         return 0;  
}  

```

该函数中, 首先读取exit_reason, 然后进行一些必要的处理, 最后调用kvm_vmx_exit_handlers[exit_reason](vcpu), 我们来看一下这个结构, 实际上是一个函数指针数组, 里面对应着所有的异常相应的异常处理函数. 

```
static int(*const kvm_vmx_exit_handlers[])(struct kvm_vcpu *vcpu) = {  
         [EXIT_REASON_EXCEPTION_NMI]           = handle_exception,  
         [EXIT_REASON_EXTERNAL_INTERRUPT]      = handle_external_interrupt,  
         [EXIT_REASON_TRIPLE_FAULT]            = handle_triple_fault,  
         [EXIT_REASON_NMI_WINDOW]          = handle_nmi_window,  
         [EXIT_REASON_IO_INSTRUCTION]          = handle_io,  
         [EXIT_REASON_CR_ACCESS]               = handle_cr,  
         [EXIT_REASON_DR_ACCESS]               = handle_dr,  
         [EXIT_REASON_CPUID]                   = handle_cpuid,  
         [EXIT_REASON_MSR_READ]                = handle_rdmsr,  
         [EXIT_REASON_MSR_WRITE]               = handle_wrmsr,  
         [EXIT_REASON_PENDING_INTERRUPT]       = handle_interrupt_window,  
         [EXIT_REASON_HLT]                     = handle_halt,  
         [EXIT_REASON_INVD]                     = handle_invd,  
         [EXIT_REASON_INVLPG]               = handle_invlpg,  
         [EXIT_REASON_RDPMC]                   = handle_rdpmc,  
         [EXIT_REASON_VMCALL]                  = handle_vmcall,  
         [EXIT_REASON_VMCLEAR]                    = handle_vmclear,  
         [EXIT_REASON_VMLAUNCH]                = handle_vmlaunch,  
         [EXIT_REASON_VMPTRLD]                 = handle_vmptrld,  
         [EXIT_REASON_VMPTRST]                 = handle_vmptrst,  
         [EXIT_REASON_VMREAD]                  = handle_vmread,  
         [EXIT_REASON_VMRESUME]                = handle_vmresume,  
         [EXIT_REASON_VMWRITE]                 = handle_vmwrite,  
         [EXIT_REASON_VMOFF]                   = handle_vmoff,  
         [EXIT_REASON_VMON]                    = handle_vmon,  
         [EXIT_REASON_TPR_BELOW_THRESHOLD]     = handle_tpr_below_threshold,  
         [EXIT_REASON_APIC_ACCESS]             = handle_apic_access,  
         [EXIT_REASON_APIC_WRITE]              = handle_apic_write,  
         [EXIT_REASON_EOI_INDUCED]             = handle_apic_eoi_induced,  
         [EXIT_REASON_WBINVD]                  = handle_wbinvd,  
         [EXIT_REASON_XSETBV]                  = handle_xsetbv,  
         [EXIT_REASON_TASK_SWITCH]             = handle_task_switch,  
         [EXIT_REASON_MCE_DURING_VMENTRY]      = handle_machine_check,  
         [EXIT_REASON_EPT_VIOLATION]         = handle_ept_violation,  
         [EXIT_REASON_EPT_MISCONFIG]           = handle_ept_misconfig,  
         [EXIT_REASON_PAUSE_INSTRUCTION]       = handle_pause,  
         [EXIT_REASON_MWAIT_INSTRUCTION]       =handle_invalid_op,  
         [EXIT_REASON_MONITOR_INSTRUCTION]     = handle_invalid_op,  
};  
```

这里面比如handle_ept_violation就是影子页(EPT页)缺页异常的处理函数. 

我们以handle_ept_violation()为例向下说明, 依次调用kvm_mmu_page_fault(), vcpu->arch.mmu.page_fault(), tdp_page_fault()等后续函数完成缺页处理. 

在这里, 我们要注意kvm_vmx_exit_handlers[exit_reason](vcpu)的返回值, 比如当实际调用handle_ept_violation()时返回值大于0, 就直接切回客户模式. 但是有时候可能需要Qemu的协助. 在实际调用(r = kvm_x86_ops->handle_exit(vcpu);)时, 返回值大于0, 那么就说明KVM已经处理完成, 可以再次切换进客户模式, 但如果返回值小于等于0, 那就说明需要Qemu的协助, KVM会在run结构体中的exit_reason中记录退出原因, 并进入到Qemu中进行处理. 这个判断过程是在 `__vcpu_run()` 函数中进行的, 实际是一个while循环. 

```
static int __vcpu_run(struct kvm_vcpu *vcpu)  
{  
         ......//省略部分代码  
         r = 1;  
         while (r > 0) {  
                   if (vcpu->arch.mp_state ==KVM_MP_STATE_RUNNABLE &&  
                       !vcpu->arch.apf.halted)  
                            r =vcpu_enter_guest(vcpu);  
                   else {  
                            ......//省略部分代码  
                   }  
                   if (r <= 0)  
                            break;  
           ......//省略部分代码  
         }  
         srcu_read_unlock(&kvm->srcu,vcpu->srcu_idx);  
         vapic_exit(vcpu);  
         return r;  
}  
```

上面函数中vcpu_enter_guest()我们前面讲过, 是在kvm内核中转入客户模式的函数, 他处于while循环中, 也就是如果不需要Qemu的协助, 即r>0, 那就继续循环, 然后重新切换进客户系统运行, 如果需要Qemu的协助, 那返回值r<=0,退出循环, 向上层返回r. 

上面说的r一直往上层返回, 直到kvm_vcpu_ioctl()函数中的

case KVM_RUN: 

trace_kvm_userspace_exit(vcpu->run->exit_reason, r);

这一条语句就是将退出原因注入到Qemu层. 

Qemu层这时候读取到ioctl的返回值, 然后继续执行, 就会判断有没有KVM的异常注入, 这里其实我在前一篇文章中简单提及了一下. 

```cpp
int kvm_cpu_exec(CPUArchState *env)  
{  
    .......  
    do {  
        ......  
        run_ret = kvm_vcpu_ioctl(cpu, KVM_RUN,0);  
        ......  
        trace_kvm_run_exit(cpu->cpu_index,run->exit_reason);  
        switch (run->exit_reason) {  
        case KVM_EXIT_IO:  
            ......  
            break;  
        case KVM_EXIT_MMIO:  
            ......  
            break;  
        case KVM_EXIT_IRQ_WINDOW_OPEN:  
            .......  
           break;  
        case KVM_EXIT_SHUTDOWN:  
            ......  
            break;  
        case KVM_EXIT_UNKNOWN:  
            ......  
            break;  
        case KVM_EXIT_INTERNAL_ERROR:  
            ......  
            break;  
        default:  
            ......  
            break;  
        }  
    } while (ret == 0);  
}
```

trace_kvm_run_exit(cpu->cpu_index,run->exit_reason);这条语句就是接收内核注入的退出原因, 后面switch语句进行处理, 每一个case对应一种退出原因, 这里你也可以自己添加的. 因为也是在while循环中, 处理完一次后又进行ioctl调用运行虚拟机并切换到客户模式, 这就形成了一个完整的闭环. 