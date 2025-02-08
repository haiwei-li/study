;*************************************************
; services.inc                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

%ifndef _SERVICE_INC
%define _SERVICE_INC

;;
;; 定义异常处理程序的 vector
;;
DE_HANDLER_VECTOR               EQU     0
DB_HANDLER_VECTOR               EQU     1
NMI_HANDLER_VECTOR              EQU     2
BP_HANDLER_VECTOR               EQU     3
OF_HANDLER_VECTOR               EQU     4
BR_HANDLER_VECTOR               EQU     5
UD_HANDLER_VECTOR               EQU     6
NM_HANDLER_VECTOR               EQU     7
DF_HANDLER_VECTOR               EQU     8
TS_HANDLER_VECTOR	        EQU     10
NP_HANDLER_VECTOR	        EQU     11
SS_HANDLER_VECTOR               EQU     12
GP_HANDLER_VECTOR               EQU     13
PF_HANDLER_VECTOR               EQU     14
MF_HANDLER_VECTOR               EQU     16
AC_HANDLER_VECTOR               EQU     17
MC_HANDLER_VECTOR               EQU     18
XM_HANDLER_VECTOR               EQU     19
SX_HANDLER_VECTOR               EQU     31

DE_VECTOR                       EQU     0
DB_VECTOR                       EQU     1
NMI_VECTOR                      EQU     2
BP_VECTOR                       EQU     3
OF_VECTOR                       EQU     4
BR_VECTOR                       EQU     5
UD_VECTOR                       EQU     6
NM_VECTOR                       EQU     7
DF_VECTOR                       EQU     8
TS_VECTOR	                EQU     10
NP_VECTOR	                EQU     11
SS_VECTOR                       EQU     12
GP_VECTOR                       EQU     13
PF_VECTOR                       EQU     14
MF_VECTOR                       EQU     16
AC_VECTOR                       EQU     17
MC_VECTOR                       EQU     18
XM_VECTOR                       EQU     19
SX_VECTOR                       EQU     31


;;
;; 8259 中断向量
;;
PIC8259A_IRQ0_VECTOR            EQU     20h
PIC8259A_IRQ1_VECTOR            EQU     (PIC8259A_IRQ0_VECTOR + 1)
PIC8259A_IRQ13_VECTOR           EQU     (PIC8259A_IRQ0_VECTOR + 13)



;;
;; Local APIC 中断服务例程向量
;;

LAPIC_TIMER_VECTOR              EQU     50h
LAPIC_LINT0_VECTOR              EQU     51h
LAPIC_LINT1_VECTOR              EQU     52h
LAPIC_PERFMON_VECTOR            EQU     53h
LAPIC_ERROR_VECTOR              EQU     54h
LAPIC_THERMAL_VECTOR            EQU     55h
LAPIC_CMCI_VECTOR               EQU     56h


;;
;; IPI 例程向量
;;
IPI_VECTOR                      EQU     0E0h
IPI_ENTRY_VECTOR                EQU     0E1h


;;
;; 定义 IOAPIC 中断 vector
;;
IOAPIC_IRQ0_VECTOR              equ     30h
IOAPIC_IRQ1_VECTOR              equ     31h
IOAPIC_IRQ2_VECTOR              equ     32h
IOAPIC_IRQ3_VECTOR              equ     33h
IOAPIC_IRQ4_VECTOR              equ     34h
IOAPIC_IRQ5_VECTOR              equ     35h
IOAPIC_IRQ6_VECTOR              equ     36h
IOAPIC_IRQ7_VECTOR              equ     37h
IOAPIC_IRQ8_VECTOR              equ     38h
IOAPIC_IRQ9_VECTOR              equ     39h
IOAPIC_IRQ10_VECTOR             equ     3Ah
IOAPIC_IRQ11_VECTOR             equ     3Bh
IOAPIC_IRQ12_VECTOR             equ     3Ch
IOAPIC_IRQ13_VECTOR             equ     3Dh
IOAPIC_IRQ14_VECTOR             equ     3Eh
IOAPIC_IRQ15_VECTOR             equ     3Fh
IOAPIC_IRQ16_VECTOR             equ     40h
IOAPIC_IRQ17_VECTOR             equ     41h
IOAPIC_IRQ18_VECTOR             equ     42h
IOAPIC_IRQ19_VECTOR             equ     43h
IOAPIC_IRQ20_VECTOR             equ     44h
IOAPIC_IRQ21_VECTOR             equ     45h
IOAPIC_IRQ22_VECTOR             equ     46h
IOAPIC_IRQ23_VECTOR             equ     47h


;;
;; 系统服务例程向量
;;
SYSTEM_SERVICE_VECTOR           EQU     48h
SYS_SERVICE_CALL                EQU     48h


;;
;; 系统服务例程号
;;
SYS_CALL_0                      EQU     0
READ_SDA_DATA                   EQU     SYS_CALL_0
WRITE_SDA_DATA                  EQU     (READ_SDA_DATA + 1)
READ_PCB_DATA                   EQU     (WRITE_SDA_DATA + 1)
WRITE_PCB_DATA                  EQU     (READ_PCB_DATA + 1)
READ_SYS_DATA                   EQU     (WRITE_PCB_DATA + 1)
WRITE_SYS_DATA                  EQU     (READ_SYS_DATA + 1)
CRT_PUTC                        EQU     (WRITE_SYS_DATA + 1)
CRT_PUTS                        EQU     (CRT_PUTC + 1)


;;
;; 定义 NMI 中断例程功能号
;;

%define NMI_HARDWARE_REQUEST            0
%define NMI_IPI_REQUEST                 1





;;
;; 保存  context 信息
;;

%macro STORE_CONTEXT 0

%if __BITS__ == 64
        ;;
        ;; 在 64 位下编译
        ;;
        mov [gs: PCB.Rax], rax
        mov [gs: PCB.Rcx], rcx
        mov [gs: PCB.Rdx], rdx
        mov [gs: PCB.Rbx], rbx
        mov [gs: PCB.Rsp], rsp
        mov [gs: PCB.Rbp], rbp
        mov [gs: PCB.Rsi], rsi
        mov [gs: PCB.Rdi], rdi
        mov [gs: PCB.R8], r8
        mov [gs: PCB.R9], r9
        mov [gs: PCB.R10], r10
        mov [gs: PCB.R11], r11
        mov [gs: PCB.R12], r12
        mov [gs: PCB.R13], r13
        mov [gs: PCB.R14], r14
        mov [gs: PCB.R15], r15
%else
        ;;
        ;; 在 32 位下编译
        ;;
        %ifdef __X64
                StoreToPcb        PCB.Rax, rax
                StoreToPcb        PCB.Rcx, rcx
                StoreToPcb        PCB.Rdx, rdx
                StoreToPcb        PCB.Rbx, rbx
                StoreToPcb        PCB.Rsp, rsp
                StoreToPcb        PCB.Rbp, rbp
                StoreToPcb        PCB.Rsi, rsi
                StoreToPcb        PCB.Rdi, rdi
                StoreToPcb        PCB.R8, r8
                StoreToPcb        PCB.R9, r9
                StoreToPcb        PCB.R10, r10
                StoreToPcb        PCB.R11, r11
                StoreToPcb        PCB.R12, r12
                StoreToPcb        PCB.R13, r13
                StoreToPcb        PCB.R14, r14
                StoreToPcb        PCB.R15, r15
        %else
                StoreToPcb        PCB.Eax, eax
                StoreToPcb        PCB.Ecx, ecx
                StoreToPcb        PCB.Edx, edx
                StoreToPcb        PCB.Ebx, ebx
                StoreToPcb        PCB.Esp, esp
                StoreToPcb        PCB.Ebp, ebp
                StoreToPcb        PCB.Esi, esi
                StoreToPcb        PCB.Edi, edi 
        %endif
%endif
%endmacro



;;
;; 恢复 context 信息
;;

%macro RESTORE_CONTEXT 0

%if __BITS__ == 64
        ;;
        ;; 在 64 位下编译
        ;;
        mov rax, [gs: PCB.Rax]
        mov rcx, [gs: PCB.Rcx]
        mov rdx, [gs: PCB.Rdx]
        mov rbx, [gs: PCB.Rbx]
        mov rbp, [gs: PCB.Rbp]
        mov rsi, [gs: PCB.Rsi]
        mov rdi, [gs: PCB.Rdi]
        mov r8, [gs: PCB.R8]
        mov r9, [gs: PCB.R9]
        mov r10, [gs: PCB.R10]
        mov r11, [gs: PCB.R11]
        mov r12, [gs: PCB.R12]
        mov r13, [gs: PCB.R13]
        mov r14, [gs: PCB.R14]
        mov r15, [gs: PCB.R15]
%else
        ;;
        ;; 在 32 位下编译
        ;;
        %ifdef __X64
                LoadFromPcb     rax, PCB.Rax
                LoadFromPcb     rcx, PCB.Rcx
                LoadFromPcb     rdx, PCB.Rdx
                LoadFromPcb     rbx, PCB.Rbx
                LoadFromPcb     rsp, PCB.Rsp
                LoadFromPcb     rbp, PCB.Rbp
                LoadFromPcb     rsi, PCB.Rsi
                LoadFromPcb     rdi, PCB.Rdi
                LoadFromPcb     r8, PCB.R8
                LoadFromPcb     r9, PCB.R9
                LoadFromPcb     r10, PCB.R10
                LoadFromPcb     r11, PCB.R11
                LoadFromPcb     r12, PCB.R12
                LoadFromPcb     r13, PCB.R13
                LoadFromPcb     r14, PCB.R14
                LoadFromPcb     r15, PCB.R15
        %else
                LoadFromPcb     eax, PCB.Eax
                LoadFromPcb     ecx, PCB.Ecx
                LoadFromPcb     edx, PCB.Edx
                LoadFromPcb     ebx, PCB.Ebx
                LoadFromPcb     esp, PCB.Esp
                LoadFromPcb     ebp, PCB.Ebp
                LoadFromPcb     esi, PCB.Esi
                LoadFromPcb     edi, PCB.Edi
        %endif
%endif
%endmacro



;-----------------------------------------------------
; PUSHA64()
; 描述：
;       1) 在 64 位下实现 pusha 指令功能
;-----------------------------------------------------
%macro pusha64 0
%if __BITS__ == 64
        ;;
        ;; 在 64 位下编译 
        ;;
        mov [rsp - 8], rax
        mov [rsp - 16], rcx
        mov [rsp - 24], rdx
        mov [rsp - 32], rbx
        mov [rsp - 40], rsp
        mov [rsp - 48], rbp
        mov [rsp - 56], rsi
        mov [rsp - 64], rdi
        mov [rsp - 72], r8
        mov [rsp - 80], r9
        mov [rsp - 88], r10
        mov [rsp - 96], r11
        mov [rsp - 104], r12
        mov [rsp - 112], r13
        mov [rsp - 120], r14
        mov [rsp - 128], r15
        sub rsp, 128
%else
        ;;
        ;; 在 32 位下编译
        ;;
%ifdef __X64
        REX.Wrxb
        mov [esp - 8], eax
        REX.Wrxb        
        mov [esp - 16], ecx
        REX.Wrxb
        mov [esp - 24], edx
        REX.Wrxb
        mov [esp - 32], ebx
        REX.Wrxb
        mov [esp - 40], esp
        REX.Wrxb
        mov [esp - 48], ebp
        REX.Wrxb
        mov [esp - 56], esi
        REX.Wrxb
        mov [esp - 64], edi

        ;;
        ;; 下面保存 r8 - r15
        ;;
        REX.WRxb
        mov [esp - 72], eax
        REX.WRxb
        mov [esp - 80], ebx
        REX.WRxb
        mov [esp - 88], ecx
        REX.WRxb
        mov [esp - 96], edx
        REX.WRxb
        mov [esp - 104], esp
        REX.WRxb
        mov [esp - 112], ebp
        REX.WRxb
        mov [esp - 120], esi
        REX.WRxb
        mov [esp - 128], edi        
        REX.Wrxb
        sub esp, 128
%endif

%endif
%endmacro




;-----------------------------------------------------
; POPA64()
; 描述：
;       1) 在 64 位下实现 popa 指令功能
;-----------------------------------------------------
%macro popa64 0
%if __BITS__ == 64
        mov rax, [rsp + 120]
        mov rcx, [rsp + 112]
        mov rdx, [rsp + 104]
        mov rbx, [rsp + 96]
        ;;mov rsp, [rsp + 88]
        mov rbp, [rsp + 80]
        mov rsi, [rsp + 72]
        mov rdi, [rsp + 64]
        mov r8, [rsp + 56]
        mov r9, [rsp + 48]
        mov r10, [rsp + 40]
        mov r11, [rsp + 36]
        mov r12, [rsp + 24]
        mov r13, [rsp + 16]
        mov r14, [rsp + 8]
        mov r15, [rsp]
        add rsp, 128
%else
%ifdef __X64
        REX.Wrxb
        mov eax, [esp + 120]
        REX.Wrxb
        mov ecx, [esp + 112]
        REX.Wrxb
        mov edx, [esp + 104]
        REX.Wrxb
        mov ebx, [esp + 96]
        REX.Wrxb
        mov ebp, [esp + 80]
        REX.Wrxb
        mov esi, [esp + 72]
        REX.Wrxb
        mov edi, [esp + 64]    

        ;;
        ;; 下面恢复 r8 - r15
        ;;
        REX.WRxb
        mov eax, [esp + 56]
        REX.WRxb
        mov ecx, [esp + 48]
        REX.WRxb
        mov edx, [esp + 40]
        REX.WRxb
        mov ebx, [esp + 36]
        REX.WRxb
        mov esp, [esp + 24]
        REX.WRxb
        mov ebp, [esp + 16]
        REX.WRxb
        mov esi, [esp + 8]
        REX.WRxb
        mov edi, [esp]
        REX.Wrxb
        add esp, 128
%endif
%endif
%endmacro


%define TRAP_GATE               100h
%define INTERRUPT_GATE          0


;-----------------------------------------------------
; EXCEPTION_ENTRY
; input:
;       %1 - handler
;       %2 - TRAP_GATE or INTERRUPT_GATE
;       %3 - DPL
; output:
;       none
; 描述：
;       1) 定义 IDT 表项
;       2) 符号　EXCEPTION_ENTRY_LENGTH 指示长度
;-----------------------------------------------------
%macro EXCEPTION_ENTRY 3
        ;;
        ;; 在 stage1 下是 8 字节
        ;;
%ifdef STAGE1_EXCEPTION_HANDLER
        DD      (KernelCsSelector32 << 16) | (%1 & 0FFFFh)
        DD      (%1 & 0FFFF0000h) | %2 | 8E00h | (%3 << 13)
        
        ;;
        ;; 在 stage3 下是 16 字节
        ;;
%elif __X64
        DD      (KernelCsSelector64 << 16) | (%1 & 0FFFFh)
        DD      (%1 & 0FFFF0000h) | %2 | 8E00h | (%3 << 13)
        DD      (%1 >> 32)
        DD      0
%else
        ;;
        ;; 在 stage2 下是 8 字节
        ;; 
        DD      (KernelCsSelector32 << 16) | (%1 & 0FFFFh)
        DD      (%1 & 0FFFF0000h) | %2 | 8E00h | (%3 << 13)
%endif

%endmacro




%endif