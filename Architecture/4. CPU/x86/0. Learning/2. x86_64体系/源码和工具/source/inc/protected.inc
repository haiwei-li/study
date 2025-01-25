; protected.inc
; Copyright (c) 2009-2010 mik 
; All rights reserved.


%ifndef PROTECTED_INC
%define PROTECTED_INC

;; 定义保护模式使用到的常量值


; 定义 selector 常量
code16_se                       equ     0x08
data16_sel                      equ     0x10
kernel_code32_sel               equ     0x18
kernel_data32_sel               equ     0x20
user_code32_sel                 equ	0x28
user_data32_sel                 equ     0x30
tss32_sel                       equ     0x38
call_gate_sel                   equ     0x40
conforming_sel                  equ     0x48
tss_sel                         equ     0x50
taskgate_sel                    equ     0x58
ldt_sel                         equ     0x60

;; 定义
LDT_SEGMENT                     equ     0x2
TASK_GATE                       equ     0x5
TSS32                           equ     0x9
TSS32_BUSY                      equ     0xb
CALL_GATE32                     equ     0xc
INTERRUPT_GATE32		equ     0xe
TRAP_GATE32                     equ     0xf



;; kernel数据
KERNEL_CS                       equ     kernel_code32_sel
KERNEL_SS                       equ	kernel_data32_sel
USER_CS                         equ     user_code32_sel
USER_SS                         equ     user_data32_sel


;; 定义 interrupt vector
DE_HANDLER_VECTOR               equ     0
DB_HANDLER_VECTOR               equ     1
NMI_HANDLER_VECTOR              equ     2
BP_HANDLER_VECTOR               equ     3
OF_HANDLER_VECTOR               equ     4
BR_HANDLER_VECTOR               equ     5
UD_HANDLER_VECTOR               equ     6
NM_HANDLER_VECTOR               equ     7
DF_HANDLER_VECTOR               equ     8
TS_HANDLER_VECTOR	        equ     10
NP_HANDLER_VECTOR	        equ     11
SS_HANDLER_VECTOR               equ     12
GP_HANDLER_VECTOR               equ     13
PF_HANDLER_VECTOR               equ     14
MF_HANDLER_VECTOR               equ     16
AC_HANDLER_VECTOR               equ     17
MC_HANDLER_VECTOR               equ     18
XM_HANDLER_VECTOR               equ     19
SX_HANDLER_VECTOR               equ     31


; 自定义中断服务例程向量值
SYSTEM_SERVICE_VECTOR           equ     0x40


;** 8259 中断 vector ***
PIC8259A_TIMER_VECTOR           equ     0x20
KEYBOARD_VECTOR                 equ     0x21
FPU_VECTOR                      equ     0x2d


;*** local APIC interrupt vector***
APIC_TIMER_VECTOR               equ     0x30
APIC_LINT0_VECTOR               equ     0x31
APIC_LINT1_VECTOR               equ     0x32
APIC_PERFMON_VECTOR             equ     0x33
APIC_ERROR_VECTOR               equ     0x34
APIC_THERMAL_VECTOR             equ     0x35
APIC_CMCI_VECTOR                equ     0x36


;*** 下面每 4 个logical processor 定义自已的 IPI 消息的中断向量
PROCESSOR0_IPI_VECTOR           equ     0x38
PROCESSOR1_IPI_VECTOR           equ     0x39
PROCESSOR2_IPI_VECTOR           equ     0x3a
PROCESSOR3_IPI_VECTOR           equ     0x3b
BP_IPI_VECTOR                   equ     PROCESSOR0_IPI_VECTOR


;*** 定义 IOAPIC 中断 vector
IOAPIC_IRQ0_VECTOR              equ     50h
IOAPIC_IRQ1_VECTOR              equ     51h
IOAPIC_IRQ2_VECTOR              equ     52h
IOAPIC_IRQ3_VECTOR              equ     53h
IOAPIC_IRQ4_VECTOR              equ     54h
IOAPIC_IRQ5_VECTOR              equ     55h
IOAPIC_IRQ6_VECTOR              equ     56h
IOAPIC_IRQ7_VECTOR              equ     57h
IOAPIC_IRQ8_VECTOR              equ     58h
IOAPIC_IRQ9_VECTOR              equ     59h
IOAPIC_IRQ10_VECTOR             equ     5Ah
IOAPIC_IRQ11_VECTOR             equ     5Bh
IOAPIC_IRQ12_VECTOR             equ     5Ch
IOAPIC_IRQ13_VECTOR             equ     5Dh
IOAPIC_IRQ14_VECTOR             equ     5Eh
IOAPIC_IRQ15_VECTOR             equ     5Fh
IOAPIC_IRQ16_VECTOR             equ     60h
IOAPIC_IRQ17_VECTOR             equ     61h
IOAPIC_IRQ18_VECTOR             equ     62h
IOAPIC_IRQ19_VECTOR             equ     63h
IOAPIC_IRQ20_VECTOR             equ     64h
IOAPIC_IRQ21_VECTOR             equ     65h
IOAPIC_IRQ22_VECTOR             equ     66h
IOAPIC_IRQ23_VECTOR             equ     67h



; 系统服务例程号
%define SYS_PUTS                        0
%define SYS_READ_GDT_DESCRIPTOR         1
%define SYS_WRITE_GDT_DESCRIPTOR	2


; 用户自定义服务例程号
SYSTEM_SERVICE_USER             equ     3
 SYSTEM_SERVICE_USER0           equ     SYSTEM_SERVICE_USER
SYSTEM_SERVICE_USER1            equ     (SYSTEM_SERVICE_USER0 + 1)
SYSTEM_SERVICE_USER2            equ     (SYSTEM_SERVICE_USER0 + 2)


;这个宏生成一个描述符
;3个参数: base, limit, attribute
%macro MAKE_SEGMENT_DESCRIPTOR        3
        dd        (%2 & 0x0000ffff) | ((%1 & 0x0000ffff) << 16)
        dd  ((%1 & 0x00ff0000) >> 16) | (%2 & 0x000f0000) | (%3 << 8) | (%1 & 0xff000000)
%endmacro

%endif

