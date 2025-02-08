;*************************************************
; guest_ex.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************
  
        ;;
        ;; 例子 ex7-5: 实现外部中断转发, 处理 CPU1 guest 的键盘中断
        ;; 编译命令可以为: 
        ;;      1) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE -D__X64 -DGUEST_X64
        ;;      2) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE -D__X64
        ;;      3) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE
        ;;
        
%if __BITS__ == 64
%define R0      rax
%define R1      rcx
%define R2      rdx
%define R3      rbx
%define R4      rsp
%define R5      rbp
%define R6      rsi
%define R7      rdi
%else
%define R0      eax
%define R1      ecx
%define R2      edx
%define R3      ebx
%define R4      esp
%define R5      ebp
%define R6      esi
%define R7      edi
%endif      

        ;;
        ;; 初始化 8259
        ;;
        cli
        call init_pic8259
        call disable_8259
        call enable_8259_keyboard
        sti
        
        ;;
        ;; 设置 IRQ1 中断 handler
        ;;
        sidt [Guest.IdtPointer]
        mov ebx, [Guest.IdtPointer + 2]

%if __BITS__ == 64
        add ebx, (GUEST_IRQ1_VECTOR * 16)
        mov rsi, (0FFFF800080000000h + GuestKeyboardHandler)
        mov [rbx + 4], rsi
        mov [rbx], si
        mov WORD [rbx + 2], GuestKernelCs64
        mov WORD [rbx + 4], 08E01h                      ; DPL = 0, IST = 1
        mov DWORD [rbx + 12], 0
%else
        add ebx, (GUEST_IRQ1_VECTOR * 8)
        mov esi, (80000000h + GuestKeyboardHandler)
        mov [ebx + 4], esi
        mov [ebx], si
        mov WORD [ebx + 2], GuestKernelCs32
        mov WORD [ebx + 4], 08E00h                      ; DPL = 0
%endif


        mov esi, GuestEx.Msg0
        call PutStr

GuestEx.Loop:
        call WaitKey
        movzx esi, BYTE [KeyMap + R0]
        call PutChar
        jmp GuestEx.Loop


        jmp $

        ;;
        ;; 进入 user 权限
        ;;
%if __BITS__ == 64
        push GuestUserSs64 | 3
        push 2FFF0h
        push GuestUserCs64 | 3
        push GuestEx.UserEntry
        retf64
%else
        push GuestUserSs32 | 3
        push 2FFF0h
        push GuestUserCs32 | 3
        push GuestEx.UserEntry
        retf
%endif        

GuestEx.UserEntry:
        mov ax, GuestUserSs32
        mov ds, ax
        mov es, ax
        jmp $




;--------------------------------------------------
; GuestKeyboardHandler:
; 描述: 
;       使用于 8259 IRQ1 handler
;--------------------------------------------------
GuestKeyboardHandler:
        push R3
        push R6
        push R7
        push R0

        
        in al, I8408_DATA_PORT                          ; 读键盘扫描码
        test al, al
        js GuestKeyboardHandler.done                    ; 为 break code
  

        mov ebx, KeyBufferPtr
        mov esi, [ebx]
        inc esi
        
        ;;
        ;; 检查是否超过缓冲区长度
        ;;
        mov edi, KeyBuffer
        cmp esi, KeyBuffer + 255
        cmovae esi, edi
        mov [esi], al                                           ; 写入扫描码
        mov [ebx], esi                                         ; 更新缓冲区指针 
 
GuestKeyboardHandler.done:
	mov al, 00100000B				        ; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
        pop R0
        pop R7
        pop R6
        pop R3
%if __BITS__ == 64
        iretq
%else
        iret
%endif
        
        
GuestEx.Msg0    db      'wait any keys: ', 0



                