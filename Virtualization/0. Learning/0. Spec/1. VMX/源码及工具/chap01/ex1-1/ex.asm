;*************************************************
; ex.asm                                         *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

;;
;; ex.asm 说明: 
;; 1) ex.asm 是实验例子的源代码文件, 它嵌入在 protected.asm 和 long.asm 文件内
;; 2) ex.asm 是通用模块, 能在 stage2 和 stage3 阶段运行
;;


        ;;
        ;; 例子 ex1-1: 这是一个空白项目的示例
        ;;
        
        mov esi, Ex.Msg1
        call puts
        mov esi, [fs: SDA.ApLongmode]
        add esi, 2
        call print_dword_decimal

        jmp  $

Ex.Msg1         db      'example 1-1: run in stage', 0        
