; boot.inc
; Copyright (c) 2009-2013 mik 
; All rights reserved.

%ifndef __BOOT_INC__
%define __BOOT_INC__


;-------------------------------------------------------------------
; 宏 DISK_ADDRESS_PACKET: 构造 int 13h 用于读写的 packet
; input：
;       $1: 起始扇区 
;       $2: far pointer 的 selector
;       $3: far pointer 的 offset
;       $4: 需要读取的扇区数
; example:
;       DISK_ADDRESS_PACKET 64, 2000, 0, 10
;       从 64 号扇区读取 10 个扇区到地址 2000:0000h 上
;-------------------------------------------------------------------
%macro DISK_ADDRESS_PACKET 4
packet_size:            DW      10h                             ; packet 结构 size
sectors:                DW      $4                              ; 读取 sectors 数
buffer_offset:          DW      $3                              ; offset 
buffer_selector:        DW      $2                              ; selector
start_sector:           DQ      $1                              ; 起始 sector
%endmacro


%macro DISK_PARAMETERS 0
driver_type:            DB      0
driver_number:          DB      0
maximum_cylinders:      DW      0
maximum_headers:        DW      0
maximum_sector:         DW      0
parameter_table:        DW      0
%endmacro


%endif
