;*************************************************
; ex.inc                                         *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

%ifndef _EX_INC
%define _EX_INC

;;
;; 定义在 ex.asm 里使用，64 位以及 32 位下通用的寄存器名
;;

%if __BITS__ == 64
        
%define R0      rax
%define R1      rcx
%define R2      rdx
%define R3      rbx
%define R4      rsp
%define R5      rbp
%define R6      rsi
%define R7      rdi

%else

%define R0      eax
%define R1      ecx
%define R2      edx
%define R3      ebx
%define R4      esp
%define R5      ebp
%define R6      esi
%define R7      edi

%endif




%endif