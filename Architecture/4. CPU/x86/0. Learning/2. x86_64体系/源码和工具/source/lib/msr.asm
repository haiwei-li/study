; msr.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;; 这个模块是关于 MSR 寄存器

        bits 32
        


;-----------------------------
; dump_IA32_APIC_BASE
;-----------------------------
dump_IA32_APIC_BASE:        
        jmp do_dump_IA32_APIC_BASE
bsp_msg           db 'BSP flag? ', 0
x2apic_msg        db 'x2APIC enable? ', 0
apic_global_msg   db 'APIC Global enable? ', 0
apic_base_msg     db 'APIC base: 0x'
apic_base_value   dd 0

do_dump_IA32_APIC_BASE:        
        push ecx
        push edx
        mov ecx, IA32_APIC_BASE
        rdmsr
        mov ecx, eax
        mov esi, bsp_msg
        call puts
        mov eax, enable
        mov esi, disable
        bt ecx, 8
        cmovc esi, eax
        call puts
        call println
        mov esi, x2apic_msg
        call puts
        mov eax, enable
        mov esi, disable
        bt ecx, 10
        cmovc esi, eax
        call puts
        call println
        mov esi, apic_global_msg
        call puts
        mov eax, enable
        mov esi, disable
        bt ecx, 11
        cmovc esi, eax
        call puts
        call println                
        mov esi, apic_base_msg
        call puts
        mov esi, ecx
        and esi, 0xfffff000
        mov edi, apic_base_value
        call get_byte_hex_string
        mov esi, apic_base_value
        call puts
        pop edx
        pop ecx
        ret
        

;;** include mtrr 模块 *****

%include "..\lib\mtrr.asm"


;; *** MSR 模块数据 *******
enable        db 'yes', 0
disable       db 'no', 0

