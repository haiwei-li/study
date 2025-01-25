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



        mov DWORD [PT1_BASE + 0 * 8 + 4], 0             ; �� 400000h ���ÿ�ִ��

; ʵ�� 14-5���۲� #DB �쳣�µ� LBR

; 1)���� L0 ִ�жϵ�λ
        mov eax, 1
        mov dr7, eax
        
; 2) ����ִ�жϵ�        
        mov eax, breakpoint
        mov dr0, eax        

; 3) ���� LBR
        mov ecx, IA32_DEBUGCTL
        rdmsr
        bts eax, LBR_BIT                               ; �� LBR λ
        bts eax, TR_BIT                                ; �� TR λ
        wrmsr

breakpoint:
; 4) ���˳� #DB handler ��۲� IA32_DEBUGCTL �Ĵ���
        call dump_debugctl                        ; 
        call println
        
; 5) �� TR
        mov ecx, IA32_DEBUGCTL
        rdmsr
        btr eax, TR_BIT                                 ; �� TR λ
        wrmsr        
        
; 6) �ر�ִ�жϵ�
        mov eax, dr7
        btr eax, 0
        mov dr7, eax

; 7) �鿴 last exception �Ƿ��ܼ�¼ #DB hanlder                
        call dump_last_exception
                
; 8) ��� LBR stack ��Ϣ
        call dump_lbr_stack
        call println

        
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




;*** #DB handler ***
debug_handler:
        jmp do_debug_handler
dh_msg1        db '>>> now, enter #DB handler', 10, 0
dh_msg2        db 'now, exit #DB handler <<<', 10, 0        
dh_msg3        db 'last exception from: 0x', 0,
dh_msg4        db 'last exception to: 0x', 0
do_debug_handler:
        mov esi, dh_msg1
        call puts
        call dump_drs                           ; ��ӡ DR0-DR3
        call dump_dr6                           ; ӡ DR6
        call dump_debugctl                      ; �۲� IA32_DEBUGCTL �Ĵ���
        call dump_last_exception                ; �۲� last exception
        mov esi, dh_msg2
        call puts
        call println
        
        bts DWORD [esp+8], 16                   ; RF=1        
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