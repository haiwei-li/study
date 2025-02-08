;*************************************************
;* VmxIo.asm                                     *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;
;; 处理访问 IO 端口的例程
;;



;-----------------------------------------------------------------------
; GetIoVte()
; input:
;       esi - IO port
; output:
;       eax - IO VTE(value table entry)地址
; 描述: 
;       1) 返回 IO 端口对应的 VTE 表项地址
;       2) 不存在相应的 IO Vte 时, 返回 0 值　
;-----------------------------------------------------------------------
GetIoVte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        cmp DWORD [ebx + VMB.IoVteCount], 0
        je GetIoVte.NotFound
        
        REX.Wrxb
        mov eax, [ebx + VMB.IoVteBuffer]               
        
GetIoVte.@1:                
        cmp esi, [eax]                                  ; 检查 IO 端口值
        je GetIoVte.Done
        REX.Wrxb
        add eax, IO_VTE_SIZE                            ; 指向下一条 entry
        REX.Wrxb
        cmp eax, [ebx + VMB.IoVteIndex]
        jb GetIoVte.@1
GetIoVte.NotFound:        
        xor eax, eax
GetIoVte.Done:        
        pop ebx
        pop ebp
        ret



;-----------------------------------------------------------------------
; AppendIoVte()
; input:
;       esi - IO port
;       edi - value
; output:
;       eax - VTE 地址
; 描述: 
;       1) 根据 IO 端口值向 IoVteBuffer 里写入 IO VTE
;-----------------------------------------------------------------------
AppendIoVte:
        push ebp
        push ebx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  

        REX.Wrxb
        mov ebp, [ebp + PCB.CurrentVmbPointer]     
        mov ebx, edi
        call GetIoVte
        REX.Wrxb
        test eax, eax
        jnz AppendIoVte.WriteVte
        
        mov eax, IO_VTE_SIZE
        REX.Wrxb
        xadd [ebp + VMB.IoVteIndex], eax
        inc DWORD [ebp + VMB.IoVteCount]
                
AppendIoVte.WriteVte:
        ;;
        ;; 写入 IO VTE 内容
        ;;
        mov [eax + IO_VTE.IoPort], esi
        mov [eax + IO_VTE.Value], ebx
        pop ebx
        pop ebp
        ret
        


;-----------------------------------------------------------------------
; GetExtIntRte()
; input:
;       esi - Processor index
; output:
;       eax - ExtInt RTE(route table entry)地址
; 描述: 
;       1) 返回 processor index 对应的 EXTINT_RTE 表项地址
;       2) 不存在相应的 EXTINT_RTE 表项时, 返回 0 值　
;-----------------------------------------------------------------------
GetExtIntRte:
        push ebp
                
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif  

        REX.Wrxb
        mov eax, [ebp + SDA.ExtIntRtePtr]
        cmp DWORD [ebp + SDA.ExtIntRteCount], 0
        je GetExtIntRte.NotFound
                   
        
GetExtIntRte.@1:                
        cmp esi, [eax]                                   ; 检查 processor index 值
        je GetExtIntRte.Done
        REX.Wrxb
        add eax, EXTINT_RTE_SIZE                        ; 指向下一条 entry
        REX.Wrxb
        cmp eax, [ebp + SDA.ExtIntRteIndex]
        jb GetExtIntRte.@1
GetExtIntRte.NotFound:        
        xor eax, eax
GetExtIntRte.Done:        
        pop ebp
        ret



;-----------------------------------------------------------------------
; GetExtIntRteWithVector()
; input:
;       esi - vector
; output:
;       eax - ExtInt RTE(route table entry)地址
; 描述: 
;       1) 返回 vector 对应的 EXTINT_RTE 表项地址
;       2) 不存在相应的 EXTINT_RTE 表项时, 返回 0 值　
;-----------------------------------------------------------------------
GetExtIntRteWithVector:
        push ebp
                
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif  

        REX.Wrxb
        mov eax, [ebp + SDA.ExtIntRtePtr]
        cmp DWORD [ebp + SDA.ExtIntRteCount], 0
        je GetExtIntRteWithVector.NotFound
                           
GetExtIntRteWithVector.@1:                
        cmp esi, [eax + EXTINT_RTE.Vector]              ; 检查 vecotr 值
        je GetExtIntRteWithVector.Done
        REX.Wrxb
        add eax, EXTINT_RTE_SIZE                        ; 指向下一条 entry
        REX.Wrxb
        cmp eax, [ebp + SDA.ExtIntRteIndex]
        jb GetExtIntRteWithVector.@1
GetExtIntRteWithVector.NotFound:        
        xor eax, eax
GetExtIntRteWithVector.Done:        
        pop ebp
        ret
        
        
        

;-----------------------------------------------------------------------
; AppendExtIntRte()
; input:
;       esi - vector
; output:
;       eax - EXTINT_RTE 地址
; 描述: 
;       1) 根据 processor ID 向 ExtIntRteBuffer 写入 ITE 
;-----------------------------------------------------------------------
AppendExtIntRte:
        push ebp
        push ebx
        push ecx
                
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
        
        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]
        mov ecx, esi
        mov esi, [ebp + PCB.ApicId]
        call GetExtIntRte
        REX.Wrxb
        test eax, eax
        jnz AppendExtIntRte.WriteRte
        
        mov eax, EXTINT_RTE_SIZE
        REX.Wrxb
        xadd [ebx + SDA.ExtIntRteIndex], eax
        lock inc DWORD [ebx + SDA.ExtIntRteCount]
                
AppendExtIntRte.WriteRte:
        ;;
        ;; 写入 IO VTE 内容
        ;;
        mov esi, [ebp + PCB.ProcessorIndex]
        mov [eax + EXTINT_RTE.ProcessorIndex], esi
        mov [eax + EXTINT_RTE.Vector], ecx
        lock or DWORD [eax + EXTINT_RTE.Flags], RTE_8259_IRQ0

        pop ecx
        pop ebx
        pop ebp
        ret
        
        


;-----------------------------------------------------------------------
; do_guest_io_process()
; input:
;       none
; output:
;       eax - status code
; 描述: 
;       1) 进行 guest IO 指令的相应处理
;-----------------------------------------------------------------------
do_guest_io_process:
        push ebp
        push ebx
        push ecx
        push edx
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif  
       
        REX.Wrxb
        mov ebx, [ebp + PCB.CurrentVmbPointer]
        
        cmp DWORD [ebp + PCB.LastStatusCode], STATUS_GUEST_PAGING_ERROR
        je do_guest_io_process.Pf
        
        mov edx, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoFlags]
        test edx, IO_FLAGS_IN
        jnz do_guest_io_process.In
        
        ;;
        ;; 处理 OUT/OUTS
        ;;
do_guest_io_process.Out:
        DEBUG_RECORD    "processing OUT instruciton ..."

        ;;
        ;; #### 作为示例, 保留实现串指令的处理 ####
        ;;
        test edx, IO_FLAGS_STRING
        jnz do_guest_io_process.Done

        ;;
        ;; 将 guest 尝试写 IO 寄存器的值保存在 IO-VTE 里
        ;;        
        mov ecx, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoPort]
        mov esi, ecx
        mov edi, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Value]
        call AppendIoVte
 
        ;;
        ;; 检查 guest 是否处于 8259 初始化工作流程!
        ;; 1) 检查是否写 MASTER_ICW1_PORT 端口
        ;;    a) 是, 则检查下一个是否为 MASTER_ICW2_PORT 端口
        ;;    b) 否, 则忽略
        ;;

       
        ;;
        ;; 检查是否为 20h 端口
        ;;
        cmp ecx, 20h
        jne do_guest_io_process.Out.@1

        movzx eax, BYTE [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Value]       
        ;;
        ;; 检查写入值: 
        ;; 1) bit 4 = 1 时: 写入 ICW 字
        ;; 2) bit 5 = 1 时, 写入 EOI 字
        ;;
        test eax, (1 << 4)
        jnz do_guest_io_process.Out.20h.ICW1
        test eax, (1 << 5)
        jz do_guest_io_process.Done
        
        ;;
        ;; 属于 EOI 命令, 则由 VMM 向 local APIC 写入 EOI
        ;;
        LAPIC_EOI_COMMAND
        jmp do_guest_io_process.Done        

do_guest_io_process.Out.20h.ICW1:        
        ;;
        ;; 设置 8259 MASTER 初始化标志位
        ;;        
        or DWORD [ebx + VMB.IoOperationFlags], IOP_FLAGS_8259_MASTER_INIT
        jmp do_guest_io_process.Done

do_guest_io_process.Out.@1:
        ;;
        ;; 检查接下来是否写 MASTER_ICW2_PORT 端口
        ;;
        cmp ecx, MASTER_ICW2_PORT
        jne do_guest_io_process.Done
        test DWORD [ebx + VMB.IoOperationFlags], IOP_FLAGS_8259_MASTER_INIT
        jz do_guest_io_process.Done

        ;;
        ;; 清 8259 MASTER 初始化标志位
        ;;
        and DWORD [ebx + VMB.IoOperationFlags], ~IOP_FLAGS_8259_MASTER_INIT
        
        ;;
        ;; 将 vector 添加到 ExtIntRte 表项里
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Value]
        call AppendExtIntRte
        jmp do_guest_io_process.Done


do_guest_io_process.In:        
        DEBUG_RECORD    "processing IN instruction ..."
        
        ;;
        ;; 处理 IN/INS
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoPort]
        call GetIoVte
        REX.Wrxb
        test eax, eax
        jz do_guest_io_process.Done
        
        mov ecx, [eax + IO_VTE.Value]                           ; IO port 原值        
        REX.Wrxb
        mov ebx, [ebx + VMB.VsbBase]                            ; VSB 区域
        
        ;;
        ;; 检查是否属于串指令
        ;;
        test edx, IO_FLAGS_STRING
        jnz do_guest_io_process.In.String
        
        ;;
        ;; 处理 IN al/ax/eax, IoPort 
        ;;
        mov esi, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.OperandSize]
        cmp esi, IO_OPS_BYTE
        je do_guest_io_process.In.Byte
        cmp esi, IO_OPS_WORD
        je do_guest_io_process.In.Word
        
        ;;
        ;; 写入 dwrod 值
        ;;
        REX.Wrxb
        mov [ebx + VSB.Rax], ecx
        jmp do_guest_io_process.Done
        
do_guest_io_process.In.Byte:
        ;;
        ;; 写入 byte 值
        ;;
        mov [ebx + VSB.Rax], cl
        jmp do_guest_io_process.Done
        
do_guest_io_process.In.Word:
        ;;
        ;; 写入 word 值
        ;;
        mov [ebx + VSB.Rax], cx
        jmp do_guest_io_process.Done
        
        
        
do_guest_io_process.In.String:
        ;;
        ;; #### 作为示例, 保留实现对串指令的处理 ####
        ;; 
        jmp do_guest_io_process.Done
        
%if 0
        ;;
        ;; 处理 INS 指令
        ;;
        REX.Wrxb
        mov edi, [[ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.LinearAddress]
        
        test DWORD [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Flags], IO_FLAGS_REP
        jz do_guest_io_process.In.String.@1
        mov ecx, [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.Count]
        
do_guest_io_process.In.String.@1:

%endif


do_guest_io_process.Pf:
        mov ecx, INJECT_EXCEPTION_PF
        mov eax, 2
        test DWORD [ebp + PCB.GuestExitInfo + IO_INSTRUCTION_INFO.IoFlags], IO_FLAGS_IN
        jz do_guest_io_process.ReflectException
        mov eax, 0
        
do_guest_io_process.ReflectException:
        SetVmcsField    VMENTRY_EXCEPTION_ERROR_CODE, eax
        SetVmcsField    VMENTRY_INTERRUPTION_INFORMATION, ecx

do_guest_io_process.Done:    
        pop edx    
        pop ecx
        pop ebx
        pop ebp
        ret




;-----------------------------------------------------------------------
; set_io_bitmap_for_8259()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 设置 8259 相关的 IO bitmap
;-----------------------------------------------------------------------
set_io_bitmap_for_8259:
        mov esi, 20h                    ;; MASTER ICW1, OCW2, OCW3
        call set_io_bitmap
        mov esi, 21h                    ;; MASTER ICW2, ICW3, ICW4, OCW1
        call set_io_bitmap              
        mov esi, 0A0h                   ;; SLAVE ICW1, OCW2, OCW3
        call set_io_bitmap
        mov esi, 0A1h                   ;; SLAVE ICW2, ICW3, ICW4, OCW1
        call set_io_bitmap        
        ret
        