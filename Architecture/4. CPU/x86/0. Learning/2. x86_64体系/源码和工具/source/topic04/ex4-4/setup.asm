; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这是一个空白模块示例，设为 setup 模块
; 用于写入磁盘的第 2 个扇区 ！
;

%include "..\inc\support.inc"

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
        mov si, [message_table + eax * 2]
        call puts
        call println
        
        mov si, eax_msg
        call puts        
        mov eax, 01H
        cpuid
        mov esi, eax
        mov di, value_address
        call get_dword_hex_string
        mov si, value_address
        call puts
        call println
        call get_DisplayFamily_DisplayModel
        mov ebx, eax
        mov si, display_family_msg
        call puts
        mov esi, ebx
        shr esi, 8
        mov di, value_address
        call get_hex_string
        mov si, value_address
        call puts
        call println
        mov si, display_model_msg
        call puts
        mov esi, ebx
        and esi, 0xff
        mov di, value_address
        call get_hex_string
        mov si, value_address
        call puts
        
                
        jmp $

display_family_msg      db 'DisplayFamily: 0x', 0
display_model_msg       db 'DisplayModel: 0x', 0
value_address           dd 0 ,0, 0

eax_msg                 db '<eax>: 0x', 0

support_message         db 'support CPUID instruction', 13, 10, 0
no_support_message      db 'no support CPUID instruction', 13, 10, 0                
message_table           dw no_support_message, support_message, 0

;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数

FUNCTION_IMPORT_TABLE:

puts:                           jmp LIB16_SEG + LIB16_PUTS * 3
putc:                           jmp LIB16_SEG + LIB16_PUTC * 3
get_hex_string:                 jmp LIB16_SEG + LIB16_GET_HEX_STRING * 3
test_CPUID:                     jmp LIB16_SEG + LIB16_TEST_CPUID * 3
get_dword_hex_string:           jmp LIB16_SEG + LIB16_GET_DWORD_HEX_STRING * 3
println                         jmp LIB16_SEG + LIB16_PRINTLN * 3
get_DisplayFamily_DisplayModel: jmp LIB16_SEG + LIB16_GET_DISPLAYFAMILY_DISPLAYMODEL * 3


SETUP_END:

; end of setup        