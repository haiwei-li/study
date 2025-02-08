;*************************************************
; apic.inc                                       *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%ifndef APIC_INC
%define APIC_INC

;;
;; 定义 APIC base 虚拟地址
;;
%define LAPIC_BASE                                      800000h
%define APIC_BASE_BSP                                   (1 << 8)
%define APIC_BASE_ENABLE                                (1 << 11)
%define APIC_BASE_X2APIC                                (1 << 10)


%define APIC_ID						0x20
%define APIC_VER					0x30
%define TPR                                             0x80
%define APR                                             0x90
%define PPR                                             0xA0
%define EOI                                             0xB0
%define RRD                                             0xC0
%define LDR                                             0xD0
%define DFR                                             0xE0
%define SVR                                             0xF0
%define ISR0						0x100
%define ISR1						0x110
%define ISR2						0x120
%define ISR3						0x130
%define ISR4						0x140
%define ISR5						0x150
%define ISR6						0x160
%define ISR7						0x170
%define TMR0						0x180
%define TMR1						0x190
%define TMR2						0x1A0
%define TMR3						0x1B0
%define TMR4						0x1C0
%define TMR5						0x1D0
%define TMR6						0x1E0
%define TMR7						0x1F0
%define IRR0						0x200
%define IRR1						0x210
%define IRR2						0x220
%define IRR3						0x230
%define IRR4						0x240
%define IRR5						0x250
%define IRR6						0x260
%define IRR7						0x270
%define ESR						0x280
%define ICR0						0x300
%define ICR1						0x310
%define LVT_CMCI					0x2F0
%define LVT_TIMER					0x320
%define LVT_THERMAL					0x330
%define LVT_PERFMON					0x340
%define LVT_LINT0					0x350
%define LVT_LINT1					0x360
%define LVT_ERROR					0x370
%define TIMER_ICR					0x380
%define TIMER_CCR					0x390
%define TIMER_DCR					0x3E0


%define LAPIC_ID                                        0x20
%define LAPIC_VERSION                                   0x30
%define LAPIC_VER                                       0x30
%define LAPIC_TPR                                       0x80
%define LAPIC_APR                                       0x90
%define LAPIC_PPR                                       0xA0
%define LAPIC_EOI                                       0xB0
%define LAPIC_RRD                                       0xC0
%define LAPIC_LDR                                       0xD0
%define LAPIC_DFR                                       0xE0
%define LAPIC_SVR                                       0xF0
%define LAPIC_ISR0                                      0x100
%define LAPIC_ISR1                                      0x110
%define LAPIC_ISR2                                      0x120
%define LAPIC_ISR3                                      0x130
%define LAPIC_ISR4                                      0x140
%define LAPIC_ISR5                                      0x150
%define LAPIC_ISR6                                      0x160
%define LAPIC_ISR7                                      0x170
%define LAPIC_TMR0                                      0x180
%define LAPIC_TMR1                                      0x190
%define LAPIC_TMR2                                      0x1A0
%define LAPIC_TMR3                                      0x1B0
%define LAPIC_TMR4                                      0x1C0
%define LAPIC_TMR5                                      0x1D0
%define LAPIC_TMR6                                      0x1E0
%define LAPIC_TMR7                                      0x1F0
%define LAPIC_IRR0                                      0x200
%define LAPIC_IRR1                                      0x210
%define LAPIC_IRR2                                      0x220
%define LAPIC_IRR3                                      0x230
%define LAPIC_IRR4                                      0x240
%define LAPIC_IRR5                                      0x250
%define LAPIC_IRR6                                      0x260
%define LAPIC_IRR7                                      0x270
%define LAPIC_ESR                                       0x280
%define LAPIC_ICR0                                      0x300
%define LAPIC_ICR1                                      0x310
%define LAPIC_LVT_CMCI                                  0x2F0
%define LAPIC_LVT_TIMER                                 0x320
%define LAPIC_LVT_THERMAL                               0x330
%define LAPIC_LVT_PERFMON                               0x340
%define LAPIC_LVT_LINT0                                 0x350
%define LAPIC_LVT_LINT1                                 0x360
%define LAPIC_LVT_ERROR                                 0x370
%define LAPIC_TIMER_ICR                                 0x380
%define LAPIC_TIMER_CCR                                 0x390
%define LAPIC_TIMER_DCR                                 0x3E0



; APIC timer 值定义
%define	TIMER_ONE_SHOT				00000h
%define TIMER_PERIODIC				20000h
%define TIMER_TSC				40000h

; 定义 delivery mode 值
%define FIXED                                   0000h
%define LOWEST                                  0100h
%define SMI                                     0200h
%define NMI                                     0400h
%define EXTINT                                  0700h
%define INIT                                    0500h

%define FIXED_DELIVERY				0000h
%define LOWEST_DELIVERY                         0100h
%define SMI_DELIVERY                            0200h
%define NMI_DELIVERY                            0400h
%define EXTINT_DELIVERY                         0700h
%define INIT_DELIVERY                           0500h
%define SIPI_DELIVERY                           0600h


%define LVT_MASKED				10000h
%define LOGICAL					0800h
%define PHYSICAL				0000h
%define EDGE					0000h
%define ASSERT                                  4000h
%define LEVEL					8000h
%define NOSHORTHAND				00000h
%define SELF					40000h
%define ALL_IN_SELF				80000h
%define ALL_EX_SELF				0C0000h


; IPI 消息发送模式

%define STARTUP_IPI                             000C4600H
%define INIT_IPI                                000C4500H

%define PHYSICAL_ID                             (EDGE | PHYSICAL | NOSHORTHAND | FIXED)
%define LOGICAL_ID                              (EDGE | LOGICAL | NOSHORTHAND | FIXED)


%define INT_LEVEL_THRESHOLD                     1



;;
;; 定义 lapic timer request mask 值
;;
%define LAPIC_TIMER_ONE_SHOT                    0
%define LAPIC_TIMER_PERIODIC                    1





;---------------------------------------------
; GET_LAPIC_BASE
; input:
;       none
; output:
;       eax - Lapic base
; 描述: 
;       1) 读取 lapic base 值
;---------------------------------------------
%macro GET_LAPIC_BASE   0
        mov eax, PCB.LapicBase

%if __BITS__ == 64
        ;;
        ;; 如果在 64 位下编译, 则使用 native 方式
        ;;
        mov rax, [gs: rax]
%else
        ;;
        ;; 如果在 32 位下编译, 则使用硬编码方式. 
        ;; 1) 定义了 __X64 符号则是: mov rax, [gs: rax]
        ;; 2) 否则为: mov eax, [gs: eax]
        ;;
        PREFIX_GS
        REX.Wrxb
        mov eax, [eax]
%endif
%endmacro



;---------------------------------------------
; SEND_IPI_TO_PROCESSOR
; input:
;       %1 - 目标处理器
;       %2 - 内容
; 描述: 
;       1) 给目标处理器发送 IPI
;---------------------------------------------
%macro SEND_IPI_TO_PROCESSOR 2
        GET_LAPIC_BASE

%if __BITS__ == 64
        mov DWORD [rax + ICR1], %1
        mov DWORD [rax + ICR0], %2
%else
        mov DWORD [eax + ICR1], %1
        mov DWORD [eax + ICR0], %2
%endif
%endmacro



;---------------------------------------------
; BROADCASE_MESSAGE
; input:
;       %1 - 内容
; output:
;       none
; 描述:
;       1) 广播 IPI 消息
;---------------------------------------------
%macro BROADCASE_MESSAGE        1
        GET_LAPIC_BASE

%if __BITS__ == 64
        mov DWORD [rax + ICR0], %1
%else
        mov DWORD [eax + ICR0], %1
%endif

%endmacro



;---------------------------------------------
; BROADCASE_MESSAGE_EXCLUDE_SELF
; input:
;       none
; output:
;       none
; 描述:
;       1) 广播 IPI 消息, 不包括自己        
;---------------------------------------------
%macro BROADCASE_MESSAGE_EXCLUDE_SELF   0
        GET_LAPIC_BASE

%if __BITS__ == 64
        mov DWORD [rax + ICR0], ALL_EX_SELF | FIXED_DELIVERY | IPI_VECTOR
%else
        mov DWORD [eax + ICR0], ALL_EX_SELF | FIXED_DELIVERY | IPI_VECTOR
%endif

%endmacro


;---------------------------------------------
; BROADCASE_MESSAGE_INCLUDE_SELF
; input:
;       none
; output:
;       none
; 描述:
;       1) 广播 IPI 消息, 包括自己        
;---------------------------------------------
%macro BROADCASE_MESSAGE_INCLUDE_SELF   0
        GET_LAPIC_BASE

%if __BITS__ == 64
        mov DWORD [rax + ICR0], ALL_IN_SELF | FIXED_DELIVERY | IPI_VECTOR
%else
        mov DWORD [eax + ICR0], ALL_IN_SELF | FIXED_DELIVERY | IPI_VECTOR
%endif

%endmacro




;---------------------------------------------
; LAPIC_EOI_COMMAND
; input:
;       none
; output:
;       none
; 描述: 
;       1) 发送 EOI 命令
;---------------------------------------------
%macro LAPIC_EOI_COMMAND 0
        GET_LAPIC_BASE

%if __BITS__ == 64
        mov DWORD [rax + EOI], 0
%else
        mov DWORD [eax + EOI], 0
%endif
%endmacro





%endif
