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


;; ʵ��ex20-6�����Խ����л��е�x87 FPU��ʱ�л�

;; ���� #NM handler
        mov esi, NM_HANDLER_VECTOR
        mov edi, nm_handler
        call set_interrupt_handler
        
;; ���� x87 FPU �� MMX ����
        mov eax, cr0
        bts eax, 1              ; MP = 1
        btr eax, 2              ; EM = 0
        mov cr0, eax
                    
        finit
        fsave [task_image]
        fsave [task_image + 108]
        
; ���� switch_to() ��������
        mov esi, 0x41
        mov edi, switch_to
        call set_user_interrupt_handler       
        
; ���񻷾�
        mov DWORD [task_context + 40 + CONTEXT_ESP], USER_ESP
        mov DWORD [task_context + 40 + CONTEXT_EIP], task_a
        mov DWORD [task_context + 40 + CONTEXT_VIDEO], 0xb8000
        mov DWORD [task_context + 40 * 2 + CONTEXT_ESP], USER_ESP
        mov DWORD [task_context + 40 * 2 + CONTEXT_EIP], task_b
        mov DWORD [task_context + 40 * 2 + CONTEXT_VIDEO], 0xb8000
       

; �������̻�
        mov esi, TASK_ID_A      ; �л��� task a
        int 0x41
        
        
        jmp $


task_link       dd 0, task_a, task_b, 0
task_id         dd 0

;; ���� x87 FPU ״̬ image
task_image: times (2 * 108) db 0

; integer ��Ԫ context
task_context: times (3 * 10) dd 0

TASK_ID_A       equ 1
TASK_ID_B       equ 2


;------------------------------------
; switch_to(): �����л�����
; input:
;       esi: task ID
;------------------------------------
switch_to:
        jmp do_switch
smsg    db '---> now: switch to task ID: ', 0
temp_id dd 0
do_switch:        
        mov [temp_id], esi
        mov esi, [task_id]                              ; ԭ���� ID
        lea esi, [esi * 4 + esi]
        lea esi, [esi * 8]                              ; esi * 40

; *** ����ɽ��� integer ��Ԫ context
        mov [task_context + esi + CONTEXT_EAX], eax     ; ���� eax �Ĵ���
        mov eax, [temp_id]
        mov [task_context + esi + CONTEXT_ESI], eax     ; ���� esi �Ĵ���
        
;  �ж�Ȩ��
        mov eax, [esp + 4]                              ; ��ȡ CS selector
        and eax, 3                                      ; CS.RPL
        jz save_cpl0
        ; ����Ȩ�޸ı�
        mov eax, [esp + 12]                             ; esp
        mov [task_context + esi + CONTEXT_ESP], eax     ; ���� esp
        jmp save_next
save_cpl0:        
        lea eax, [esp + 12]
        mov [task_context + esi + CONTEXT_ESP], eax     ; ���� esp
save_next:        
        mov eax, [esp]                                  ; eip
        mov [task_context + esi + CONTEXT_EIP], eax     ; ���� eip
        mov [task_context + esi + CONTEXT_ECX], ecx
        mov [task_context + esi + CONTEXT_EDX], edx
        mov [task_context + esi + CONTEXT_EBX], ebx
        mov [task_context + esi + CONTEXT_EBP], ebp
        mov [task_context + esi + CONTEXT_EDI], edi
        call get_video_current
        mov [task_context + esi + CONTEXT_VIDEO], eax
        
; �ý��� ID
        mov eax, [temp_id]
        mov DWORD [task_id], eax                        ; ��ǰ���̣��л���Ŀ����̣�        
        
; ��ӡ��Ϣ        
        mov esi, smsg
        call puts
        mov ebx, [task_id]
        mov esi, ebx
        call print_dword_decimal
        call println

        
; �� TS λ
        mov eax, cr0
        bts eax, 3                                      ; TS = 1
        mov cr0, eax
      
      
     
; *** ����Ŀ����� integer ��Ԫ context

;  �ж�Ȩ��
        mov eax, [esp + 4]                              ; ��ȡ CS selector
        and eax, 3                                      ; CS.RPL
        mov eax, 20
        mov esi, 12
        cmovz eax, esi
        add esp, eax                                    ; ��д���ص�ַ
        
; �л���Ŀ�����
        mov esi, ebx                                    ; Ŀ����� ID                        
        lea esi, [esi * 4 + esi]
        lea esi, [esi * 8]                              ; esi * 40
        
        call get_video_current
        mov [task_context + esi + CONTEXT_VIDEO], eax        
        mov ebx, [task_context + esi + CONTEXT_ESP]
        mov eax, [task_context + esi + CONTEXT_EIP]
                
        push DWORD user_data32_sel | 0x3
        push ebx
        push DWORD 2
        push DWORD user_code32_sel | 0x3        
        push eax
        
        mov eax, esi
        mov esi, [task_context + esi + CONTEXT_VIDEO]   ; video_current
        test esi, esi
        jz load_next
        call set_video_current
load_next:        
        mov esi, eax
        mov eax, [task_context + esi + CONTEXT_EAX]
        mov ecx, [task_context + esi + CONTEXT_ECX]
        mov edx, [task_context + esi + CONTEXT_EDX]
        mov ebx, [task_context + esi + CONTEXT_EBX]
        mov ebp, [task_context + esi + CONTEXT_EBP]
        mov edi, [task_context + esi + CONTEXT_EDI]
        mov esi, [task_context + esi + CONTEXT_ESI]        
        
        iret

;-----------------------------------
; ���� A
;----------------------------------
task_a:
        jmp do_task_a
a dd 0.25
b dd 1.5
amsg        db '<task A>:', 10, 0
result  dd 0
msg3    db ' + ', 0
msg4    db ' ) = ', 0

do_task_a:
        mov ax, user_data32_sel | 3
        mov ds, ax
        mov ss, ax
        mov es, ax
        
        mov esi, amsg
        call puts
        mov esi, '('
        call putc
        mov esi, a
        call print_dword_float
        mov esi, msg3
        call puts
        mov esi, b
        call print_dword_float
        mov esi, msg4
        call puts
        fld DWORD [a]
        fadd DWORD [b]   
         
        mov esi, TASK_ID_B
        int 0x41                                ; ���������л����л��� task b 
        
        fstp DWORD [result]
        mov esi, result
        call print_dword_float
        jmp $

;------------------------------------
; ���� B
;-----------------------------------
task_b:
        jmp do_task_b
array   dd 1, 2, 3, 4, 5, 6, 7, 8        
fmsg    db '(1+2+3+4+5+6+7+8) = ', 0
fmsg1   db '<task B>:', 10, 0
do_task_b:      
        mov ax, user_data32_sel | 3
        mov ds, ax
        mov ss, ax
        mov es, ax
          
        push ebp
        mov ebp, esp
        sub esp, 8

        mov esi, fmsg1
        call puts
        movq mm0, [array]                       ; 12
        movq mm1, [array + 8]                   ; 34
        movq mm2, [array + 16]                  ; 56
        movq mm3, [array + 24]                  ; 78
        paddd mm0, mm1                          
        paddd mm2, mm3                          
        movq mm4, mm0
        punpckhdq mm4, mm2                       
        punpckldq mm0, mm2
        paddd mm0, mm4
        movq [esp], mm0
        mov esi, fmsg
        call puts
        mov esi, [esp]
        add esi, [esp + 4]
        call print_dword_decimal
        call println

; �л��� task a        
        mov esi, TASK_ID_A 
        int 0x41
        
        mov esp, ebp
        pop ebp
        jmp $

;----------------------------------------------
; #NM handler
;----------------------------------------------
nm_handler:
        jmp do_nm_handler    
nmsg    db 10, '>>> now, enter the #NM handler', 10, 0
nmsg1   db 'exit the #NM handler <<<', 10, 0        
do_nm_handler:
        STORE_CONTEXT    
        mov esi, nmsg
        call puts

; �� TS ��־λ        
        clts
        
        ; �жϽ��� ID
        mov eax, [task_id]
        cmp eax, TASK_ID_A
        je switch_task_a                ; �л��� task A
        ;; �л��� task B
        fsave [task_image]              ; ���� task A �� image
        frstor [task_image + 108]       ; ���� task B �� image
        jmp do_nm_handler_done
        
switch_task_a:
        fsave [task_image + 108]        ; ���� task B �� image
        frstor [task_image]             ; ���� task A �� image

do_nm_handler_done:        
        mov esi, nmsg1
        call puts
        RESTORE_CONTEXT
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