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
        ;; 例子 ex2-1: 列举出其中一个逻辑处理器VMX提供的能力信息
        ;;
                              
        call get_usable_processor_index                         ; 得取可用的处理器 index 值
        mov esi, eax                                            ; 目标处理器为获取的处理器
        mov edi, TargetCpuVmxCapabilities                       ; 目标代码
        mov eax, signal                                         ; signal
        call dispatch_to_processor_with_waitting                ; 调度到目标处理器执行
        
        ;;
        ;; 等待 CPU 重启
        ;;
        call wait_esc_for_reset




        
;----------------------------------------------
; TargetCpuVmxCapabilities()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 调度执行的目标代码
;----------------------------------------------
TargetCpuVmxCapabilities:
        call update_system_status                       ; 更新系统状态
        call println
                
        ;;
        ;; 打印 VMX capabilities 信息
        ;;
        call dump_vmx_capabilities  
        ret
        

signal  dd 1        