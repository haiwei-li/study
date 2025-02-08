; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

;  protected ?

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected ??

entry:
        
;; ?????????
        call disable_timer
        
;;  #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;;  #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

;  #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler


;;  sysenter/sysexit ?û
        call set_sysenter

;;  system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

; ? SSE ?        
        mov eax, cr4
        bts eax, 9                              ; CR4.OSFXSR = 1
        bts eax, 10                             ; CR4.OSXMMEXCPT = 1
        mov cr4, eax
        
        
; CR4.PAE
        call pae_enable
        
;  XD 
        call execution_disable_enable
                
; ? paging 
        call init_pae_paging
        
; PDPT ?        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; ??paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                                 

        mov esi, PIC8259A_TIMER_VECTOR
        mov edi, timer_handler
        call set_interrupt_handler        

        mov esi, KEYBOARD_VECTOR
        mov edi, keyboard_handler
        call set_interrupt_handler                
        
        call init_8259A
        call init_8253        
        call disable_8259
        sti
        
;========= ? =================


;; ??ex21-1#XM?handler

;;  x87 FPU  MMX 
        mov eax, cr0
        bts eax, 1              ; MP = 1
        btr eax, 2              ; EM = 0
        mov cr0, eax

;  #XM handler
        mov esi, XM_HANDLER_VECTOR
        mov edi, xm_handler
        call set_interrupt_handler

        
        stmxcsr [esp]
        and DWORD [esp], 0xe07f         ; clear mask ?
        ldmxcsr [esp]
        movups xmm0, [a]
        movups xmm1, [b]
        addps xmm0, xmm1                ;  numeric ?
        jmp $

a       dd 0, 0, 0, 0x76000000
b       dd 0, 0x7fa00000, 1, 0x7f7fffff



;-------------------------------------
; SIMD floating-point ? handler
;-------------------------------------
xm_handler:
        jmp do_xm_handler
xhmsg   db '>>> now: enter #XM handler, occur at 0x', 0
xhmsg0  db 'exit the #XM handler <<<', 10, 0        

do_xm_handler:        
        mov esi, xhmsg
        call puts
        mov esi, [esp]
        call print_dword_value
        call println
        call dump_mxcsr
        sub esp, 4
        stmxcsr [esp]
        mov eax, [esp]
        
        bt eax, 0               ; IE
        jnc test_de
        btr eax, 0
        bts eax, 7        
test_de:        
        bt eax, 1               ; DE
        jnc test_ze
        btr eax, 1
        bts eax, 8
test_ze:        
        bt eax, 2               ; ZE
        jnc test_oe
        btr eax, 2
        bts eax, 9
test_oe:
        bt eax, 3               ; OE
        jnc test_ue
        btr eax, 3
        bts eax, 10
test_ue:
        bt eax, 4               ; UE
        jnc test_pe
        btr eax, 4
        bts eax, 11
test_pe:
        bt eax, 5               ; PE
        jnc set_mxcsr
        btr eax, 5
        bts eax, 12
set_mxcsr:
        mov [esp], eax
        ldmxcsr [esp]
        add esp, 4
        mov esi, xhmsg0
        call puts
        iret

        

; ? long ?
        ;jmp LONG_SEG
                                
                                
;  ring 3 
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; û

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:

        jmp $






%define APIC_PERFMON_HANDLER

;******** include ? handler  ********
%include "..\common\handler32.asm"


;********* include ? ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\apic.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\page32.asm"
%include "..\lib\pic8259A.asm"
%include "..\lib\x87.asm"
%include "..\lib\sse.asm"

;;*************   *****************

;  lib32 ? common\ ?¼£
; ? protected.asm ??

%include "..\common\lib32_import_table.imt"


PROTECTED_END: