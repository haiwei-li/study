; pci.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\ports.inc"
%include "..\inc\pci.inc"


;-----------------------------------------------------------------
; get_pci_address(int bus, int device, int function, int offset): 
;-----------------------------------------------------------------
get_pci_address:
	push ebp
	mov ebp, esp
	push ecx
	mov esi, [ebp + 8]			; bus
	mov edi, [ebp + 0Ch]		; device
	shl edi, 11
	shl esi, 16
	mov ecx, [ebp + 10h]		; function
	shl ecx, 8
	mov eax, [ebp + 14h]		; register offset
	and eax, 0xfc
	or eax, esi
	or eax, edi
	or eax, ecx
	btc eax, 31
	pop ecx
	mov esp, ebp
	pop ebp
	ret

;-----------------------------------------------------------------
; read_pci_dword(int bus, int device, int function, int offset);
;-----------------------------------------------------------------	
read_pci_dword:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	in eax, dx
	pop edx
	mov esp, ebp
	pop ebp
	ret	

;------------------------------------------------------------------
; read_pci_word(int bus, int device, int function, int offset)
;-----------------------------------------------------------------
read_pci_word:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	in ax, dx
	pop edx
	mov esp, ebp
	pop ebp
	ret

;------------------------------------------------------------------
; read_pci_byte(int bus, int device, int function, int offset)
;-----------------------------------------------------------------
read_pci_byte:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	in al, dx
	pop edx
	mov esp, ebp
	pop ebp
	ret
	
;-----------------------------------------------------------------------------
; write_pci_dword(int bus, int device, int function, int offset, int value);
;-----------------------------------------------------------------------------
write_pci_dword:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	mov eax, [ebp + 18h]
	out dx, eax
	pop edx
	mov esp, ebp
	pop ebp	
	ret	
	
;-----------------------------------------------------------------------------
; write_pci_word(int bus, int device, int function, int offset, short value);
;-----------------------------------------------------------------------------
write_pci_word:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	mov ax, [ebp + 18h]
	out dx, ax
	pop edx
	mov esp, ebp
	pop ebp	
	ret		

;-----------------------------------------------------------------------------
; write_pci_byte(int bus, int device, int function, int offset, char value);
;-----------------------------------------------------------------------------
write_pci_byte:
	push ebp
	mov ebp, esp
	push edx
	push DWORD [ebp + 14h]
	push DWORD [ebp + 10h]
	push DWORD [ebp + 0Ch]
	push DWORD [ebp + 8]
	call get_pci_address
	add esp, 16
	mov dx, CONFIG_ADDRESS
	out dx, eax
	mov dx, CONFIG_DATA
	mov al, [ebp + 18h]
	out dx, al
	pop edx
	mov esp, ebp
	pop ebp	
	ret	



;-------------------------------------------
; get_PMBASE(): 得到Power Management I/O base
; output:
;	eax: PMBASE(I/O 地址)
;-------------------------------------------
get_PMBASE:
; 读 bus 0, device 31, function 0, offset 40h
	READ_PCI_DWORD	0, 31, 0, 40h
; 返回 PMBASE
	and eax, 0FF80h			; PMBASE 地址 128 bytes 对齐
	ret


;-------------------------------------------
; get_GPIOBASE(): 得到 GPIO I/O base
; output:
;	eax: GPIOBASE(I/O 地址)
;-------------------------------------------
get_GPIOBASE:
; 读 bus 0, device 31, function 0, offset 48h
	READ_PCI_DWORD	0, 31, 0, 48h
; 返回 GPIOBASE
	and eax, 0FF80h			; GPIOBASE 地址 128 bytes 对齐
	ret

;----------------------------------------------
; enable_GPIO(): 开启 GPIO, 使用 GPIOBASE 有效
;-----------------------------------------------
enable_GPIO:
	READ_PCI_DWORD 0, 31, 0, 4Ch
	mov ebx, eax
	bts ebx, 4		; enable GPIO 
	WRITE_PCI_DWORD 0, 31, 0, 4Ch, ebx
	ret

;----------------------------------------------
; get_TCOBASE(): 得到 TCO I/O Base
; output:
;	eax: TCOBASE(I/O 地址)
;----------------------------------------------
get_TCOBASE:
	call get_PMBASE
	add eax, 60h		; TCOBASE = PMBASE + 60h
	ret


;-----------------------------------------------
; get_RCBA(): 得到 Root complex base address
;-----------------------------------------------
get_RCBA:
        READ_PCI_DWORD  0, 31, 0, 0F0h          ; 读 bus 0, device 31, function 0, offset F0h
        ret

;-------------------------------------------------
; get_root_complex_base_address(): 得到 RCBA 地址
; output:
;       eax - RCBA address(memroy space)
;-------------------------------------------------
get_root_complex_base_address:
        ;* 读 RCBA 寄存器
        READ_PCI_DWORD  0, 31, 0, 0F0h         ; 读 bus 0, device 31, function 0, offset F0h 
        and eax, 0FFFFC000h                    ; 得到 base address
        ret


read_OIC:
        push ebx
        call get_RCBA
        and eax, 0xFFFFC000
        mov ebx, 0xFEC00000
        sub eax, ebx
        mov eax, [eax + PCI_FEC00000 + 0x31fe]                 ; 读 OIC(other interrupt control)寄存器
        and eax, 0xffff
        pop ebx
        ret

;----------------------------------------------
; write_OIC():
; input:
;       esi: value
;---------------------------------------------        
write_OIC:
        push ebx
        call get_RCBA
        and eax, 0xFFFFC000
        mov ebx, 0xFEC00000
        sub eax, ebx
        mov [eax + PCI_FEC00000 + 0x31fe], esi
        pop ebx
        ret
        

;---------------------------------
; enable_APMC(): 开启 APM 控制器
;---------------------------------
enable_APMC:
	call get_PMBASE
	lea edx, [eax + 30h]		; SMI_EN 寄存器
	in eax, dx			; 读 SMI_EN 寄存器 DWORD
	bts eax, 5			; APMC_EN = 1
	bts eax, 0			; BGL_SMI_EN = 1
	out dx, eax			; 开启 SMI
	ret



