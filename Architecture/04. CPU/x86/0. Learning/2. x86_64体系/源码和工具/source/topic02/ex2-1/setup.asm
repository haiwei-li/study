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

setup_length        dw (SETUP_END - SETUP_BEGIN)        ; SETUP_END-SETUP_BEGIN 是这个模块的 size


main:                                                   ; 这是模块代码的入口点。
        
        mov si, caller_message
        call puts                       ; printf("'Now: I am the caller, address is 0x%x", get_hex_string(current_eip));
        mov si, current_eip        
        mov di, caller_address
current_eip:        
        call get_hex_string
        mov si, caller_address                                        
        call puts
        
        mov si, 13                      ; 打印回车
        call putc
        mov si, 10                      ; 打印换行
        call putc
        
        call say_hello
        
        jmp $        


caller_message  db 'Now: I am the caller, address is 0x'
caller_address  dq 0

hello_message   db 13, 10, 'hello,world!', 13,10
                db 'This is my first assembly program...', 13, 10, 13, 10, 0
callee_message  db "Now: I'm callee - say_hello(), address is 0x"
callee_address  dq 0                                


;-------------------------------------------
; say_hello()
;-------------------------------------------
say_hello:
        mov si, hello_message
        call puts                       ; printf("hello,world\nThis is my first assembly program...");
        
        mov si, callee_message          ; printf("Now: I'm callee - say_hello(), address is 0x%x", get_hex_string(say_hello));
        call puts
        
        mov si, say_hello                                                        
        mov di, callee_address
        call get_hex_string
        
        mov si, callee_address
        call puts
        ret



;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数

FUNCTION_IMPORT_TABLE:

puts:           jmp LIB16_SEG + LIB16_PUTS * 3
putc:           jmp LIB16_SEG + LIB16_PUTC * 3
get_hex_string: jmp LIB16_SEG + LIB16_GET_HEX_STRING * 3



SETUP_END:

; end of setup        