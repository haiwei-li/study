;************************************************
;* perfmon.inc                                  *
;* Copyright (c) 2009-2012 邓志                 *
;* All rights reserved.                         *
;*                                              *
;* 此代码用于学习和研究, 请勿用于商业用途!      *
;* 保留所有权利! 2009-2012                      *
;* 交流学习或报告 bug: mik@mouseo.com           *
;************************************************


;
; 定义 performance monitior 单元头文件 
;

%ifndef PERFMON_INC
%define PERFMON_INC



;*
;* 使用预定义监控事件, 用来监控指令执行数量
;* IA32_PERFEVTSELx 寄存器的设置为: EN=1, INT=1, USR=OS=1, umask=0, event select = c0
;*
%define UNHALTED_CORE_CYCLE_EVENT               53003Ch
%define INST_COUNT_EVENT                        5300C0h
%define UNHALTED_REFERENCE_CYCLE_EVENT          53013Ch
%define LLC_REFERENCE_EVENT                     534F2Eh
%define LLC_MISS_EVENT                          53412Eh
%define BR_INST_COUNT_EVENT                     5300C4h
%define BR_MISS_COUNT_EVENT                     5300C5h


;*
;* 定义 Westmere 架构上的 PEBS 事件
;*
%define PEBS_INST_COUNT_EVENT                   5300C0h
%define PEBS_X87_OPS_COUNT_EVENT                53FEC1h
%define PEBS_BR_MISS_COUNT_EVENT                5300C5h
%define PEBS_SIMD_INST_COUNT_EVENT              531FC7h
%define PEBS_MEM_LOAD_L1D_MISS_EVENT            5301CBh
%define EPBS_MEM_LOAD_L1D_LINE_MISS_EVENT       5302CBh
%define PEBS_MEM_LOAD_L2_MISS_EVENT             5304CBh
%define PEBS_MEM_LOAD_L2_LINE_MISS_EVENT        5308CBh
%define PEBS_MEM_LOAD_DTLB_MISS_EVENT           5310CBh


;* 定义 load latency 事件
%define PEBS_MEM_INST_COUNT_EVENT               53100Bh


;*
;* 下面定义 IA32_PERF_GLOBAL_CTRL 寄存器 enable 位
;*
%define IA32_PMC0_EN                            01h
%define IA32_PMC1_EN                            02h
%define IA32_PMC2_EN                            04h
%define IA32_PMC3_EN                            08h
%define IA32_FIXED_CTR0_EN                      01h
%define IA32_FIXED_CTR1_EN                      02h
%define IA32_FIXED_CTR2_EN                      04h


;*
;* 下面定义 IA32_PEBS_ENABLE 寄存器 enable 位
;*
%define PEBS_PMC0_EN                            01h
%define PEBS_PMC1_EN                            02h
%define PEBS_PMC2_EN                            04h
%define PEBS_PMC3_EN                            08h
%define LL_PMC0_EN                              01h
%define LL_PMC1_EN                              02h
%define LL_PMC2_EN                              04h
%define LL_PMC3_EN                              08h



;*
;* 定义宏总开关
;*

;-------------------------------------------------------
; 宏 ENABLE_COUNTER: 开启 counter enable
; input:
;       %1 - 参数1: 需要开启的 IA32_PMCx 计数器 
;       %2 - 参数2: 需要开启的 IA32_FIXED_CTRx 计数器
;
; 示例: 
;       ENABLE_COUNTER (IA32_PMC0_EN | IA32_PMC1_EN), 0
;-------------------------------------------------------
%macro ENABLE_COUNTER 2
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        or eax, %1                      ; IA32_PMCx 计数器
        or edx, %2                      ; IA32_FIXED_CTRx 计数器
        wrmsr
%endmacro


;-------------------------------------------------------
; 宏 DISABLE_COUNTER: 关闭 counter enable
; input:
;       %1 - 参数1: 需要关闭的 IA32_PMCx 计数器 
;       %2 - 参数2: 需要关闭的 IA32_FIXED_CTRx 计数器
;
; 示例: 
;       DISABLE_COUNTER (IA32_PMC0_EN | IA32_PMC1_EN), 0
;-------------------------------------------------------
%macro DISABLE_COUNTER 2
        mov ecx, IA32_PERF_GLOBAL_CTRL
        rdmsr
        and eax, (-1) ^ (%1)    ; IA32_PMCx 计数器　
        and edx, (-1) ^ (%2)    ; IA32_FIXED_CTRx 计数器
        wrmsr
%endmacro


;-----------------------------------------------------
; 宏 ENABLE_PEBS_COUNTER: 开启 counter PEBS 中断许可
; input:
;       %1 - 参数1: 需要开启的 IA32_PMCx 计数器
;       %2 - 参数2: 需要开启的 load latency 计数器许可
; 示例: 
;       ENABLE_PEBS_COUNTER (PEBS_PMC0_EN), 0
;-------------------------------------------------------
%macro ENABLE_PEBS_COUNTER 2
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        or eax, %1                      ; PEBS_PMCx_EN
        or edx, %2                      ; LL_PMCx_EN
        wrmsr
%endmacro


;-----------------------------------------------------
; 宏 DISABLE_PEBS_COUNTER: 关闭 counter PEBS 中断许可
; input:
;       %1 - 参数1: 需要关闭的 IA32_PMCx 计数器
;       %2 - 参数2: 需要关闭的 load latency 计数器许可
; 示例: 
;       DISABLE_PEBS_COUNTER (PEBS_PMC0_EN), 0
;-------------------------------------------------------
%macro DISABLE_PEBS_COUNTER 2
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        and eax, (-1) ^ (%1)
        and edx, (-1) ^ (%2)
        wrmsr
%endmacro



;-----------------------------------------
; 在全局控制器里开启所有的计数器
;-----------------------------------------
%macro ENABLE_GLOBAL_COUNTER 0
        ENABLE_COUNTER 0Fh, 07h
%endmacro


;------------------------------------------
; 关闭所有全局控制器的计数器
;------------------------------------------
%macro DISABLE_GLOBAL_COUNTER 0
        DISABLE_COUNTER 0Fh, 07h
%endmacro


%macro DISABLE_PEBS 0
        DISABLE_PEBS_COUNTER 0Fh, 0Fh
%endmacro


;*
;* 下面定义开启 IA32_PMCx 计数器宏
;*
%macro ENABLE_IA32_PMC0 0
        ENABLE_COUNTER (IA32_PMC0_EN), 0
%endmacro

%macro ENABLE_IA32_PMC1 0
        ENABLE_COUNTER (IA32_PMC1_EN), 0
%endmacro

%macro ENABLE_IA32_PMC2 0
        ENABLE_COUNTER (IA32_PMC2_EN), 0
%endmacro

%macro ENABLE_IA32_PMC3 0
        ENABLE_COUNTER (IA32_PMC3_EN), 0
%endmacro


;*
;*
;* 下面定义关闭 IA32_PMCx 计数器
;*
%macro DISABLE_IA32_PMC0 0
        DISABLE_COUNTER (IA32_PMC0_EN), 0
%endmacro

%macro DISABLE_IA32_PMC1 0
        DISABLE_COUNTER (IA32_PMC1_EN), 0
%endmacro

%macro DISABLE_IA32_PMC2 0
        DISABLE_COUNTER (IA32_PMC2_EN), 0
%endmacro

%macro DISABLE_IA32_PMC3 0
        DISABLE_COUNTER (IA32_PMC3_EN), 0
%endmacro


;*
;* 下面定义开启 IA32_FIXED_CTRx 计数器
;*
%macro ENABLE_IA32_FIXED_CTR0 0
        ;*
        ;* 先设置IA32_FIXED_CTR_CTRL寄存器
        ;*
        mov ecx, IA32_FIXED_CTR_CTRL
        rdmsr
        and eax, 0FFFFFFF0h             ; 设置 IA32_FIXED_CTR0
        or eax, 0Bh                     ; En=3(all ring levels), ANY=0, PMI=1
        wrmsr
        ENABLE_COUNTER  0, (IA32_FIXED_CTR0_EN)
%endmacro

%macro ENABLE_IA32_FIXED_CTR1 0
        mov ecx, IA32_FIXED_CTR_CTRL
        rdmsr
        and eax, 0FFFFFF0Fh             ; 设置 IA32_FIXED_CTR1
        or eax, 0B0h                    ; En=3(all ring levels), ANY=0, PMI=1
        wrmsr
        ENABLE_COUNTER 0, (IA32_FIXED_CTR1_EN)
%endmacro

%macro ENABLE_IA32_FIXED_CTR2 0
        mov ecx, IA32_FIXED_CTR_CTRL
        rdmsr
        and eax, 0FFFFF0FFh             ; 设置 IA32_FIXED_CTR2
        or eax, 0B00h                   ; En=3(all ring levels), ANY=0, PMI=1
        wrmsr
        ENABLE_COUNTER 0, (IA32_FIXED_CTR2_EN)
%endmacro


;* 
;* 下面定义关闭 IA32_FIXED_CTRx 计数器
;*
%macro DISABLE_IA32_FIXED_CTR0 0
        DISABLE_COUNTER 0, (IA32_FIXED_CTR0_EN)
%endmacro

%macro DISABLE_IA32_FIXED_CTR1 0
        DISABLE_COUNTER 0, (IA32_FIXED_CTR1_EN)
%endmacro

%macro DISABLE_IA32_FIXED_CTR2 0
        DISABLE_COUNTER 0, (IA32_FIXED_CTR2_EN)
%endmacro


;*
;* 下面定义开启 PEBS_ENABLE 宏
;*
%macro ENABLE_PEBS_PMC0 0
        ENABLE_PEBS_COUNTER (PEBS_PMC0_EN), 0
%endmacro

%macro ENABLE_PEBS_PMC1 0
        ENABLE_PEBS_COUNTER (PEBS_PMC1_EN), 0
%endmacro

%macro ENABLE_PEBS_PMC2 0
        ENABLE_PEBS_COUNTER (PEBS_PMC2_EN), 0
%endmacro

%macro ENABLE_PEBS_PMC3 0
        ENABLE_PEBS_COUNTER (PEBS_PMC3_EN), 0
%endmacro


;*
;* 开启 PEBS 并使用 load latency 机制
;*
%macro ENABLE_PEBS_WITH_LL_PMC0 0
        ENABLE_PEBS_COUNTER (PEBS_PMC0_EN), (LL_PMC0_EN)
%endmacro

%macro ENABLE_PEBS_WITH_LL_PMC1 0
        ENABLE_PEBS_COUNTER (PEBS_PMC1_EN), (LL_PMC1_EN)
%endmacro

%macro ENABLE_PEBS_WITH_LL_PMC2 0
        ENABLE_PEBS_COUNTER (PEBS_PMC2_EN), (LL_PMC2_EN)
%endmacro

%macro ENABLE_PEBS_WITH_LL_PMC3 0
        ENABLE_PEBS_COUNTER (PEBS_PMC3_EN), (LL_PMC3_EN)
%endmacro


;*
;* 关闭 PEBS
;*
%macro DISABLE_PEBS_PMC0 0
        DISABLE_PEBS_COUNTER (PEBS_PMC0_EN), 0
%endmacro

%macro DISABLE_PEBS_PMC1 0
        DISABLE_PEBS_COUNTER (PEBS_PMC1_EN), 0
%endmacro

%macro DISABLE_PEBS_PMC2 0
        DISABLE_PEBS_COUNTER (PEBS_PMC2_EN), 0
%endmacro

%macro DISABLE_PEBS_PMC3 0
        DISABLE_PEBS_COUNTER (PEBS_PMC3_EN), 0
%endmacro



;*
;* 关闭 PEBS 和 load latency 机制
;*
%macro DISABLE_PEBS_WITH_LL_PMC0 0
        DISABLE_PEBS_COUNTER (PEBS_PMC0_EN), (LL_PMC0_EN)
%endmacro

%macro DISABLE_PEBS_WITH_LL_PMC1 0
        DISABLE_PEBS_COUNTER (PEBS_PMC1_EN), (LL_PMC1_EN)
%endmacro

%macro DISABLE_PEBS_WITH_LL_PMC2 0
        DISABLE_PEBS_COUNTER (PEBS_PMC2_EN), (LL_PMC2_EN)
%endmacro

%macro DISABLE_PEBS_WITH_LL_PMC3 0
        DISABLE_PEBS_COUNTER (PEBS_PMC3_EN), (LL_PMC3_EN)
%endmacro


;-----------------------------------------------
; 宏 RESET_FIXED_PMC()
; 描述: 
;       清所有 IA32_FIXED_CTR计数器的值为 0
;-----------------------------------------------
%macro RESET_FIXED_PMC 0
        xor eax, eax
        xor edx, edx
        mov ecx, IA32_FIXED_CTR0
        wrmsr
        mov ecx, IA32_FIXED_CTR1
        wrmsr
        mov ecx, IA32_FIXED_CTR2
        wrmsr
%endmacro


;---------------------------------------------
; 宏 RESET_PMC()
; 描述:
;       清所有 IA32_PMC 计数器的值为0
;---------------------------------------------
%macro RESET_PMC 0
        xor eax, eax
        xor edx, edx
        mov ecx, IA32_PMC0
        wrmsr
        mov ecx, IA32_PMC1
        wrmsr
        mov ecx, IA32_PMC2
        wrmsr
        mov ecx, IA32_PMC3
        wrmsr
%endmacro


;########## 下面是相关 PEBS 中断 handler 处理的宏定义 ##############

;--------------------------------------------------------------
; 宏 RESET_COUNTER_OVERFLOW()
; 描述: 
;       清 IA32_PERF_GLOBAL_STATUS 寄存器所有 overflow 标志位
;-------------------------------------------------------------
%macro RESET_COUNTER_OVERFLOW 0
	mov ecx, IA32_PERF_GLOBAL_OVF_CTRL
	mov eax, 0Fh                    ; IA32_PMCx overflow
	mov edx, 07h                    ; IA32_FIXED_CTRx overflow
	wrmsr
%endmacro

;-------------------------------------------------------------
; 宏 RESET_PMI_COUNTER_OVERFLOW()
; 描述: 
;       清触发 PMI 中断的 counter overflow
;       去掉触发 PEBS 中断的 counter overflow
;-------------------------------------------------------------
%macro RESET_PMI_COUNTER_OVERFLOW 0
        mov ecx, IA32_PERF_GLOBAL_STATUS
        rdmsr
        mov esi, eax                    ; 保存 overflow status
        mov ecx, IA32_PEBS_ENABLE
        rdmsr
        and eax, esi                    ; 取 PEBS overflow status
        not eax
        and eax, esi                    ; 取 PMI overflow status
        mov ecx, IA32_PERF_GLOBAL_OVF_CTRL
        mov edx, 0
        wrmsr
%endmacro


;--------------------------------------------------------------
; 宏 RESET_PEBS_BUFFER_OVERFLOW() 
; 描述: 
;       清 IA32_PERF_GLOBAL_STATUS 寄存器的 OvfBuffer 位
;--------------------------------------------------------------
%macro RESET_PEBS_BUFFER_OVERFLOW 0
        mov ecx, IA32_PERF_GLOBAL_OVF_CTRL
        mov eax, 0
        mov edx, 40000000h              ; OvfBuffer 位
        wrmsr
%endmacro




%endif

