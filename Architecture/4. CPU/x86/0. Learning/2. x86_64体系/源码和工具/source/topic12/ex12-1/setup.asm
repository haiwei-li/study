; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这是一个空白模块示例, 设为 setup 模块
; 用于写入磁盘的第 2 个扇区 ！
;

%include "..\inc\support.inc"
%include "..\inc\protected.inc"

;
; setup 模块是运行在 16 位实模式下

        bits 16
        
        
;
; 模块开始点是 SETUP_SEG - 2, 减 2 是因为要算上模块头的存放的"模块 size"
; load_module 加载到 SETUP_SEG-2, 实际效果是 SETUP 模块会被加载到"入口点"即: setup_entry
;
        org SETUP_SEG - 2
        
;
; 在模块的开头 word 大小的区域里存放模块的大小, 
; load_module 会根据这个 size 加载模块到内存

SETUP_BEGIN:

setup_length        dw (SETUP_END - SETUP_BEGIN)        ; SETUP_END-SETUP_BEGIN 是这个模块的 size


setup_entry:                            ; 这是模块代码的入口点. 

        cli
        NMI_DISABLE

        call support_long_mode
        test eax, eax
        jz no_support


; 加载 GDTR
        db 66h                          ; 使用 32 位 operand size
        lgdt [GDT_POINTER]        


; 开启 PAE
        mov eax, cr4
        bts eax, 5                      ; CR4.PAE = 1
        mov cr4, eax

; init page
        call init_page

; 加载 CR3
        mov eax, 5000h
        mov cr3, eax

; enable long-mode
        mov ecx, IA32_EFER
        rdmsr
        bts eax, 8                      ; IA32_EFER.LME =1
        wrmsr

        mov si, msg0
        call puts

; 加载 IDTR        
        db 66h                          ; 使用 32-bit operand size
        lidt [IDT_POINTER]        

; 开启 PE 和 paging
        mov eax, cr0
        bts eax, 0                      ; CR0.PE =1
        bts eax, 31
        mov cr0, eax                    ; IA32_EFER.LMA = 1

        
        jmp 28h:entry64                                                
        

no_support:
        mov si, msg1
        call puts
        jmp $

;;; 以下是 64-bit 模式代码
        
        bits 64

entry64:
        mov ax, 30h                    ; 设置 data segment
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, 7FF0h        

        mov esi, msg2
        call puts64
        jmp $
                


puts64:
        mov edi, 0B8000h

puts64_loop:
        lodsb
        test al, al
        jz puts64_done
        cmp al, 10
        jne puts64_next
        add edi, 80*2
        jmp puts64_loop
puts64_next:
        mov ah, 0Fh
        stosw
        jmp puts64_loop

puts64_done:
        ret


msg0        db 'now: enter real-mode', 13, 10, 0        
msg1        db 'no support long mode', 13, 10, 0
msg2        db 10, 'now: enter 64-bit mode', 0
        

; 以下定义 protected mode 的 GDT 表 segment descriptor

GDT:
null_desc               dq 0                            ; NULL descriptor

code16_desc             dq 0x00009a000000ffff           ; for real mode code segment
data16_desc             dq 0x000092000000ffff           ; for real mode data segment
code32_desc             dq 0x00cf9a000000ffff           ; for protected mode code segment
                                                           ; or for compatibility mode code segment
data32_desc             dq 0x00cf92000000ffff           ; for protected mode data segment
                                                        ; or for compatibility mode data segment

kernel_code64_desc      dq 0x0020980000000000           ; 64-bit code segment
kernel_data64_desc      dq 0x0000920000000001            ; 64-bit data segment
;;; 也为 sysexit 指令使用而组织
user_code32_desc        dq 0x00cffa000000ffff           ; for protected mode code segment
                                                        ; or for compatibility mode code segmnt
user_data32_desc        dq 0x00cff2000000ffff           ; for protected mode data segment
                                                        ; or for compatibility mode data segment        
;; 也为 sysexit 指令使用而组织                                                 
user_code64_desc        dq 0x0020f80000000000           ; 64-bit non-conforming
user_data64_desc        dq 0x0000f20000000000           ; 64-bit data segment
        times 10        dq 0                            ; 保留 10 个
GDT_END:


; 以下定义 protected mode 的 IDT entry
IDT:
        times 0x50 dq 0                                ; 保留 0x50 个 vector
IDT_END:


TSS32_SEG:
        dd 0                
        dd 1FFFF0h                                  ; esp0
        dd kernel_data32_sel                        ; ss0
        dq 0                                        ; ss1/esp1
        dq 0                                        ; ss2/esp2
times 19 dd 0        
         dw 0
IOBITMAP_ADDRESS        dw        IOBITMAP - TSS32_SEG
TSS32_END:

TSS_TEST_SEG:
        dd 0                
        dd 0x8f00                                   ; esp0
        dd kernel_data32_sel                        ; ss0
        dq 0                                        ; ss1/esp1
        dq 0                                        ; ss2/esp2
times 19 dd 0        
                dw 0
TEST_IOBITMAP_ADDRESS        dw        IOBITMAP - TSS_TEST_SEG
TSS_TEST_END:



;; 为 IO bit map 保留 10 bytes(IO space 从 0 - 80)
IOBITMAP:
times        10 db 0        
IOBITMAP_END:


; 定义 GDT pointer
GDT_POINTER:
GDT_LIMIT        dw        GDT_END - GDT - 1
GDT_BASE         dd        GDT

; 定义 IDT pointer
IDT_POINTER:
IDT_LIMIT        dw        IDT_END - IDT - 1
IDT_BASE         dd        IDT

;; 定义实模式的  IVT pointer
IVT_POINTER:     dw     3FFH
                 dd     0


        bits 16

;; 初始化 page 
init_page:
        ;; virtual address 0 到 1FFFFFh
        ;; 映射到 physical address 0 到 1FFFFFh, 使用 2M 页

        ; PML4T[0]
        mov DWORD [0x5000], 0x6000 | RW | US | P
        mov DWORD [0x5004], 0

        ; PDPT[0]
        mov DWORD [0x6000], 0x7000 | RW | US | P
        mov DWORD [0x6004], 0

        ; PDT[0]
        mov DWORD [0x7000], 0000h | PS | RW | US | P    ; 物理 page 0
        mov DWORD [0x7004], 0

        ret
                

;---------------------------------------------------
; support_long_mode(): 检测是否支持long-mode模式
; output:
;        1-support, 0-no support
;---------------------------------------------------
support_long_mode:
        mov eax, 80000000H
        cpuid
        cmp eax, 80000001H
        setnb al
        jb support_long_mode
        mov eax, 80000001H
        cpuid
        bt edx, 29                ; long mode  support 位
        setc al

support_long_mode_done:
        movzx eax, al
        ret


;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数


FUNCTION_IMPORT_TABLE:

puts:   jmp     LIB16_SEG + LIB16_PUTS * 3


SETUP_END:

; end of setup        