; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; ���� protected ģ��

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected ģ�鳤��

entry:
        cli
        NMI_DISABLE

; ����ִ�� SSE ָ��        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        call pae_enable
        call execution_disable_enable

;; ���� sysenter/sysexit ʹ�û���
        call set_sysenter
 
        ;*
        ;* perfmon ��ʼ����
        ;* �ر����� counter �� PEBS 
        ;* �� overflow ��־λ
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW       
        RESET_PMC
        
       
;;; ���� bootstrap processor ���� application processor ?
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc application_processor_enter


;------------------------------------------------
; ������ bootstrap processor ִ�д���
;-----------------------------------------------
bsp_processor_enter:
        call init_pae_paging
        mov eax, PDPT_BASE
        mov cr3, eax
        mov eax, cr0
        bts eax, 31
        mov cr0, eax  

        ;*
        ;* ���� startup routine ���뵽 20000h                
        ;* �Ա��� AP processor ����
        ;*
        mov esi, startup_routine
        mov edi, 20000h
        mov ecx, startup_routine_end - startup_routine
        rep movsb


; ���� IRQ0 �� IRQ1 �ж�
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

;; ���� #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; ���� #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

; ���� #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler

;; ���� system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

;���� APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler

; ���� APIC timer handler
        mov esi, APIC_TIMER_VECTOR
        mov edi, apic_timer_handler
        call set_interrupt_handler      

;����APIC
        call enable_apic        

; ���� LVT �Ĵ���
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        mov DWORD [APIC_BASE + LVT_TIMER], TIMER_ONE_SHOT | APIC_TIMER_VECTOR
        mov DWORD [APIC_BASE + LVT_ERROR], APIC_ERROR_VECTOR

; ���� BSP IPI handler
        mov esi, BP_IPI_VECTOR
        mov edi, bp_ipi_handler
        call set_interrupt_handler             
        
;===============================================

        inc DWORD [processor_index]                             ; ���� index ֵ
        inc DWORD [processor_count]                             ; ���� logical processor ����
        mov ecx, [processor_index]                              ; ȡ index ֵ
        mov edx, [APIC_BASE + APIC_ID]                          ; �� APIC ID
        mov [apic_id + ecx * 4], edx                            ; ���� APIC ID 
;*
;* ���� stack �ռ�
;*
        mov eax, PROCESSOR_STACK_SIZE                           ; ÿ���������� stack �ռ��С
        mul ecx                                                 ; stack_offset = STACK_SIZE * index
        mov esp, PROCESSOR_KERNEL_ESP                           ; stack ��ֵ
        add esp, eax  

; ���� logical ID
        mov eax, 01000000h
        shl eax, cl
        mov [APIC_BASE + LDR], eax
 
        call extrac_x2apic_id 
        
; ���� lock 
        mov DWORD [20100h], 0

        ;*
        ;* ���淢�� IPIs��ʹ�� INIT-SIPI-SIPI ����
        ;* ���� SIPI ʱ������ startup routine ��ַλ�� 200000h
        ;*
        mov DWORD [APIC_BASE + ICR0], 000c4500h                ; ���� ,NIT IPI, ʹ���� processor ִ�� INIT
        DELAY
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H               ; ���� Start-up IPI
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; �ٴη��� Start-up IPI
     
        ; ���ж�
        sti
        NMI_ENABLE


        ;*
        ;* �ȴ� AP ��������ɳ�ʼ��
        ;*
wait_for_done:
        cmp DWORD [ap_init_done], 1
        je next
        nop
        pause
        jmp wait_for_done 

next:  

;============== ��ʼ��������� ======================


; ʵ�� ex18-12������IPI��Ϣ�е�APIC error�ж�

        mov esi, APIC_ERROR_VECTOR
        mov edi, apic_error_handler
        call set_interrupt_handler

;; ���ڷ� IPI ��Ŀ�� processor
        mov esi, bp_msg1
        call puts

        mov DWORD [APIC_BASE + ICR1], 02000000h             ; �� processor #1 ���� IPI
        mov DWORD [APIC_BASE + ICR0], LOGICAL_ID | 0        ; no shorthand, logical mode, fixed


        jmp $

;-----------------------------------------
; apic_error_handler() ���� APIC error ����
;------------------------------------------
apic_error_handler:
        jmp do_apic_error_handler
ae_msg0        db 10, '>>> now: enter APIC Error handler, occur at: 0x', 0
ae_msg1        db 'exit the APIC error handler <<<', 10, 0
ae_msg2        db 'APIC ID: 0x', 0
ae_msg3        db 'ESR:     0x', 0
do_apic_error_handler:
test_error_handler_lock:
        lock bts DWORD [vacant], 0
        jc get_error_handler_lock
        mov esi, ae_msg0
        call puts
        mov esi, [esp]
        call print_dword_value
        call println
        mov esi, ae_msg2
        call puts
        mov esi, [APIC_BASE + APIC_ID]
        call print_dword_value
        call println
        mov esi, ae_msg3
        call puts
        call read_esr
        mov esi, eax
        call print_dword_value
        call println
        mov esi, ae_msg1
        call puts
        mov DWORD [APIC_BASE + EOI], 0
        lock btr DWORD [vacant], 0                ; �ͷ� lock
        iret
get_error_handler_lock:
        jmp test_error_handler_lock





bp_msg1         db '<bootstrap processor>  : '
bp_msg2         db 'now, send IPI to processor 01', 10, 10, 0

msg0    db '-------------------------------------------', 10, 0
msg1    db 'APIC ID: 0x', 0
msg2    db 'pkg_ID: 0x', 0
msg3    db 'core_ID: 0x', 0
msg4    db 'smt_ID: 0x', 0


; ת�� long ģ��
        ;jmp LONG_SEG
                                
                                
; ���� ring 3 ����
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; �û�����
user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax
user_start:
        jmp $



%define APIC_PERFMON_HANDLER
%define APIC_TIMER_HANDLER
%define AP_PROTECTED_ENTER

;******** include ���õĴ��� ***********
%include "..\common\application_processor.asm"

        bits 32
%include "..\common\handler32.asm"


;********* include ģ�� ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\apic.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\page32.asm"
%include "..\lib\pic8259A.asm"


;;************* ���������  *****************

; ��� lib32 �⵼������� common\ Ŀ¼�£�
; ������ʵ��� protected.asm ģ��ʹ��

%include "..\common\lib32_import_table.imt"


PROTECTED_END: