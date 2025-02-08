;*************************************************
; pic8259.asm                                    *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%include "..\inc\ports.inc"



;----------------------------------------------
; init_8253() - init 8253-PIT controller
;----------------------------------------------        
init_8253:
        mov al, 36h                                   ; set to 100Hz
        out PIT_CONTROL_PORT, al
        xor ax, ax
        out PIT_COUNTER0_PORT, al
        out PIT_COUNTER0_PORT, al
        ret
        
        
;-------------------------------------------------
; init_8259()
; input:
;       none
; ouput:
;       none
; 描述: 
;       初始化 8259 设置
;       1) master 片中断向量是 20h
;       2) slave 片中断向量是 28h       
;-------------------------------------------------
init_pic8259:
;;; 初始化 master 8259A 芯片
; 1) 先写 ICW1
	mov al, 11h  					; ICW = 1, ICW4-write required
	out MASTER_ICW1_PORT, al
	jmp $+2
	nop
; 2) 接着写 ICW2
	mov al, GUEST_IRQ0_VECTOR                       ; interrupt vector
	out MASTER_ICW2_PORT, al
	jmp $+2
	nop
; 3) 接着写 ICW3				
	mov al, 04h					; bit2 must be 1
	out MASTER_ICW3_PORT, al
	jmp $+2
	nop
; 4) 接着写 ICW4
	mov al, 01h					; for Intel Architecture
	out MASTER_ICW4_PORT, al
	jmp $+2
        nop
;; 初始化 slave 8259A 芯片
; 1) 先写 ICW1
	mov al, 11h					; ICW = 1, ICW4-write required
	out SLAVE_ICW1_PORT, al
	jmp $+2
	nop
; 2) 接着写 ICW2
	mov al, GUEST_IRQ0_VECTOR + 8                   ; interrupt vector
	out SLAVE_ICW2_PORT, al
	jmp $+2
	nop
; 3) 接着写 ICW3				
	mov al, 02h					; bit2 must be 1
	out SLAVE_ICW3_PORT, al
	jmp $+2
	nop
; 4) 接着写 ICW4
	mov al, 01h					; for Intel Architecture
	out SLAVE_ICW4_PORT, al		
	ret


;-------------------------------------------------
; setup_pic8259()
; input:
;       none
; 描述: 
;       初始化 8259 并设置相应的中断服务例程
;-------------------------------------------------
setup_pic8259:
        ;;
        ;; 初始化 8259 和 8253
        ;;
        call init_pic8259
        call init_8253                             
        call disable_8259
        ret
	
	
	
;--------------------------
; write_master_EOI:
;--------------------------
write_master_EOI:
	mov al, 00100000B				; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
	ret
        
;-----------------------------
; 宏 MASTER_EOI()
;-----------------------------
%macro MASTER_EOI 0
	mov al, 00100000B				; OCW2 select, EOI
	out MASTER_OCW2_PORT, al
%endmacro
        
        
        
        
write_slave_EOI:
        mov al,  00100000B
        out SLAVE_OCW2_PORT, al
        ret
	
;-----------------------------
; 宏 SLAVE_EOI()
;-----------------------------
%macro SLAVE_EOI 0
        mov al,  00100000B
        out SLAVE_OCW2_PORT, al
%endmacro


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
disable_8259_timer:
	in al, MASTER_MASK_PORT
	or al, 0x01
	out MASTER_MASK_PORT, al
	ret	
	
enable_8259_timer:
	in al, MASTER_MASK_PORT
	and al, 0xfe
	out MASTER_MASK_PORT, al
	ret	
		
;--------------------------
; mask 键盘
;--------------------------
disable_8259_keyboard:
	in al, MASTER_MASK_PORT
	or al, 0x02
	out MASTER_MASK_PORT, al
	ret
	
enable_8259_keyboard:
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
        




KeyMap:
        db 0, 0, "1234567890-=", 0
        db 0, "qwertyuiop[]", 0, 0
        db "asdfghjkl;'`", 0, "\zxcvbnm,./"
        db 0, 0, 0, 0, 0
        db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
        db 0, 0, 0, 0, 0, 0, 0, 0
        db 0, 0, 0, 0, 0, 0, 0
        db 0, 0, 0, 0, 0, 0, 0, 0        





                	
       	

	