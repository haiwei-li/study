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
        
;; �ر�8259
        call disable_8259
        
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
        mov edi, debug_handler
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
                  
;========= ��ʼ��������� =================

;;; ʵ�� ex14-8������ single-step on branch ����
        
; 1) ���� debug control        
        mov ecx, IA32_DEBUGCTL
        mov edx, 0
        mov eax, 2                                ; BTF = 1
        wrmsr
        
; 2) ���� single-step
        pushf
        bts DWORD [esp], 8                        ; eflags.TF = 1
        popf
        
; 3) ���� single-step        
        mov ecx, 0
        mov ecx, 1
        mov ecx, 2
        jmp next1
        mov ecx, 3
        mov ecx, 4
        mov ecx, 5
next1:
        mov ecx, 6
        mov ecx, 7
        jmp next2
        mov ecx, 8
        mov ecx, 9
        mov ecx, 10
next2:        
        pushf
        btr DWORD [esp], 8                        ; eflags.TF = 0
        popf
                        
; �� BTF
        mov ecx, IA32_DEBUGCTL
        mov edx, 0
        mov eax, 0
        wrmsr

        
        jmp $


        
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



;; ��ʵ����ʹ�õ� #DB handler

debug_handler:
        jmp do_debug_handler
dh_msg      db '#', 0        
dh_msg1     db ': #DB exception occur: 0x', 0
dh_msg2     db '  ecx: 0x', 0
count       dd 0
do_debug_handler:
        mov esi, dh_msg
        call puts
        mov esi, [count]
        call print_dword_decimal
        mov esi, dh_msg1
        call puts
        mov esi, [esp]
        call print_dword_value
        mov esi, dh_msg2
        call puts
        mov esi, ecx
        call print_dword_value
        call println

; ���� BTF        
        mov ecx, IA32_DEBUGCTL
        mov edx, 0
        mov eax, 2                           ; BTF = 1
        wrmsr
                
        bts DWORD [esp+8], 16                ; RF=1        
        inc DWORD [count]
        iret



        
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