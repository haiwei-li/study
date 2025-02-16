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
        
;========= ��ʼ��������� =================



; 1) ����APIC
        call enable_xapic        
        
; 2������ PMI handler
        mov esi, APIC_PERFMON_VECTOR
        mov edi, perfmon_handler
        call set_interrupt_handler
        
        
; 3) ���� LVT perfmon �Ĵ���
        mov DWORD [APIC_BASE + LVT_PERFMON], FIXED | APIC_PERFMON_VECTOR


;;; ʵ�� ex15-2������ IA32_PMC counter

; ���� IA32_PERF_GLOBAL_CTRL
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        bts eax, 0                              ; PMC0 enable
        wrmsr

        ; ��һ�δ�ӡ PMC ������ֵ
        call dump_pmc                           ; ��ӡ PMC ������
                
; ���� IA32_PERFEVTSEL0 �Ĵ���
        mov ecx, IA32_PERFEVTSEL0
        mov eax, INST_COUNT_EVENT               ; EN=1, INT=1, USR=OS=1, umask=0, event select = c0
        mov edx, 0
        wrmsr

        call foo                                 ; ���ò��Ժ���
        
        mov ecx, IA32_PERFEVTSEL0
        rdmsr
        btr eax, 22                              ; �ر� counter
        wrmsr
        
        ; �ڶ��δ�ӡ������ֵ
        call dump_pmc                            ; ��ӡ PMC ������

        jmp $
        
; ���� ring 3 ����
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf


;; **********************************        
;; �������û����루CPL = 3)
;; **********************************

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:
                
next:
        jmp $



;;; ���Ժ���
foo:
        mov esi, msg
        call puts                        ; ��ӡһ����Ϣ
        ret

msg     db 10, 'hi, this is test function !!!', 10, 10,0



;-------------------------------
; perfmon handler
;------------------------------
perfmon_handler:
        jmp do_perfmon_handler
pfh_msg1 db '>>> now: enter PMI handler', 10, 0
pfh_msg2 db 'exit the PMI handler <<<', 10, 0        
do_perfmon_handler:        
        mov esi, pfh_msg1
        call puts
        call dump_perfmon_global_status
        call dump_perfmon_global_ovf
        call dump_apic

        RESET_COUNTER_OVERFLOW
        mov esi, pfh_msg2
        call puts
do_perfmon_handler_done:
        btr DWORD [APIC_BASE + LVT_PERFMON], 16         ; �� mask λ
        mov DWORD [APIC_BASE + EOI], 0                  ; ���� EOI ����
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