; demo.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 实验2-1:
; 建立一个 1.44M 的 floppy 映像文件，名为：demo.img
;
; 生成命令：nasm demo.asm -o demo.img




;
; 用 0 填满 1.44M floppy 的空间

times 0x168000-($-$$) db 0