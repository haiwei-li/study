;*************************************************
; pic8259.asm                                    *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%include "..\inc\ports.inc"



;----------------------------------------------
; init_8253() - init 8253-PIT controller
;----------------------------------------------        
init_8253:
        mov al, 36h                                   ; set to 100Hz
        out PIT_CONTROL_PORT, al
        xor ax, ax
        out PIT_COUNTER0_PORT, al
        out PIT_COUNTER0_PORT, al
        ret
        
        
;-------------------------------------------------
; init_8259()
; input:
;       none
; ouput:
;       none
; 描述: 
;       初始化 8259 设置
;       1) master 片中断向量是 20h
;       2) slave 片中断向量是 28h       
;-------------------------------------------------
init_pic8259:
;;; 初始化 master 8259A 芯片
; 1) 先写 ICW1
	mov al, 11h  					; ICW = 1, ICW4-write required
	out MASTER_ICW1_PORT, al
	jmp $+2
	nop
; 2) 接着写 ICW2
	mov al, PIC8259A_IRQ0_VECTOR                    ; interrupt vector
	out MASTER_ICW2_PORT, al
	jmp $+2
	nop
; 3) 接着写 ICW3				
	mov al, 04h					; bit2 must be 1
	out MASTER_ICW3_PORT, al
	jmp $+2
	nop
; 4) 接着写 ICW4
	mov al, 01h					; for Intel Architecture
	out MASTER_ICW4_PORT, al
	jmp $+2
        nop
;; 初始化 slave 8259A 芯片
; 1) 先写 ICW1
	mov al, 11h					; ICW = 1, ICW4-write required
	out SLAVE_ICW1_PORT, al
	jmp $+2
	nop
; 2) 接着写 ICW2
	mov al, PIC8259A_IRQ0_VECTOR + 8                ; interrupt vector
	out SLAVE_ICW2_PORT, al
	jmp $+2
	nop
; 3) 接着写 ICW3				
	mov al, 02h					; bit2 must be 1
	out SLAVE_ICW3_PORT, al
	jmp $+2
	nop
; 4) 接着写 ICW4
	mov al, 01h					; for Intel Architecture
	out SLAVE_ICW4_PORT, al		
	ret


;-------------------------------------------------
; setup_pic8259()
; input:
;       none
; 描述: 
;       初始化 8259 并设置相应的中断服务例程
;-------------------------------------------------
setup_pic8259:
        ;;
        ;; 初始化 8259 和 8253
        ;;
        call init_pic8259
        call init_8253                             
        call disable_8259
        ret
	
	
	
;--------------------------
; write_master_EOI:
;--------------------------
write_master_EOI:
	mov al, 00100000B				; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
	ret
        
;-----------------------------
; 宏 MASTER_EOI()
;-----------------------------
%macro MASTER_EOI 0
	mov al, 00100000B				; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
%endmacro
        
        
        
        
write_slave_EOI:
        mov al,  00100000B
        out SLAVE_OCW2_PORT, al
        ret
	
;-----------------------------
; 宏 SLAVE_EOI()
;-----------------------------
%macro SLAVE_EOI 0
        mov al,  00100000B
        out SLAVE_OCW2_PORT, al
%endmacro


;----------------------------
; 屏蔽所有 8259 中断
;----------------------------
disable_8259:
        mov al, 0FFh
	out MASTER_MASK_PORT, al        
        ret

;--------------------------
; mask timer
;--------------------------
disable_8259_timer:
	in al, MASTER_MASK_PORT
	or al, 0x01
	out MASTER_MASK_PORT, al
	ret	
	
enable_8259_timer:
	in al, MASTER_MASK_PORT
	and al, 0xfe
	out MASTER_MASK_PORT, al
	ret	
		
;--------------------------
; mask 键盘
;--------------------------
disable_8259_keyboard:
	in al, MASTER_MASK_PORT
	or al, 0x02
	out MASTER_MASK_PORT, al
	ret
	
enable_8259_keyboard:
	in al, MASTER_MASK_PORT
	and al, 0xfd
	out MASTER_MASK_PORT, al
	ret	
	
;------------------------------
; read_master_isr:
;------------------------------
read_master_isr:
	mov al, 00001011B			; OCW3 select, read ISR
	out MASTER_OCW3_PORT, al
	jmp $+2
	in al, MASTER_OCW3_PORT
	ret
read_slave_isr:
	mov al, 00001011B
        out SLAVE_OCW3_PORT, al
        jmp $+2
        in al, SLAVE_OCW3_PORT
        ret
;-------------------------------
; read_master_irr:
;--------------------------------
read_master_irr:
	mov al, 00001010B			; OCW3 select, read IRR	
	out MASTER_OCW3_PORT, al
	jmp $+2
	in al, MASTER_OCW3_PORT
	ret

read_slave_irr:
        mov al, 00001010B
        out SLAVE_OCW3_PORT, al
        jmp $+2
        in al, SLAVE_OCW3_PORT
        ret

read_master_imr:
	in al, MASTER_IMR_PORT
	ret
        
read_slave_imr:
        in al, SLAVE_IMR_PORT
        ret
;------------------------------
; send_smm_command
;------------------------------
send_smm_command:
	mov al, 01101000B			; SMM=ESMM=1, OCW3 select
	out MASTER_OCW3_PORT, al	
	ret
        

	
	
;--------------------------------------------------
; keyboard_8259_handler:
; 描述: 
;       使用于 8259 IRQ1 handler
;--------------------------------------------------
keyboard_8259_handler:                
        push ebp
        push ecx
        push edx
        push ebx
        push esi
        push edi
        push eax

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif  
        
        in al, I8408_DATA_PORT                          ; 读键盘扫描码
        test al, al
        js keyboard_8259_handler.done                   ; 为 break code
  
        ;;
        ;; 是否为功能键
        ;;
        cmp al, SC_F1
        jb keyboard_8259_handler.next
        cmp al, SC_F10
        ja keyboard_8259_handler.next

        ;;
        ;; 切换当前处理器
        ;;
        sub al, SC_F1
        movzx esi, al
        mov edi, switch_to_processor
        call force_dispatch_to_processor
        
        
        jmp keyboard_8259_handler.done
        
keyboard_8259_handler.next:
        
        ;;
        ;; 将扫描码保存在处理器自己的 local keyboard buffer 中
        ;; local keyboard buffer 由 SDA.KeyBufferHeadPointer 和 SDA.KeyBufferPtrPointer 指针指向
        ;;
        REX.Wrxb
        mov ebx, [ebp + SDA.KeyBufferPtrPointer]                ; ebx = LSB.LocalKeyBufferPtr 指针值
        REX.Wrxb
        mov esi, [ebx]                                          ; esi = LSB.LocalKeyBufferPtr 值
        REX.Wrxb
        INCv esi
        
     
        ;;
        ;; 检查是否超过缓冲区长度
        ;;
        mov ecx, [ebp + SDA.KeyBufferLength]
        REX.Wrxb
        mov edi, [ebp + SDA.KeyBufferHead]
        REX.Wrxb
        add ecx, edi        
        REX.Wrxb
        cmp esi, ecx
        REX.Wrxb
        cmovae esi, edi                                         ; 如果到达缓冲区尾部, 则指向头部
        mov [esi], al                                           ; 写入扫描码
        REX.Wrxb
        xchg [ebx], esi                                         ; 更新缓冲区指针 
        
        ;;
        ;; 检查是否需要发送外部中断 IPI 的目标处理器
        ;;
        REX.Wrxb
        mov ebx, [ebp + SDA.ExtIntRtePtr]
        mov ecx, [ebp + SDA.ExtIntRteCount]
        test ecx, ecx
        jz keyboard_8259_handler.done

        mov edx, [ebp + SDA.InFocus]     
keyboard_8259_handler.SendExtIntIpi:
        ;;
        ;; 检查目标处理器是否拥有焦点
        ;;
        cmp edx, [ebx + EXTINT_RTE.ProcessorIndex]
        jne keyboard_8259_handler.SendExtIntIpi.Next

        mov esi, edx
        call get_processor_pcb
        REX.Wrxb
        test eax, eax
        jz keyboard_8259_handler.SendExtIntIpi.Next

        ;;
        ;; 检查目标处理器是否处于 guest, 并且拥有焦点
        ;;
        mov esi, [eax + PCB.ProcessorStatus]
        xor esi, CPU_STATUS_GUEST | CPU_STATUS_GUEST_FOCUS
        test esi, CPU_STATUS_GUEST | CPU_STATUS_GUEST_FOCUS
        jnz keyboard_8259_handler.SendExtIntIpi.Next

        DEBUG_RECORD    "sending IPI to target processor !"
        
        ;;
        ;; 发送外部中断到目标处理器
        ;;
        mov esi, [eax + PCB.ApicId]
        movzx edi, BYTE [ebx + EXTINT_RTE.Vector]               ; 8259 的 IRQ0 vector
        INCv edi                                                ; 得到键盘中断 IRQ1 vector
        or edi, FIXED_DELIVERY | PHYSICAL        
        SEND_IPI_TO_PROCESSOR esi, edi
        
keyboard_8259_handler.SendExtIntIpi.Next:
        REX.Wrxb
        add ebx, EXTINT_RTE_SIZE 
        DECv ecx
        jnz keyboard_8259_handler.SendExtIntIpi
        
keyboard_8259_handler.done:
        MASTER_EOI
        pop eax
        pop edi
        pop esi
        pop ebx
        pop edx
        pop ecx
        pop ebp        
        REX.Wrxb
        iret


%if 0           ;; 取消 !!

;--------------------------------------------------
; Keyboard_8259_handler.BottomHalf
; input:
;       none
; output:
;       none
; 描述: 
;       1) 键盘服务例程的下半部处理
;--------------------------------------------------
Keyboard_8259_handler.BottomHalf:
        ;;
        ;; 此时, 栈中数据为: 
        ;; 1) 保存的 context
        ;; 2) 返回参数
        ;;

%ifdef __X64
%define RETURN_EIP_OFFSET               (5 * 8)
%define REG_WIDTH                       8
%else
%define RETURN_EIP_OFFSET               (5 * 4)
%define REG_WIDTH                       4
%endif        

        REX.Wrxb
        mov esi, esp
        
        ;;
        ;; 将中断栈结构调整为 far call 栈结构
        ;;

        REX.Wrxb
        mov eax, [esi + RETURN_EIP_OFFSET]                      ; 读 eip
        REX.Wrxb
        mov ebx, [esi + RETURN_EIP_OFFSET + REG_WIDTH]          ; 读 cs
        REX.Wrxb
        mov ecx, [esi + RETURN_EIP_OFFSET + REG_WIDTH * 2]      ; 读 eflags
        REX.Wrxb
        mov [esi + RETURN_EIP_OFFSET + REG_WIDTH * 2], ebx      ; cs 写入原 eflags 位置
        REX.Wrxb
        mov [esi + RETURN_EIP_OFFSET + REG_WIDTH], eax          ; eip 写入原 cs 位置
        REX.Wrxb
        mov [esi + RETURN_EIP_OFFSET], ecx                      ; eflags 写入原 eip 位置


        ;;
        ;; 检查处理器是否拥有焦点
        ;; 1) 否, 将转入 HLT 状态
        ;; 2) 是, 返回被中断者
        ;;        
        mov eax, PCB.ProcessorIndex
        mov ecx, [gs: eax]                                      ; 读处理器的 index 值
        
        mov eax, SDA.InFocus
        cmp ecx, [fs: eax]
        je Keyboard_8259_handler.BottomHalf.Done

Keyboard_8259_handler.BottomHalf.@0:        
        ;;
        ;; 进入 HLT 状态
        ;;
        hlt
        
        ;;
        ;; 当处理器收到外部中断请求, 从 HLT 中唤醒！
        ;; 重新执行下次检查是否拥有焦点
        ;;
        cmp ecx, [fs: eax]
        jne Keyboard_8259_handler.BottomHalf.@0


%undef RETURN_EIP_OFFSET
%undef REG_WIDTH

Keyboard_8259_handler.BottomHalf.Done:
        
        pop eax
        pop edi
        pop esi
        pop ecx
        pop ebp
        popf
        REX.Wrxb        
        retf
        

%endif



;--------------------------------------------------
; timer_8259_handler()
; 描述: 
;       1) 使用于 8259 IRQ0 handler
;       2) 每次中断将计数值加 1
;--------------------------------------------------
timer_8259_handler:
        push eax
        
%ifdef __X64        
        bits 64
        lock inc DWORD [fs: SDA.TimerCount]
        bits 32
%else
        lock inc DWORD [fs: SDA.TimerCount]      
%endif        

        MASTER_EOI
        pop eax
        DW 4840h
        iret
        






                	
       	

	