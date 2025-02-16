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

;����APIC
        call enable_xapic        

        ;*
        ;* perfmon ��ʼ����
        ;* �ر����� counter �� PEBS 
        ;* �� overflow ��־λ
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW       
        RESET_PMC
        

;========= ��ʼ��������� =================


;;; ʵ�� 18-07: ��APIC IDΪ01�Ĵ���������IPI��Ϣ
        
;;; ���� bootstrap processor ���� application processor ?
        mov ecx, IA32_APIC_BASE
        rdmsr
        bt eax, 8
        jnc ap_processor

;; ** ������ BSP ���� ***


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

; ���� AP IPI handler
        mov esi, 30h
        mov edi, ap_ipi_handler
        call set_interrupt_handler             
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
        mov esp, PROCESSOR_KERNEL_ESP                           ; stack ��ֵ
        add esp, eax                                            ; stack_base + stack_offset

        ; ��ȡ x2APIC ID
        call extrac_x2apic_id

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
        DELAY
        DELAY

;; ���ڷ� IPI ��Ŀ�� processor
	mov esi, bp_msg1
	call puts
	mov esi, 01
	call print_dword_value
	call println

        mov DWORD [APIC_BASE + ICR1], 01000000h                 ; APIC ID = 01
        mov DWORD [APIC_BASE + ICR0], PHYSICAL_ID | 30h         ; vector Ϊ 30h

        jmp $



; ������ APs ����
ap_processor:       
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
        
        ; ��ȡ x2APIC ID 
        call extrac_x2apic_id

        lock btr DWORD [vacant], 0                          ; �ͷ� lock
        sti
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



bp_msg1 db '<bootstrap processor>  : '
bp_msg2 db 'now, send IPIs to APIC ID: ', 0

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


;---------------------------------------------
; ap_ipi_handler()������ AP IPI handler
;---------------------------------------------
ap_ipi_handler:
	jmp do_ap_ipi_handler
at_msg2 db 10, 10, '>>>>>>> This is processor ID: ', 0
at_msg3 db '---------- extract APIC ID -----------', 10, 0
do_ap_ipi_handler:	
	mov esi, at_msg2
	call puts
	mov edx, [APIC_BASE + APIC_ID]	; �� APIC ID
	shr edx, 24
	mov esi, edx
	call print_dword_value
	call println
	mov esi, at_msg3
	call puts

	mov esi, msg2			; ��ӡ package ID
	call puts
	mov esi, [x2apic_package_id + edx * 4]
	call print_dword_value
	call printblank	
	mov esi, msg3			; ��ӡ core ID
	call puts
	mov esi, [x2apic_core_id + edx * 4]
	call print_dword_value
	call printblank	
	mov esi, msg4			; ��ӡ smt ID
	call puts
	mov esi, [x2apic_smt_id + edx * 4]
	call print_dword_value
	call println

	mov DWORD [APIC_BASE + EOI], 0
	iret






%define APIC_PERFMON_HANDLER
%define APIC_TIMER_HANDLER

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