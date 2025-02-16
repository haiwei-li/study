; float.inc
; Copyright (c) 2009-2012 邓志
; All rights reserved.


%ifndef FLOAT_INC
%define FLOAT_INC

;;
;; 定义 float 的相关常量



%define FLT_MAX                 0x7F7FFFFF                      ; 单精度的最大值
%define FLT_MIN                 0x00800000                      ; 单精度最小值
%define DBL_FLT_MAX             0x7FEFFFFFFFFFFFFF              ; 双精度的最大值
%define DBL_FLT_MIN             0x0018000000000000              ; 双精度最小值


;%define FLT_MAX                 3.402823466e+38                ; 单精度最大值
;%define FLT_MIN                 1.175494351e-38                ; 单精度最小值
;%define DBL_FLT_MAX             1.7976931348623158e+308         ; 双精度最大值
;%define DBL_FLT_MIN             2.2250738585072014e-308         ; 双精度最小值

;扩展双精度最大值
%macro DBE_FLAT_MAX 0
        0xFFFFFFFF
        dd 0xFFFFFFFF
        dw 0x7FFE
%endmacro
%define DBE_FLAT_MIN            0x1p-16382                      ; 扩展双精度最小值

%define Inf                     __Infinity__ 
%define NaN                     __QNaN__ 
%define QNaN                    __QNaN__ 
%define SNaN                    __SNaN__

;%define SNaN                    0x7fb00000
;%define QNaN                    0x7ff00000
;%define NaN                     QNaN
;%define Inf                     0x7f000000

; 定义80位 denormal 数
%macro DENORMAL80 0
        1                       ; significand 为 1 值
        dw 0                    ; exponent 为 0
%endmacro

; 定义 80位 unsupported 数
%macro UNSUPPORTED80 0
        0                       ; significand 为 0 值
        dw 0x7FFFF              ; exponent 为最大
%endmacro

%endif

