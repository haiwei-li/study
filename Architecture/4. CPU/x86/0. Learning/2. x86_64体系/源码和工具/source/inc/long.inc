; long.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.

%ifndef LONG_INC
%define LONG_INC

; 定义 selector 常量
code16_sel              equ     0x08
data16_sel              equ     0x10
code32_sel              equ     0x18
data32_sel              equ     0x20
kernel_code64_sel       equ     0x28
kernel_data64_sel       equ     0x30
user_code32_sel         equ     0x38
user_data32_sel         equ     0x40
user_code64_sel         equ     0x48
user_data64_sel         equ     0x50
tss64_sel               equ     0x58

call_gate_sel           equ     0x68

conforming_code_sel     equ     0x78
sysret_cs_sel           equ     0x80
data64_sel              equ     0x98
test_tss_sel            equ     0xa0
ldt_sel                 equ     0xb0

conforming_callgate_sel equ     0xc0

processor0_tss_sel      equ     tss64_sel

;*
;* 定义 processor 的 TSS selector
;*
;* 保留 8 个 TSS 描述符空间
;*
processor_tss_sel       equ     0xd0

reserved_sel            equ     0x150


;; 定义
LDT64                   equ     0x2
TSS64                   equ     0x9
TSS64_BUSY              equ     0xb
CALL_GATE64             equ     0xc
INTERRUPT_GATE64        equ     0xe
TRAP_GATE64             equ     0xf

KERNEL_CS               equ     kernel_code64_sel
KERNEL_SS               equ     kernel_data64_sel
USER_CS                 equ     user_code64_sel
USER_SS                 equ     user_data64_sel
USER_DS                 equ     data64_sel

LDT_KERNEL_CS           equ     0x08 | 4
LDT_KERNEL_SS           equ     0x10 | 4
LDT_USER32_CS           equ     0x18 | 4
LDT_USER32_SS           equ     0x20 | 4
LDT_USER_CS             equ     0x28 | 4
LDT_USER_SS             equ     0x30 | 4

;; 定义 interrupt vector
DE_HANDLER_VECTOR       equ 0
DB_HANDLER_VECTOR       equ 1
NMI_HANDLER_VECTOR      equ 2
BP_HANDLER_VECTOR       equ 3
OF_HANDLER_VECTOR       equ 4
BR_HANDLER_VECTOR       equ 5
UD_HANDLER_VECTOR       equ 6
NM_HANDLER_VECTOR       equ 7
DF_HANDLER_VECTOR       equ 8
TS_HANDLER_VECTOR       equ 10
NP_HANDLER_VECTOR       equ 11
SS_HANDLER_VECTOR       equ 12
GP_HANDLER_VECTOR       equ 13
PF_HANDLER_VECTOR       equ 14
MF_HANDLER_VECTOR       equ 16
AC_HANDLER_VECTOR       equ 17
MC_HANDLER_VECTOR       equ 18
XF_HANDLER_VECTOR       equ 19
SX_HANDLER_VECTOR       equ 31


; 自定义中断服务例程向量值
SYSTEM_SERVICE_VECTOR   equ     0x40


; timer
PIC8259A_TIMER_VECTOR   equ     0x20
; keyboard
KEYBOARD_VECTOR         equ     0x21
;; x87 FPU error 
FPU_VECTOR              equ     0x2d


; APIC interrupt vector
APIC_TIMER_VECTOR       equ     0x30
APIC_LINT0_VECTOR       equ     0x31
APIC_LINT1_VECTOR       equ     0x32
APIC_PERFMON_VECTOR     equ     0x33
APIC_ERROR_VECTOR       equ     0x34

;*** 下面每 4 个logical processor 定义自已的 IPI 消息的中断向量
PROCESSOR0_IPI_VECTOR                equ        0x38
PROCESSOR1_IPI_VECTOR                equ        0x39
PROCESSOR2_IPI_VECTOR                equ        0x3a
PROCESSOR3_IPI_VECTOR                equ        0x3b

BP_IPI_VECTOR                        equ        PROCESSOR0_IPI_VECTOR
AP_IPI_VECTOR                        equ        PROCESSOR1_IPI_VECTOR


;**** 自定义系统服务例程号 ****

SYSTEM_SERVICE_USER     equ     0
SYSTEM_SERVICE_USER0    equ     SYSTEM_SERVICE_USER
SYSTEM_SERVICE_USER1    equ     (SYSTEM_SERVICE_USER + 1)
SYSTEM_SERVICE_USER2    equ     (SYSTEM_SERVICE_USER + 2)
SYSTEM_SERVICE_USER3    equ     (SYSTEM_SERVICE_USER + 3)
SYSTEM_SERVICE_USER4    equ     (SYSTEM_SERVICE_USER + 4)
SYSTEM_SERVICE_USER5    equ     (SYSTEM_SERVICE_USER + 5)
SYSTEM_SERVICE_USER6    equ     (SYSTEM_SERVICE_USER + 6)
SYSTEM_SERVICE_USER7    equ     (SYSTEM_SERVICE_USER + 7)
SYSTEM_SERVICE_USER8    equ     (SYSTEM_SERVICE_USER + 8)
SYSTEM_SERVICE_USER9    equ     (SYSTEM_SERVICE_USER + 9)



;-----------------------------------------------
; MAKE_SEGMENT_ATTRIBUTE(): 宏组合段属性
; input:
;                %1: type, %2: DPL, %3: G,  %4: D/B
;-----------------------------------------------
%macro MAKE_SEGMENT_ATTRIBUTE 4
        mov eax, (%1 | %2 << 5 | %3 << 15 | %4 << 14 | 0x90 | 0x2000)
%endmacro


%endif
