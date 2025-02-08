;*************************************************
;* smp.asm                                       *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************
     


;;
;; 定义IPI执行方式
;;      1) GOTO_ENTRY:                  让处理器跳转到入口点
;;      2) DISPATCH_TO_ROUTINE:         让处理器执行一段 routine
;;      3) FORCE_DISPATCH_TO_ROUTINE:   让处理器执行 NMI handler
;;
%define GOTO_ENTRY                      FIXED_DELIVERY | IPI_ENTRY_VECTOR
%define DISPATCH_TO_ROUTINE             FIXED_DELIVERY | IPI_VECTOR
%define FORCE_DISPATCH_TO_ROUTINE       NMI_DELIVERY | 02h





;-----------------------------------------------------
; force_dispatch_to_processor()
; input:
;       esi - 处理器 index
;       edi - routine 入口
; output:
;       eax - status code
; 描述: 
;       1) 使用 NMI delivery 方式发送 IPI
;       2) 将忽略目标处理器的 eflags.IF 标志位
;-----------------------------------------------------
force_dispatch_to_processor:
        mov eax, FORCE_DISPATCH_TO_ROUTINE
        jmp dispatch_to_processor.Entry



;-----------------------------------------------------
; goto_processor()
; input:
;       esi - 处理器 Index 号
;       edi - entry
; output:
;       eax - status code 
; 描述: 
;       1) 转到目标处理器的入口点执行
;       2) 输入参数 esi 提供目标处理器的 index 值(从0开始)
;       3) 输入参数 edi 提供目标代码入口地址
;       4) 这个函数无须等待直接返回       
;       5) 可以给自己调度执行！
;-----------------------------------------------------
goto_processor:
        mov eax, GOTO_ENTRY
        jmp dispatch_to_processor.Entry



;-----------------------------------------------------
; dispatch_to_processor()
; input:
;       esi - 处理器 Index 号
;       edi - routine 入口
; output:
;       eax - status code
; 描述: 
;       1) 将一段 routine 调度到某个处理器执行
;       2) 输入参数 esi 提供目标处理器的 index 值(从0开始)
;       3) 输入参数 edi 提供目标代码入口地址
;       4) 这个函数无须等待直接返回       
;       5) 不能自己给自己调度任务执行！
;-----------------------------------------------------
dispatch_to_processor:
        mov eax, DISPATCH_TO_ROUTINE


dispatch_to_processor.Entry:
        push ebp
        push ebx         
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif               

        mov ecx, esi                                                    ; 处理器 index 值
        mov edx, eax
        
        ;;
        ;; 得到目标处理器的 PCB 块
        ;;
        call get_processor_pcb
        REX.Wrxb
        mov ebx, eax
        
        ;;
        ;; 检查是否出错
        ;;
        mov eax, STATUS_PROCESSOR_INDEX_EXCEED
        REX.Wrxb
        test ebx, ebx
        jz dispatch_to_processor.done
        

        ;;
        ;; 置处理器为 busy 状态(去掉 usable processor 列表)
        ;;
        mov eax, SDA.UsableProcessorMask
        lock btr DWORD [fs: eax], ecx                                   ; 处理器为 unusable 状态
        
        cmp edx, FORCE_DISPATCH_TO_ROUTINE
        jne dispatch_to_processor.@0
        ;;
        ;; 如果是使用 NMI delivery 方式
        ;;
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]                                    ; sda base
        REX.Wrxb
        mov [ebp + SDA.NmiIpiRoutine], edi                              ; 写入 SDA.NmiIpiRoutine
        lock bts DWORD [ebp + SDA.NmiIpiRequestMask], ecx               ; 设置 Nmi IPI routine Mask位
        jmp dispatch_to_processor.@1
        
dispatch_to_processor.@0:        
        ;;
        ;; 写入 Routine 入口地址到 PCB 中
        ;;
        REX.Wrxb
        mov [ebx + PCB.IpiRoutinePointer], edi


dispatch_to_processor.@1:
        
        ;;
        ;; 使用物理ID方式, 发送 IPI 到目标处理器
        ;;
        mov esi, [ebx + PCB.ApicId]                     ; 处理器 ID 值        
        SEND_IPI_TO_PROCESSOR   esi, edx
  
        mov eax, STATUS_SUCCESS
        
dispatch_to_processor.done:
        pop edx
        pop ecx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------
; dipatch_to_processor_with_waitting()
; input:
;       esi - 处理器 Index 号
;       edi - routine 入口
; output:
;       eax - status code
; 描述: 
;       1) 将一段 routine 调度到某个处理器执行
;       2) 输入参数 esi 提供目标处理器的 index 值(从0开始)
;       3) 输入参数 edi 提供目标代码入口地址
;       4) 这个函数等 dispatch routine 完成后返回
;-----------------------------------------------------
dispatch_to_processor_with_waitting:
        ;;
        ;; 内部信号无效
        ;;
        RELEASE_INTERNAL_SIGNAL
        
        ;;
        ;; 调度到处理器
        ;;     
        call dispatch_to_processor
        
        ;;
        ;; 等待信号有效, 等待目标处理器执行完毕
        ;;
        WAIT_FOR_INTERNAL_SIGNAL        
        ret



;-----------------------------------------------------
; broadcast_message_exclude_self()
; input:
;       esi - routine 入口
; output:
;       none
; 描述: 
;       1) 以 NMI delivery 方式广播 IPI
;       2) 不包括自己
;-----------------------------------------------------
broadcast_message_exclude_self:
        push ebp
        push ecx
        
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif  

        xor eax, eax
        xor edi, edi
        DECv eax                                        ; eax = 0FFFFFFFFh        
        mov ecx, [ebp + SDA.ProcessorCount]             ; 处理器个数
        shld edi, eax, cl                               ; edi = ProcessorCount Mask
        mov eax, PCB.ProcessorIndex
        mov eax, [gs: eax]                              ; 处理器 index
        btr edi, eax                                    ; 清 self Mask 位                
        mov [ebp + SDA.NmiIpiRequestMask], edi          ; 写入 NMI request Mask 值
        REX.Wrxb
        mov [ebp + SDA.NmiIpiRoutine], esi              ; 写入 NMI IPI routine
        
        ;;
        ;; 广播 NMI IPI message
        ;;
        BROADCASE_MESSAGE       ALL_EX_SELF | NMI_DELIVERY | 02h

        pop ecx        
        pop ebp
        ret






;-----------------------------------------------------
; get_for_signal()
; input:
;       esi - signal
; output:
;       none
; 描述: 
;       1) 获取信号量
;       2) 输入参数 esi 提供信号地址       
;-----------------------------------------------------
get_for_signal:
        mov [fs: SDA.SignalPointer], esi
        call wait_for_signal
        ret

   
        
;-----------------------------------------------------
; wait_for_signal()
; input:
;       esi - Signal
; output:
;       none
; 描述: 
;       1) 等待 signal
;-----------------------------------------------------
wait_for_signal:
        mov eax, 1
        xor edi, edi       
        ;;
        ;; 尝试获取 lock
        ;;
wait_for_signal.acquire:
        lock cmpxchg [esi], edi
        je wait_for_signal.done

        ;;
        ;; 获取失败后, 检查 lock 是否开放(未上锁)
        ;; 1) 是, 则再次执行获取锁, 并上锁
        ;; 2) 否, 继续不断地检查 lock, 直到 lock 开放
        ;;
wait_for_signal.check:        
        mov eax, [esi]
        cmp eax, 1
        je wait_for_signal.acquire
        pause
        jmp wait_for_signal.check
wait_for_signal.done:        
        ret



;-----------------------------------------------------
; get_processor_pcb()
; input:
;       esi - 处理器 Index 值
; output:
;       eax - 该处理器的 PCB 基址
; 描述: 
;       1) 根据提供的处理器Index值(从0开始), 得到该处理器对应的 PCB 块
;       2) 出错时返回 0 值
;-----------------------------------------------------
get_processor_pcb:
        push ebp
        push edx

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif        
        ;;
        ;; 检查提供的处理器 Index 值是否超限
        ;;
        mov eax, [ebp + SDA.ProcessorCount]
        cmp esi, eax
        setb al
        movzx eax, al
        jae get_processor_pcb.done
        ;;
        ;; 目标处理器 PCB base = PCB_BASE + (Index * PCB_SIZE)
        ;;
        mov eax, PCB_SIZE
        mul esi
        REX.Wrxb
        add eax, [ebp + SDA.PcbBase]
        
get_processor_pcb.done:        
        pop edx
        pop ebp
        ret
        

;-----------------------------------------------------
; get_processor_id()
; input:
;       esi - 处理器 Index 值
; output:
;       eax - local APIC ID
; 描述: 
;       1) 根据提供的处理器Index值(从0开始), 得到该处理器 LAPIC ID
;       2) 出错时返回 -1 值
;-----------------------------------------------------
get_processor_id:
        call get_processor_pcb
        REX.Wrxb
        test eax, eax
        jz get_processor_id.FoundNot        
        mov eax, [eax + PCB.ApicId]
        ret
get_processor_id.FoundNot:
        mov eax, -1        
        ret
        
        
        
;-----------------------------------------------------
; dispatch_routine()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理器的 IPI 服务例程
;-----------------------------------------------------        
dispatch_routine:
        ;;
        ;; 保存被中断者 context
        ;;
        pusha
        
        ;;
        ;; 构造 BottomHalf 例程 0 级中断栈
        ;;
        push 02 | FLAGS_IF                      ; eflags, 可中断
        push KernelCsSelector32                 ; cs
        push dispatch_routine.BottomHalf        ; eip       
       
        ;;
        ;; 读 routine 入口地址
        ;;
        mov ebx, [gs: PCB.IpiRoutinePointer]
        
        ;;
        ;; IPI routine 返回, 目标任务由 BottomHalf 处理
        ;;
        LAPIC_EOI_COMMAND                       ; 发送 EOI 命令
        iret                                    ; 转入执行 BottomHalf 例程
                



;-----------------------------------------------------
; dispatch_routine.BottomHalf
; 描述: 
;       dispatch_routine 的下半部分处理
;-----------------------------------------------------
dispatch_routine.BottomHalf:
        ;;
        ;; 当前栈中数据: 
        ;; 1) 8 个 GPRs
        ;; 2) 被中断者的返回参数
        ;;

%define RETURN_EIP_OFFSET               (8 * 4)

        mov ebp, esp
                
        ;;
        ;; 将中断栈结构调整为 far pointer
        ;;
        mov eax, [ebp + RETURN_EIP_OFFSET]                      ; 读 eip
        mov esi, [ebp + RETURN_EIP_OFFSET + 4]                  ; 读 cs
        mov ecx, [ebp + RETURN_EIP_OFFSET + 8]                  ; 读 eflags
        mov [ebp + RETURN_EIP_OFFSET + 8], esi                  ; cs 写入原 eflags 位置
        mov [ebp + RETURN_EIP_OFFSET + 4], eax                  ; eip 写入原 cs 位置
        mov [ebp + RETURN_EIP_OFFSET], ecx                      ; eflags 写入原 eip 位置
        
        ;;
        ;; 执行目标任务
        ;;
        test ebx, ebx
        jz dispatch_routine.BottomHalf.@1
        call ebx
        
        ;;
        ;; 写入状态值
        ;;
        mov [fs: SDA.LastStatusCode], eax
         
        ;;
        ;; 如果提供了 IPI routine 下半部分处理, 则执行
        ;;
        mov eax, [gs: PCB.IpiRoutineBottomHalf]
        test eax, eax
        jz dispatch_routine.BottomHalf.@1
        call eax
        
dispatch_routine.BottomHalf.@1:
        ;;
        ;; 目标处理器已完成工作, 置为 usable 状态
        ;;
        mov eax, [gs: PCB.ProcessorIndex]
        lock bts DWORD [fs: SDA.UsableProcessorMask], eax

        ;;
        ;; 置内部信号有效
        ;;        
        SET_INTERNAL_SIGNAL
     
        
%undef RETURN_EIP_OFFSET        

        ;;
        ;; 恢复 context 返回被中断者
        ;;
        popa                                                    ; 被中断者 context
        popf                                                    ; eflags
        retf                                                    ; 返回被中断者
        
                


;-----------------------------------------------------
; goto_entry()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 强制让处理器跳到入口点代码
;       2) 注意, 这种方式不能返回！
;-----------------------------------------------------
goto_entry:
        push eax
        push ebp
        mov ebp, esp
        
        add esp, 12                                             ; 指向 CS
        
        ;;
        ;; 检查被中断者权限
        ;;
        test DWORD [esp], 03                                    ; 检查 cs
        jz goto_entry.@0
        
        ;;
        ;; 属于非0级, 改写为 0 级中断栈
        ;;
        add esp, 16                                             ; 指向未压入返回参数前
        push 02 | FLAGS_IF                                      ; 压入 EFLAGS
        push KernelCsSelector32                                 ; 压入 CS
        
goto_entry.@0:        
        ;;
        ;; 写入目标地址
        ;;
        push DWORD [gs: PCB.IpiRoutinePointer]                  ; 原返回地址 <--- 目标地址

        ;;
        ;; 写 lapic EOI 命令
        ;;        
        mov eax, [gs: PCB.LapicBase]
        mov DWORD [eax + EOI], 0
        mov eax, [ebp + 4]
        mov ebp, [ebp]
        iret                                                    ; 转入目标地址




;-----------------------------------------------------
; do_schedule()
; input:
;       esi -处理器 index
; output:
;       none
; 描述: 
;       1) 按下功能键, 进行当前处理器切换
;-----------------------------------------------------
do_schedule:
        push esi
        push edi
        push ecx

        ;;
        ;; 切换当前处理器
        ;;
        mov edi, switch_to_processor
        call force_dispatch_to_processor
        
        pop ecx
        pop edi
        pop esi
        ret
        


;-----------------------------------------------------
; switch_to_processor()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 切换当前处理器
;-----------------------------------------------------
switch_to_processor:
        push ebp
        push ecx
        push ebx

        
%ifdef  __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        ;;
        ;; 切换焦点处理器
        ;;
        mov ecx, [ebp + PCB.ProcessorIndex]
        mov eax, SDA.InFocus
        xchg [fs: eax], ecx        

        ;;
        ;; 检查是否有 guese 环境存在需要切换
        ;;
        mov esi, [ebp + PCB.ProcessorStatus]
        test esi, CPU_STATUS_GUEST_EXIST
        jz switch_to_processor.host
        
        
        ;;
        ;; 检查当前处理器是否已经拥有焦点 ?
        ;; 1) 是: 则 XOR CPU_STATUS_GUEST 标志位
        ;; 2) 否: 则清 CPU_STATUS_GUEST 标志位
        ;;
        mov edi, esi
        and esi, ~CPU_STATUS_GUEST_FOCUS
        xor edi, CPU_STATUS_GUEST_FOCUS
        cmp ecx, [ebp + PCB.ProcessorIndex]
        cmove esi, edi
        mov [ebp + PCB.ProcessorStatus], esi
        
        ;;
        ;; 检查 host/guest 焦点
        ;;
        test esi, CPU_STATUS_GUEST_FOCUS
        jnz switch_to_processor.Guest


switch_to_processor.host:
        ;;
        ;; 切换 lcoal keyboard buffer
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.LsbBase]                    ; ebx = LSB
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]                    ; ebp = SDA        
        REX.Wrxb
        mov eax, [ebx + LSB.LocalKeyBufferHead]
        REX.Wrxb
        mov [ebp + SDA.KeyBufferHead], eax              ; SDA.KeyBufferHead = LSB.LocalKeyBufferHead
        REX.Wrxb
        lea eax, [ebx + LSB.LocalKeyBufferPtr]
        REX.Wrxb
        mov [ebp + SDA.KeyBufferPtrPointer], eax        ; KeyBufferPtrPointer = &LocalKeyBufferPtr
        mov eax, [ebx + LSB.LocalKeyBufferSize]
        mov [ebp + SDA.KeyBufferLength], eax            ; KeyBufferLength = LocalKeyBufferSize
        
        ;;
        ;; 切换屏幕
        ;;        
        call flush_local_video_buffer                   ; 刷新为当前处理器 local video buffer                

        jmp switch_to_processor.Done


switch_to_processor.Guest:
        ;;
        ;; 切换 VM keyboard buffer
        ;;
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov ebx, [ebx + VMB.VsbBase]
        REX.Wrxb
        mov ebp, [ebp + PCB.SdaBase]                    ; ebp = SDA       
        REX.Wrxb
        mov eax, [ebx + VSB.VmKeyBufferHead]
        REX.Wrxb
        mov [ebp + SDA.KeyBufferHead], eax              ; SDA.KeyBufferHead = VSB.VmKeyBufferHead
        REX.Wrxb
        lea eax, [ebx + VSB.VmKeyBufferPtr]
        REX.Wrxb
        mov [ebp + SDA.KeyBufferPtrPointer], eax        ; SDA.KeyBufferPtrPointer = &VmKeyBufferPtr
        mov eax, [ebx + VSB.VmKeyBufferSize]
        mov [ebp + SDA.KeyBufferLength], eax            ; SDA.KeyBufferLength = VmKeyBufferSize
        
        ;;
        ;; 切换屏幕
        ;;        
        call flush_vm_video_buffer                      ; 刷新为当前处理器 vm video buffer  

switch_to_processor.Done:        
        pop ebx
        pop ecx
        pop ebp
        ret
