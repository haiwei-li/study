


```x86asm
/**
 * __vmx_vcpu_run - Run a vCPU via a transition to VMX guest mode
 * @vmx:    struct vcpu_vmx * (forwarded to vmx_update_host_rsp)
 * @regs:   unsigned long * (to guest registers)
 * @launched:   %true if the VMCS has been launched
 *
 * Returns:
 *  0 on VM-Exit, 1 on VM-Fail
 */
SYM_FUNC_START(__vmx_vcpu_run)
    ......
    /* Enter guest mode */
    // 调用进入 guest 模式
    call vmx_vmenter

    /* Jump on VM-Fail. */
    // 如果 CF=1 或者 ZF=1, 表明 VMfailInvalid 或者 VMfailValid
    jbe 2f
    ......
1:
    ......
    ret
    /* VM-Fail.  Out-of-line to avoid a taken Jcc after VM-Exit. */
    // VM-fail, 所以将 eax 设为 1, 即返回值
2:  mov $1, %eax
    jmp 1b
SYM_FUNC_END(__vmx_vcpu_run)
```

如果成功 `VM-entry + VM-exit`, 则会直接跳转到 `vmx_vmexit` 处.

**如果 CF=1 或者 ZF=1**(jbe 的作用), 则会跳到 2 处, 设置**返回值为 1**, 然后会返回.

```
/**
 * vmx_vmenter - VM-Enter the current loaded VMCS
 *
 * %RFLAGS.ZF:  !VMCS.LAUNCHED, i.e. controls VMLAUNCH vs. VMRESUME
 *
 * Returns:
 *  %RFLAGS.CF is set on VM-Fail Invalid
 *  %RFLAGS.ZF is set on VM-Fail Valid
 *  %RFLAGS.{CF,ZF} are cleared on VM-Success, i.e. VM-Exit
 *
 * Note that VMRESUME/VMLAUNCH fall-through and return directly if
 * they VM-Fail, whereas a successful VM-Enter + VM-Exit will jump
 * to vmx_vmexit.
 */
SYM_FUNC_START_LOCAL(vmx_vmenter)
    /* EFLAGS.ZF is set if VMCS.LAUNCHED == 0 */
    // 如果 zf=1, 即 VMCS.LAUNCHED = 0, 首次进入
    // 跳到 2
    je 2f

1:  vmresume
    ret

2:  vmlaunch
    ret

    // 比较
3:  cmpb $0, kvm_rebooting
    // zf=1, 则跳到 4, 即上面相等
    je 4f
    ret
4:  ud2

    _ASM_EXTABLE(1b, 3b)
    _ASM_EXTABLE(2b, 3b)

SYM_FUNC_END(vmx_vmenter)
```

这里的 `vmresume` 和 `vmlaunch` 只要发生 VM-fail 就会直接返回, 而如果成功 `VM-entry + VM-exit` 就会直接跳转到 `vmx_vmexit` 处.

疑问: 什么情况下会走到 3

* `JBE X`的意思是 "小于等于则跳转"(即"**如果 CF=1 或者 ZF=1**")
* `JE X`的意思是 "等于则跳转"(即"**如果 rflags.ZF=1, 则跳到 X**")
* `ud2`的意思是 "抛出操作码无效异常", 即产生 `#UD` 异常

1. 产生异常
2. 产生 `VM-exit` 行为
3. 产生 `VMfailInvalid` 失败或者 `VMfailValid` 失败
