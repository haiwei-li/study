; boot.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;
; 编译命令: 
; 1.用floppy 启动： nasm -Ie:\x86\source ex1-1\boot.asm
; 2.用u盘启动:      nasm -Ie:\x86\source ex1-1\boot.asm -o ex1-1\uboot -d UBOOT
;
; 生成 boot 模块后，使用 merge 工具合并映像
;


%include "..\inc\support.inc"
%include "..\inc\ports.inc"

        bits 16

;--------------------------------------
; now, the processor is real mode
;--------------------------------------        
        
; Int 19h 加载 sector 0 (MBR) 进入 BOOT_SEG 段, BOOT_SEG 定义为 0x7c00
         
        org BOOT_SEG
        
start:
        cli

; enable a20 line
        FAST_A20_ENABLE
        
        sti
        
; set BOOT_SEG environment
        mov ax, cs
        mov ds, ax
        mov ss, ax
        mov es, ax
        mov sp, BOOT_SEG                        ; 设 stack 底为 BOOT_SEG
        
        call clear_screen

;;实验 ex1-1：测试 byte 内排列        
        mov dword [Foo], 2                      ; 00000000000000000000000000000010B
        bt dword [Foo], 1                       ; 取 bit 1
        setc bl                                 ; bit 1 是否等于 1
        movzx ebx, bl
        mov si, [message_table + ebx * 2]
        call print_message
                
next:        
        jmp $
        
Foo             dd 0
LSB_to_MSB      db 'byte order: LSB to MSB', 13, 10, 0
MSB_to_LSB      db 'byte order: MSB to LSB', 13, 10, 0
message_table   dw MSB_to_LSB, LSB_to_MSB, 0



;------------------------------------------------------
; clear_screen()
; description:
;                clear the screen & set cursor position at (0,0)
;------------------------------------------------------
clear_screen:
        pusha
        mov ax, 0x0600
        xor cx, cx
        xor bh, 0x0f                                ; white
        mov dh, 24
        mov dl, 79
        int 0x10
        
set_cursor_position:
        mov ah, 02
        mov bh, 0
        mov dx, 0
        int 0x10        
        popa
        ret
        
;--------------------------------
; print_message()
; input: 
;                si: message
;--------------------------------
print_message:
        pusha
        mov ah, 0x0e
        xor bh, bh        

do_print_message_loop:        
        lodsb
        test al,al
        jz do_print_message_done
        int 0x10
        jmp do_print_message_loop

do_print_message_done:        
        popa
        ret

;--------------------------
; dot(): 打印点
;--------------------------
dot:        
        push ax
        push bx
        mov ah, 0x0e
        xor bh, bh
        mov al, '.'
        int 0x10                
        pop bx
        pop ax
        ret
        
        
;-------------------------------------------------------
; LBA_to_CHS(): LBA mode converting CHS mode for floppy 
; input:
;                ax - LBA sector
; output:
;                ch - cylinder
;                cl - sector (1-63)
;                dh - head        
;-------------------------------------------------------
LBA_to_CHS:
        mov cl, SPT
        div cl                                          ; al = LBA / SPT, ah = LBA % SPT
; cylinder = LBA / SPT / HPC
        mov ch, al
        shr ch, (HPC / 2)                                ; ch = cylinder
; head = (LBA / SPT ) % HPC
        mov dh, al
        and dh, 1                                        ; dh = head
; sector = LBA % SPT + 1
        mov cl, ah
        inc cl                                           ; cl = sector
        ret


;--------------------------------------------------------
; check_int13h_extension(): 测试是否支持 int13h 扩展功能
; ouput:
;                0 - support, 1 - not support
;--------------------------------------------------------
check_int13h_extension:
        push bx
        mov bx, 0x55aa
%ifdef UBOOT        
        mov dl, 0x80                                      ; for hard disk
%endif        
        mov ah, 0x41
        int 0x13
        setc al                                           ; 失败
        jc do_check_int13h_extension_done
        cmp bx, 0xaa55
        setnz al                                          ; 不支持
        jnz do_check_int13h_extension_done
        test cx, 1
        setz al                                           ; 不支持扩展功能号：AH=42h-44h,47h,48h
do_check_int13h_extension_done:        
        pop bx
        movzx ax, al
        ret
        
;--------------------------------------------------------------
; read_sector_extension(): 使用扩展功能读扇区        
; input:
;                esi - sector
;                di - buf (es:di)
;----------------------------------------------------------------------
read_sector_extension:
        xor eax, eax
        push eax
        push esi                                        ; 要读的扇区号 (LBA) - 64 位值
        push es
        push di                                         ; buf 缓冲区 es:di - 32 位值
        push word 0x01                                  ; 扇区数, word
        push word 0x10                                  ; 结构体 size, 16 bytes
        
        mov ah, 0x42                                    ; 扩展功能号
%ifdef UBOOT
        mov dl, 0x80
%else
        mov dl, 0
%endif                
        mov si, sp                                      ; 输入结构体地址
        int 0x13        
        add sp, 0x10
        ret
        
        
;----------------------------------------------------------------------        
; read_sector(int sector, char *buf): read one floppy sector(LBA mode)
; input:  
;                si - sector
;                di - buf
;----------------------------------------------------------------------
read_sector:
        pusha
        push es
        push ds
        pop es

; 测试是否支持 int 13h 扩展功能
        call check_int13h_extension
        test ax, ax
        jz do_read_sector_extension                     ; 支持

        mov bx, di                                      ; data buffer
        mov ax, si                                      ; disk sector number
; now: LBA mode --> CHS mode        
        call LBA_to_CHS
; now: read sector        
%ifdef UBOOT
        mov dl, 0x80                                    ; for U 盘或者硬盘
%else        
        mov dl, 0                                       ; for floppy
%endif
        mov ax, 0x201
        int 0x13
        setc al                                         ; 0: success  1: failure        
        jmp do_read_sector_done

; 使用扩展功能读扇区
do_read_sector_extension:
        call read_sector_extension
        mov al, 0
        
do_read_sector_done:        
        pop es
        popa
        movzx ax, al
        ret
        

;-------------------------------------------------------------------
; load_module(int module_sector, char *buf):  加载模块到 buf 缓冲区
; input:
;                esi: module_sector 模块的扇区
;                di: buf 缓冲区
; example:
;                load_module(SETUP_SEG, SETUP_SECTOR);
;-------------------------------------------------------------------
load_module:
        call read_sector                                ; read_sector(sector, buf)
        test ax, ax
        jnz do_load_module_done
        
        mov cx, [di]                                    ; 读取模块 size
        test cx, cx
        setz al
        jz do_load_module_done
        add cx, 512 - 1
        shr cx, 9                                        ; 计算 block（sectors）
  
do_load_module_loop:  
        call dot
        dec cx
        jz do_load_module_done 
        inc esi
        add di, 0x200
        call read_sector
        test ax, ax
        jz do_load_module_loop

do_load_module_done:  
        ret




                                                        
times 510-($-$$) db 0
        dw 0xaa55
