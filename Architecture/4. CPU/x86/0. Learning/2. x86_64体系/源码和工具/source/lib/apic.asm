; apic.asm
; Copyright (c) 2009-2012 邓志
; All rights reserved.

%include "..\inc\apic.inc"


;-----------------------------------------------------
; support_apic(): 检测是否支持 APIC on Chip的 local APIC
;----------------------------------------------------
support_apic:
	mov eax, 1
	cpuid
	bt edx, 9				; APIC bit 
	setc al
	movzx eax, al
	ret

;--------------------------------------------
; support_x2apic(): 检则是否支持 x2apic
;--------------------------------------------
support_x2apic:
	mov eax, 1
	cpuid
	bt ecx, 21
	setc al					; x2APIC bit
	movzx eax, al
	ret	

;-------------------------------------
; enable_apic(): 开启 apic
; output:
;       0 - failure, other - success
;------------------------------------
enable_apic:
        call support_x2apic
        test eax, eax
        jz check_support_apic
        call enable_x2apic
        jmp enable_apic_done
check_support_apic:
        call support_apic
        test eax, eax
        jz enable_apic_failure
        call set_apic
enable_apic_done:
        bts DWORD [APIC_BASE + SVR], 8          ; SVR.enable = 1
enable_apic_failure:
        ret


disable_apic:
	btr DWORD [APIC_BASE + SVR], 8		; SVR.enable=0
        ret

;--------------------------------
; enable_xapic()
;--------------------------------
enable_xapic:
	bts DWORD [APIC_BASE + SVR], 8		; SVR.enable=1
	ret


;-------------------------------
; enable_x2apic():
;------------------------------
enable_x2apic:
	mov ecx, IA32_APIC_BASE
	rdmsr
	or eax, 0xc00						; bit 10, bit 11 置位
	wrmsr
	ret
	
;-------------------------------
; disable_x2apic():
;-------------------------------
disable_x2apic:
	mov ecx, IA32_APIC_BASE
	rdmsr
	and eax, 0xfffff3ff					; bit 10, bit 11 清位
	wrmsr
	ret	


;------------------------------
; reset_apic(): 清掉 local apic
;------------------------------
reset_apic:
	mov ecx, IA32_APIC_BASE
	rdmsr
	btr eax, 11							; clear xAPIC enable flag
	wrmsr
	ret

;---------------------------------
; set_apic(): 开启 apic
;---------------------------------
set_apic:
	mov ecx, IA32_APIC_BASE
	rdmsr
	bts eax, 11							; enable = 1
	wrmsr
	ret
	
;------------------------------------
; set_apic_base(): 设置 APIC base地址
; input:
;		esi: 低 32 位,  edi: 高半部分
;------------------------------------
set_apic_base:
	call get_MAXPHYADDR						; 得到 MAXPHYADDR 值
	mov ecx, 64
	sub ecx, eax
	shl edi, cl
	shr edi, cl							; 去掉 MAXPHYADDR 以上的位
	mov ecx, IA32_APIC_BASE
	rdmsr
	mov edx, edi
	and esi, 0xfffff000
	and eax, 0x00000fff						; 保持原来的 IA32_APIC_BASE 寄存器低 12 位
	or eax, esi
	wrmsr
	ret

;--------------------------------------
; get_apic_base(): 
; output:
;		edx: 高半部分, 　eax: 低32位
;--------------------------------------	
get_apic_base:
	mov ecx, IA32_APIC_BASE
	rdmsr
	and eax, 0xfffff000
	ret


;-----------------------------------------------------------------------------
; get_logical_processor_count(): 获得 package(处理器)中的逻辑 processor 数量
;-----------------------------------------------------------------------------
get_logical_processor_count:
	mov eax, 1
	cpuid
	mov eax, ebx
	shr eax, 16
	and eax, 0xff				; EBX[23:16]
	ret

get_processor_core_count:
	mov eax, 4					; main-leaf
	mov ecx, 0					; sub-leaf
	cpuid
	shr eax, 26
	inc eax						; EAX[31:26] + 1
	ret
		

;-------------------------------------
; get_apic_id(): 得到 initial apic id
;-------------------------------------
get_apic_id:
	mov eax, 1
	cpuid
	mov eax, ebx
	shr eax, 24
	ret

;---------------------------------------
; get_x2apic_id(): 得到 x2APIC ID
;---------------------------------------
get_x2apic_id:
	mov eax, 11
	cpuid
	mov eax, edx			; 返回 x2APIC ID
	ret

;-------------------------------------------------
; get_x2apic_id_level(): 得到 x2APIC ID 的 leve 数
;-------------------------------------------------
get_x2apic_id_level:
	mov esi, 0
enumerate_loop:	
	mov ecx, esi
	mov eax, 11
	cpuid
	inc esi
	movzx eax, cl			; ECX[7:0]
	shr ecx, 8
	and ecx, 0xff			; 测试 ECX[15:8]
	jnz enumerate_loop		; ECX[15:8] != 0 时, 重复迭代
	ret
	
;-----------------------------------------------------
; get_mask_width(): 得到 mask width, 使用于 xAPIC ID中
; input:
;		esi: maximum count(SMT 或 core 的最大 count 值)
; output:
;		eax: mask width
;-------------------------------------------------------
get_mask_width:
	xor eax, eax			; 清目标寄存器, 用于MSB不为1时
	bsr eax, esi			; 查找 count 中的 MSB 位
	ret
	
	
;------------------------------------------------------------------
; extrac_xapic_id(): 从 8 位的 xAPIC ID 里提取 package, core, smt 值
;-------------------------------------------------------------------	
extrac_xapic_id:
	jmp do_extrac_xapic_id
current_apic_id		dd	0	
do_extrac_xapic_id:	
	push ecx
	push edx
	push ebx

	call get_apic_id						; 得到 xAPIC ID 值
	mov [current_apic_id], eax				; 保存 xAPIC ID

;; 计算 SMT_MASK_WIDTH 和 SMT_SELECT_MASK	
	call get_logical_processor_count		; 得到 logical processor 最大计数值
	mov esi, eax
	call get_mask_width						; 得到 SMT_MASK_WIDTH
	mov edx, [current_apic_id]
	mov [xapic_smt_mask_width + edx * 4], eax
	mov ecx, eax
	mov ebx, 0xFFFFFFFF
	shl ebx, cl								; 得到 SMT_SELECT_MASK
	not ebx
	mov [xapic_smt_select_mask + edx * 4], ebx
	
;; 计算 CORE_MASK_WIDTH 和 CORE_SELECT_MASK 
	call get_processor_core_count
	mov esi, eax
	call get_mask_width						; 得到 CORE_MASK_WIDTH
	mov edx, [current_apic_id]	
	mov [xapic_core_mask_width + edx * 4], eax
	mov ecx, [xapic_smt_mask_width + edx * 4]
	add ecx, eax							; CORE_MASK_WIDTH + SMT_MASK_WIDTH
	mov eax, 32
	sub eax, ecx
	mov [xapic_package_mask_width + edx * 4], eax		; 保存 PACKAGE_MASK_WIDTH
	mov ebx, 0xFFFFFFFF
	shl ebx, cl
	mov [xapic_package_select_mask + edx * 4], ebx		; 保存 PACKAGE_SELECT_MASK
	not ebx									; ~(-1 << (CORE_MASK_WIDTH + SMT_MASK_WIDTH))
	mov eax, [xapic_smt_select_mask + edx * 4]
	xor ebx, eax							; ~(-1 << (CORE_MASK_WIDTH + SMT_MASK_WIDTH)) ^ SMT_SELECT_MASK
	mov [xapic_core_select_mask + edx * 4], ebx
	
;; 提取 SMT_ID, CORE_ID, PACKAGE_ID
	mov ebx, edx							; apic id
	mov eax, [xapic_smt_select_mask]
	and eax, edx							; APIC_ID & SMT_SELECT_MASK
	mov [xapic_smt_id + edx * 4], eax
	mov eax, [xapic_core_select_mask]
	and eax, edx							; APIC_ID & CORE_SELECT_MASK
	mov cl, [xapic_smt_mask_width]
	shr eax, cl								; APIC_ID & CORE_SELECT_MASK >> SMT_MASK_WIDTH
	mov [xapic_core_id + edx * 4], eax
	mov eax, [xapic_package_select_mask]
	and eax, edx							; APIC_ID & PACKAGE_SELECT_MASK
	mov cl, [xapic_package_mask_width]
	shr eax, cl
	mov [xapic_package_id + edx * 4], eax

	pop ebx
	pop edx
	pop ecx
	ret
	
		
;-------------------------------------------------------------
; extrac_x2apic_id(): 从 x2APIC_ID 里提取 package, core, smt 值
;-------------------------------------------------------------
extrac_x2apic_id:
	push ecx
	push edx
	push ebx

; 测试是否支持 leaf 11
	mov eax, 0
	cpuid
	cmp eax, 11
	jb extrac_x2apic_id_done
	
	xor esi, esi
	
do_extrac_loop:	
	mov ecx, esi
	mov eax, 11
	cpuid	
	mov [x2apic_id + edx * 4], edx				; 保存 x2apic id
	shr ecx, 8
	and ecx, 0xff								; level 类型
	jz do_extrac_subid
	
	cmp ecx, 1									; SMT level
	je extrac_smt
	cmp ecx, 2									; core level
	jne do_extrac_loop_next

;; 计算 core mask	
	and eax, 0x1f
	mov [x2apic_core_mask_width + edx * 4], eax	; 保存 CORE_MASK_WIDTH
	mov ebx, 32
	sub ebx, eax
	mov [x2apic_package_mask_width + edx * 4], ebx	; 保存 package_mask_width
	mov cl, al
	mov ebx, 0xFFFFFFFF							;
	shl ebx, cl									; -1 << CORE_MASK_WIDTH
	mov [x2apic_package_select_mask + edx * 4], ebx		; 保存 package_select_mask
	not ebx										; ~(-1 << CORE_MASK_WIDTH)
	xor ebx, [x2apic_smt_select_mask + edx * 4]					; ~(-1 << CORE_MASK_WIDTH) ^ SMT_SELECT_MASK
	mov [x2apic_core_select_mask + edx * 4], ebx					; 保存 CORE_SELECT_MASK
	jmp do_extrac_loop_next

;; 计算 smt mask	
extrac_smt:
	and eax, 0x1f
	mov [x2apic_smt_mask_width + edx * 4], eax					; 保存 SMT_MASK_WIDTH
	mov cl, al
	mov ebx, 0xFFFFFFFF
	shl ebx, cl									; (-1) << SMT_MASK_WIDTH
	not ebx										; ~(-1 << SMT_MASK_WIDTH)
	mov [x2apic_smt_select_mask + edx * 4], ebx					; 保存 SMT_SELECT_MASK

do_extrac_loop_next:
	inc esi
	jmp do_extrac_loop
	
;; 提取 SMT_ID, CORE_ID 以及 PACKAGE_ID
do_extrac_subid:
	mov eax, [x2apic_id + edx * 4]
	mov ebx, [x2apic_smt_select_mask]
	and ebx, eax								; x2APIC_ID & SMT_SELECT_MASK
	mov [x2apic_smt_id + eax * 4], ebx
	mov ebx, [x2apic_core_select_mask]
	and ebx, eax								; x2APIC_ID & CORE_SELECT_MASK
	mov cl, [x2apic_smt_mask_width]
	shr ebx, cl									; (x2APIC_ID & CORE_SELECT_MASK) >> SMT_MASK_WIDTH
	mov [x2apic_core_id + eax * 4], ebx
	mov ebx, [x2apic_package_select_mask]
	and ebx, eax								; x2APIC_ID & PACKAGE_SELECT_MASK
	mov cl, [x2apic_core_mask_width]
	shr ebx, cl									; (x2APIC_ID & PACKAGE_SELECT_MASK) >> CORE_MASK_WIDTH
	mov [x2apic_package_id + eax * 4], ebx		; 
	
extrac_x2apic_id_done:	
	pop ebx
	pop edx
	pop ecx
	ret
			
	
		
;-----------------------------------
; read_esr(): 读 ESR 寄存器
;-----------------------------------
read_esr:
	mov DWORD [APIC_BASE + ESR], 0		; 写 ESR 寄存器
	mov eax, [APIC_BASE + ESR]
	ret


;-------------------------------------
; 打印 ISR
;-------------------------------------
dump_isr:
	mov esi, inr
	call puts
	mov esi, [APIC_BASE + ISR7]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + ISR6]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + ISR5]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + ISR4]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + ISR3]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + ISR2]
	call print_dword_value
	mov esi, '_'
	call putc		
	mov esi, [APIC_BASE + ISR1]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + ISR0]
	call print_dword_value
	call println
	ret
	
;-----------------------------
; 打印 IRR
;-----------------------------	
dump_irr:
	mov esi, irr
	call puts
	mov esi, [APIC_BASE + IRR7]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + IRR6]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + IRR5]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + IRR4]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + IRR3]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + IRR2]
	call print_dword_value
	mov esi, '_'
	call putc		
	mov esi, [APIC_BASE + IRR1]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + IRR0]
	call print_dword_value
	call println
	ret
		
;--------------------------
; 打印 TMR
;-------------------------		
dump_tmr:
	mov esi, tmr
	call puts
	mov esi, [APIC_BASE + TMR7]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + TMR6]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + TMR5]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + TMR4]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + TMR3]
	call print_dword_value
	mov esi, '_'
	call putc
	mov esi, [APIC_BASE + TMR2]
	call print_dword_value
	mov esi, '_'
	call putc		
	mov esi, [APIC_BASE + TMR1]
	call print_dword_value
	mov esi, '_'
	call putc	
	mov esi, [APIC_BASE + TMR0]
	call print_dword_value
	call println
	ret		
	
;--------------------------------
; 打印 LVT 表寄存器
;--------------------------------
dump_lvt:
	mov esi, lvt_msg
	call puts
	mov esi, lvt_cmci
	call puts
	mov esi, [APIC_BASE + LVT_CMCI]
	call print_dword_value
	mov esi, lvt_timer
	call puts
	mov esi, [APIC_BASE + LVT_TIMER]
	call print_dword_value	
	mov esi, lvt_thermal
	call puts
	mov esi, [APIC_BASE + LVT_THERMAL]
	call print_dword_value	
	call println
	mov esi, lvt_perfmon
	call puts
	mov esi, [APIC_BASE + LVT_PERFMON]
	call print_dword_value	
	mov esi, lvt_lint0
	call puts
	mov esi, [APIC_BASE + LVT_LINT0]
	call print_dword_value	
	mov esi, lvt_lint1
	call puts
	mov esi, [APIC_BASE + LVT_LINT1]
	call print_dword_value	
	call println
	mov esi, lvt_error
	call puts
	mov esi, [APIC_BASE + LVT_ERROR]
	call print_dword_value	
	call println
	ret


;------------------------------
; dump_apic(): 打印 apic寄存器信息
;--------------------------------
dump_apic:
	mov esi, apicid
	call puts
	mov esi, [APIC_BASE + APIC_ID]		
	call print_dword_value
	mov esi, apicver
	call puts
	mov esi, [APIC_BASE + APIC_VER]
	call print_dword_value
	call println
	mov esi, tpr
	call puts
	mov esi, [APIC_BASE + TPR]
	call print_dword_value
	mov esi, apr
	call puts
	mov esi, [APIC_BASE + APR]
	call print_dword_value
	mov esi, ppr
	call puts
	mov esi, [APIC_BASE + PPR]
	call print_dword_value
	call println	
	mov esi, eoi
	call puts
	mov esi, [APIC_BASE + EOI]
	call print_dword_value
	mov esi, rrd
	call puts
	mov esi, [APIC_BASE + RRD]
	call print_dword_value
	mov esi, ldr
	call puts
	mov esi, [APIC_BASE + LDR]
	call print_dword_value	
	call println
	mov esi, dfr
	call puts
	mov esi, [APIC_BASE + DFR]
	call print_dword_value	
	mov esi, svr
	call puts
	mov esi, [APIC_BASE + SVR]
	call print_dword_value	
	call println

; 打印 Interrupt Request Register
	call dump_irr
		
;; 打印 In-service register	
	call dump_isr

; 打印 tigger mode rigister
	call dump_tmr

	mov esi, esr
	call puts
	call read_esr		; 读 ESR 寄存器
	mov esi, eax
	call print_dword_value
	mov esi, icr
	call puts
	mov esi, [APIC_BASE + ICR0]	
	mov edi, [APIC_BASE + ICR1]	
	call print_qword_value
	call println
	
; 打印 LVT 表寄存器
	call dump_lvt

; 打印 APIC timer 寄存器
	mov esi, init_count
	call puts
	mov esi, [APIC_BASE + TIMER_ICR]
	call print_dword_value
	mov esi, current_count
	call puts
	mov esi, [APIC_BASE + TIMER_CCR]
	call print_dword_value
	mov esi, dcr
	call puts
	mov esi, [APIC_BASE + TIMER_DCR]
	call print_dword_value
	call println
	ret
	

;*
;* 定义多处理器环境
;*

; 处理器 index 值及 logical processor 数量
processor_index                 dd      -1
processor_count                 dd      0

;*
;* 处理器 ID 数组
;* 定义支持最多8个处理器
;*
apic_id                         dd      0, 0, 0, 0, 0, 0, 0, 0
vacant                          dd      0        
ap_init_done                    dd      0



; 定义 x2APIC ID 相关变量
x2apic_smt_mask_width		dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_smt_select_mask		dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_core_mask_width		dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_core_select_mask		dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_package_mask_width	dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_package_select_mask	dd	0, 0, 0, 0, 0, 0, 0, 0

x2apic_id			dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_package_id		dd	0, 0, 0, 0, 0, 0, 0, 0
x2apic_core_id			dd 	0, 0, 0, 0, 0, 0, 0, 0
x2apic_smt_id			dd	0, 0, 0, 0, 0, 0, 0, 0


;;; 定义 xAPIC ID 相关变量
xapic_smt_mask_width		dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_smt_select_mask		dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_core_mask_width		dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_core_select_mask		dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_package_mask_width	dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_package_select_mask	dd	0, 0, 0, 0, 0, 0, 0, 0

xapic_id			dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_package_id		dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_core_id			dd	0, 0, 0, 0, 0, 0, 0, 0
xapic_smt_id			dd 	0, 0, 0, 0, 0, 0, 0, 0



;**** 数据 *****
apicid				db	'apic ID: 0x', 0
apicver				db	'    apic version: 0x', 0
tpr					db	'TPR: 0x', 0
apr					db	'  APR: 0x', 0
ppr					db	'  PPR: 0x', 0
eoi					db	'EOI: 0x', 0	
rrd					db	'  RRD: 0x', 0
ldr					db	'  LDR: 0x', 0
dfr					db	'DFR: 0x', 0
svr					db	'  SVR: 0x', 0
inr					db	'ISR: 0x', 0
tmr					db	'TMR: 0x', 0	
irr					db	'IRR: 0x', 0
esr					db	'ESR: 0x', 0
icr					db	'  ICR: 0x', 0
lvt_msg				db	'---------------------- Local Vector Table -----------------', 10, 0
lvt_cmci			db	'CMCI: 0x', 0
lvt_timer			db	'  TIMER: 0x', 0
lvt_thermal			db	'  THERMAL: 0x', 0
lvt_perfmon			db	'PERFMON: 0x', 0
lvt_lint0			db	'  LINT0: 0x', 0
lvt_lint1			db	'  LINT1: 0x', 0
lvt_error			db	'ERROR: 0x', 0
init_count			db	'timer_ICR: 0x', 0
current_count		db	'  timer_CCR: 0x', 0
dcr					db	'  timer_DCR: 0x', 0




