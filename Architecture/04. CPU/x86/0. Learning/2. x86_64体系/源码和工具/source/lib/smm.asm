; smm.asm
; Copyright (c) 2009-2012 mik
; All rights reserved.



%include "..\inc\CPU.inc"


	bits 16
	
; SMI handler Èë¿Úµã
	
;	org SMBASE + 0x8000

SMI_handler:
	mov ax, cs
	mov es, ax
	mov ds, ax
	mov ss, ax
	mov sp, 0x7ff0
	
	mov esi, smi_msg1
	call smm_puts
	rsm
	

;-------------------------------------
; smm_puts();
; input:
; 		esi: message
;-------------------------------------	
smm_puts:
	mov ebx, [video]
smm_puts_loop:	
	lodsb
	test al, al
	jz smm_puts_done
	mov ah, 0x0f
	mov [fs:ebx], ax
	add ebx, 2
	jmp smm_puts_loop
smm_puts_done:	
	mov [video], ebx
	ret

video	dd	0xb8000

smi_msg1		db '---> Now, enter the SMM mode !!!!', 0	