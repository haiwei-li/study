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
        
;; Ϊ�����ʵ�飬�ر�ʱ���жϺͼ����ж�
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


;; ���� sysenter/sysexit ʹ�û���
        call set_sysenter

;; ���� system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

; ����ִ�� SSE ָ��        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        
        
;���� CR4.PAE
        call pae_enable
        
; ���� XD ����
        call execution_disable_enable
                
; ��ʼ�� paging ����
        call init_pae_paging
        
;���� PDPT ����ַ        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; �򿪡�paging
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
        call disable_keyboard
        call disable_timer
        sti


;����APIC
        call enable_xapic        
        

;========= ��ʼ��������� =================


;;; ʵ�� 18-06��ö�����е�processor��APIC IDֵ
        
;;; ���� bootstrap processor ���� application processor ?
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc ap_processor

;; ** ������ BSP ���� ***

        ;*
        ;* perfmon ��ʼ����
        ;* �ر����� counter �� PEBS 
        ;* �� overflow ��־λ
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW       
        RESET_PMC

;���� APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler

;  ���� APIC timer handler
        mov esi, APIC_TIMER_VECTOR
        mov edi, apic_timer_handler
        call set_interrupt_handler      
        
; ���� LVT �Ĵ���
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR
        mov DWORD [APIC_BASE + LVT_TIMER], TIMER_ONE_SHOT | APIC_TIMER_VECTOR


;*        
;* ���� startup routine ���뵽 20000h                
;* �Ա��� AP processor ����
;*
        mov esi, startup_routine
        mov edi, 20000h
        mov ecx, startup_routine_end - startup_routine
        rep movsb


;*
;* ���Ӵ�������ż���
;* BSP ������Ϊ processor #0
;*
        inc DWORD [processor_index]                             ; ���� index ֵ
        inc DWORD [processor_count]                             ; ���� logical processor ����
        mov ecx, [processor_index]                              ; ������ index ֵ
        mov edx, [APIC_BASE + APIC_ID]                          ; ��ȡ APIC ID ֵ
        mov [apic_id + ecx * 4], edx                            ; ���� APIC ID

;*
;* ���� stack �ռ�
;*
;* ���䷽����
;       1) ÿ���������� idedx * STACK_SIZE �õ� stack_offset
;       2) stack_offset ���� stack_base ֵ
;
        mov eax, PROCESSOR_STACK_SIZE                           ; ÿ���������� stack �ռ��С
        mul ecx                                                 ; stack_offset = STACK_SIZE * index
        mov esp, PROCESSOR_KERNEL_ESP + PROCESSOR_STACK_SIZE    ; stack ��ֵ
        add esp, eax                                            ; stack_base + stack_offset

        mov esi, bp_msg1
        call puts
        mov esi, msg
        call puts
        mov esi, edx
        call print_dword_value
        call println
        mov esi, bp_msg2
        call puts

                  
;*
;* ���� lock �ź�
;*
        mov DWORD [vacant], 0                                   ; lock 


        ;*
        ;* ���淢�� IPIs��ʹ�� INIT-SIPI-SIPI ����
        ;* ���� SIPI ʱ������ startup routine ��ַλ�� 200000h
        ;*

        mov DWORD [APIC_BASE + ICR0], 000c4500h                ; ���� ,NIT IPI, ʹ���� processor ִ�� INIT
        DELAY
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; ���� Start-up IPI
        DELAY
        mov DWORD [APIC_BASE + ICR0], 000C4620H                ; �ٴη��� Start-up IPI

        ;* ������ AP ���
test_ap_done:
        cmp DWORD [ap_done], 1
        jne get_ap_done
        mov DWORD [APIC_BASE + TIMER_ICR], 100                  ; ���� apic timer
        hlt
        jmp $

get_ap_done:
        jmp test_ap_done

        jmp $



; ������ APs ����
ap_processor:        

;*
;* �رռ��������ռ�����
;*
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR2_EN)

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
        add esp, eax                                            ; stack_base + stack_offset


        ;* ��ӡ��Ϣ
        mov esi, ap_msg1
        call puts
        mov esi, ecx
        call print_dword_decimal
        mov esi, ap_msg2
        call puts

        mov esi, edx
        call print_dword_value
        mov esi, ','
        call putc
        call printblank

; ��ӡָ����
        mov esi, msg2
        call puts
        mov ecx, IA32_FIXED_CTR0
        rdmsr
        mov esi, eax
        call print_dword_decimal
        mov esi, ','
        call putc
        call printblank

; ��ӡ clocks ֵ       
        mov esi, msg1
        call puts
        mov ecx, IA32_FIXED_CTR2
        rdmsr
        mov esi, eax
        mov edi, edx
        call print_qword_value
        call println

; ���� AP ��ɹ���
        xor eax, eax
        cmp DWORD [processor_index], 3
        setae al
        mov [ap_done], eax

        lock btr DWORD [vacant], 0                          ; �ͷ� lock
        cli
        hlt
        
        jmp $


;*
;* ������ starup routine ����
;* ���� AP ������ִ�� setupģ�飬ִ�� protected ģ��
;* ʹ���� AP ����������protectedģʽ
;*
startup_routine:
        bits 16
        
        mov ax, 0
        mov ds, ax
        mov es, ax
        mov ss, ax

;*
;* **** ���������� ****
;* ͳ��ÿ�� AP �������ӵȴ�����ɳ�ʼ������ʹ��ָ��� cloks��
;*
        mov ecx, IA32_FIXED_CTR_CTRL
        mov eax, 0B0Bh
        mov edx, 0
        wrmsr
        ENABLE_COUNTER 0, (IA32_FIXED_CTR0_EN | IA32_FIXED_CTR2_EN)


; ���� lock��ֻ���� 1 �� local processor ����
test_ap_lock:        
        lock bts DWORD [vacant], 0
        jc get_ap_lock

        jmp WORD 0:SETUP_SEG                ; ����ʵģʽ�� setup.asm ģ��

get_ap_lock:
        jmp test_ap_lock

        bits 32
startup_routine_end: 

  


        jmp $

       
ap_done         dd 0

bp_msg1         db '<bootstrap processor>: ', 0
bp_msg2         db 'now, sent all processor IPIs...', 10, 10, 0
ap_msg1         db '<Processor #', 0
ap_msg2         db '>: ', 0
msg             db 'APIC ID: ', 0
msg1            db 'clocks:', 0
msg2            db 'instructions:', 0

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



;---------------------------------------------
; apic_timer_handler()������ APIC TIMER �� ISR
;---------------------------------------------
apic_timer_handler:
        jmp do_apic_timer_handler
at_msg2 db        10, '--------- summary -------------', 10
        db        'processor: ', 0
at_msg3 db        'APIC ID : ', 0
do_apic_timer_handler:        
        mov esi, at_msg2
        call puts
        mov ebx, [processor_count]
        mov esi, ebx
        call print_dword_decimal
        call println
        mov esi, at_msg3
        call puts
        xor ecx, ecx

at_loop:
        mov esi, [apic_id + ecx * 4]
        call print_dword_value
        mov esi, ','
        call putc
        inc ecx
        cmp ecx, ebx
        jb at_loop

        mov DWORD [APIC_BASE + EOI], 0
        iret




%define APIC_PERFMON_HANDLER

;******** include �ж� handler ���� ********
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