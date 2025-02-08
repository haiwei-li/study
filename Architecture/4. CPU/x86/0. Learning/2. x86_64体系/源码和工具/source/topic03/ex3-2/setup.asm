; boot.asm
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


message db 'the message from setup module at sector 20...', 13, 10, 0

        
times 512-($-$$) db 0


SETUP_END:

; end of setup        