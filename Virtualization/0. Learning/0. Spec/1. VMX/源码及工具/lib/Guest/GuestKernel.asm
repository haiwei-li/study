;*************************************************
; GuestKernel.asm                                *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%include "..\..\inc\support.inc"
%include "..\..\lib\Guest\Guest.inc"



        
        [SECTION .text]
        org GUEST_KERNEL_ENTRY
        dd GUEST_KERNEL_LENGTH
        
;;
;; 当前 guest 已经位于未分页的 protected 模式下
;; 
        bits 32

GuestKernel.Start:        
        
        mov esi, Guest.StartMsg
        call PutStr

        mov eax, cr4
        or eax, CR4_PAE
        mov cr4, eax                            ; 开启 CR4.PAE
        
        
        ;;
        ;; 根据 GUEST_X64 符号来决定 guest 进入 IA-32e 还是 protected 模式
        ;;
        
%ifdef GUEST_X64
        ;;
        ;; 初始化 long mode 模式页表
        ;;
        call init_longmode_page
        
        mov eax, GUEST_PML4T_BASE
        mov cr3, eax
        
        ;;
        ;; 开启 long mode
        ;;
        mov ecx, IA32_EFER
        rdmsr
        or eax, EFER_LME
        wrmsr
        
        ;;
        ;; 开启分页
        ;;
        mov eax, cr0
        or eax, CR0_PG
        mov cr0, eax
        
        jmp GuestKernelCs64 : GuestKernel.@0

GuestKernel.@0:
        
        bits 64
        
        mov ax, GuestKernelSs64
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov rsp, 0FFFF8000FFF00FF0h
        
        
        mov rax, (0FFFF800080000000h + GuestKernel.Next)
        jmp rax
        
        
%else   

        ;;-------------------------
        ;; 32 位保护模式
        ;;-------------------------
   
        call init_pae_page
        
        mov eax, Guest.Pdpt
        mov cr3, eax
        
        ;;
        ;; 开启分页
        ;;
        mov eax, cr0
        or eax, CR0_PG
        mov cr0, eax
        
        mov esp, 0FFF00FF0h
        mov eax, (80000000h + GuestKernel.Next)
        jmp eax
        
%endif        
        
        



;;###########################
;;      guest kernel 
;;###########################

 GuestKernel.Next:  
        ;;
        ;; 更新处理器标志
        ;;
        or DWORD [Guest.ProcessorFlag], GUEST_PROCESSOR_PAGING 
        
        ;;
        ;; 输出信息
        ;;     
        mov esi, Guest.DoneMsg
        call PutStr
        mov esi, Guest.RunMsg
        call PutStr
        mov esi, Guest.TscMsg
        call PutStr
        rdtsc
        mov esi, eax
        mov edi, edx
        call PrintQword
        call PrintLn
       

       
        ;;
        ;; geust_ex.asm 是 guest 的示例文件
        ;;
        %include "guest_ex.asm"
        
       
        jmp $
        
        
        
%include "..\..\lib\Guest\GuestLib.asm"
%include "..\..\lib\Guest\GuestCrt.asm"
%include "..\..\lib\Guest\Guest8259.asm"




;;#####################################
;;
;;         Guest 的数据区域
;;
;;#####################################
        
        [SECTION .data]

Guest.PoolPhysicalBase          DD      GUEST_POOL_PHYSICAL_BASE

;;
;; 处理器状态标志位
;;
Guest.ProcessorFlag             DD      0


Guest.VideoBufferPtr            DQ      0B8000h
Guest.IdtPointer:               DW      0
                                DQ      0
Guest.TssBase                   DQ      0


KeyBufferLength                 DD      256
KeyBufferHead                   DQ      KeyBuffer
KeyBufferPtr                    DQ      (KeyBuffer - 1)
KeyBuffer            times 256  DB      0




%ifndef GUEST_X64

;;
;; 下面是 PAE paging 下的 PDPT 表
;; 1) 每个 PDPTE 为 8 字节
;;
        ALIGNB 32
Guest.Pdpt                      DQ      GUEST_PDT0_BASE | P
                                DQ      GUEST_PDT1_BASE | P
                                DQ      GUEST_PDT2_BASE | P
                                DQ      GUEST_PDT3_BASE | P
                
%endif        


;;
;; 信息
;;
Guest.StartMsg                  db      '[OS]: start ...', 10, 0
Guest.DoneMsg                   db      '[OS]: initialize done ...', 10, 0
Guest.RunMsg                    db      '[OS]: running ...', 10, 0
Guest.TscMsg                    db      '[OS]: TSC = ', 0


GUEST_KERNEL_LENGTH             EQU     $ - GUEST_KERNEL_ENTRY
