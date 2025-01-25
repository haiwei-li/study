; apic.inc
; Copyright (c) 2009-2012 邓志
; All rights reserved.

%ifndef APIC_INC
%define APIC_INC

;
; 定义 APIC_BASE 的 linear address
;
%define APIC_BASE					0x800000

%define APIC_ID						0x20
%define APIC_VER					0x30
%define TPR							0x80
%define APR							0x90
%define PPR							0xA0
%define EOI							0xB0
%define RRD							0xC0
%define LDR							0xD0
%define DFR							0xE0
%define SVR							0xF0
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


%define MASKED					10000h
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

%define PHYSICAL_ID                             (ASSERT | EDGE | PHYSICAL | NOSHORTHAND | FIXED)
%define LOGICAL_ID                              (ASSERT | EDGE | LOGICAL | NOSHORTHAND | FIXED)



%endif
