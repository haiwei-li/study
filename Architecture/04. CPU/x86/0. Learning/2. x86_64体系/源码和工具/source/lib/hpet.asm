; hpet.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.



;------------------------------------
; enable_hpet(): 开启 HPET(高精度定时器)
;------------------------------------
enable_hpet:
      
;* 
;* 读取 HPET 配置寄存器
;* Address Enable 位置位, 开启 HPET 地址
;* Address Select 域设置为 00B, HPET 基址位于 0FED00000h
;
        call get_root_complex_base_address
        mov esi, [eax + 3404h]
        bts esi, 7                      ; address enable 位
        and esi, 0FFFFFFFCh             ; address select = 00B
        mov [eax + 3404h], esi
;*
;* 设置 HPET 的配置寄存器
;*
;* legacy replacement rout = 1 时:
;*      1. timer0 转发到 IOAPIC IRQ2
;*      2. timer1 转发到 IOAPIC IRQ8
;*
;* overall enable 必须设为 1
;*
        mov eax, 3                      ; Overall Enable = 1, legacy replacement rout = 1
        mov [HPET_BASE + 10h], eax

;*
;* 初始化 HPET timer 配置
;*
        call init_hpet_timer
        ret


;------------------------------------------
; init_hpet_timer(): 初始化 8 个 timer
;------------------------------------------
init_hpet_timer:
;*
;* HPET 配置说明:
;*
;* 1). timer 0 配置 routed 到 IO APIC 的 IRQ2 上
;* 2). timer 1 配置 routed 到 IO APIC 的 IRQ8 上
;* 3). timer 2, 3 配置 routed 到 IO APIC 的 IRQ20 上
;* 4). timer 4, 5, 6, 7 必须使用 direct processor message 方式
;*    而不是 routed 到 8259 或 IO APIC 的 IRQ
;*

        ;*
        ;* timer 0 配置为: 周期性中断, 64 位的 comparator 值
        ;*
        mov DWORD [HPET_TIMER0_CONFIG], 0000004Ch
        mov DWORD [HPET_TIMER0_CONFIG + 4], 0
        mov DWORD [HPET_TIMER1_CONFIG], 00000004h
        mov DWORD [HPET_TIMER1_CONFIG + 4], 0
        mov DWORD [HPET_TIMER2_CONFIG], 00002804h
        mov DWORD [HPET_TIMER2_CONFIG + 4], 0
        mov DWORD [HPET_TIMER3_CONFIG], 00002804h
        mov DWORD [HPET_TIMER3_CONFIG + 4], 0
        ret



;--------------------------------------------
; dump_hpet_capabilities(): 输出 HPET 能力信息
;--------------------------------------------
dump_hpet_capabilities:
        push ebx
        push edx
        mov ebx, [HPET_BASE + 0h]
        mov edx, [HPET_BASE + 4h]
        mov esi, counter_period_msg
        call puts
        mov esi, edx
        call print_dword_decimal
        call println
        mov esi, interrupt_rout_msg
        call puts
        bt ebx, 15
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        mov esi, counter_size_msg
        call puts
        bt ebx, 13
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        mov esi, timer_number_msg
        call puts
        shr ebx, 8
        and ebx, 01Fh
        lea esi, [ebx + 1]
        call print_dword_decimal
        pop edx
        pop ebx
        ret


counter_period_msg      db 'counter period:       ', 0
interrupt_rout_msg      db 'interrupt rout:       ', 0
counter_size_msg        db 'counter size(64 bit): ', 0
timer_number_msg        db 'number of timer:      ', 0

