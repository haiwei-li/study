; debug.inc
; Copyright (c) 2009-2012 邓志
; All rights reserved.

%ifndef DEBUG_INC
%define DEBUG_INC


%define	LBR_BIT					0
%define	BTF_BIT					1
%define TR_BIT					6
%define BTS_BIT					7
%define BTINT_BIT				8


;; 定义 IA32_DEBUGCTL 寄存器的功能位位
%define LBR                             01h
%define BTF                             02h
%define TR                              40h
%define BTS                             80h
%define BTINT                           100h
%define BTS_OFF_OS                      200h
%define BTS_OFF_USR                     400h
%define FREEZE_LBRS_ON_PMI              800h
%define FREEZE_PERFMON_ON_PMI           1000h
%define UNCORE_PMI_EN                   2000h
%define FREEZE_WHILE_SMM_EN             4000h


;*
;* 定义 DS save 区域基地址
;* 缺省情况下是使用 400000h 区域
;*
%define DS_SAVE_BASE			0x400000
%define BTS_BUFFER_BASE			0x400100
%define PEBS_BUFFER_BASE		0x400400

;* 
;* 定义 BTS 与 PEBS 最大记录数(maximum 与 threshold值)
;* 缺省情况下, 最多可容纳 10 条记录
;*
%define BTS_RECORD_MAXIMUM			10
%define BTS_RECORD_INT_THRESHOLD		(BTS_RECORD_MAXIMUM)
%define BTS_RECORD_CIRCULAR_THRESHOLD		(BTS_RECORD_MAXIMUM + 1)
%define PEBS_RECORD_MAXIMUM			10
%define PEBS_RECORD_THRESHOLD			(PEBS_RECORD_MAXIMUM)


;* 
;* 定义 32 位格式下的记录 size
;* 
%define BTS_RECORD_SIZE                 12
%define PEBS_RECORD_SIZE                40

;*
;* 定义 64 位格式下的记录 size
;*
%define BTS_RECORD64_SIZE               24
%define PEBS_RECORD64_SIZE              144

;*
;* 定义增强格式下的 PEBS 记录 size
;*
%define PEBS_ENHANCEMENT_RECORD64_SIZE  176



;*
;* 定义 32 位格式的 BTS 管理区记录 offset 位置
;*
%define	BTS_BASE                        0
%define BTS_INDEX                       4
%define BTS_MAXIMUM                     8
%define BTS_THRESHOLD                   0CH

;*
;* 定义 64 位格式 BTS 管理区
;*
%define	BTS64_BASE                      0
%define BTS64_INDEX                     8
%define BTS64_MAXIMUM                   10H
%define BTS64_THRESHOLD                 18H

;*
;* 定义 32 位格式的 PEBS 管理区记录 offset 位置
;*
%define PEBS_BASE                       10H
%define PEBS_INDEX                      14H
%define PEBS_MAXIMUM                    18H
%define PEBS_THRESHOLD                  1CH
%define PEBS_COUNTER0                   20H
%define PEBS_COUNTER1                   24H
%define PEBS_COUNTER2                   28H
%define PEBS_COUNTER3                   2CH

;*
;* 定义 64 位格式的 PEBS 管理区
;*
%define PEBS64_BASE                     20H
%define PEBS64_INDEX                    28H
%define PEBS64_MAXIMUM                  30H
%define PEBS64_THRESHOLD                38H
%define PEBS64_COUNTER0                 40H
%define PEBS64_COUNTER1                 48H
%define PEBS64_COUNTER2                 50H
%define PEBS64_COUNTER3                 58H



;-----------------------------------------------------------
; ENABLE_DEBUGCTL 宏: 开启 IA32_DEBUGCTL 寄存器的功能
; input:
;       参数是功能位
; 示例:
;       ENABLE_DEBUGCTL (TR | BTS | BTINT): 开启 BTS 与 BTINT 功能
;------------------------------------------------------------
%macro ENABLE_DEBUGCTL 1
        mov ecx, IA32_DEBUGCTL
        rdmsr
        or eax, %1              ; 参数值
        wrmsr
%endmacro


;-------------------------------------------------------------
; DISABLE_DEBUGCTL 宏: 关闭 IA32_DEBUGCTL 功能
; input:
;       参数是功能位
; 示例:
;       DISABLE_DEBUGCTL (TR | BTINT): 关闭 TR 与 BTINT 功能
;-------------------------------------------------------------
%macro DISABLE_DEBUGCTL 1
        mov ecx, IA32_DEBUGCTL
        rdmsr
        and eax, (0FFFFFFFFh) ^ (%1)
        wrmsr
%endmacro



;-----------------------------------------
; ENABLE_LBR() 宏: 开启 LBR
;-----------------------------------------
%macro ENABLE_LBR 0
        ENABLE_DEBUGCTL (LBR)
%endmacro


;-----------------------------------
; ENABLE_BTS() 宏: 开启 bts, 环状回路 
;-----------------------------------
%macro ENABLE_BTS 0
        ENABLE_DEBUGCTL (TR | BTS)	
%endmacro

;-------------------------------------------------
; ENABLE_BTS_FREEZE_PERFMON_ON_PMI 宏
; 描述:
;       开启 BTS 并使用 freeze_perfmon_on_pmi 功能
;--------------------------------------------------
%macro ENABLE_BTS_FREEZE_PERFMON_ON_PMI 0
        ENABLE_DEBUGCTL (TR | BTS | FREEZE_PERFMON_ON_PMI)
%endmacro


;--------------------------------------------
; ENABLE_BTS_BTINT() 宏: 开启 bts, 并且使用 BTINT
;--------------------------------------------
%macro ENABLE_BTS_BTINT 0
        ENABLE_DEBUGCTL (TR | BTS | BTINT)
%endmacro


;--------------------------------------------
; ENABLE_BTS_BTINT_FREEZE_PERFMON_ON_PMI
;--------------------------------------------
%macro ENABLE_BTS_BTINT_FREEZE_PERFMON_ON_PMI 0
        ENABLE_DEBUGCTL (TR | BTS | BTINT | FREEZE_PERFMON_ON_PMI)
%endmacro


;-----------------------------------------
; DISABLE_LBR() 宏: 关闭 LBR
;-----------------------------------------
%macro DISABLE_LBR 0
        DISABLE_DEBUGCTL (LBR)
%endmacro


;-------------------------------－－－－－－－－------------
; DISABLE_TR(): 如果 TR 是开启就关闭 TR, 同时 BTS 功能也无效
;----------------------------------------------------------
%macro DISABLE_TR 0
	mov ecx, IA32_DEBUGCTL
	rdmsr
	bt eax, 6			; TR 位
	mov edi, eax,
	mov esi, 0FFBFh			; TR = 0
	cmovc edi, esi
	and eax, edi
	wrmsr
%endmacro



;--------------------------
; DISABLE_BTS() 宏: 关闭 bts
;---------------------------
%macro DISABLE_BTS 0
        DISABLE_DEBUGCTL (TR | BTS)
%endmacro


;--------------------------------------------
; BIDSABLE_BTS_FREEZE_PERFMON_ON_PMI
;--------------------------------------------
%macro DISABLE_BTS_FREEZE_PERFMON_ON_PMI 0
        DISABLE_DEBUGCTL (TR | BTS | FREEZE_PERFMON_ON_PMI)
%endmacro

;--------------------------------------------
; DISABLE_BTS_BTINT() 宏: 关闭 bts
;--------------------------------------------
%macro DISABLE_BTS_BTINT 0
        DISABLE_DEBUGCTL (TR | BTS | BTINT)
%endmacro


;--------------------------------------------
; DISABLE_BTS_BTINT_FREEZE_PERFMON_ON_PMI
;--------------------------------------------
%macro DISABLE_BTS_BTINT_FREEZE_PERFMON_ON_PMI 0
        DISABLE_DEBUGCTL (TR | BTS | BTINT | FREEZE_PERFMON_ON_PMI)
%endmacro


;------------------------------------------
; 宏 SET_DS_MANAGEMENT() 用来设置 DS 管理区
;------------------------------------------
%macro SET_DS_MANAGEMENT 0
	mov esi, BTS_BUFFER_BASE		; BTS buffer 基址
	mov edi, PEBS_BUFFER_BASE		; PEBS buffer 基址
	call set_ds_management_record
%endmacro


;---------------------------------------------------
; 宏 SET_DS_AREA() 
; 描述: 
;	用来设置完整的 DS 区域(环形回路 buffer 类型)
;----------------------------------------------------
%macro SET_DS_AREA 0
	;;; 设置 IA32_DS_AERA 寄存器
	call set_debug_store_area	

	;;; 设置 DS 管理区域
	SET_DS_MANAGEMENT
%endmacro


;------------------------------------------------
; 宏 SET_INT_DS_AREA()
; 描述: 
;	用来设置当 buffer 满时产生 DS buffer 中断
;------------------------------------------------
%macro SET_INT_DS_AREA 0
	SET_DS_AREA				; 先设置为环形回路 buffer 类型

	; 接下来设置 threshold 值等于 maximum 值
	; 来达到 buffer 满时产生 DS 中断
	mov esi, [bts_maximum_pointer]		; 读 BTS maximum 地址
	mov esi, [esi]				; 读 BTS maximum 值
	mov edi, [bts_threshold_pointer]	; 读 BTS threshold 地址
	mov [edi], esi				; 设 BTS threshold 等于 BTS maximum 值
%endmacro




;---------------------------------------------------
; 宏 SET_DS_AREA64() 
; 描述: 
;	用来设置完整的 DS 区域(环形回路 buffer 类型)
;----------------------------------------------------
%macro SET_DS_AREA64 0
	;;; 设置 IA32_DS_AERA 寄存器
	call set_debug_store_area	

	;;; 设置 DS 管理区域
	mov rsi, BTS_BUFFER_BASE
	mov rdi, PEBS_BUFFER_BASE
	call set_ds_management_record
%endmacro

;------------------------------------------------
; 宏 SET_INT_DS_AREA64()
; 描述: 
;	用来设置当 buffer 满时产生 DS buffer 中断
;------------------------------------------------
%macro SET_INT_DS_AREA64 0
	SET_DS_AREA64				; 先设置为环形回路 buffer 类型

	; 接下来设置 threshold 值等于 maximum 值
	; 来达到 buffer 满时产生 DS 中断
	mov rsi, [bts_maximum_pointer]		; 读 BTS maximum 地址
	mov rsi, [rsi]				; 读 BTS maximum 值
	mov rdi, [bts_threshold_pointer]	; 读 BTS threshold 地址
	mov [rdi], rsi				; 设 BTS threshold 等于 BTS maximum 值
%endmacro


;------------------------------------------------------------
; 宏 DUMP_DS_MANAGEMENT() 用来打印 BTS 管理区
; 使用这个宏先关闭 BTS 避免记录 dump_ds_managment()函数分支
;------------------------------------------------------------
%macro DUMP_DS_MANAGEMENT 0
	mov ecx, IA32_DEBUGCTL
	rdmsr
	mov esi, 0FF3Fh			; BTS=0, TR=0
	mov edi, eax
	push eax
	bt eax, 7			; 测试 BTS 位
	cmovc edi, esi
	and eax, edi
	wrmsr
	call dump_ds_management
	; 恢复原设置
	pop eax
	mov edx, 0
	mov ecx, IA32_DEBUGCTL
	wrmsr
%endmacro

;------------------------------------------------------------
; 宏 DUMP_BTS_RECORD() 用来打印 BTS buffer 记录
; 使用这个宏先关闭 BTS 避免记录 dump_bts_record() 函数分支
;------------------------------------------------------------
%macro DUMP_BTS_RECORD 0
	mov ecx, IA32_DEBUGCTL
	rdmsr
	mov esi, 0FF3Fh			; BTS=0, TR=0
	mov edi, eax
	push eax
	bt eax, 7			; 测试 BTS 位
	cmovc edi, esi
	and eax, edi
	wrmsr
	call dump_bts_record
	; 恢复原设置
	pop eax
	mov edx, 0
	mov ecx, IA32_DEBUGCTL
	wrmsr
%endmacro

;------------------------------------------------------------
; 宏 DUMP_BTS() 用来打印 DS 管理区与 BTS buffer 记录
; 使用这个宏先关闭 BTS 避免记录函数分支
;------------------------------------------------------------
%macro DUMP_BTS 0
	mov ecx, IA32_DEBUGCTL
	rdmsr
	mov esi, 0FF3Fh			; BTS=0, TR=0
	mov edi, eax
	push eax
	bt eax, 7			; 测试 BTS 位, BTS 机制是否开启
	cmovc edi, esi			; 如果开启就关闭它
	and eax, edi
	wrmsr
	call dump_ds_management
	call dump_bts_record
	; 恢复原设置
	pop eax
	mov edx, 0
	mov ecx, IA32_DEBUGCTL
	wrmsr
%endmacro

;------------------------------------------------------------
; 宏 DUMP_BTS64() 用来打印 DS 管理区与 BTS buffer 记录
;------------------------------------------------------------
%macro DUMP_BTS64 0
	call dump_ds_management
	call dump_bts_record
%endmacro


;------------------------------------------------------------
; 宏 DUMP_PEBS() 用来打印 PEBS 管理区与 buffer 记录
; 使用这个宏先关闭 BTS 避免记录函数分支
;------------------------------------------------------------
%macro DUMP_PEBS 0
	mov ecx, IA32_DEBUGCTL
	rdmsr
	mov esi, 0FF3Fh			; BTS=0, TR=0
	mov edi, eax
	push eax
	bt eax, 7			; 测试 BTS 位
	cmovc edi, esi
	and eax, edi
	wrmsr
	call dump_ds_management
	call dump_pebs_record
	; 恢复原设置
	pop eax
	mov edx, 0
	mov ecx, IA32_DEBUGCTL
	wrmsr
%endmacro

%endif