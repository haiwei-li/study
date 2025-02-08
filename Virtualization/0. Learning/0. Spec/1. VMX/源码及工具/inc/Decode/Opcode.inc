;*************************************************
;* opcode.inc                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

%ifndef _OPCODE_INC
%define _OPCODE_INC



%define DECODE_STATUS_SUCCESS           0
%define DECODE_STATUS_FAILURE           80000000h
%define DECODE_STATUS_OUTBUFFER         80000100h
%define DECODE_STATUS_CONTINUE          40000000h


%define OPCODE_FLAG_PREFIX              80000000h


%define TARGET_CPU_LONG                 80000000h
%define TARGET_CPU_PROTECTED            40000000h
%define TARGET_CPU_REAL                 10000000h
%define TARGET_CODE64                   00008000h
%define TARGET_CODE32                   00004000h
%define TARGET_CODE16                   00002000h


%define DECODE_PREFIX_REX               80000000h
%define DECODE_PREFIX_OPS               00000001h
%define DECODE_PREFIX_ADS               00000002h
%define DECODE_PREFIX_CS                00000004h
%define DECODE_PREFIX_DS                00000008h
%define DECODE_PREFIX_ES                00000010h
%define DECODE_PREFIX_SS                00000020h
%define DECODE_PREFIX_FS                00000040h
%define DECODE_PREFIX_GS                00000080h
%define DECODE_PREFIX_REP               00000100h
%define DECODE_PREFIX_REPNZ             00000200h
%define DECODE_PREFIX_LOCK              00000400h



;-----------------------------------------------
; MAKE_OPCODE_INFO
; input:
;       %1 - opcode 
;       %2 - instruction 
; output:
;       none
; 描述：
;       1) 生成 opcode 信息，包括 opcode 与指令名
;-----------------------------------------------
%macro MAKE_OPCODE_INFO 3
OpcodeInfo%1            DD      DoOpcode%1
OpcodeFlag%1            DD      %3
InstructionMsg%1        DB      %2, 0
%endmacro



;-----------------------------------------------
; MAKE_REGISTER_INFO
; input:
;       %1 - 寄存器
; output:
;       none
; 描述：
;       1) 生成寄存器名
;-----------------------------------------------
%macro MAKE_REGISTER_INFO       1
%if %1 == al
        Register10      DB      'al', 0
%elif %1 == cl
        Register11      DB      'cl', 0
%elif %1 == dl
        Register12      DB      'dl', 0
%elif %1 == bl
        Register13      DB      'bl', 0
%elif %1 == ah
        Register14      DB      'ah', 0
%elif %1 == ch
        Register15      DB      'ch', 0
%elif %1 == dh
        Register16      DB      'dh', 0
%elif %1 == bh
        Register17      DB      'bh', 0
%elif %1 == r8b
        Register18      DB      'r8b', 0
%elif %1 == r9b
        Register19      DB      'r9b', 0
%elif %1 == r10b
        Register1A      DB      'r10b', 0
%elif %1 == r11b
        Register1B      DB      'r11b', 0
%elif %1 == r12b
        Register1C      DB      'r12b', 0
%elif %1 == r13b
        Register1D      DB      'r13b', 0
%elif %1 == r14b
        Register1E      DB      'r14b', 0
%elif %1 == r15b
        Register1F      DB      'r15b', 0
%elif %1 == spl
        Register014     DB      'spl', 0
%elif %1 == bpl
        Register015     DB      'bpl', 0
%elif %1 == sil
        Register016     DB      'sil', 0
%elif %1 == dil
        Register017     DB      'dil', 0
%elif %1 == ax
        Register20      DB      'ax', 0
%elif %1 == cx
        Register21      DB      'cx', 0
%elif %1 == dx
        Register22      DB      'dx', 0
%elif %1 == bx
        Register23      DB      'bx', 0
%elif %1 == sp
        Register24      DB      'sp', 0
%elif %1 == bp
        Register25      DB      'bp', 0
%elif %1 == si
        Register26      DB      'si', 0
%elif %1 == di
        Register27      DB      'di', 0
%elif %1 == r8w
        Register28      DB      'r8w', 0
%elif %1 == r9w
        Register29      DB      'r9w', 0
%elif %1 == r10w
        Register2A      DB      'r10w', 0
%elif %1 == r11w
        Register2B      DB      'r11w', 0
%elif %1 == r12w
        Register2C      DB      'r12w', 0
%elif %1 == r13w
        Register2D      DB      'r13w', 0
%elif %1 == r14w
        Register2E      DB      'r14w', 0
%elif %1 == r15w
        Register2F      DB      'r15w', 0
%elif %1 == eax
        Register40      DB      'eax', 0
%elif %1 == ecx
        Register41      DB      'ecx', 0
%elif %1 == edx
        Register42      DB      'edx', 0
%elif %1 == ebx
        Register43      DB      'ebx', 0
%elif %1 == esp
        Register44      DB      'esp', 0
%elif %1 == ebp
        Register45      DB      'ebp', 0
%elif %1 == esi
        Register46      DB      'esi', 0
%elif %1 == edi
        Register47      DB      'edi', 0
%elif %1 == r8d
        Register48      DB      'r8d', 0
%elif %1 == r9d
        Register49      DB      'r9d', 0
%elif %1 == r10d
        Register4A      DB      'r10d', 0
%elif %1 == r11d
        Register4B      DB      'r11d', 0
%elif %1 == r12d
        Register4C      DB      'r12d', 0
%elif %1 == r13d
        Register4D      DB      'r13d', 0
%elif %1 == r14d
        Register4E      DB      'r14d', 0
%elif %1 == r15d
        Register4F      DB      'r15d', 0
%elif %1 == rax
        Register80      DB      'rax', 0
%elif %1 == rcx
        Register81      DB      'rcx', 0
%elif %1 == rdx
        Register82      DB      'rdx', 0
%elif %1 == rbx
        Register83      DB      'rbx', 0
%elif %1 == rsp
        Register84      DB      'rsp', 0
%elif %1 == rbp
        Register85      DB      'rbp', 0
%elif %1 == rsi
        Register86      DB      'rsi', 0
%elif %1 == rdi
        Register87      DB      'rdi', 0
%elif %1 == r8
        Register88      DB      'r8', 0
%elif %1 == r9
        Register89      DB      'r9', 0
%elif %1 == r10
        Register8A      DB      'r10', 0
%elif %1 == r11
        Register8B      DB      'r11', 0
%elif %1 == r12
        Register8C      DB      'r12', 0
%elif %1 == r13
        Register8D      DB      'r13', 0
%elif %1 == r14
        Register8E      DB      'r14', 0
%elif %1 == r15
        Register8F      DB      'r15', 0
%endif
%endmacro



%endif