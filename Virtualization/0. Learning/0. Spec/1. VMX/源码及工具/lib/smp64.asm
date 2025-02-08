;*************************************************
;* smp64.asm                                     *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************




        


;-----------------------------------------------------
; dispatch_to_processor_sets64()
; input:
;       esi - sets of index
;       rdi - routine 入口
;       rax - delivery 类型
; 描述: 
;       1) 发送 IPI 给一组CPU
;-----------------------------------------------------
dispatch_to_processor_sets64:
        push rbx         
        push rcx
        push rdx
        push r15
        mov ecx, esi
        mov edx, esi
        mov r15d, eax
        
        
        ;;
        ;; 得到目标处理器的 PCB 块
        ;;
dispatch_to_processor_sets64.@0:
        bsf esi, ecx
        jz dispatch_to_processor_sets64.@1
        
        ;;
        ;; 置处理器为 busy 状态(去掉 usable processor 列表)
        ;;
        lock btr DWORD [fs: SDA.UsableProcessorMask], esi               ; 处理器为 unusable 状态
        btr ecx, esi
        
        call get_processor_pcb
        mov rbx, rax
        mov eax, STATUS_PROCESSOR_INDEX_EXCEED
        test rbx, rbx
        jz dispatch_to_processor_sets64.@1
        
        ;;
        ;; 写入 Routine 入口地址到 PCB 中
        ;;
        mov [rbx + PCB.IpiRoutinePointer], rdi       
        jmp dispatch_to_processor_sets64.@0

dispatch_to_processor_sets64.@1:                
        ;;
        ;; 发送 IPI 到目标处理器
        ;;
        mov eax, [rbx + PCB.ApicId]
        shl edx, 24
        mov rsi, [gs: PCB.LapicBase]
        mov [rsi + ICR1], edx
        or r15d, IPI_VECTOR | LOGICAL
        mov DWORD [rsi + ICR0], r15d
                
dispatch_to_processor_sets64.done:        
        pop r15
        pop rdx
        pop rcx
        pop rbx        
        ret
        




        
        
;-----------------------------------------------------
; dispatch_routine64()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 处理器的 IPI 服务例程
;-----------------------------------------------------        
dispatch_routine64:
        ;;
        ;; 读取返回参数
        ;;
        pop QWORD [gs: PCB.RetRip]
        pop QWORD [gs: PCB.RetCs]
        pop QWORD [gs: PCB.Rflags]
        pop QWORD [gs: PCB.RetRsp]
        pop QWORD [gs: PCB.RetSs]
        
        ;;
        ;; 保存 context
        ;;
        pusha64
        
        mov rbp, rsp
                
        ;;
        ;; 构造 BottomHalf 例程 0 级中断栈
        ;;
        push KernelSsSelector64                 ; ss
        push rbp                                ; rsp
        push 02 | FLAGS_IF                      ; rflags, 可中断
        push KernelCsSelector64                 ; cs
        push dispatch_routine64.BottomHalf      ; rip
                
        ;;
        ;; 读 routine 入口地址
        ;;
        mov rbx, [gs: PCB.IpiRoutinePointer]

        ;;
        ;; IPI routine 返回, 目标任务由 BottomHalf 处理
        ;;
        LAPIC_EOI_COMMAND
        iret64        
        
        
        
                

  
;-----------------------------------------------------
; dispatch_routine64.BottomHalf
; 描述: 
;       dispatch_routine 的下半部分处理
;-----------------------------------------------------
dispatch_routine64.BottomHalf:               
        ;;
        ;; 执行目标任务
        ;;
        test rbx, rbx
        jz dispatch_routine64.BottomHalf.@1
        call rbx
        
        ;;
        ;; 写入 routine 返回状态
        ;;
        mov [fs: SDA.LastStatusCode], eax
        
        ;;
        ;; 如果提供了 Ipi routine 下半部分处理, 则执行
        ;;
        mov rax, [gs: PCB.IpiRoutineBottomHalf]
        test rax, rax
        jz dispatch_routine64.BottomHalf.@1
        call rax
        
dispatch_routine64.BottomHalf.@1:
        ;;
        ;; 目标处理器已完成工作, 置为 usable 状态
        ;;
        mov ecx, [gs: PCB.ProcessorIndex]
        lock bts DWORD [fs: SDA.UsableProcessorMask], ecx        

        ;;
        ;; 置内部信号有效
        ;;
        SET_INTERNAL_SIGNAL
        
        ;;
        ;; 恢复 context 返回被中断者
        ;;
        popa64                                                  ; 被中断者 context

        cli
        mov rsp, [gs: PCB.ReturnStackPointer]
        popf
        
        ;;
        ;; 检查是否返回 0 级
        ;;
        test DWORD [gs: PCB.RetCs], 03
        jz dispatch_routine64.BottomHalf.R0
        sti
        retf64
        
dispatch_routine64.BottomHalf.R0:
        mov rsp, [gs: PCB.RetRsp]
        sti
        jmp QWORD FAR [gs: PCB.RetRip]
        
        


;-----------------------------------------------------
; goto_entry64()
; input:
;       rsi - 目标地址
; output:
;       none
; 描述: 
;       1) 让处理器转入执行入口点代码
;-----------------------------------------------------
goto_entry64:
        push rax
        push rbp
        mov rbp, rsp
        
        add rsp, 24                                     ; 指向 CS
        
        ;;
        ;; 检查被中断者权限
        ;;
        test DWORD [rsp], 03                            ; 检查 CS 
        jz goto_entry64.@0
        
        ;;
        ;; 属于非0级, 改写为 0 级中断栈
        ;;
        add rsp, 32                                     ; 指向未压入返回参数前
        mov rax, rsp
        push KernelSsSelector64
        push rax
        push 02 | FLAGS_IF                              ; 压入 rflags
        push KernelCsSelector64                         ; 压入 cs       
        
goto_entry64.@0:        
        push QWORD [gs: PCB.IpiRoutinePointer]          ; 原返回地址 <--- 目标地址
        
        mov rax, [gs: PCB.LapicBase]
        mov DWORD [rax + EOI], 0
        mov rax, [rbp + 8]
        mov rbp, [rbp]
        iret64                                          ; 转入目标地址


        