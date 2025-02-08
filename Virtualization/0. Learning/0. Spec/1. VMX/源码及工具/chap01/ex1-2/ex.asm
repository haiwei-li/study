;*************************************************
; ex.asm                                         *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

;;
;; ex.asm 说明：
;; 1) ex.asm 是实验例子的源代码文件，它嵌入在 protected.asm 和 long.asm 文件内
;; 2) ex.asm 是通用模块，能在 stage2 和 stage3 阶段运行
;;


        ;;
        ;; 例子 ex1-2：使用调试记录功能观察信息
        ;;
               
               
               
        ;;
        ;; 调度目标处理器执行 dump_debug_record() 函数，根据 CPU 数量来确定目标处理器！
        ;;
        mov esi, [fs: SDA.ProcessorCount]
        dec esi
        mov edi, dump_debug_record
        call dispatch_to_processor


        ;;
        ;; 输出信息
        ;;        
        mov esi, Ex.Msg1
        call puts

        
        ;;
        ;; 插入三条调试记录
        ;;
        mov ecx, 1
        DEBUG_RECORD    "debug record 1"        
        mov ecx, 2
        DEBUG_RECORD    "debug record 2"
        mov ecx, 3
        DEBUG_RECORD    "debug record 3"        
        
        jmp  $

Ex.Msg1         db      'example 1-2: test DEUBG_REOCRD', 0        