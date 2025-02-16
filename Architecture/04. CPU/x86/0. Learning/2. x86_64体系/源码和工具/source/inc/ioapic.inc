; ioapic.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%ifndef IOAPIC_INC
%define IOAPIC_INC


;*
;* 定义 IOAPIC 寄存器 base 地址
;* 注: 这里使用一对一的映射
;* 虚拟地址 0FEC00000h 映射到相同的物理地址
;*
%define IOAPIC_INDEX_REG                    0FEC00000h
%define IOAPIC_DATA_REG                     0FEC00010h
%define IOAPIC_EOI_REG                      0FEC00040h


; 定义 IOAPIC 寄存器 index 值
%define IOAPIC_ID_INDEX                 0
%define IOAPIC_VER_INDEX                1

; 定义 IOAPIC 24 个 redirection table index 值

%define IRQ0_HI_INDEX                   10h
%define IRQ0_LO_INDEX                   11h
%define IRQ0_INDEX                      10h
%define IRQ1_INDEX                      12h
%define IRQ2_INDEX                      14h
%define IRQ3_INDEX                      16h
%define IRQ4_INDEX                      18h
%define IRQ5_INDEX                      1Ah
%define IRQ6_INDEX                      1Ch
%define IRQ7_INDEX                      1Eh
%define IRQ8_INDEX                      20h
%define IRQ9_INDEX                      22h
%define IRQ10_INDEX                     24h
%define IRQ11_INDEX                     26h
%define IRQ12_INDEX                     28h
%define IRQ13_INDEX                     2Ah
%define IRQ14_INDEX                     2Ch
%define IRQ15_INDEX                     2Eh
%define IRQ16_INDEX                     30h
%define IRQ17_INDEX                     32h
%define IRQ18_INDEX                     34h
%define IRQ19_INDEX                     36h
%define IRQ20_INDEX                     38h
%define IRQ21_INDEX                     3Ah
%define IRQ22_INDEX                     3Ch
%define IRQ23_INDEX                     3Eh


%endif