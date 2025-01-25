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
        cli
        NMI_DISABLE

; ? SSE ?        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        call pae_enable
        call execution_disable_enable

;;  sysenter/sysexit ?û
        call set_sysenter
 
        ;*
        ;* perfmon ?
        ;* ? counter  PEBS 
        ;*  overflow ??
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW       
        RESET_PMC
        
       
;;;  bootstrap processor  application processor ?
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc application_processor_enter


;------------------------------------------------
;  bootstrap processor ??
;-----------------------------------------------
bsp_processor_enter:
        call init_pae_paging
        mov eax, PDPT_BASE
        mov cr3, eax
        mov eax, cr0
        bts eax, 31
        mov cr0, eax  

        ;*
        ;*  startup routine ? 20000h                
        ;* ? AP processor 
        ;*
        mov esi, startup_routine
        mov edi, 20000h
        mov ecx, startup_routine_end - startup_routine
        rep movsb


;  IRQ0  IRQ1 ?
        mov esi, PIC8259A_TIMER_VECTOR
        mov edi, timer_handler
        call set_interrupt_handler        

        mov esi, KEYBOARD_VECTOR
        mov edi, keyboard_handler
        call set_interrupt_handler                
        
        call init_8259A
        call init_8253        
        call disable_keyboard
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

;;  system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

; APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler

;  APIC timer handler
        mov esi, APIC_TIMER_VECTOR
        mov edi, apic_timer_handler
        call set_interrupt_handler      

;APIC
        call enable_apic        

;  LVT ?
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        mov DWORD [APIC_BASE + LVT_TIMER], TIMER_ONE_SHOT | APIC_TIMER_VECTOR
        mov DWORD [APIC_BASE + LVT_ERROR], APIC_ERROR_VECTOR

;  BSP IPI handler
        mov esi, BP_IPI_VECTOR
        mov edi, bp_ipi_handler
        call set_interrupt_handler             
        
;===============================================

        inc DWORD [processor_index]                             ;  index ?
        inc DWORD [processor_count]                             ;  logical processor 
        mov ecx, [processor_index]                              ; ? index ?
        mov edx, [APIC_BASE + APIC_ID]                          ;  APIC ID
        mov [apic_id + ecx * 4], edx                            ;  APIC ID 
;*
;*  stack ?
;*
        mov eax, PROCESSOR_STACK_SIZE                           ; ÿ stack ??
        mul ecx                                                 ; stack_offset = STACK_SIZE * index
        mov esp, PROCESSOR_KERNEL_ESP                           ; stack ?
        add esp, eax  

;  logical ID
        mov eax, 01000000h
        shl eax, cl
        mov [APIC_BASE + LDR], eax
 
        call extrac_x2apic_id 
        
;  lock 
        mov DWORD [20100h], 0

        ;*
        ;* ? IPIs? INIT-SIPI-SIPI 
        ;*  SIPI ? startup routine ?? 200000h
        ;*
        mov DWORD [APIC_BASE + ICR0], 000c4500h                ;  ,NIT IPI, ? processor ? INIT
        DELAY
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H               ;  Start-up IPI
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; ?? Start-up IPI
     
        ; ?
        sti
        NMI_ENABLE


        ;*
        ;* ? AP ??
        ;*
wait_for_done:
        cmp DWORD [ap_init_done], 1
        je next
        nop
        pause
        jmp wait_for_done 

next:  

;============== ? ======================


;; ? 18-15 logcal processor 1  PMI ?

;   logical processor 1  IPI handler
	mov esi, PROCESSOR1_IPI_VECTOR                                          ; ? 1  IPI ? vector
	mov edi, processor1_ipi_handler                                         ; IPI ? handler
	call set_interrupt_handler

	mov esi, msg0                                                           ; ??
	call puts

;  IPI ? processor 1
	mov DWORD [APIC_BASE + ICR1], 02000000h                                 ;  processor 1  IPI
	mov DWORD [APIC_BASE + ICR0], LOGICAL_ID | PROCESSOR1_IPI_VECTOR        ; no shorthand, logical mode, fixed

        jmp $

msg0	db 'now: test preformance monitoring for logical processor 1 ...', 10, 10, 0



;---------------------------------------
; logical processor 1  IPI handler
; :
;       ? Fixed delivery ??
;---------------------------------------
processor1_ipi_handler:
;  LVT preformance monitor ?
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR

;  IA32_PERFEVTSEL0 ?
        mov ecx, IA32_PERFEVTSEL0
        mov eax, INST_COUNT_EVENT
        mov edx, 0
        wrmsr

;  counter ?        
        mov esi, IA32_PMC0
        call write_counter_maximum

;  counter
        ENABLE_IA32_PMC0

        nop
        mov DWORD [APIC_BASE + EOI], 0                ;  EOI 
        iret


;-------------------------------
; perfmon handler
;------------------------------
apic_perfmon_handler:
        jmp do_apic_perfmon_handler
ph_msg1	db '>>> now: enter PMI handler', 10, 0
ph_msg2 db 'exit the PMI handler <<<', 10, 0	
do_apic_perfmon_handler:	
        mov esi, ph_msg1                	; ??
        call puts
        call dump_apic                        ; ? local APIC??
	
; ??
        RESET_COUNTER_OVERFLOW
	
        mov esi, ph_msg2
        call puts
	
; ? EOI 	
        mov DWORD [APIC_BASE + EOI], 0	;  EOI 
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



%define APIC_TIMER_HANDLER
%define APIC_ERROR_HANDLER
%define AP_PROTECTED_ENTER

;******** include õ? ***********
%include "..\common\application_processor.asm"

        bits 32
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


;;*************   *****************

;  lib32 ? common\ ?¼£
; ? protected.asm ??

%include "..\common\lib32_import_table.imt"


PROTECTED_END: