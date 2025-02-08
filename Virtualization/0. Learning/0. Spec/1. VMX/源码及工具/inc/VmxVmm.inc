;************************************************
;* VmxVmm.inc                                   *
;* Copyright (c) 2009-2013 邓志                 *
;* All rights reserved.                         *
;************************************************

%ifndef _VMXVMM_INC
%define _VMXVMM_INC


;;
;; 定义 guest 状态
;;
%define GUEST_INITIALIZED                       80h
%define GUEST_READY                             81h
%define GUEST_RUNNING                           82h
%define GUEST_SUSPENDED                         83h
%define GUEST_NOT_INIT                          00h
%define GUEST_NOT_READY                         01h
%define GUEST_ERROR                             02h

%define GUEST_QUEUE_EMPTY                       0
%define GUEST_QUEUE_NORMAL                      1
%define GUEST_QUEUE_FULL                        2         


%define GUEST_PAGING_LONGMODE                   1
%define GUEST_PAGING_PAE                        2
%define GUEST_PAGING_32bit                      3


;;
;; INVVPID 指令的 cache 刷新类型
;;
%define INDIVIDUAL_ADDRESS_INVALIDATION                 0
%define SINGLE_CONTEXT_INVALIDATION                     1
%define ALL_CONTEXT_INVALIDATION                        2
%define SINGLE_CONTEXT_EXCLUDE_GLOBAL_INVALIDATION      3


%define LOAD_LDTR_SUCCESS                       0
%define LOAD_LDTR_ERROR                         1
%define LOAD_TR_SUCCESS                         0
%define LOAD_TR_ERROR                           1
%define LOAD_LDTR_TR_SUCCESS                    0


;;
;; #GP 异常处理标志位
;;
%define GPF_GUEST_LIMIT                         (1 << 0)
%define GPF_HOST_LIMIT                          (0 << 0)


%define DO_INTERRUPT_SUCCESS                    0
%define DO_INTERRUPT_ERROR                      1


;;
;; 刷新描述符 INV_DESC(invalidate descriptor)
;;
struc INV_DESC
        .Eptp:
        .Pcid:
        .Vpid:
        .Qword0:
        .Dword0                 RESD    1
        .Dword1                 RESD    1

        .Reserved:
        .LinearAddress:
        .Qword1:
        .Dword2                 RESD    1
        .Dword3                 RESD    1

        INV_DESC_SIZE           EQU     $
endstruc




;-------------------------------------------------------------------
; REGISTER_VMEXIT_ROUTINE
; input:
;       %1 - routine
;       %2 - VM-exit reason
; output:
;       none
; 描述: 
;       1) 注册VM-exit处理例程
;-------------------------------------------------------------------
%macro REGISTER_VMEXIT_ROUTINE  2
        mov DWORD [DoVmExitRoutineTable + %2 * 4], %1
%endmacro



;-------------------------------------------------------------------
; REGISTER_EXCEPTION_ROUTINE
; input:
;       %1 - routine
;       %2 - exception vector
; output:
;       none
; 描述: 
;       1) 注册异常处理例程
;-------------------------------------------------------------------
%macro REGISTER_EXCEPTION_ROUTINE  2
        mov DWORD [DoExceptionTable + %2 * 4], %1
%endmacro





%endif
