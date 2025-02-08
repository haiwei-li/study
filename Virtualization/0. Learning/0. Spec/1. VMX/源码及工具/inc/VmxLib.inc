;*************************************************
;* VmxLib.inc                                    *
;* Copyright (c) 2009-2013 µÀ÷æ                  *
;* All rights reserved.                          *
;*************************************************


%ifndef _VMX_LIB_INC
%define _VMX_LIB_INC


;-----------------------------------------------------
; SET_MSR_READ_BITMAP
; input:
;       %1 - msr
; output:
;       none
;-----------------------------------------------------
%macro SET_MSR_READ_BITMAP      1
        mov esi, %1
        call set_msr_read_bitmap
%endmacro


;-----------------------------------------------------
; SET_MSR_WRITE_BITMAP
; input:
;       %1 - msr
; output:
;       none
;-----------------------------------------------------
%macro SET_MSR_WRITE_BITMAP      1
        mov esi, %1
        call set_msr_write_bitmap
%endmacro


;-----------------------------------------------------
; CLEAR_MSR_READ_BITMAP
; input:
;       %1 - msr
; output:
;       none
;-----------------------------------------------------
%macro CLEAR_MSR_READ_BITMAP      1
        mov esi, %1
        call clear_msr_read_bitmap
%endmacro


;-----------------------------------------------------
; CLEAR_MSR_WRITE_BITMAP
; input:
;       %1 - msr
; output:
;       none
;-----------------------------------------------------
%macro CLEAR_MSR_WRITE_BITMAP      1
        mov esi, %1
        call clear_msr_write_bitmap
%endmacro




;-----------------------------------------------------
; SET_IO_BITMAP
; input:
;       %1 - io port
; output:
;       none
;-----------------------------------------------------
%macro SET_IO_BITMAP      1
        mov esi, %1
        call set_io_bitmap
%endmacro


;-----------------------------------------------------
; CLEAR_IO_BITMAP
; input:
;       %1 - io port
; output:
;       none
;-----------------------------------------------------
%macro CLEAR_IO_BITMAP      1
        mov esi, %1
        call clear_io_bitmap
%endmacro


%endif
