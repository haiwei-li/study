;*************************************************
; crt16.asm                                      *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%include "..\inc\support.inc"

;;
;; 这是 16位实模式下使用的 runtime 库
;;


	bits 16
	
%include "..\lib\a20.asm"



;------------------------------------------------------
; clear_screen()
; description:
;       clear the screen & set cursor position at (0,0)
;------------------------------------------------------
cls:
        mov ax, 0x0600
        xor cx, cx
        xor bh, 0x0f            ; white
        mov dh, 24
        mov dl, 79
        int 0x10
        mov ah, 02
        xor bh, bh
        xor dx, dx
        int 0x10        
        ret
        
        

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


;------------------------------------------------------
; putc16()
; input: 
;       si - 字符
; output:
;       none
; 描述: 
;       打印一个字符
;------------------------------------------------------
putc16:
	push bx
	xor bh, bh
	mov ax, si
	mov ah, 0Eh	
	int 10h
	pop bx
	ret

;------------------------------------------------------
; println16()
; input:
;       none
; output:
;       none
; 描述: 
;       打印换行
;------------------------------------------------------
println16:
	mov si, 13
	call putc16
	mov si, 10
	call putc16
	ret

;------------------------------------------------------
; puts16()
; input: 
;       si - 字符串
; output:
;       none
; 描述: 
;       打印字符串信息
;------------------------------------------------------
puts16:
	pusha
	mov ah, 0Eh
	xor bh, bh	

do_puts16.loop:	
	lodsb
	test al,al
	jz do_puts16.done
	int 10h
	jmp do_puts16.loop

do_puts16.done:	
	popa
	ret	
	
	
;------------------------------------------------------
; hex_to_char()
; input:
;       si - Hex number
; ouput:
;       ax - 字符
; 描述:
;       将 Hex 数字转换为对应的字符
;------------------------------------------------------
hex_to_char16:
	push si
	and si, 0Fh
	movzx ax, BYTE [Crt16.Chars + si]
	pop si
	ret
	
	
;------------------------------------------------------
; convert_word_into_buffer()
; input:
;       si - 需转换的数(word size)
;       di - 目标串 buffer(最短需要 5 bytes, 包括 0)
; 描述: 
;       将一个WORD转换为字符串, 放入提供的 buffer 内
;------------------------------------------------------
convert_word_into_buffer:
	push cx
	push si
	mov cx, 4                                       ; 4 个 half-byte
convert_word_into_buffer.loop:
	rol si, 4                                       ; 高4位 --> 低 4位
	call hex_to_char16
	mov BYTE [di], al
	inc di
	dec cx
	jnz convert_word_into_buffer.loop
	mov BYTE [di], 0
	pop si
	pop cx
	ret

;------------------------------------------------------
; convert_dword_into_buffer()
; input:
;       esi - 需转换的数(dword size)
;       di - 目标串 buffer(最短需要 9 bytes, 包括 0)
; 描述: 
;       将一个WORD转换为字符串, 放入提供的 buffer 内
;------------------------------------------------------
convert_dword_into_buffer:
	push cx
	push esi
	mov cx, 8					; 8 个 half-byte
convert_dword_into_buffer.loop:
	rol esi, 4					; 高4位 --> 低 4位
	call hex_to_char16
	mov BYTE [di], al
	inc di
	dec cx
	jnz convert_dword_into_buffer.loop
	mov BYTE [di], 0
	pop esi
	pop cx
	ret

;------------------------------------------------------
; check_cpuid()
; output:
;       1 - support,  0 - no support
; 描述:
;       检查是否支持 CPUID 指令
;------------------------------------------------------
check_cpuid:
	pushfd                                          ; save eflags DWORD size
	mov eax, DWORD [esp]                            ; get old eflags
	xor DWORD [esp], 0x200000                       ; xor the eflags.ID bit
	popfd                                           ; set eflags register
	pushfd                                          ; save eflags again
	pop ebx                                         ; get new eflags
	cmp eax, ebx                                    ; test eflags.ID has been modify
	setnz al                                        ; OK! support CPUID instruction
	movzx eax, al
	ret


;------------------------------------------------------
; ccheck_cpu_environment()
; input:
;       none
; output:
;       none
; 描述: 
;       检查是否支持 x64
;------------------------------------------------------
check_cpu_environment:
        mov eax, [CpuIndex]
        cmp eax, 16
        jb check_cpu_environment.check_x64
        hlt
        jmp $-1
check_cpu_environment.check_x64:
        mov eax, 80000000h
        cpuid
        cmp eax, 80000001h
        jb check_cpu_environment.no_support

        mov eax, 80000001h
        cpuid 
        bt edx, 29
        jc check_cpu_environment.done

check_cpu_environment.no_support:
        mov si, SDA.ErrMsg2
        call puts16
        hlt
        RESET_CPU

check_cpu_environment.done:
        ret    



;------------------------------------------------------
; get_system_memory()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 得到内存 size, 保存在 MMap.Size 里
;------------------------------------------------------
get_system_memory:
        push ebx
        push ecx
        push edx
        
;;
;; 常量定义
;;
SMAP_SIGN       EQU     534D4150h
MMAP_AVAILABLE  EQU     01h
MMAP_RESERVED   EQU     02h
MMAP_ACPI       EQU     03h
MMAP_NVS        EQU     04h




        xor ebx, ebx                            ; 第 1 次迭代
        mov edi, MMap.Base        
        
        ;;
        ;; 查询 memory map
        ;;
get_system_memory.loop:      
        mov eax, 0E820h
        mov edx, SMAP_SIGN
        mov ecx, 20
        int 15h
        jc get_system_memory.done
        
        cmp eax, SMAP_SIGN
        jne get_system_memory.done
        
        mov eax, [MMap.Type]
        cmp eax, MMAP_AVAILABLE
        jne get_system_memory.next
        
        mov eax, [MMap.Length]
        mov edx, [MMap.Length + 4]
        add [MMap.Size], eax
        adc [MMap.Size + 4], edx
        
get_system_memory.next:
        test ebx, ebx
        jnz get_system_memory.loop
        
get_system_memory.done:
        pop edx
        pop ecx
        pop ebx        
        ret
        


;------------------------------------------------------
; unreal_mode_enter()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 在 16 位 real mode 环境下使用
;       2) 函数返回后, 进入 32位 unreal mode, 使用 4G 段限
;------------------------------------------------------
unreal_mode_enter:
        push ebp
        push edx
        push ecx
        push ebx
               
        mov cx, ds
        
        ;;
        ;; 计算进入保护模式和返回实模式入口点地址
        ;;        
        call _TARGET
_TARGET  EQU     $
        pop ax
        mov bx, ax
        add ax, (_RETURN_TARGET - _TARGET)                      ; 返回实模式入口偏移量
        add bx, (_ENTER_TARGET - _TARGET)                       ; 进入保护模式入口偏移量
          
        ;;
        ;; 保存原 GDT pointer
        ;;
        sub esp, 6
        sgdt [esp]
        
        ;;
        ;; 压入返回实模式的 far pointer(16:16)
        ;;
        push cs
        push ax
      
        
        ;;
        ;; 记录返回到实模式前的 stack pointer 值
        ;;        
        mov ebp, esp
        
        ;;
        ;; 压入 code descriptor
        ;;
        mov ax, cs
        xor edx, edx
        shld edx, eax, 20
        shl eax, 20
        or eax, 0000FFFFh                                       ; limit = 4G, base = cs << 4
        or edx, 00CF9A00h                                       ; DPL = 0, P = 1,　32-bit code segment
        ;or edx, 008F9A00h
        push edx
        push eax
        
        ;;
        ;; 压入 data descriptor
        ;;
        mov ax, ds
        xor edx, edx       
        shld edx, eax, 20
        shl eax, 20
        or eax, 0000FFFFh                                       ; limit = 4G, base = ds << 4
        or edx, 00CF9200h                                       ; DPL = 0, P = 1, 32-bit data segment
        push edx
        push eax
        
        ;;
        ;; 压入 NULL descriptor
        ;;
        xor eax, eax
        push eax
        push eax    

        
        ;;
        ;; 必须保证 ds = ss
        ;;
        mov ax, ss
        mov ds, ax
        
        ;;
        ;; 压入　GDT pointer(16:32)
        ;;
        push esp
        push WORD (3 * 8 - 1)
        
        ;;
        ;; 加载 GDT
        ;;
        lgdt [esp]
        
        ;;
        ;; 切换到 32 位保护模式
        ;;
        mov eax, cr0
        bts eax, 0
        mov cr0, eax
        
        ;;
        ;; 转入保护模式(此处 operand size = 16)
        ;;
        push 10h
        push bx
        retf
       


;;
;; 32 位保护模式入口
;;

_ENTER_TARGET   EQU     $

        bits 32
        ;bits 16
        
        ;;
        ;; 更新 segment
        ;;
        mov ax, 08
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ss, ax
        mov esp, ebp
        
        ;;
        ;; 关闭保护模式
        ;;
        mov eax, cr0
        btr eax, 0
        mov cr0, eax
        
        ;;
        ;; 返回到实模式(此处 operand size = 32)
        ;; 因此: 使用 66h 来调整到 16 位 operand
        ;;
        DB 66h
        retf
        ;retf

        
_RETURN_TARGET  EQU     $

        ;;
        ;; 恢复原 data segment 值
        ;;
        mov ds, cx
        mov es, cx
        mov fs, cx
        mov gs, cx
        mov ss, cx
        
        ;;
        ;; 恢复原 GDT pointer 值
        ;;
        lgdt [esp]
        add esp, 6
        
        pop ebx
        pop ecx
        pop edx
        pop ebp
        
        ;;
        ;; 此处是 32-bit operand size
        ;; 因此: 需使用 16 位的返回地址
        ;;
        DB 66h
        ret
        

;------------------------------------------------------
; protected_mode_enter()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 函数将切换到保护模式
;       2) 加载为 FS 设置的描述符
;------------------------------------------------------
        bits 16
        
protected_mode_enter:
	    pop ax
        push esp
        push ebp
        push edx
        push ecx
        push ebx

        xor ebx, ebx
        xor edi, edi
	    movzx eax, ax
                
        ;;
        ;; 计算进入保护模式和返回实模式入口点地址
        ;;        
        call _TARGET1
_TARGET1 EQU $
        pop bx

        mov di, cs
        shl edi, 4
    	lea ebx, [edi+ebx+_TARGET2-_TARGET1]
	    mov [cs:_OFFSET], ebx
	    lea ebx, [eax+edi]

        
        ;;
        ;; 记录返回到实模式前的 stack pointer 值
        ;;        
	    mov ax, ss
	    shl eax, 4
        lea ebp, [esp+eax]

	    ;;
        ;; 设置临时的 GDT 表, 并加载 GDT   
	    ;;
	    mov esi, [CpuIndex]
        shl esi, 7
        add esi, setup.Gdt
	    call set_stage1_gdt 
        lgdt [eax]


        ;;
        ;; 切换到 32 位保护模式
        ;;
        mov eax, cr0
        bts eax, 0
        mov cr0, eax

        DB 66H, 0EAh
_OFFSET:
        DD 0
        DW KernelCsSelector32



;;
;; 32 位保护模式入口
;;

_TARGET2  EQU     $

        bits 32

        ;;
        ;; 更新 segment
        ;;
        mov ax, FsSelector
        mov fs, ax        
        mov ax, GsSelector
        mov gs, ax
        mov ax, KernelSsSelector32
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov esp, ebp
        mov ax, TssSelector32
        ltr ax
        mov eax, [CpuIndex]
        shl eax, 13
        lea eax, [eax+KERNEL_STACK_PHYSICAL_BASE+1FF0h]
        mov [esp+10h], eax
        mov eax, ebx
        pop ebx
        pop ecx
        pop edx
        pop ebp
        pop esp
        jmp eax        



;------------------------------------------------------
; get_spin_lock16()
; input:
;       esi - lock
; output:
;       none
; 描述:
;       1) 此函数用来获得自旋锁
;       2) 输入参数为 spin lock 地址
;------------------------------------------------------
get_spin_lock16:
        ;;
        ;; 自旋锁操作方法说明:
        ;; 1) 使用 bts 指令, 如下面指令序列
        ;;    lock bts DWORD [esi], 0
        ;;    jnc AcquireLockOk
        ;;
        ;; 2) 本例中使用 cmpxchg 指令
        ;;    lock cmpxchg [esi], edi
        ;;    jnc AcquireLockOk
        ;;    
        
        xor eax, eax
        mov edi, 1        
        
        ;;
        ;; 尝试获取 lock
        ;;
get_spink_lock16.acquire:
        lock cmpxchg [esi], edi
        je get_spink_lock16.done

        ;;
        ;; 获取失败后, 检查 lock 是否开放(未上锁)
        ;; 1) 是, 则再次执行获取锁, 并上锁
        ;; 2) 否, 继续不断地检查 lock, 直到 lock 开放
        ;;
get_spink_lock16.check:        
        mov eax, [esi]
        test eax, eax
        jz get_spink_lock16.acquire
        pause
        jmp get_spink_lock16.check
        
get_spink_lock16.done:                
        ret
        


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
        buffer_selector         DW      0               ; 默认 buffer 为 0
        start_sector            DQ      0               ; start sector


Crt16.Chars     DB      '0123456789ABCDEF', 0

