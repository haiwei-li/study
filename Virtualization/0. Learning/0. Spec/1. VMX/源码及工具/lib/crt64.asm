;*************************************************
;* crt64.asm                                     *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


       
        
        bits 64
         
        
;-----------------------------------------
; clear_4k_page64()
; input:  
;       rsi - address
; output;
;       none
; 描述: 
;       1) 一次清 4K 页面
;       2) 地址在 4K 边界上
;       3) 需开启 SSE 指令支持    
;       4) 在 64-bit 下使用
;------------------------------------------        
clear_4k_page64:
        pxor xmm0, xmm0
        test rsi, rsi
        mov eax, 4096
        jz clear_4k_page64.done
        
        and rsi, ~0FFFh
        
clear_4k_page64.loop:        
        movdqa [rsi + rax - 16], xmm0
        movdqa [rsi + rax - 32], xmm0
        movdqa [rsi + rax - 48], xmm0
        movdqa [rsi + rax - 64], xmm0
        movdqa [rsi + rax - 80], xmm0
        movdqa [rsi + rax - 96], xmm0
        movdqa [rsi + rax - 112], xmm0
        movdqa [rsi + rax - 128], xmm0
        sub eax, 128
        jnz clear_4k_page64.loop
        
clear_4k_page64.done:
        ret 


;-----------------------------------------
; clear_4k_buffer64(): 清 4K 内存
; input:  
;       rsi: address
; output;
;       none
; 描述: 
;       1) 一次清 4K 页面
;       2) 地址在 4K 边界上
;       3) 使用 GPI 指令处理
;-----------------------------------------
clear_4k_buffer64:
        push rsi
        push rdi
        mov rdi, rsi
        mov esi, 1000h
        call zero_memory64
        pop rdi
        pop rsi
        ret



;-----------------------------------------
; clear_4k_page_n64(): 清 n个 4K页面
; input:  
;       rsi - address
;       rdi - count
; output;
;       none
;------------------------------------------   
clear_4k_page_n64:
        call clear_4k_page64
        add rsi, 4096
        dec edi
        jnz clear_4k_page_n64
        ret        


;-----------------------------------------
; clear_4k_buffer_n64(): 清 n个 4K 内存块
; input:  
;       rsi - address
;       rdi - count
; output;
;       none
;------------------------------------------ 
clear_4k_buffer_n64:
        call clear_4k_buffer64
        add rsi, 4096
        dec edi
        jnz clear_4k_buffer_n64
        ret        
        
        
;-------------------------------------------------------------------
; zero_memory64()
; input:
;       rsi - size
;       rdi - buffer
; output:
;       none
; 描述: 
;       1) 清内存块
;-------------------------------------------------------------------
zero_memory64:
        push rcx
        test rdi, rdi
        jz zero_memory64.done

        xor eax, eax
        
        ;;
        ;; 检查 count > 8 ?
        ;;
        cmp esi, 8
        jb zero_memory64.@1
        
        ;;
        ;; 先写入首 8 字节
        ;;
        mov [rdi], rax
        
        ;;
        ;; 计算调整到 8 字节边界上的差额, 下面原理等于 8 - (dest & 07)
        ;; 1) 例如: [2:0] = 011B(3)
        ;; 2) 取反后 = 100B(4)
        ;; 3) 加1后 = 101B(5)
        ;;
        mov ecx, esi                                    ; count 
        mov esi, edi
        not esi                                         ; 原 dest 取反
        inc esi                                         ; 
        and esi, 07h                                    ; 得到 QWORD 边界上的差额
        sub ecx, esi                                    ; c = count - 差额
        
        ;;
        ;; dest 向上调整到 QWORD 边界
        ;;
        add rdi, rsi                                    ; dest = 原 dest + 差额
        
        ;;
        ;; 以 QWORD 为单位写入
        ;;
        mov esi, ecx
        shr ecx, 3                                      ; n = c / 8
                
        ;;
        ;; 一次 8 字节 QWORD 边界上写入
        ;;        
        rep stosq


zero_memory64.@1:            
        ;;
        ;; 一次 1 字节, 写入剩余字节数
        ;;
        mov ecx, esi
        and ecx, 07h
        rep stosb
        
zero_memory64.done:        
        pop rcx
        ret   
        
        


;-------------------------------------------------
; strlen64(): 得取字符串长度
; input:
;       rsi - string
; output:
;       eax - length of string
;-------------------------------------------------
strlen64:
        push rcx
        xor eax, eax
        ;;
        ;; 输入的 string = NULL 时, 返回 0 值
        ;;
        test rsi, rsi
        jz strlen64.done
        
        ;;
        ;; 测试是否支持 SSE4.2 指令, 以及是否开启 SSE 指令执行
        ;; 选择使用 SSE4.2 版本的 strlen 指令
        ;;
        cmp DWORD [gs: PCB.SSELevel], SSE4_2
        jb strlen64.legacy
        test DWORD [gs: PCB.InstructionStatus], INST_STATUS_SSE
        jnz sse4_strlen + 1                           ; 转入执行 sse4_strlen() 


strlen64.legacy:

        ;;
        ;; 使用 legacy 方式
        ;;
        xor ecx, ecx
        mov rdi, rsi
        dec rcx                                         ; rcx = -1
        repne scasb                                     ; 循环查找 0 值
        sub rax, rcx                                    ; 0 - rcx
        dec rax
strlen64.done:
        pop rcx
        ret 
        
        
;-------------------------------------------------
; memcpy64(): 复制内存块
; input:
;       rsi - source
;       rdi - dest 
;       r8 - count
; output:
;       none
;-------------------------------------------------
memcpy64:
        push rcx
        mov rcx, r8
        shr rcx, 3
        rep movsq
        mov rcx, r8
        and ecx, 07h
        rep movsb
        pop rcx
        ret  
        
        
        
        
        
;-------------------------------------------------------------------
; get_tss_base64()
; input:
;       none
; output:
;       rax - tss 块地址
; 描述: 
;       1) 从 TSS POOL 里分配一个 TSS 块
;       2) 失败时返回 0 值
;-------------------------------------------------------------------
get_tss_base64:
        push rbx
        xor esi, esi
        mov eax, [fs: SDA.TssPoolGranularity]
        lock xadd [fs: SDA.TssPoolBase], rax
        cmp rax, [fs: SDA.TssPoolTop]
        cmovae rax, rsi
        mov rbx, rax
        mov esi, [fs: SDA.TssPoolGranularity]
        mov rdi, rbx
        call zero_memory64
        mov rax, rbx
        pop rbx
        ret
        


;-------------------------------------------------------------------
; append_gdt_descriptor64(): 往 GDT 表添加一个描述符
; input:
;       rsi - 64 位描述符
; output:
;       rax - 返回 selector 值
; 描述: 
;       1) 往 GDT 表添加一个描述符
;       2) 在 64-bit 下使用
;-------------------------------------------------------------------
append_gdt_descriptor64:
        ;;
        ;; 检查 Top 上的描述符是否为 128 位系统描述符
        ;; 1) 是: 下一条 entry = top + 16
        ;; 2) 否: 下一条 entry = top + 8
        ;;
        mov r9, [fs: SDA.GdtTop]                        ; 读取 GDT 顶端原值
        mov rax, [r9]
        bt rax, 44                                      ; 检查 S 标志位
        mov r8, 8
        mov rax, 16
        cmovc rax, r8
        add r9, rax                                     ; 指向下一条 entry
        mov [r9], rsi                                   ; 写入 GDT 
        mov [fs: SDA.GdtTop], r9                        ; 更新 gdt_top 记录
        add DWORD [fs: SDA.GdtLimit], 8                 ; 更新 gdt_limit 记录
        sub r9, [fs: SDA.GdtBase]                       ; 得到 selector 值
        mov rax, r9
        
        ;;
        ;; 下面刷新 gdtr 寄存器
        ;;
        lgdt [fs: SDA.GdtPointer]
        ret
           
           
;-------------------------------------------------------------------
; append_gdt_system_descriptor64()
; input:
;       rdi:rsi - 128 位系统描述符
; output:
;       rax - 返回 selector 值
; 描述:
;       1) 往 GDT 添加系统描述符, 包括: TSS, LDT 以及 Call-gate 描述符
;-------------------------------------------------------------------
append_gdt_system_descriptor64:
        ;;
        ;; 检查 Top 上的描述符是否为 128 位系统描述符
        ;; 1) 是: 下一条 entry = top + 16
        ;; 2) 否: 下一条 entry = top + 8
        ;;
        mov r9, [fs: SDA.GdtTop]                        ; 读取 GDT 顶端原值
        mov rax, [r9]
        bt rax, 44                                      ; 检查 S 标志位
        mov r8, 8
        mov rax, 16
        cmovc rax, r8
        add r9, rax                                     ; 指向下一条 entry
        mov [r9], rsi                                   ; 写入 GDT 
        mov [r9 + 8], rdi
        mov [fs: SDA.GdtTop], r9                        ; 更新 gdt_top 记录
        add DWORD [fs: SDA.GdtLimit], 16                ; 更新 gdt_limit 记录
        sub r9, [fs: SDA.GdtBase]                       ; 得到 selector 值
        mov rax, r9
        
        ;;
        ;; 下面刷新 gdtr 寄存器
        ;;
        lgdt [fs: SDA.GdtPointer]
        ret
            



;-------------------------------------------------------------------
; remove_gdt_descriptor64()
; input:
;       none
; output:
;       rax - 返回移除的描述符
;       rdx:rax - 128 位系统描述符
; 描述: 
;       1) 移除 GDT 表顶上的一个描述符
;       2) 返回被移除的描述符, 如果属于 system 描述符, 返回 128 位描述符
;-------------------------------------------------------------------
remove_gdt_descriptor64:
        xor r9, r9
        xor rax, rax
        ;;
        ;; 检查 GDT 表是否为空
        ;;
        mov r8, [fs: SDA.GdtTop]                        ; GDT top 指针
        cmp r8, [fs: SDA.GdtBase]
        jbe remove_gdt_descriptor64.done
        
        mov rax, [r8]                                   ; 读顶上原描述符值
        ;;
        ;; 检查是否属于 system 描述符
        ;; 
        bt rax, 44
        jnc remove_gdt_descriptor64.system
        mov [r8], r9                                    ; 清原 GDT 表项
        mov esi, 8
        jmp remove_gdt_descriptor64.next
        
remove_gdt_descriptor64.system:        
        mov rdx, [r8 + 8]
        mov [r8], r9
        mov [r8 + 8], r9
        mov esi, 16
        
remove_gdt_descriptor64.next:
        sub DWORD [fs: SDA.GdtLimit], esi               ; 更新 GDT limit
        ;;
        ;; 检查前一个 entry 是否为 system 描述符
        ;; 1) 是: 前一个 entry = top - 16
        ;; 2) 否: 前一个 entry = top - 8
        ;;
        mov rsi, [r8 - 8]
        ;;
        ;; 检查描述符类型是否为 0 
        ;;        
        shr rsi, 40
        and esi, 0Fh
        mov r9d, 8
        mov esi, 16
        cmovnz esi, r9d
              
        ;;
        ;; 更新 TOP 值
        ;;
        sub r8, rsi        
        mov [fs: SDA.GdtTop], r8
        
        ;;
        ;; 更新 GDTR
        ;;
        lgdt [fs: SDA.GdtPointer]
        
remove_gdt_descriptor64.done:        
        ret
        
        
        
        
;-------------------------------------------------------------------
; write_gdt_descriptor64()
; input:
;       esi - selector
;       rdi - 64 位描述符值
; output:
;       rax - 返回描述符地址
; 描述: 
;       根据提供的 selector 值在 GDT 表写入一个描述符
;-------------------------------------------------------------------   
write_gdt_descriptor64:
        and esi, 0FFF8h
        mov r8, [fs: SDA.GdtBase]
        add r8, rsi
        mov [r8], rdi                                   ; 写入描述符
        
        ;;
        ;; 检测及更新 GDT 的 top
        ;;
        add esi, 7
        cmp r8, [fs: SDA.GdtTop]                        ; 是否超 GDT TOP
        jbe write_gdt_descriptor64.next
        
        ;;
        ;; 大于 Top, 需更新 Top 
        ;;
        mov [fs: SDA.GdtTop], r8

write_gdt_descriptor64.next:
        ;;
        ;; 检查是否超 GDT limit
        ;;
        cmp esi, [fs: SDA.GdtLimit]
        jbe write_gdt_descriptor64.done
        
        ;;
        ;; 超 limit, 需更新 GDT limit
        ;;
        mov [fs: SDA.GdtLimit], esi
        
        ;;
        ;; 刷新 GDTR
        ;;
        lgdt [fs: SDA.GdtPointer]
        
write_gdt_descriptor64.done:        
        mov rax, r8
        ret
        
        
        
        
;-------------------------------------------------------------------
; read_gdt_descriptor64()
; input:
;       esi - selector
; output:
;       rdx:rax - 128 位系统描述符
; 描述: 
;       1) 读取 GDT 描述符项
;       2) 属于系统描述符, 则 rdx:rax 返回 128 位描述符
;       3) 失败返回 -1
;-------------------------------------------------------------------        
read_gdt_descriptor64:
        and esi, 0FFF8h
        mov r8, rsi
        add esi, 7
        xor eax, eax
        dec rax
        mov rdx, rax
        
        ;;
        ;; 检查是否超 limit
        ;;
        cmp esi, [fs: SDA.GdtLimit]
        ja read_gdt_descriptor64.done
        ;;
        ;; 读 GDT 表项
        ;;
        add r8, [fs: SDA.GdtBase]
        mov rax, [r8]
        
        ;;
        ;; 检查是否为 system 描述符
        ;;
        xor edx, edx
        bt rax, 44                                      ; S 标志位
        jc read_gdt_descriptor64.done
        
        ;;
        ;; S = 0, 属于 system 描述符
        ;;
        mov rdx, [r8 + 8]
                
read_gdt_descriptor64.done:        
        ret
        



;-------------------------------------------------------------------
; read_idt_descriptor64(): 读取 IDT 描述符
; input:
;       esi - vector  
; output:
;       rdx:rax - 成功时, 返回 128 位描述符, 失败时, 返回 -1 值
;------------------------------------------------------------------- 
read_idt_descrptor64:
        and esi, 0FFh
        shl esi, 4                                      ; vector * 16
        mov r8, rsi
        add esi, 15
        xor eax, eax
        dec rax
        mov rdx, rax
        
        ;;
        ;; 检查是否超 limit
        ;;
        cmp esi, [fs: SDA.IdtLimit]
        ja read_idt_descriptor64.done
        ;;
        ;; 读取 IDT 表项
        ;;
        add r8, [fs: SDA.IdtBase]
        mov rax, [r8]
        mov rdx, [r8 + 8]
read_idt_descriptor64.done:        
        ret




;-------------------------------------------------------------------
; write_idt_descriptor64(): 根据提供的 vector 值在 IDT 表写入一个描述符
; input:
;       esi - vector
;       rdx:rax - 128 位描述符值
; output:
;       rax - 返回描述符地址
;-------------------------------------------------------------------
write_idt_descriptor64:
        and esi, 0FFh
        shl esi, 4                                      ; vector * 16
        mov r8, [fs: SDA.IdtBase]
        add r8, rsi
        mov [r8], rax
        mov [r8 + 8], rdx
        ret
        

        
;-------------------------------------------------------------------
; mask_io_port_access64(): 屏蔽对某个端口的访问
; input:
;       esi - 端口值
; output:
;       none
;-------------------------------------------------------------------
mask_io_port_access64:
        mov r8, [gs: PCB.IomapBase]                     ; 读当前 Iomap 基址
        mov eax, esi
        shr eax, 3                                      ; port / 8
        and esi, 7                                      ; 取 byte 内位置
        bts [r8 + rax], esi                             ; 置位
        ret
        
        
;-------------------------------------------------------------------
; unmask_io_port_access(): 屏蔽对某个端口的访问
; input:
;       esi - 端口值
; output:
;       none
;-------------------------------------------------------------------
unmask_io_port_access64:
        mov r8, [gs: PCB.IomapBase]                     ; 读当前 Iomap 基址
        mov eax, esi
        shr eax, 3                                      ; port / 8
        and esi, 7                                      ; 取 byte 内位置
        btr [r8 + rax], esi                             ; 清位
        ret
        
        



        

        
;-------------------------------------------------------------------
; read_fs_base()
; input:
;       none
; output:
;       rax - fs base
; 描述: 
;       1) 读取 FS base 值
;       2) basic 版本使用 RDMSR 指令读 FS base
;       3) extended 版本使用 RDFSBASE 指令读 FS base
;-------------------------------------------------------------------
read_fs_base:
        push rcx
        push rdx
        mov ecx, IA32_FS_BASE
        jmp read_fs_gs_base.legacy
        
read_fs_base_ex:
        push rcx
        push rdx
        mov ecx, IA32_FS_BASE
        mov rax, read_fs_base.rdfsbase
        mov r8, read_fs_gs_base.legacy
        jmp rw_fs_gs_base
        
;-------------------------------------------------------------------
; read_gs_base()
; input:
;       none
; output:
;       rax - gs base
; 描述: 
;       1) 读取 GS base 值
;       2) basic 版本使用 RDMSR 指令读 GS base
;       3) extended 版本使用 RDFSBASE 指令读 GS base
;-------------------------------------------------------------------
read_gs_base:
        push rcx
        push rdx
        mov ecx, IA32_GS_BASE
        jmp read_fs_gs_base.legacy
        
read_gs_base_ex:
        push rcx
        push rdx
        mov ecx, IA32_GS_BASE        
        mov rax, read_gs_base.rdgsbase
        mov r8, read_fs_gs_base.legacy        
        jmp rw_fs_gs_base        
        

;-------------------------------------------------------------------
; write_fs_base()
; input:
;       rsi - fs base
; output:
;       none
; 描述: 
;       1) 写 FS base 值
;       2) basic 版本使用 WRMSR 指令写 FS base
;       3) extended 版本使用 WRFSBASE 指令写 FS base
;-------------------------------------------------------------------
write_fs_base:
        push rcx
        push rdx
        mov ecx, IA32_FS_BASE
        jmp write_fs_gs_base.legacy        
        
write_fs_base_ex:
        push rcx
        push rdx
        mov ecx, IA32_FS_BASE        
        mov rax, write_fs_base.wrfsbase
        mov r8, write_fs_gs_base.legacy        
        jmp rw_fs_gs_base
        
        
;-------------------------------------------------------------------
; write_gs_base()
; input:
;       rsi - gs base
; output:
;       none
; 描述: 
;       1) 写 GS base 值
;       2) basic 版本使用 WRMSR 指令写 GS base
;       3) extended 版本使用 WRGSBASE 指令写 GS base
;-------------------------------------------------------------------
write_gs_base:
        push rcx
        push rdx
        mov ecx, IA32_GS_BASE
        jmp write_fs_gs_base.legacy  

write_gs_base_ex: 
        push rcx
        push rdx
        mov ecx, IA32_GS_BASE       
        mov rax, write_gs_base.wrgsbase
        mov r8, write_fs_gs_base.legacy  

                

rw_fs_gs_base:
        
        ;;
        ;; 检查 RDWRFSBASE 指令是否可用
        ;;
        test DWORD [gs: PCB.InstructionStatus], INST_STATUS_RWFSBASE
        cmovz rax, r8
        jmp rax
        

       
read_fs_base.rdfsbase:
        ;;
        ;; 读 FS base
        ;;
        rdfsbase rax
        jmp rw_fs_gs_base.done

read_gs_base.rdgsbase:
        ;;
        ;; 读 GS base
        ;;
        rdgsbase rax
        jmp rw_fs_gs_base.done
        
write_fs_base.wrfsbase:        
        ;;
        ;; 写 FS base
        ;;
        wrfsbase rsi
        jmp rw_fs_gs_base.done
        
write_gs_base.wrgsbase:
        ;;
        ;; 写 GS base
        ;;
        wrgsbase rsi
        jmp rw_fs_gs_base.done

read_fs_gs_base.legacy:        
        ;;
        ;; 使用 legacy 方式读 FS/GS base
        ;;
        rdmsr
        shl rdx, 32
        or rax, rdx   
        jmp rw_fs_gs_base.done
        
write_fs_gs_base.legacy:                
        ;;
        ;; 使用 legacy 方式写 FS/GS base
        ;;
        shld rdx, rsi, 32
        mov eax, esi
        wrmsr       
        
rw_fs_gs_base.done:        
        pop rdx
        pop rcx
        ret        
        








;-------------------------------------------------
; bit_swap64(): 交换 qword 内的位
; input:
;       rsi - source
; output:
;       rax - dest
; 描述:
;       dest[63] <= source[0]
;       ... ...
;       dest[0]  <= source[63]
;------------------------------------------------- 
bit_swap64:
        push rcx
        mov ecx, 64
        xor eax, eax
        
        ;;
        ;; 循环移动 1 位值
        ;;
bit_swap64.loop:        
        shl rsi, 1                              ; rsi 高位移出到 CF
        rcr rax, 1                              ; CF 移入 rax 高位
        dec ecx
        jnz bit_swap64.loop
        pop rcx        
        ret
                        


        


%if 0
                                
                        
;-------------------------------------------------
; check_new_line64()
; input:
;       esi - string
; output:
;       0 - no, otherwise yes.
; 描述:
;       根据提供的字符串, 检查是否需要转换
;-------------------------------------------------          
check_new_line64:
        push rcx
        call strlen64
        mov ecx, eax                            ; 字符串长度
        shl ecx, 1                              ; length * 2
        call target_video_buffer_column64
        neg eax
        add eax, 80 * 2
        cmp eax, ecx
        jae check_new_line64.done
        ;;
        ;; 换行
        ;;
        add [fs: SDA.VideoBufferPtr], eax
check_new_line64.done:        
        pop rcx
        ret  

%endif


                 



;-------------------------------------------------
; print_hex_value64()
; input:
;       rsi - value
; output:
;       none
; 描述:
;       1) 打印 64 位十六进制数
;-------------------------------------------------
print_qword_value64:
print_hex_value64:
        push r10
        mov r10, rsi
        ;;
        ;; 打印高 32 位
        ;;
        shr rsi, 32
        call print_dword_value
        ;;
        ;; 打印低 32 位
        ;;
        mov esi, r10d
        call print_dword_value
        pop r10
        ret


;-------------------------------------------------
; print_decimal64()
; input:
;       rsi - value
; output:
;       none
; 描述:
;       打印十进制数
;-------------------------------------------------
print_decimal64:
print_dword_decimal64:
        push rdx
        push rcx
        mov rax, rsi
        mov [crt.quotient], rax
        mov ecx, 10
        
        ;;
        ;; 指向数组尾部, 从数组后面往前写
        ;;
        mov BYTE [crt.digit_array + 60], 0
        lea rsi, [crt.digit_array + 59]

print_decimal64.loop:
        dec rsi
        xor edx, edx
        div rcx                                 ; value / 10
        
        ;;
        ;; 检查商是否为 0, 为 0 时, 除 10 结束
        ;;
        test rax, rax
        cmovz rdx, [crt.quotient]
        mov [crt.quotient], rax
        lea rdx, [rdx + '0']                    ; 余数转化为字符
        mov [rsi], dl                           ; 写入余数
        jnz print_decimal64.loop
        
        ;;
        ;; 下面打印出数字串
        ;;
        call puts
        pop rcx
        pop rdx
        ret



;------------------------------------------------------
; get_spin_lock64()
; input:
;       rsi - lock
; output:
;       none
; 描述:
;       1) 此函数用来获得自旋锁
;       2) 输入参数为 spin lock 地址
;------------------------------------------------------
get_spin_lock64:
        push rdx
        ;;
        ;; 自旋锁操作方法说明:
        ;; 1) 使用 bts 指令, 如下面指令序列
        ;;    lock bts DWORD [rsi], 0
        ;;    jnc AcquireLockOk
        ;;
        ;; 2) 本例中使用 cmpxchg 指令
        ;;    lock cmpxchg [rsi], edi
        ;;    jnc AcquireLockOk
        ;;    
        
        xor eax, eax
        mov edi, 1        
        
        ;;
        ;; 尝试获取 lock
        ;;
get_spin_lock64.acquire:
        lock cmpxchg [rsi], edi
        je get_spin_lock64.done

        ;;
        ;; 获取失败后, 检查 lock 是否开放(未上锁)
        ;; 1) 是, 则再次执行获取锁, 并上锁
        ;; 2) 否, 继续不断地检查 lock, 直到 lock 开放
        ;;
get_spin_lock64.check:        
        mov eax, [rsi]
        test eax, eax
        jz get_spin_lock64.acquire
        pause
        jmp get_spin_lock64.check
        
get_spin_lock64.done:                
        pop rdx
        ret
        


;------------------------------------------------------
; delay_with_us64()
; input:
;       esi - 延时 us 数
; output:
;       none
; 描述:
;       1) 执行延时操作
;       2) 延时的单位为us(微秒)
;------------------------------------------------------
delay_with_us64:
        push rdx
        ;;
        ;; 计算 ticks 数 = us 数 * ProcessorFrequency
        ;;
        mov eax, [gs: PCB.ProcessorFrequency]
        mul esi
        mov edi, edx
        mov esi, eax

        ;;
        ;; 计算目标 ticks 值
        ;;
        rdtsc
        add esi, eax
        adc edi, edx                            ; edi:esi = 目标 ticks 值
        
        ;;
        ;; 循环比较当前 tick 与 目标 tick
        ;;
delay_with_us64.loop:
        rdtsc
        cmp edx, edi
        jne delay_with_us64.@0
        cmp eax, esi
delay_with_us64.@0:
        jb delay_with_us64.loop
        
        pop rdx
        ret
        
        
        
        

%if 0
;-----------------------------------------------------
; wait_esc_for_reset64()
; input:
;       none
; output:
;       none
; 描述:
;       1) 等待按下 <ESC> 键重启
;------------------------------------------------------
wait_esc_for_reset64:
        mov esi, 24
        mov edi, 0
        call set_video_buffer
        mov rsi, Ioapic.WaitResetMsg
        call puts64

        ;;
        ;; 等待按键
        ;;        
wait_esc_for_reset64.loop:
        call read_keyboard
        cmp al, SC_ESC
        jne wait_esc_for_reset64.loop
        
wait_esc_for_reset64.next:

        ;;
        ;; 执行 CPU RESET 操作
        ;; 1) 在真实机器上使用 INIT RESET
        ;; 2) 在vmware 上使用 CPU RESET
        ;;
        
%ifdef REAL
        ;;
        ;; 使用 INIT RESET 类型
        ;;
        mov rax, [gs: PCB.LapicBase]
        ;;
        ;; 向所有处理器广播 INIT
        ;;
        mov DWORD [rax + ICR1], 0FF000000h
        mov DWORD [rax + ICR0], 00004500h   
        
%else  
        ;;
        ;; 执行 CPU hard reset 操作
        ;;
        RESET_CPU 
%endif        
        ret
        
             
%endif        
        
 

%include "..\lib\sse64.asm"
