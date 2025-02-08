; hpet.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;*
;* 为 High Precision Event Timer 功能所定义
;*

%ifndef HPET_INC
%define HPET_INC


;*
;* 定义高精度定时器的基址
;* 采用一对一映射方式：
;* 虚拟地址 0FED00000h 映射到物理地址 0FED00000h
;
%define HPET_BASE                       0FED00000h

;*
;* 定义 HPET 的寄存器地址
;*
%define HPET_COUNTER                    0FED000F0h

%define HPET_TIMER0_CONFIG              0FED00100h
%define HPET_TIMER1_CONFIG              0FED00120h
%define HPET_TIMER2_CONFIG              0FED00140h
%define HPET_TIMER3_CONFIG              0FED00160h
%define HPET_TIMER4_CONFIG              0FED00180h
%define HPET_TIMER5_CONFIG              0FED001A0h
%define HPET_TIMER6_CONFIG              0FED001C0h
%define HPET_TIMER7_CONFIG              0FED001E0h

%define HPET_TIMER0_COMPARATOR          0FED00108h
%define HPET_TIMER1_COMPARATOR          0FED00128h
%define HPET_TIMER2_COMPARATOR          0FED00148h
%define HPET_TIMER3_COMPARATOR          0FED00168h
%define HPET_TIMER4_COMPARATOR          0FED00188h
%define HPET_TIMER5_COMPARATOR          0FED001A8h
%define HPET_TIMER6_COMPARATOR          0FED001C8h
%define HPET_TIMER7_COMPARATOR          0FED001E8h



;-----------------------------------------------+
;  为 HPET 定义 count 值                        |
;                                               |
;  HPET 按下面的频进行计数：                    |
;       1) 1秒          = 约 14318179 次        |
;       2) 1毫秒(ms)    = 约 14318 次           |
;       3) 1微秒(us)    = 约 14 次              |
;       4) 1纳秒(ns)    = 约 0.014 次           |
;-----------------------------------------------+

%define HPET_COUNT_SECOND               14318179                ; 1 秒 count 值
%define HPET_COUNT_MILLISECOND          14318                   ; 1 毫秒 count 值
%define HPET_COUNT_MICROSECOND          14                      ; 1 微秒 count 值



;----------------------------------------------------
; 宏 START_HPET_TIMER()：开启定时器
; input:
;       %1 - timer
;       %2 - 时间单位
;       %3 - 单位值
;
; 示例：
;       START_HPET_TIMER  0, HPET_COUNT_MILLISECOND, 100
;--------------------------------------------------------
%macro START_HPET_TIMER 3
        bts DWORD [HPET_BASE + 100h + (20h * %1)], 2
        mov DWORD [HPET_BASE + 108h + (20h * %1) + 4], 0
        mov DWORD [HPET_BASE + 108h + (20h * %1)], (%2 * %3)
        mov DWORD [HPET_COUNTER + 4], 0
        mov DWORD [HPET_COUNTER], 0
%endmacro



;----------------------------------------------------
; 宏 STOP_HPET_TIMER()：关闭定时器
; input:
;       %1 - timer
;
; 示例：
;       STOP_HPET_TIMER  0
;--------------------------------------------------------
%macro STOP_HPET_TIMER 1
        btr DWORD [HPET_BASE + 100h + (20h * %1)], 2
%endmacro



;------------------------------------------
; 使用 HPET timer 1 进行延时
; 描述：使用微秒级别
;------------------------------------------
%macro DELAY_WITH_US 1
        mov esi, [HPET_TIMER1_CONFIG]
        btr DWORD [HPET_TIMER1_CONFIG], 2
        mov DWORD [HPET_TIMER1_COMPARATOR + 4], 0
        mov DWORD [HPET_TIMER1_COMPARATOR], (%1 * HPET_COUNT_MICROSECOND)
        mov DWORD [HPET_COUNTER + 4], 0
        mov DWORD [HPET_COUNTER], 0

%%1:
        mov eax, [HPET_COUNTER]
        mov edi, [HPET_TIMER1_COMPARATOR]
        cmp eax, edi
        jb %%1
        mov [HPET_TIMER1_CONFIG], esi
%endmacro

;------------------------------------------
; 使用 HPET timer 1 进行延时
; 描述：使用毫秒级别
;------------------------------------------
%macro DELAY_WITH_MS 1
        mov esi, [HPET_TIMER1_CONFIG]
        btr DWORD [HPET_TIMER1_CONFIG], 2
        mov DWORD [HPET_TIMER1_COMPARATOR + 4], 0
        mov DWORD [HPET_TIMER1_COMPARATOR], (%1 * HPET_COUNT_MILLISECOND)
        mov DWORD [HPET_COUNTER + 4], 0
        mov DWORD [HPET_COUNTER], 0

%%1:
        mov eax, [HPET_COUNTER]
        mov edi, [HPET_TIMER1_COMPARATOR]
        cmp eax, edi
        jb %%1
        mov [HPET_TIMER1_CONFIG], esi
%endmacro


%endif