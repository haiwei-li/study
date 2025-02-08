;*************************************************
; dump_pic8259.asm                               *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

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