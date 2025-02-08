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

setup_length    dw (SETUP_END - SETUP_BEGIN)            ; SETUP_END-SETUP_BEGIN 是这个模块的 size


setup_entry:                                            ; 这是模块代码的入口点. 

        cli
        
        db 0x66
        lgdt [__gdt_pointer]                      ; 加载 GDT
        
        db 0x66
        lidt [__idt_pointer]                      ; 加载 IDT

;;设置 TSS 
        mov WORD [tss32_desc], 0x68 + __io_bitmap_end - __io_bitmap
        mov WORD [tss32_desc + 2], __task_status_segment
        mov BYTE [tss32_desc + 5], 0x80 | TSS32
        
;; 设置用于测试的 TSS
        mov WORD [tss_test_desc], 0x68 + __io_bitmap_end - __io_bitmap
        mov WORD [tss_test_desc + 2], __test_tss
        mov BYTE [tss_test_desc + 5], 0x80 | TSS32        

;; 设置 LDT 
        mov WORD [ldt_desc], __local_descriptor_table_end - __local_descriptor_table - 1        ; limit
        mov DWORD [ldt_desc + 4], __local_descriptor_table              ; base [31:24]
        mov DWORD [ldt_desc + 2], __local_descriptor_table              ; base [23:0]
        mov WORD [ldt_desc + 5], 80h | LDT_SEGMENT                      ; DPL=0, type=LDT


        mov eax, cr0
        bts eax, 0                              ; CR0.PE = 1
        mov cr0, eax
        
        jmp kernel_code32_sel:entry32                                                
        


;;; 以下是 32 位 protected 模式代码
        
        bits 32

entry32:
        mov ax, kernel_data32_sel               ; 设置 data segment
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, 0x7ff0        

;; load TSS segment
        mov ax, tss32_sel
        ltr ax
                
        jmp PROTECTED_SEG                        
                
  
     
;*        
;* 以下定义 protected mode 的 GDT 表 segment descriptor
;*
__global_descriptor_table:

null_desc                       dq 0                    ; NULL descriptor

code16_desc                     dq 0x00009a000000ffff   ; base=0, limit=0xffff, DPL=0                
data16_desc                     dq 0x000092000000ffff   ; base=0, limit=0xffff, DPL=0
kernel_code32_desc              dq 0x00cf9a000000ffff   ; non-conforming, DPL=0, P=1
kernel_data32_desc              dq 0x00cf92000000ffff   ; DPL=0, P=1, writeable, expand-up
user_code32_desc                dq 0x00cff8000000ffff   ; non-conforming, DPL=3, P=1
user_data32_desc                dq 0x00cff2000000ffff   ; DPL=3, P=1, writeable, expand-up

tss32_desc                      dq 0
call_gate_desc                  dq 0
conforming_code32_desc          dq 0x00cf9e000000ffff   ; conforming, DPL=0, P=1
tss_test_desc                   dq 0
task_gate_desc                  dq 0
ldt_desc                        dq 0
                       times 10 dq 0                    ; 保留 10 个
__global_descriptor_table_end:


; 以下定义 protected mode 的 IDT entry
__interrupt_descriptor_table:
        times 0x80 dq 0                                ; 保留 0x80 个 vector
__interrupt_descriptor_table_end:


__local_descriptor_table:
        times 10 dq 0
__local_descriptor_table_end:

;*
;* 以下定义 TSS 段结构
;*
__task_status_segment:
        dd 0                
        dd PROCESSOR0_KERNEL_ESP        ; esp0
        dd kernel_data32_sel            ; ss0
        dq 0                            ; ss1/esp1
        dq 0                            ; ss2/esp2
times 19 dd 0        
        dw 0
        ;*** 下面是 IOBITMAP 偏移量地址 ***
        dw __io_bitmap - __task_status_segment

__task_status_segment_end:


;*** 测试用 TSS 段
__test_tss:
        dd 0                
        dd 0x8f00                       ; esp0
        dd kernel_data32_sel            ; ss0
        dq 0                            ; ss1/esp1
        dq 0                            ; ss2/esp2
times 19 dd 0        
        dw 0
        ;*** 下面是 IOBITMAP 偏移量地址 ***
        dw __io_bitmap - __test_tss
__test_tss_end:



;; 为 IO bit map 保留 10 bytes(IO space 从 0 - 80)
__io_bitmap:
        times 10 db 0        
__io_bitmap_end:



; 定义 GDT pointer
__gdt_pointer:
gdt_limit       dw      (__global_descriptor_table_end - __global_descriptor_table) - 1
gdt_base        dd      __global_descriptor_table


; 定义 IDT pointer
__idt_pointer:
idt_limit       dw      (__interrupt_descriptor_table_end - __interrupt_descriptor_table) - 1
idt_base        dd       __interrupt_descriptor_table


;; 定义实模式的  IVT pointer
__ivt_pointer:
                dw 3FFH
                dd 0
                



;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数


FUNCTION_IMPORT_TABLE:

puts:                   jmp LIB16_SEG + LIB16_PUTS * 3
putc:                   jmp LIB16_SEG + LIB16_PUTC * 3
get_hex_string:         jmp LIB16_SEG + LIB16_GET_HEX_STRING * 3
test_CPUID:             jmp LIB16_SEG + LIB16_TEST_CPUID * 3
clear_screen:           jmp LIB16_SEG + LIB16_CLEAR_SCREEN * 3

puts32:                 jmp LIB32_SEG + LIB32_PUTS * 5
get_dword_hex_string:   jmp LIB32_SEG + LIB32_GET_DWORD_HEX_STRING * 5        
println                 jmp LIB32_SEG + LIB32_PRINTLN * 5
print_value             jmp LIB32_SEG + LIB32_PRINT_VALUE * 5



SETUP_END:

; end of setup        