;*************************************************
; GuestBoot.asm                                  *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%include "..\..\inc\support.inc"
%include "..\..\inc\ports.inc"
%include "..\..\lib\Guest\Guest.inc"

;;
;; Guest 示例模块说明: 
;; 1) 开始于 7C00h(实模式)
;; 2) 切换到保护模式
;;


;;
;; 注意: 
;; 1) 现在处理器处于 real mode 下       
;; 2) 模拟 GuestBoot 已经被加载到 7C00h 位置上, GUEST_BOOT_ENTRY 定义为 7C00h
;;        

        [SECTION .text]
        org GUEST_BOOT_ENTRY
        dd GUEST_BOOT_LENGTH                                    ;; GuestBoot 模块长度
          
        bits 16
        
GuestBoot.Start:
        cli
        NMI_DISABLE                                             ; 关闭 NMI
        FAST_A20_ENABLE                                         ; 开启 A20 位        
        
; set BOOT_SEG environment
        mov ax, cs
        mov ds, ax
        mov ss, ax
        mov es, ax
        mov sp, GUEST_BOOT_ENTRY                                ; 设 stack 底为 GUEST_BOOT_ENTRY

               
        
        ;**************************************
        ;*  下面切换到保护模式                *
        ;**************************************

        lgdt [Guest.GdtPointer]                                 ; 加载 GDT
        lidt [Guest.IdtPointer]                                 ; 加载 IDT        

        ;;
        ;; 设置 TSS 
        ;;
        mov WORD [tss_desc], 67h
        mov WORD [tss_desc + 2], Guest.Tss
        mov BYTE [tss_desc + 5],  89h
        
        mov eax, cr0
        bts eax, 0                                              ; CR0.PE = 1
        mov cr0, eax
             
        jmp GuestKernelCs32 : GuestBoot.Entry32
        
        ;;
        ;; 以下是 32 位 protected 模式代码
        ;;
        
        bits 32

GuestBoot.Entry32:
        mov ax, GuestKernelSs32                                 ; 设置 data segment
        mov ds, ax
        mov es, ax
        mov ss, ax

        
        ;; 
        ;; 加载 TSS
        ;;
        mov ax, GuestKernelTss
        ltr ax

        ;;
        ;; 下面转入 GuestKernel 模块, 入口在 GUEST_KERNEL_ENTRY + 4
        ;;        
        jmp GUEST_KERNEL_ENTRY + 4





        [SECTION .data]
;;        
;; Guest 模块的 GDT
;;
Guest.Gdt:
null_desc               dq 0                    ; NULL descriptor
kernel_code64_desc      dq 0x0020980000000000   ; DPL=0, L=1
kernel_data64_desc      dq 0x0000920000000000   ; DPL=0
user_code32_desc        dq 0x00cff8000000ffff   ; non-conforming, DPL=3, P=1
user_data32_desc        dq 0x00cff2000000ffff   ; DPL=3, P=1, writeable, expand-up
user_code64_desc        dq 0x0020f80000000000   ; DPL = 3
user_data64_desc        dq 0x0000f20000000000   ; DPL = 3
kernel_code32_desc      dq 0x00cf9a000000ffff   ; non-conforming, DPL=0, P=1
kernel_data32_desc      dq 0x00cf92000000ffff   ; DPL=0, P=1, writeable, expand-up
tss_desc                dq 0                    ; TSS
reserved_desc           dq 0
                        dq 0
                        dq 0
                        dq 0 
Guest.Gdt.End:



;;
;; Guest 模块的 IDT
;;
Guest.Idt:
        times 256       dq 0                    ; 保留 256 个 vector
Guest.Idt.End:        


;;
;; Guest 模块的 TSS
;;
Guest.Tss:
                        dd 0                
                        dd 7FF0h                        ; esp0
                        dd GuestKernelSs32              ; ss0
                        dq 0                            ; ss1/esp1
                        dq 0                            ; ss2/esp2
                        dq 0                            ; reserved
                        dq 0FFFF8000FFF008F0h           ; IST1
               times 17 dd 0        
                        dw 0                       
                        dw 0                            ; I/O permission bitmap offset = 0 
Guest.Tss.End:



;;
;; Guest 模块的 Gdt pointer
;;
Guest.GdtPointer:
gdt_limit               dw      (Guest.Gdt.End - Guest.Gdt) - 1
gdt_base                dd      Guest.Gdt


;;
;; Guest 模块的 Idt pointer
;;
Guest.IdtPointer:
idt_limit               dw      (Guest.Idt.End - Guest.Idt) - 1
idt_base                dd      Guest.Idt



    
  

GUEST_BOOT_LENGTH       EQU     $ - GUEST_BOOT_ENTRY