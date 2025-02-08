;*************************************************
; guest_ex.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************
  
        ;;
        ;; 例子 ex7-4：实现拦截 INT 指令，并且模拟处理器中断的delivery操作
        ;; 编译命令可以为：
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
        ;; 设置 60h 中断 handler
        ;;
        sidt [Guest.IdtPointer]
        mov ebx, [Guest.IdtPointer + 2]
        
%if __BITS__ == 64
        add ebx, (60h * 16)
        mov rsi, (0FFFF800080000000h + GuestEx.Int60Handler)
        mov [rbx + 4], rsi
        mov [rbx], si
        mov WORD [rbx + 2], GuestKernelCs64
        mov WORD [rbx + 4], 0EE01h                      ; DPL = 3, IST = 1
        mov DWORD [rbx + 12], 0
%else
        add ebx, (60h * 8)
        mov esi, (80000000h + GuestEx.Int60Handler)
        mov [ebx + 4], esi
        mov [ebx], si
        mov WORD [ebx + 2], GuestKernelCs32
        mov WORD [ebx + 4], 0EE00h                      ; DPL = 3
%endif
        call PrintLn
        int 60h
        mov esi, GuestEx.Msg1
        call PutStr

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
        mov esi, GuestEx.Msg2
        call PutStr
        int 60h
        mov esi, GuestEx.Msg1
        call PutStr
        jmp $
        
        
;;
;; guest 的 60h 中断例程
;;        
GuestEx.Int60Handler:
        mov esi, GuestEx.Msg0
        call PutStr
%if __BITS__ == 64
        iretq
%else 
        iret
%endif


        
GuestEx.Msg0    db      'guest Int 60h !', 10, 0
GuestEx.Msg1    db      'interrupt end!', 10, 0
GuestEx.Msg2    db      'enter User !', 10, 0



                