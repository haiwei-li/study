; pic8259A.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.

%include "..\inc\ports.inc"



;----------------------------------------------
; init_8253() - init 8253-PIT controller
;----------------------------------------------        
init_8253:
; set freq
        mov al, 0x36                                  ; set to 100Hz
        out PIT_CONTROL_PORT, al
; set counter
        mov ax, 1193180 / 100                         ; 100Hz
        out PIT_COUNTER0_PORT, al
        mov al, ah
        out PIT_COUNTER0_PORT, al
        ret
        
        
;----------------------------
; 初始化 8259A
;----------------------------
init_8259A:
;;; 初始化 master 8259A 芯片
; 1) 先写 ICW1
	mov al, 0x11					; ICW = 1, ICW4-write required
	out MASTER_ICW1_PORT, al
	jmp m1
m1:
	nop
; 2) 接着写 ICW2
	mov al, 0x20					; interrupt vector = 0x20
	out MASTER_ICW2_PORT, al
	jmp m2
m2:
	nop
; 3) 接着写 ICW3				
	mov al, 0x04					; bit2 must be 1
	out MASTER_ICW3_PORT, al
	jmp m3
m3:
	nop
; 4) 接着写 ICW4
	mov al, 0x01					; for Intel Architecture
	out MASTER_ICW4_PORT, al
	jmp slave
		
slave:
	nop
;; 初始化 slave 8259A 芯片
; 1) 先写 ICW1
	mov al, 0x11					; ICW = 1, ICW4-write required
	out SLAVE_ICW1_PORT, al
	jmp s1
s1:
	nop
; 2) 接着写 ICW2
	mov al, 0x28					; interrupt vector = 0x28
	out SLAVE_ICW2_PORT, al
	jmp s2
s2:
	nop
; 3) 接着写 ICW3				
	mov al, 0x02					; bit2 must be 1
	out SLAVE_ICW3_PORT, al
	jmp s3
s3:
	nop
; 4) 接着写 ICW4
	mov al, 0x01					; for Intel Architecture
	out SLAVE_ICW4_PORT, al		
	ret
	
	
;--------------------------
; write_master_EOI:
;--------------------------
write_master_EOI:
	mov al, 00100000B				; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
	ret
        
write_slave_EOI:
        mov al,  00100000B
        out SLAVE_OCW2_PORT, al
        ret
	

;----------------------------
; 屏蔽所有 8259 中断
;----------------------------
disable_8259:
        mov al, 0FFh
	out MASTER_MASK_PORT, al        
        ret

;--------------------------
; mask timer
;--------------------------
disable_timer:
	in al, MASTER_MASK_PORT
	or al, 0x01
	out MASTER_MASK_PORT, al
	ret	
	
enable_timer:
	in al, MASTER_MASK_PORT
	and al, 0xfe
	out MASTER_MASK_PORT, al
	ret	
		
;--------------------------
; mask 键盘
;--------------------------
disable_keyboard:
	in al, MASTER_MASK_PORT
	or al, 0x02
	out MASTER_MASK_PORT, al
	ret
	
enable_keyboard:
	in al, MASTER_MASK_PORT
	and al, 0xfd
	out MASTER_MASK_PORT, al
	ret	
	
;------------------------------
; read_master_isr:
;------------------------------
read_master_isr:
	mov al, 00001011B			; OCW3 select, read ISR
	out MASTER_OCW3_PORT, al
	jmp $+2
	in al, MASTER_OCW3_PORT
	ret
read_slave_isr:
	mov al, 00001011B
        out SLAVE_OCW3_PORT, al
        jmp $+2
        in al, SLAVE_OCW3_PORT
        ret
;-------------------------------
; read_master_irr:
;--------------------------------
read_master_irr:
	mov al, 00001010B			; OCW3 select, read IRR	
	out MASTER_OCW3_PORT, al
	jmp $+2
	in al, MASTER_OCW3_PORT
	ret

read_slave_irr:
        mov al, 00001010B
        out SLAVE_OCW3_PORT, al
        jmp $+2
        in al, SLAVE_OCW3_PORT
        ret

read_master_imr:
	in al, MASTER_IMR_PORT
	ret
        
read_slave_imr:
        in al, SLAVE_IMR_PORT
        ret
;------------------------------
; send_smm_command
;------------------------------
send_smm_command:
	mov al, 01101000B			; SMM=ESMM=1, OCW3 select
	out MASTER_OCW3_PORT, al	
	ret
        
;---------------------------------
; dump_8259_isr:
;---------------------------------
dump_8259_isr:		
	mov esi, isr_msg
	call puts
	call read_master_isr
        movzx esi, al
	shl esi, 24
	call reverse
	mov esi, eax
	mov edi, isr_flags
	call dump_flags
	call println
        mov esi, isr_msg1
        call puts
        call read_slave_isr
        movzx esi, al
        shl esi, 24
	call reverse
	mov esi, eax
	mov edi, isr_flags1
	call dump_flags
	call println
	ret

dump_8259_irr:
	mov esi, irr_msg
	call puts
	call read_master_irr
	movzx esi, al
	shl esi, 24
	call reverse
	mov esi, eax
	mov edi, irr_flags
	call dump_flags
	call println
        mov esi, irr_msg1
        call puts
        call read_slave_irr
        movzx esi, al
	shl esi, 24
	call reverse
	mov esi, eax
	mov edi, irr_flags1
	call dump_flags
	call println        
	ret
	
dump_8259_imr:
	mov esi, imr_msg
	call puts
	call read_master_imr
	movzx esi, al
	shl esi, 24
	call reverse
	mov esi, eax
	mov edi, imr_flags
	call dump_flags
        call println
        mov esi, imr_msg1
        call puts
        call read_slave_imr
        movzx esi, al        
        shl esi, 24
        call reverse
        mov edi, imr_flags1
        call dump_flags
	call println
	ret	
	
isr_msg         db '<ISR>: ', 0
irr_msg	        db '<IRR>: ', 0
imr_msg	        db '<IMR>: ', 0
isr_msg1:
irr_msg1:
imr_msg1        db '       ', 0
irq0	db 'irq0 ', 0
irq1	db 'irq1 ', 0
irq3	db 'irq3 ', 0
irq4	db 'irq4 ', 0
irq5	db 'irq5 ', 0
irq6	db 'irq6 ', 0
irq7	db 'irq7 ', 0
irq2	db 'irq2 ', 0
irq8	db 'irq8 ', 0
irq9    db 'irq9 ', 0
irq10   db 'irq10', 0
irq11   db 'irq11', 0
irq12   db 'irq12', 0
irq13   db 'irq13', 0
irq14   db 'irq14', 0
irq15   db 'irq15', 0
imr_flags:
irr_flags:
isr_flags	dd irq7, irq6, irq5, irq4, irq3, irq2, irq1, irq0, -1

imr_flags1:
irr_flags1:
isr_flags1      dd irq15, irq14, irq13, irq12, irq11, irq10, irq9, irq8, -1
	