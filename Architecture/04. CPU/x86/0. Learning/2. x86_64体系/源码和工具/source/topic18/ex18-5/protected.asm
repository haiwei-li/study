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

        ;*
        ;* perfmon ��ʼ����
        ;* �ر����� counter �� PEBS 
        ;* �� overflow ��־λ
        ;*
        DISABLE_GLOBAL_COUNTER
        DISABLE_PEBS
        RESET_COUNTER_OVERFLOW        

;����APIC
        call enable_xapic        
        
;���� APIC performance monitor counter handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, apic_perfmon_handler
        call set_interrupt_handler

        
; ���� LVT performance monitor counter
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED_DELIVERY | APIC_PERFMON_VECTOR


;========= ��ʼ��������� =================


;;; ʵ�� 18-05����xAPIC ID����ȡ Package/Core/SMT IDֵ
        
        call extrac_xapic_id
        
        call get_apic_id
        mov edx, eax
        
        mov esi, msg1
        call puts
        mov esi, [xapic_id + edx * 4]
        call print_dword_value
        call println
        mov esi, msg
        call puts
        
        mov esi, msg2
        call puts
        mov esi, [xapic_package_id + edx * 4]
        call print_dword_value
        call println        
        mov esi, msg3
        call puts
        mov esi, [xapic_core_id + edx * 4]
        call print_dword_value
        call println        
        mov esi, msg4
        call puts
        mov esi, [xapic_smt_id + edx * 4]
        call print_dword_value
        call println        

        mov esi, msg
        call puts
                
        mov esi, msg5
        call puts
        mov esi, [xapic_smt_mask_width + edx * 4]
        call print_dword_decimal
        mov esi, msg6
        call puts
        mov esi, [xapic_smt_select_mask]
        call print_dword_value
        call println

        mov esi, msg7
        call puts
        mov esi, [xapic_core_mask_width + edx * 4]
        call print_dword_decimal
        mov esi, msg8
        call puts
        mov esi, [xapic_core_select_mask]
        call print_dword_value
        call println
        
        mov esi, msg9
        call puts
        mov esi, [xapic_package_mask_width + edx * 4]
        call print_dword_decimal
        mov esi, msg10
        call puts
        mov esi, [xapic_package_select_mask]
        call print_dword_value
        call println

  


        jmp $

msg         db '-------------------------------------------', 10, 0
msg1        db 'APIC ID    : 0x', 0
msg2        db 'PACKAGE ID : 0x', 0
msg3        db 'CORE ID    : 0x', 0
msg4        db 'SMT ID     : 0x', 0
msg5        db 'SMT_MASK_WIDTH: ', 0
msg6        db '        SMT_SELECT_MASK: 0x', 0
msg7        db 'CORE_MASK_WIDTH: ', 0
msg8        db '       CORE_SELECT_MASK: 0x', 0
msg9        db 'PACKAGE_MASK_WIDTH: ', 0
msg10       db '   PACKAGE_SELECT_MASK: 0x', 0

        
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