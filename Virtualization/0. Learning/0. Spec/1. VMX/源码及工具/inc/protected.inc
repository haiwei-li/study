; protected.inc
; Copyright (c) 2009-2010 mik 
; All rights reserved.


%ifndef PROTECTED_INC
%define PROTECTED_INC

;; 定义保护模式使用到的常量值

%if 0

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


%endif




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
;3个参数：base, limit, attribute
%macro MAKE_SEGMENT_DESCRIPTOR        3
        dd        (%2 & 0x0000ffff) | ((%1 & 0x0000ffff) << 16)
        dd  ((%1 & 0x00ff0000) >> 16) | (%2 & 0x000f0000) | (%3 << 8) | (%1 & 0xff000000)
%endmacro

%endif

