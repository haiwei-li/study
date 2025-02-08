;*************************************************
; guest_ex.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

        ;;
        ;; 加入 ex.asm 模块使用的头文件
        ;;
        %include "ex.inc"
        
        
        ;;
        ;; 例子 ex7-3: 实现 local APIC 虚拟化
        ;; 编译命令可以为: 
        ;;      1) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE -D__X64 -DGUEST_X64
        ;;      2) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE -D__X64
        ;;      3) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE
        ;;
        

        ;;
        ;; 设置 local APIC base 值为 01000000h
        ;;
        mov ecx, IA32_APIC_BASE
        mov eax, 01000000h | APIC_BASE_BSP | APIC_BASE_ENABLE
        xor edx, edx
        wrmsr

        mov esi, GuestEx.Msg0
        call PutStr
        mov ecx, IA32_APIC_BASE
        rdmsr
        mov esi, eax
        and esi, ~0FFFh
        mov edi, edx
        call PrintQword
        call PrintLn
                
        mov R3, GUEST_APIC_BASE 
        
        ;;
        ;; TPR = 50h
        ;;
        mov eax, 50h
        mov [R3 + LAPIC_TPR], eax        
        mov esi, GuestEx.Msg1
        call PutStr        
        mov esi, [R3 + LAPIC_TPR]        
        call PrintValue
        call PrintLn

        ;;
        ;; TPR = 60h
        ;;
        mov DWORD [R3 + LAPIC_TPR], 60h    
        mov esi, GuestEx.Msg1
        call PutStr        
        mov esi, [R3 + LAPIC_TPR]        
        call PrintValue        
        
        jmp $
        
GuestEx.Msg0    db      'APIC base: ', 0
GuestEx.Msg1    db      'TPR:       ', 0


                