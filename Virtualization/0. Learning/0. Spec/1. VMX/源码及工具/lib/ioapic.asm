;*************************************************
;* ioapic.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


init_ioapic_unit:
        call enable_ioapic
        call init_ioapic_keyboard
        ret
        
        
;------------------------------------
; enable_ioapic()
; input:
;       none
; output:
;       none
; 描述:
;       1) 开启 ioapic
;       2) 在 stage1 下使用
;------------------------------------
enable_ioapic:
        ;;
        ;; 开启 ioapic
        ;;
        call get_root_complex_base_address
        mov esi, [eax + 31FEh]
        bts esi, 8                                      ; IOAPIC enable 位
        and esi, 0FFFFFF00h                             ; IOAPIC range select
        mov [eax + 31FEh], esi                          ; enable ioapic
       
        ;;
        ;; 设置 IOAPIC ID
        ;;
        mov DWORD [0FEC00000h], IOAPIC_ID_INDEX
        mov DWORD [0FEC00010h], 0F000000h              ; IOAPIC ID = 0Fh
        ret



;-----------------------------------
; ioapic_keyboard_handler()
;-----------------------------------
ioapic_keyboard_handler:
        push ebp
        push ecx
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
        js ioapic_keyboard_handler.done                 ; 为 break code
        
        ;;
        ;; 是否为功能键
        ;;
        cmp al, SC_F1
        jb ioapic_keyboard_handler.next
        cmp al, SC_F10
        ja ioapic_keyboard_handler.next

        ;;
        ;; 切换当前处理器
        ;;
        sub al, SC_F1
        movzx esi, al
        mov edi, switch_to_processor
        call force_dispatch_to_processor
        
        
        jmp ioapic_keyboard_handler.done
        
ioapic_keyboard_handler.next:
        
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
        REX.Wrxb
        mov ecx, [ebp + SDA.KeyBufferHead]                      ; ecx = LSB.KeyBufferHead
        REX.Wrxb
        mov edi, ecx
        REX.Wrxb
        add ecx, [ebp + SDA.KeyBufferLength]
        REX.Wrxb
        cmp esi, ecx
        REX.Wrxb
        cmovae esi, edi                                         ; 如果到达缓冲区尾部, 则指向头部
        mov [esi], al                                           ; 写入扫描码
        REX.Wrxb
        xchg [ebx], esi                                         ; 更新缓冲区指针 
                
ioapic_keyboard_handler.done:       
        call send_eoi_command
        pop eax
        pop edi
        pop esi
        pop ebx
        pop ecx
        pop ebp
        REX.Wrxb
        iret


;----------------------------------------------------
; init_ioapic_keyboard(): 初始化 ioapic keyboard 功能
;----------------------------------------------------
init_ioapic_keyboard:
        push ebx
        ;;
        ;; 设置 IOAPIC 的 redirectior table 1 寄存器        
        ;;
        mov ebx, [gs: PCB.IapicPhysicalBase]
        mov DWORD [ebx + IOAPIC_INDEX], IRQ1_INDEX
        mov DWORD [ebx + IOAPIC_DATA], LOGICAL | IOAPIC_IRQ1_VECTOR | IOAPIC_RTE_MASKED
        mov DWORD [ebx + IOAPIC_INDEX], IRQ1_INDEX + 1
        mov DWORD [ebx + IOAPIC_DATA], 01000000h                ; 使用 processor #0
        pop ebx
        ret
        
        
%if 0        
;----------------------------------------------
; wait_esc_for_reset_ex(): 等待按下 <ESC> 键重启
;---------------------------------------------
wait_esc_for_reset_ex:
        mov esi, Ioapic.WaitResetMsg
        call puts
wait_esc_for_reset_ex.loop:
        xor esi, esi
        lock xadd [fs: SDA.KeyBufferPtr], esi
        mov al, [esi]
        cmp al, 01                              ; 检查按键是否为 <ESC> 键
        je wait_esc_for_reset_ex.next
        pause
        jmp wait_esc_for_reset_ex.loop        
        
wait_esc_for_reset_ex.next:        
        ;;
        ;; Now: broadcast INIT message
        ;;
        mov DWORD [APIC_BASE + ICR1], 0FF000000h
        mov DWORD [APIC_BASE + ICR0], 00004500h        
        ret
        
%endif        
        
        
