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
        call disable_8259
        sti
        
;========= ��ʼ��������� =================


;
;** ʵ�� 20-3����ӡ status��Ϣ�� stack
;

        finit                                   ; ��ʼ�� x87 FPU
        fldz                                    ; ���� 0.0
        fld TWORD [QNaN_value]                  ; ���� QNaN ��
        fld TWORD [SNaN_value]                  ; ���� SNaN ��
        fld1                                    ; ���� 1.0
        call dump_data_register                 ; ��ӡ stack
        call println
        mov esi, msg
        call puts

;; ����Ƚ�
        fcom st2                                ; ST(2)�� QNaN ��
        call dump_x87_status

;; ���쳣������λ
        fstenv [x87env32]
        and WORD [status_word], 0x3800          ; �� status
        fldenv [x87env32]

;; ����Ƚ�
        mov esi, msg1
        call puts

        fucom st2                               ; ST(2)�� QNaN ��
        call dump_x87_status

;; ���쳣������λ
        fstenv [x87env32]
        and WORD [status_word], 0x3800          ; �� status
        fldenv [x87env32]

; �Ƚ� SNaN ��
        mov esi, msg2
        call puts

        fucom st1                               ; ST(1)�� SNaN ��
        call dump_x87_status

        jmp $
        


SNaN_value      dd 0xffffffff                    ; SNaN ������
                dd 0xbfffffff
                dw 0xffff

QNaN_value      dd 0xffffffff                   ; QNaN ������
                dd 0xffffffff
                dw 0xffff
infinity        dd 0x7f800000                   ; infinity ������
denormal        dd 0xFFFFFFFF                   ; denormal ������
                dd 0x7FFFFFFF
                dw 0


msg     db 10, 'fcom st2 (for QNaN): ', 10, 0
msg1    db 10, 'fucom st2 (for QNaN): ', 10, 0
msg2    db 10, 'fucom st1 (for SNaN): ', 10, 0


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
%include "..\lib\x87.asm"

;;************* ���������  *****************

; ��� lib32 �⵼������� common\ Ŀ¼�£�
; ������ʵ��� protected.asm ģ��ʹ��

%include "..\common\lib32_import_table.imt"


PROTECTED_END: