; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; ???? protected ???

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected ??øA??

entry:
        
;; ???8259
        call disable_8259
        
;; ???? #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; ???? #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

; ???? #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, DB_handler
        call set_interrupt_handler


;; ???? sysenter/sysexit ??????
        call set_sysenter

;; ???? system_service handler
        mov esi, SYSTEM_SERVICE_VECTOR
        mov edi, system_service
        call set_user_interrupt_handler 

; ??????? SSE ???        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        
        
;???? CR4.PAE
        call pae_enable
        
; ???? XD ????
        call execution_disable_enable
                
; ????? paging ????
        call init_pae_paging
        
;???? PDPT ?????        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; ???paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax               
                  
;========= ???????????? =================

        mov DWORD [PT1_BASE + 0 * 8 + 4], 0             ; ?? 400000h ????????

; ??? 14-4?????????? jmp ????????

; 1)?????????? func() ?? 0x400000 ?????
        mov esi, func
        mov edi, 0x400000
        mov ecx, func_end - func
        rep movsb


; 2) ???? LBR
        mov ecx, IA32_DEBUGCTL
        rdmsr
        bts eax, LBR_BIT                        ; ?? LBR ¦Ë
        wrmsr

; 3) ???¨´???????

; ????????????§Ö?jmp??????????¦Ë??
;        mov ecx, MSR_LBR_SELECT
;        xor edx, edx
;        mov eax, 0x1c4                        ; ???????? jmp ???
;        wrmsr

; ????????????§Ö?jmp??????????¦Ë?????? FAR_BRANCH)
        mov ecx, MSR_LBR_SELECT
        xor edx, edx
        mov eax, 0xc4                        ; ???????? jmp ???(???? FAR_BRANCH)
        wrmsr
        
        
; 4) ???????

; ?????????? near indirect call??
;        mov eax, 0x400000
;        call eax                                        ; ??? near indirect call

; ?????????? far call??
        call DWORD KERNEL_CS:0x400000

; 5) ?? LBR 
        mov ecx, IA32_DEBUGCTL
        rdmsr
        btr eax, LBR_BIT                        ; ?? LBR ¦Ë
        wrmsr


; 6) ??? LBR stack ???
        call dump_lbr_stack
        call println

        
        jmp $


        
; ??? long ???
        ;jmp LONG_SEG
                                
                                
; ???? ring 3 ????
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; ???????

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:

        jmp $




;; ???????
func:
        mov eax, func_next-func+0x400000
        jmp eax                                        ; near indirect jmp
func_next:        
        call get_eip                                    ; near relative call
get_eip:
        pop eax        
        mov eax, 0
        mov esi, msg1                                   ; ???????
        int 0x40                                        ; ??? int ?????? system service
        ret
func_end:        

msg1        db 10, 0







        
;******** include ?§Ø? handler ???? ********
%include "..\common\handler32.asm"


;********* include ??? ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\apic.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\page32.asm"
%include "..\lib\pic8259A.asm"


;;************* ?????????  *****************

; ??? lib32 ????????? common\ ?????
; ?????????? protected.asm ??????

%include "..\common\lib32_import_table.imt"


PROTECTED_END: