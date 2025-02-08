; pci.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这个模块是关于 PCI 的一些库

%ifndef PIC_INC
%define PIC_INC

%include "..\inc\ports.inc"


; 定义 PCI 空间常量
%define PCI_FEC00000            0x600000





;--------------------------------------------
; MAKE_PCI_ADDRESS(): 合成一个 PCI 地址放在 eax 寄存器
; args: 
;	bus, device, function, offset
;---------------------------------------------
%macro MAKE_PCI_ADDRESS 4
	mov eax, DWORD (0x80000000|(%1<<16)|(%2<<11)|(%3<<8)|(%4&0xfc))
%endmacro



;---------------------------------------------
; READ_PCI_DWORD(): 读一个DWORD
; args:
;	bus, device, function, offset
;----------------------------------------------
%macro READ_PCI_DWORD 4
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	in eax, dx
%endmacro


;---------------------------------------------
; READ_PCI_WORD(): 读一个WORD
; args:
;	bus, device, function, offset
;----------------------------------------------
%macro READ_PCI_WORD 4
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	in ax, dx
%endmacro


;---------------------------------------------
; READ_PCI_BYTE(): 读一个 BYTE
; args:
;	bus, device, function, offset
;----------------------------------------------
%macro READ_PCI_BYTE 4
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	in al, dx
%endmacro



;---------------------------------------------
; WRITE_PCI_DWORD(): 写一个 DWORD
; args:
;	bus, device, function, offset, value
;----------------------------------------------
%macro WRITE_PCI_DWORD 5
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	mov eax, %5
	out dx, eax
%endmacro


;---------------------------------------------
; WRITE_PCI_WORD(): 写一个 WORD
; args:
;	bus, device, function, offset, value
;----------------------------------------------
%macro WRITE_PCI_WORD 5
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	mov ax, %5
	out dx, ax
%endmacro


;---------------------------------------------
; WRITE_PCI_BYTE(): 写一个 BYTE
; args:
;	bus, device, function, offset, value
;----------------------------------------------
%macro WRITE_PCI_BYTE 5
	mov dx, CONFIG_ADDRESS
	MAKE_PCI_ADDRESS %1, %2, %3, %4
	out dx, eax
	mov dx, CONFIG_DATA
	mov al, %5
	out dx, al
%endmacro


;-------------------------------------
; DO_SIM(): 主动发起 SMI 中断
; args:
;	%1: 传送给 SMI handler 的参数
;--------------------------------------
%macro DO_SMI 1
	mov dx, APM_CNT			; advanced power management 控制寄存器
	mov al, %1
	out dx, al			; 产生 SMI 中断
%endmacro

;-------------------------------------
; DO_SIM(): 主动发起 SMI 中断
; args:
;	%1: 传送给 SMI handler 的参数
;--------------------------------------
%macro DO_SMI 0
	mov dx, APM_CNT			; advanced power management 控制寄存器
	mov al, 0
	out dx, al			; 产生 SMI 中断
%endmacro



;---------------------------------
; DO_NMI(): 主动发起 #NMI 中断
;---------------------------------
%macro DO_NMI 0
	call get_TCOBASE
	lea edx, [eax + 08h]		; TCO1 control
	in ax, dx
	or ax, 100h			; NMI NOW 
	out dx, ax
%endmacro	

%define CLEAR_NMI	DO_NMI



;-----------------------------------------------
; SMRAM_OPEN() 打开 SMRAM 可读
; 描述: 
;	使得 compatible SMM space 解码至 DRAM
;-----------------------------------------------
%macro SMRAM_OPEN 0
	READ_PCI_DWORD 0, 0, 0, 9Dh
	or eax, 4800h			; D_OPEN=1, G_SMRARE=1
	mov ebx, eax
	WRITE_PCI_DWORD 0, 0, 0, 9Dh, ebx
%endmacro

;-----------------------------------------------
; SMRAM_OPEN() 关闭 SMRAM
; 描述: 
;	使得 compatible SMM space 解码至 VGA
;-----------------------------------------------
%macro SMRAM_CLOSE 0
	READ_PCI_DWORD 0, 0, 0, 9Dh
	btr eax, 14			; D_OPEN=0
	bts eax, 13			; D_CLS=1
	mov ebx, eax
	WRITE_PCI_DWORD 0, 0, 0, 9Dh, ebx
%endmacro


;----------------------------------------------
; SET_SMRAM_OPEN(): 打开SMRAM 可读
;----------------------------------------------
%macro SET_SMRAM_OPEN 0
;; Note: only for bochs (440FX chipset)
	MAKE_PCI_ADDRESS	0, 0, 0, 70h
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA + 2
	mov al, 4Ah				; D_OPEN = 1, D_LCK = 0
	out dx, al
%endmacro

;----------------------------------------------
; SET_SMRAM_CLOSE(): 关闭 SMRAM 可读
;----------------------------------------------
%macro SET_SMRAM_CLOSE 0
;; Note: only for bochs (440FX chipset)
	MAKE_PCI_ADDRESS	0, 0, 0, 70h
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA + 2
	mov al, 0Ah				; D_OPEN = 0
	out dx, al
%endmacro
	
	
	
%endif

