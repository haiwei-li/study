;*************************************************
; boot.asm                                       *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

%include "..\inc\support.inc"
%include "..\inc\ports.inc"







;----------------------------------------------------
; MAKE_LOAD_MODULE_ENTRY
; input:
;       %1 - 模块加载的内存段地址
;       %2 - 模块在磁盘的扇区号(LBA)
; output:
;       none
; 描述: 
;       1) 用来定义需要加载的模块表
;----------------------------------------------------
%macro MAKE_LOAD_MODULE_ENTRY   2
        %%segment       DW      %1
        %%sector        DW      %2
%endmacro

LOAD_MODULE_ENTRY_SIZE          EQU     4






        bits 16

    
;;
;; 注意: 
;; 1) 现在处理器处于 real mode 下       
;; 2) int 19h 加载 boot 模块进入 BOOT_SEGMENT 段, BOOT_SEGMENT 定义为 7C00h
;;
         
        org BOOT_SEGMENT
        jmp WORD Boot.Start
        
;;
;; 用于保存 int 13h/ax=08h 获得的 driver 参数
;;
driver_parameters_table:        
        driver_number           DB      0               ; driver number
        driver_type             DB      0               ; driver type       
        cylinder_maximum        DW      0               ; 最大的 cylinder 号
        header_maximum          DW      0               ; 最大的 header 号
        sector_maximum          DW      0               ; 最大的 sector 号
        parameter_table         DW      0               ; address of parameter table 
                
;;
;; 定义 int 13h 使用的 disk address packet, 用于 int 13h 读/写
;;        
disk_address_packet:
        size                    DW      10h             ; size of packet
        read_sectors            DW      0               ; number of sectors
        buffer_offset           DW      0               ; buffer far pointer(16:16)
        buffer_selector         DW      0               ; buffer 为 0
        start_sector            DQ      0               ; start sector



;;
;;
;; 加载模块表, 需要加载下面的模块(符号定义在 ..\inc\support.inc 文件里)
;; 1) setup 模块
;; 2) 定义 X64 时 long 模块, 在 32 位下加载 protected 模块
;; 3) guest 的 boot 模块
;; 4) guest 的 kernel 模块
;;
load_module_table:
        MAKE_LOAD_MODULE_ENTRY          (SETUP_SEGMENT >> 4), SETUP_SECTOR

;;
;; 在 64 位运行环境下, 需要加载 long 模块, 否则加载 proteccted 模块
;;        
%ifdef __X64
        MAKE_LOAD_MODULE_ENTRY          (LONG_SEGMENT >> 4), LONG_SECTOR
%else
        MAKE_LOAD_MODULE_ENTRY          (PROTECTED_SEGMENT >> 4), PROTECTED_SECTOR
%endif

;;
;; 假如定义了 GUEST_ENABLE 符号, 则需要加载 GuestBoot 与 GuestKernel 模块
;;        
%ifdef GUEST_ENABLE
        MAKE_LOAD_MODULE_ENTRY          (GUEST_BOOT_SEGMENT >> 4), GUEST_BOOT_SECTOR
        MAKE_LOAD_MODULE_ENTRY          (GUEST_KERNEL_SEGMENT >> 4), GUEST_KERNEL_SECTOR
%endif
        
load_module_table.end:




;;########################## boot 模块入口 ############################

Boot.Start:
        ;; 
        ;; set BOOT_SEG environment
        ;;
        xor ax, ax
        mov ss, ax
        mov sp, BOOT_SEGMENT                                    ; 设 stack 底为 BOOT_SEGMENT
        mov ds, ax
        mov es, ax
        jmp WORD 0:Boot.Next
Boot.Next:        
        mov [driver_number], dl                                 ; 保存 boot driver
        mov WORD [buffer_selector], es                          ; 读磁盘的 buffer segment 设置为 es
        call get_driver_parameters                              ; 读磁盘参数
        
        
        ;;
        ;; 下面进行加载模块工作
        ;;

        mov bx, load_module_table                               ; 模块加载表
load_module.loop:        
        mov ax, [bx]                                            
        mov [buffer_selector], ax                               ; segment 从模块加载表中读取
        mov WORD [buffer_offset], 0                             ; selector = 0
        mov ax, [bx + 2]
        mov [start_sector], ax                                  ; sector 从模块加载表中读取
        call load_module
        add bx, LOAD_MODULE_ENTRY_SIZE
        cmp bx, load_module_table.end
        jb load_module.loop



        ;;
        ;; 加载模块到内存后, 转入 setup 模块入口点执行(SETUP_SEGMENT + 0x18)
        ;;
        jmp SETUP_SEGMENT+0x18
       

        

  

;-----------------------------------------------------------------
; read_sector(): 读取扇区
; input:
;       使用 disk_address_packet 结构
; output:
;       0 - successful, otherwise - error code
;----------------------------------------------------------------        
read_sector:
        push es
        push bx
        mov es, WORD [buffer_selector]                  ; es = buffer_selector
               
        ;
        ; 起始扇区大于 0FFFFFFFFh
        ;
        cmp DWORD [start_sector + 4], 0
        jnz check_lba
        
        ;
        ; 如果模块在低于 504M 区域内则使用 CHS 模式
        ;
        cmp DWORD [start_sector], 504 * 1024 * 2        ; 504M
        jb chs_mode
        
check_lba:
        ;
        ; 检查是否支持 13h 扩展功能
        ;
        call check_int13h_extension
        test ax, ax
        jz chs_mode
        
lba_mode:        
        ;
        ; 使用 LBA 方式读 sector
        ;
        call read_sector_with_extension
        test ax, ax
        jz read_sector_done


        ;
        ; 使用 CHS 方式读 sector
        ;
chs_mode:       

        ;
        ; 如果一次读超过 63 个扇区则分批读取, 每次最多个63扇区
        ;
        movzx cx, BYTE [read_sectors]
        mov bx, cx
        and bx, 3Fh                                     ; bl = 64以内扇区数
        shr cx, 6                                       ; read_sectors / 64
        
        mov BYTE [read_sectors], 64                     ; 每次读取64个扇区
        
chs_mode.@0:        
        test cx, cx
        jz chs_mode.@1

        call read_sector_with_chs                       ; 读扇区
                
        ;
        ; 调整起始扇区和buffer
        ;
        add DWORD [start_sector], 64                    ; 下一个起始扇区
        add WORD [buffer_offset], 64 * 512              ; 指向下一个 buffer 块
        setc al
        shl ax, 12
        add WORD [buffer_selector], ax                  ; selector 增加
        dec cx
        jmp chs_mode.@0


chs_mode.@1:
        ;
        ; 读取剩余扇区
        ;
        mov [read_sectors], bl
        call read_sector_with_chs                
        
read_sector_done:      
        pop bx
        pop es
        ret



;--------------------------------------------------------
; check_int13h_extension(): 测试是否支持 int13h 扩展功能
; input:
;       使用 driver_paramter_table 结构
; ouput:
;       1 - support, 0 - not support
;--------------------------------------------------------
check_int13h_extension:
        push bx
        mov bx, 55AAh
        mov dl, [driver_number]                 ; driver number
        mov ah, 41h
        int 13h
        setnc al                                ; c = 失败
        jc do_check_int13h_extension_done
        cmp bx, 0AA55h
        setz al                                 ; nz = 不支持
        jnz do_check_int13h_extension_done
        test cx, 1
        setnz al                                ; z = 不支持扩展功能号: AH=42h-44h,47h,48h
do_check_int13h_extension_done:        
        pop bx
        movzx ax, al
        ret
        
        
        
;--------------------------------------------------------------
; read_sector_with_extension(): 使用扩展功能读扇区        
; input:
;       使用 disk_address_packet 结构
; output:
;       0 - successful, otherwise - error code
;--------------------------------------------------------------
read_sector_with_extension:
        mov si, disk_address_packet             ; DS:SI = disk address packet        
        mov dl, [driver_number]                 ; driver
        mov ah, 42h                             ; 扩展功能号
        int 13h
        movzx ax, ah                            ; if unsuccessful, ah = error code
        ret
                


;-------------------------------------------------------------
; read_sector_with_chs(): 使用 CHS 模式读扇区
; input:
;       使用 disk_address_packet 和 driver_paramter_table
; output:
;       0 - successful
; unsuccessful:
;       ax - error code
;-------------------------------------------------------------
read_sector_with_chs:
        push bx
        push cx
        ;
        ; 将 LBA 转换为 CHS, 使用 int 13h, ax = 02h 读
        ;
        call do_lba_to_chs
        mov dl, [driver_number]                 ; driver number
        mov es, WORD [buffer_selector]          ; buffer segment
        mov bx, WORD [buffer_offset]            ; buffre offset
        mov al, BYTE [read_sectors]             ; number of sector for read
        test al, al
        jz read_sector_with_chs_done
        mov ah, 02h
        int 13h
        movzx ax, ah                            ; if unsuccessful, ah = error code
read_sector_with_chs_done:
        pop cx
        pop bx
        ret
        
        
        
;-------------------------------------------------------------
; do_lba_to_chs(): LBA 号转换为 CHS
; input:
;       使用 driver_parameter_table 和 disk_address_packet 结构
; output:
;       ch - cylinder 低 8 位
;       cl - [5:0] sector, [7:6] cylinder 高 2 位
;       dh - header
;
; 描述: 
;       
; 1) 
;       eax = LBA / (head_maximum * sector_maximum),  cylinder = eax
;       edx = LBA % (head_maximum * sector_maximum)
; 2)
;       eax = edx / sector_maximum, head = eax
;       edx = edx % sector_maximum
; 3)
;       sector = edx + 1      
;-------------------------------------------------------------
do_lba_to_chs:
        movzx ecx, BYTE [sector_maximum]        ; sector_maximum
        movzx eax, BYTE [header_maximum]        ; head_maximum
        imul ecx, eax                           ; ecx = head_maximum * sector_maximum
        mov eax, DWORD [start_sector]           ; LBA[31:0]
        mov edx, DWORD [start_sector + 4]       ; LBA[63:32]        
        div ecx                                 ; eax = LBA / (head_maximum * sector_maximum)
        mov ebx, eax                            ; ebx = cylinder
        mov eax, edx
        xor edx, edx        
        movzx ecx, BYTE [sector_maximum]
        div ecx                                 ; LBA % (head_maximum * sector_maximum) / sector_maximum
        inc edx                                 ; edx = sector, eax = head
        mov cl, dl                              ; secotr[5:0]
        mov ch, bl                              ; cylinder[7:0]
        shr bx, 2
        and bx, 0C0h
        or cl, bl                               ; cylinder[9:8]
        mov dh, al                              ; head
        ret
        
        
        
        
;---------------------------------------------------------------------
; get_driver_parameters(): 得到 driver 参数
; input:
;       使用 driver_parameters_table 结构
; output:
;       0 - successful, 1 - failure
; failure: 
;       ax - error code
;---------------------------------------------------------------------
get_driver_parameters:
        push dx
        push cx
        push bx
        mov ah, 08h                             ; 08h 功能号, 读 driver parameters
        mov dl, [driver_number]                 ; driver number
        mov di, [parameter_table]               ; es:di = address of parameter table
        int 13h
        jc get_driver_parameters_done
        mov BYTE [driver_type], bl              ; driver type for floppy drivers
        inc dh
        mov BYTE [header_maximum], dh           ; 最大 head 号
        mov BYTE [sector_maximum], cl           ; 最大 sector 号
        and BYTE [sector_maximum], 3Fh          ; 低 6 位
        shr cl, 6
        rol cx, 8
        and cx, 03FFh                           ; 最大 cylinder 号
        inc cx
        mov [cylinder_maximum], cx              ; cylinder
get_driver_parameters_done:
        movzx ax, ah                            ; if unsuccessful, ax = error code
        pop bx
        pop cx
        pop dx
        ret
 
 
;-------------------------------------------------------------------
; load_module(int module_sector, char *buf)
; input:
;       使用 disk_address_packet 结构中提供的参数
; output:
;       none
; 描述: 
;       1) 加载模块到 buf 缓冲区
;-------------------------------------------------------------------
load_module:
        push es
        push cx
        
        ;;
        ;; 将读 1 个扇区, 得到模块的 size 值, 然后根据这个 size 进行整个模块读取
        ;;
        mov WORD [read_sectors], 1
        call read_sector
        test ax, ax
        jnz do_load_module_done
        movzx esi, WORD [buffer_offset]
        mov es, WORD [buffer_selector]
        mov ecx, [es: esi]                                              ; 读取模块 siz
        test ecx, ecx
        setz al
        jz do_load_module_done
        
        ;;
        ;; size 向上调整到 512 倍数
        ;;
        add ecx, 512 - 1
        shr ecx, 9							; 计算 block(sectors)
        mov WORD [read_sectors], cx                                     ; 
        call read_sector
do_load_module_done:  
        pop cx
        pop es
        ret
 
 
 
                                                        
times 510-($-$$) db 0
        dw 0AA55h
