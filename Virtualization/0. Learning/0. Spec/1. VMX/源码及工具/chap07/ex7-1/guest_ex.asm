;*************************************************
; guest_ex.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


;;
;; guest 的示例文件
;;

        ;;
        ;; 设置 SYSENTER 使用环境
        ;;
        xor edx, edx
        xor eax, eax
        mov ax, cs
        mov ecx, IA32_SYSENTER_CS
        wrmsr

       
%if __BITS__ == 64
        mov rax, rsp
        shld rdx, rax, 32        
%else
        mov eax, esp
        xor edx, edx
%endif
        mov ecx, IA32_SYSENTER_ESP
        wrmsr
        

%if __BITS__ == 64
        mov rax, 0FFFF800080000000h + SysRoutine
        shld rdx, rax, 32
%else
        mov eax, 80000000h + SysRoutine
        xor edx, edx
%endif
        mov ecx, IA32_SYSENTER_EIP
        wrmsr
        
        
        ;;
        ;; 下面进入 user 权限
        ;;
%if __BITS__ == 64
        push GuestUserSs64 | 3
        push 7FF0h
        push GuestUserCs64 | 3
        push GuestEx.UserEntry
        retf64
%else
        push GuestUserSs32 | 3
        push 7FF0h
        push GuestUserCs32 | 3
        push GuestEx.UserEntry
        retf
%endif




;;#################################
;; 下面是 guest 的 User 层代码
;;#################################

GuestEx.UserEntry:        
%if __BITS__ == 64
        mov ax, GuestUserSs64
%else
        mov ax, GuestUserSs32
%endif        
        mov ds, ax
        mov es, ax

        ;;
        ;; 调用系统服务例程
        ;;       
        call FastSysCallEntry
        
        mov esi, GuestEx.Msg2
        call PutStr
        
        jmp $
        
        

        
;-------------------------------------
; FastSysCallEntry()
;-------------------------------------        
FastSysCallEntry:
%if __BITS__ == 64
        mov rcx, rsp
        mov rdx, [rsp]
%else
        mov ecx, esp
        mov edx, [esp]
%endif
        sysenter
        ret


        
;-------------------------------------
; SYSENTER 指令的服务例程
;-------------------------------------
SysRoutine:
        mov esi, GuestEx.Msg1
        call PutStr
        REX.Wrxb
        sysexit
        


GuestEx.Msg1            db      10, 'now, enter sysenter service routine...', 10, 0        
GuestEx.Msg2            db      'system service done ...', 0