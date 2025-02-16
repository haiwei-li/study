; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这是一个空白模块示例，设为 setup 模块
; 用于写入磁盘的第 2 个扇区 ！
;

%include "..\inc\support.inc"

;
; setup 模块是运行在 16 位实模式下

        bits 16
        
        
;
; 模块开始点是 SETUP_SEG - 2，减 2 是因为要算上模块头的存放的“模块 size”
; load_module 加载到 SETUP_SEG-2，实际效果是 SETUP 模块会被加载到“入口点”即：setup_entry
;
        org SETUP_SEG - 2
        
;
; 在模块的开头 word 大小的区域里存放模块的大小，
; load_module 会根据这个 size 加载模块到内存

SETUP_BEGIN:

setup_length    dw (SETUP_END - SETUP_BEGIN)            ; SETUP_END-SETUP_BEGIN 是这个模块的 size


setup_entry:                                            ; 这是模块代码的入口点。
        
        call test_CPUID
        test ax, ax
        jz no_support

;; 获得最大 basic 功能号
        mov eax, 0
        cpuid
        mov esi, eax
        mov di, value_address
        call get_dword_hex_string
        mov si, basic_message
        call puts
        mov si, value_address
        call puts
        call println
        
;; 获得最大 extended 功能号        
        mov eax, 0x80000000
        cpuid
        mov esi, eax
        mov di, value_address
        call get_dword_hex_string
        mov si, extend_message
        call puts
        mov si, value_address
        call puts        
        call println
        
        jmp $
        
no_support:        
        mov si, [message_table + eax * 2]
        call puts
        jmp $
        

support_message         db 'support CPUID instruction', 13, 10, 0
no_support_message      db 'no support CPUID instruction', 13, 10, 0                
message_table           dw no_support_message, support_message, 0

basic_message           db 'maximun basic function: 0x', 0
extend_message          db 'maximun extended function: 0x', 0
value_address           dd 0, 0, 0


;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数

FUNCTION_IMPORT_TABLE:

puts:                   jmp LIB16_SEG + LIB16_PUTS * 3
putc:                   jmp LIB16_SEG + LIB16_PUTC * 3
get_hex_string:         jmp LIB16_SEG + LIB16_GET_HEX_STRING * 3
test_CPUID:             jmp LIB16_SEG + LIB16_TEST_CPUID * 3
get_dword_hex_string:   jmp LIB16_SEG + LIB16_GET_DWORD_HEX_STRING * 3
println                 jmp LIB16_SEG + LIB16_PRINTLN * 3


SETUP_END:

; end of setup        