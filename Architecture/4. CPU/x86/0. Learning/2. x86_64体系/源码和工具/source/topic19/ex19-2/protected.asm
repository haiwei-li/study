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
        call enable_ioapic
        call enable_hpet

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


; ʵ��ex19-2��ʹ��HPET timer�ļ�ʱ��

        mov esi, IOAPIC_IRQ2_VECTOR
        mov edi, ioapic_irq2_handler
        call set_interrupt_handler

        mov DWORD [IOAPIC_INDEX_REG], IRQ2_INDEX
        mov DWORD [IOAPIC_DATA_REG], LOGICAL | FIXED_DELIVERY | IOAPIC_IRQ2_VECTOR
        mov DWORD [IOAPIC_INDEX_REG], IRQ2_INDEX + 1
        mov DWORD [IOAPIC_DATA_REG], 08000000h                          ; processor #4

        mov esi, msg
        call puts

        call get_video_current                                          ; ��ʱ����ӡ�ĵ�ǰλ��
        mov [position], eax

        ;*
        ;* ����ʹ�� timer 0��ʹ��ÿ���ж�1��
        ;*
        START_HPET_TIMER 0, HPET_COUNT_SECOND, 1

        jmp $


msg             db 'HPET timer: ', 0
position        dd 0


;--------------------------------------
; IOAPIC IRQ2 �ж� handler
;--------------------------------------
ioapic_irq2_handler:
        jmp do_ioapic_irq2_handler
second  dd 0
minute  dd 0
do_ioapic_irq2_handler:
        mov ebx, [minute]
        mov edx, [second]

        cmp ebx, 10
        jb print_timer
        STOP_HPET_TIMER 0
        jmp ioapic_irq2_handler_done

print_timer:
        mov esi, [position]
        call set_video_current

        cmp edx, 59
        jb ioapic_irq2_handler_next
        inc ebx
        xor edx, edx

ioapic_irq2_handler_next:
        ; ��ӡ����
        mov esi, ebx
        cmp ebx, 10
        mov eax, print_byte_value
        mov edi, print_dword_decimal
        cmovae eax, edi
        call eax
        mov esi, ':'
        call putc
        ;��ӡ����
        mov esi, edx
        cmp edx, 10
        mov eax, print_byte_value
        mov edi, print_dword_decimal
        cmovae eax, edi
        call eax

        inc edx
        mov [second], edx
        mov [minute], ebx

ioapic_irq2_handler_done:
        mov DWORD [APIC_BASE + EOI], 0
        iret



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
%define APIC_ERROR_HANDLER
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
%include "..\lib\ioapic.asm"
%include "..\lib\hpet.asm"


;;************* ���������  *****************

; ��� lib32 �⵼������� common\ Ŀ¼�£�
; ������ʵ��� protected.asm ģ��ʹ��

%include "..\common\lib32_import_table.imt"


PROTECTED_END: