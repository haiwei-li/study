;*************************************************
; Guest.inc                                      *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

%ifndef _GUEST_INC
%define _GUEST_INC

%include "..\inc\support.inc"

GUEST_BOOT_ENTRY                EQU     7C00h                   ;; GuestBoot 模块入口在 7C00h 处
GUEST_KERNEL_ENTRY              EQU     20000h                  ;; GuestKernel 模块入口在 20000h 处


;;
;; Guest 模块常量
;;

GuestKernelCs64                 EQU     08h
GuestKernelSs64                 EQU     10h
GuestUserCs32                   EQU     18h
GuestUserSs32                   EQU     20h
GuestUserCs64                   EQU     28h
GuestUserSs64                   EQU     30h
GuestKernelCs32                 EQU     38h
GuestKernelSs32                 EQU     40h
GuestKernelTss                  EQU     48h

GuestReservedSel0               EQU     50h
GuestReservedSel1               EQU     (GuestReservedSel0 + 8)
GuestReservedSel2               EQU     (GuestReservedSel1 + 8)
GuestReservedSel3               EQU     (GuestReservedSel2 + 8)



%ifdef GUEST_X64

;;
;; 在 long mode 模式下
;;
GUEST_POOL_PHYSICAL_BASE        EQU     201000h                 ;; pool 物理基址在 201000h
GUEST_PML4T_BASE                EQU     200000h                 ;; PML4T 基址


PML4T_BASE                      EQU     0FFFF8000C0200000h
POOL_BASE                       EQU     0FFFF8000C0201000h
GUEST_APIC_BASE                 EQU     0FFFF800081000000h      ;; local APIC 线性地址


%else

;;
;; 在 legacy 模式下
;;
GUEST_POOL_PHYSICAL_BASE        EQU     204000h                 ;; pool 物理基址在 204000h
GUEST_PDT0_BASE                 EQU     200000h                 ;; PDT0 基址
GUEST_PDT1_BASE                 EQU     201000h                 ;; PDT1 基址
GUEST_PDT2_BASE                 EQU     202000h                 ;; PDT1 基址
GUEST_PDT3_BASE                 EQU     203000h                 ;; PDT1 基址


PML4T_BASE                      EQU     0C0200000h
POOL_BASE                       EQU     0C0201000h
GUEST_APIC_BASE                 EQU     81000000h               ;; local APIC 线性地址

%endif




;;
;; guest processor flag 值
;;
GUEST_PROCESSOR_PAGING          EQU     80000000h
GUEST_PROCESSOR_PE              EQU     00000001h


;;
;; 8259 中断向量
;;
GUEST_IRQ0_VECTOR               EQU     30h
GUEST_IRQ1_VECTOR               EQU     (GUEST_IRQ0_VECTOR + 1)
GUEST_IRQ13_VECTOR              EQU     (GUEST_IRQ0_VECTOR + 13)



%endif
