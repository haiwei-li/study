; cpuid.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这个模块负责打印 cpuid 返回的信息

        bits 32


;--------------------------------------------
; dump_tsc_support(): 是否支持恒率的 TSC
;--------------------------------------------
dump_tsc_support:
        jmp do_dump_tsc_support
dt_msg0 db 'TSC support:                ', 0
dt_msg1 db 'Invariant TSC support:      ', 0
dt_msg2 db 'RDTSCP instruction support: ', 0
do_dump_tsc_support:
        mov esi, dt_msg0
        call puts
        mov eax, 1
        cpuid 
        bt edx, 4                       ; TSC 位
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        mov esi, dt_msg1
        call puts
        mov eax, 80000000h
        cpuid
        cmp eax, 80000007h
        cmc
        jnc dump_tsc_support_next
        mov eax, 80000007h
        cpuid
        bt edx, 8               ; Invarint TSC 位
dump_tsc_support_next:
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        mov esi, dt_msg2
        call puts
        mov eax, 80000001h
        cpuid
        bt edx, 27              ; RDTSCP 位
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        ret





;--------------------------------------
; dump_sse_support(): 打印 SSE 环境支持
;--------------------------------------
dump_sse_support:
        jmp do_dump_sse
sse_flags       dd sse_msg0, sse_msg1, sse_msg2, sse_msg3, sse_msg4, sse_msg5, sse_msg6, sse_msg7, 0
sse_msg         db 'instruction:       support', 10, '-----------------------------', 10, 0
sse_msg0        db 'SSE:                 ', 0
sse_msg1        db 'SSE2:                ', 0
sse_msg2        db 'SSE3:                ', 0
sse_msg3        db 'SSSE3:               ', 0
sse_msg4        db 'SSE4.1:              ', 0
sse_msg5        db 'SSE4.2:              ', 0  
sse_msg6        db 'MONITOR/MWAIT:       ', 0
sse_msg7        db 'POPCNT:              ', 0
yes             db 'Yes', 10, 0
no              db 'No', 10, 0
do_dump_sse:        
        mov eax, 1
        cpuid
        bt ecx, 23              ; POPCNT 
        rcl eax, 1
        bt ecx, 3               ; MONITOR/MWAIT
        rcl eax, 1
        bt ecx, 20              ; sse4.2
        rcl eax, 1
        bt ecx, 19              ; sse4.1
        rcl eax, 1
        bt ecx, 9               ; ssse3
        rcl eax, 1
        bt ecx, 0               ; sse3
        rcl eax, 1           
        bt edx, 26              ; sse2
        rcl eax, 1
        bt edx, 25              ; sse
        rcl eax, 1
        xor ebx, ebx
        mov ecx, eax
        mov esi, sse_msg
        call puts
dump_sse_loop:        
        mov esi, [sse_flags + ebx * 4]     
        test esi, esi
        jz dump_sse_done
        call puts
        shr ecx, 1
        mov esi, yes
        mov edi, no
        cmovnc esi, edi
        call puts
        inc ebx
        jmp dump_sse_loop
dump_sse_done:        
        ret
        

;-----------------------------------------------------
; support_multi_threading(): 查询是否支持多线程或多core
;-----------------------------------------------------
support_multi_threading:
        mov eax, 1
        cpuid
        bt edx, 28                                        ; HTT 位
        setc al
        movzx eax, al
        ret

;------------------------------------------------------------
; dump_CPUID_leaf_01_edx(): 打印 CPUID.01H 返回的 EDX值
;------------------------------------------------------------
dump_CPUID_leaf_01_edx:
        jmp do_dump_CPUID_leaf_01_edx        
fpu0    db 'fpu', 0
vme0    db 'vme', 0
de0     db 'de',  0
pse0    db 'pse', 0
tsc0    db 'tsc', 0
msr0    db 'msr', 0
pae0    db 'pae', 0
mce0    db 'mce', 0
cx80    db 'cx8', 0
apic0   db 'apic', 0
sep0    db 'sep', 0
mtrr0   db 'mtrr', 0
pge0    db 'pge', 0
mca0    db 'mca', 0
cmov0   db 'cmov', 0
pat0    db 'pat', 0
pse360  db 'pse-36', 0
psn0    db 'psn', 0
clfsh0  db 'clfsh', 0
ds0     db 'ds', 0
acpi0   db 'acpi', 0
mmx0    db 'mmx', 0
fxsr0   db 'fxsr', 0
sse0    db 'sse', 0
sse20   db 'sse2', 0
ss0     db 'ss', 0
htt0    db 'htt', 0
tm0     db 'tm', 0
pbe0    db 'pbe', 0

edx_flags        dd fpu0, vme0, de0, pse0, tsc0, msr0, pae0, mce0
                 dd cx80, apic0, 0, sep0, mtrr0, pge0, mca0, cmov0
                 dd pat0, pse360, psn0, clfsh0, 0, ds0, acpi0, mmx0
                 dd fxsr0, sse0, sse20, ss0, htt0, tm0, 0, pbe0, -1

dump_edx_msg     db '<CPUID.01H:EDX>', 10, 0

do_dump_CPUID_leaf_01_edx:
        push ebx
        push ecx
        push edx
        mov esi, dump_edx_msg
        call puts
        mov eax, 01H
        cpuid
        mov esi, edx
        mov edi, edx_flags
        call dump_flags
        call println
        pop edx
        pop ecx
        pop ebx
        ret


;------------------------------------------
; dump_CPUID_leaf_01_ecx():
;------------------------------------------
dump_CPUID_leaf_01_ecx:
        jmp do_dump_CPUID_leaf_01_ecx
sse30          db 'sse3', 0
pclmuldq0      db 'pclmuldq', 0
dtes640        db 'dtes64', 0
monitor0       db 'monitor', 0
ds_cpl0        db 'ds-cpl', 0
vmx0           db 'vmx', 0
smx0           db 'smx', 0
eist0          db 'eist', 0
tm20           db 'tm2', 0
ssse30         db 'ssse3', 0
cnxt_id0       db 'cnxt-id', 0
fma0           db 'fma', 0
cx160          db 'cx16', 0
xptr0          db 'xptr', 0
pdcm0          db 'pdcm', 0
pcid0          db 'pcid', 0
dca0           db 'dca', 0
sse4_10        db 'sse4.1', 0
sse4_20        db 'sse4.2', 0
x2apic0        db 'x2apic', 0
movbe0         db 'movbe', 0
popcnt0        db 'popcnt', 0
tsc_deadline0  db 'tsc-deadline', 0
aes0           db 'aes', 0
xsave0         db 'xsave', 0
osxsave0       db 'osxsave', 0
avx0           db 'avx', 0

leaf_01_ecx_flags        dd sse30, pclmuldq0, dtes640, monitor0, ds_cpl0
                         dd vmx0, smx0, eist0, tm20, ssse30, cnxt_id0, 0
                         dd fma0, cx160, xptr0, pdcm0, 0, pcid0, dca0
                         dd sse4_10, sse4_20, x2apic0, movbe0, popcnt0
                         dd tsc_deadline0, aes0, xsave0, osxsave0, avx0
                         dd -1
                                        
dump_CPUID_leaf_01_msg   db '<CPUID.EAX=01H.ECX:>', 10, 0

do_dump_CPUID_leaf_01_ecx:        
        push ebx
        push ecx
        push edx
        mov esi, dump_CPUID_leaf_01_msg
        call puts
        mov eax, 1
        cpuid
        mov esi, ecx
        mov edi, leaf_01_ecx_flags
        call dump_flags
        call println
        pop edx
        pop ecx
        pop ebx
        ret

;-------------------------------------
; dump_CPUID_leaf_07_ebx():
;-------------------------------------
dump_CPUID_leaf_07_ebx:
        jmp do_dump_CPUID_leaf_07_ebx
fsgsbase           db 'fsgsbase', 0
smep_msg           db 'smep', 0
repmovsb_ex        db 'enhanced_movsb/stosb', 0
invpcid_msg        db 'invpcid', 0
leaf_07_ebx_flags  dd fsgsbase, 0, 0, 0, 0, 0, 0, smep_msg, 0, repmovsb_ex, invpcid_msg, -1
leaf_07_ebx_msg    db '<CPUID.07H:EBX>', 10, 0
do_dump_CPUID_leaf_07_ebx:        
        mov esi, leaf_07_ebx_msg
        call puts
        mov eax, 07H
        mov ecx, 0                        ; subleaf=0H
        cpuid
        mov esi, ebx
        mov edi, leaf_07_ebx_flags
        call dump_flags
        call println
        ret

;------------------------------------------
; dump_CPUID_leaf_80000001_edx():
;------------------------------------------
dump_CPUID_leaf_80000001_edx:
        jmp do_dump_CPUID_leaf_80000001_edx
longmode  db 'longmode', 0
rdtscp0   db 'rdtscp', 0
gpage     db '1g-page', 0
xd        db 'xd', 0
sc        db 'syscall', 0

leaf_80000001_edx_flags        dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                               dd sc, 0, 0, 0, 0, 0, 0, 0, 0
                               dd xd, 0, 0, 0, 0, 0, gpage, rdtscp0, 0, longmode, -1

leaf_80000001_edx_msg        db '<CPUID.80000001H:EDX>', 10, 0

do_dump_CPUID_leaf_80000001_edx:        
        push ebx
        push ecx
        push edx
        mov esi, leaf_80000001_edx_msg
        call puts
        mov eax, 80000001H
        cpuid
        mov esi, edx
        mov edi, leaf_80000001_edx_flags
        call dump_flags
        call println
        pop edx
        pop ecx
        pop ebx
        ret
        
        
;-------------------------------------
; dump_CPUID_leaf_05
;-------------------------------------
dump_CPUID_leaf_05:
        jmp do_dump_CUPID_leaf_05
ssize        db 'smallest monitor line size(bytes): 0x'
ssize_value  dq 0, 0
lsize        db 'largest moniotr line size(bytes): 0x'
lsize_value  dq 0, 0
extensions_support  db 'monitor/mwait extensions support? ', 0
m_msg1        db 'yes', 0
m_msg2        db 'no', 0
do_dump_CUPID_leaf_05:        
        push ebx
        push ecx
        push edx
        mov eax, 05
        cpuid
        mov esi, eax
        mov edi, ssize_value
        call get_dword_hex_string
        mov esi, ssize
        call puts
        call println
        mov esi, ebx
        mov edi, lsize_value
        call get_dword_hex_string
        mov esi, lsize
        call puts
        call println
        mov esi, extensions_support
        call puts
        mov eax, m_msg1
        mov esi, m_msg2
        bt ecx, 0
        cmovc esi, eax
        call puts
        call println
        pop edx
        pop ecx
        pop ebx
        ret
        

;---------------------------
; dump_CPUID_leaf_0a()
;---------------------------
dump_CPUID_leaf_0a:
        jmp do_dump_CPUID_leaf_0a
perfmon_version db        'perfmon version ID: ', 0
counter_number  db        'perfmon counter number: ', 0
counter_width   db        'perfmon counter width: ', 0
fixcnt_number   db        'fixed-counter number: ', 0
fixcnt_width    db        'fixed-counter width: ', 0
event_number    db        'perfmon event number: ', 0
ebx_bit0        db        'core cycle event:                  ', 0
ebx_bit1        db        'instruction retired event:         ', 0
ebx_bit2        db        'reference cycle event:             ', 0
ebx_bit3        db        'last-level cache reference event:  ', 0
ebx_bit4        db         'last-level cache misses event:     ', 0
ebx_bit5        db        'branch instruction retired event:  ', 0
ebx_bit6        db        'branch mispredict retired event:   ', 0
leaf_0a_msg1    db        '-bit', 0
leaf_0a_msg2    db        'yes', 10, 0
leaf_0a_msg3    db        'no', 10, 0
eax_value       dd 0
ebx_value       dd 0
ecx_value       dd 0
edx_value       dd 0
ebx_flags       dd ebx_bit0, ebx_bit1, ebx_bit2, ebx_bit3, ebx_bit4, ebx_bit5, ebx_bit6, 0
do_dump_CPUID_leaf_0a:
        push ebx
        push ecx
        push edx
        mov eax, 0x0a
        cpuid
        mov [eax_value], eax
        mov [ebx_value], ebx
        mov [ecx_value], ecx
        mov [edx_value], edx
        mov esi, perfmon_version
        call puts
        mov ecx, [eax_value]
        movzx esi, bl
        call print_dword_decimal
        call println
        mov esi, counter_number
        call puts
        mov esi, ecx
        shr esi, 8
        and esi, 0xff
        call print_dword_decimal
        call println
        mov esi, counter_width
        call puts
        mov esi, ecx
        shr esi, 16
        and esi, 0xff
        call print_dword_decimal
        mov esi, leaf_0a_msg1
        call puts
        call println
        
        mov ecx, [edx_value]
        mov esi, fixcnt_number
        call puts
        mov esi, ecx
        and esi, 0x1f
        call print_dword_decimal
        call println
        mov esi, fixcnt_width        
        call puts
        mov esi, ecx
        shr esi, 5
        and esi, 0xff
        call print_dword_decimal
        mov esi, leaf_0a_msg1
        call puts
        call println
        
        mov esi, event_number
        call puts
        mov esi, [eax_value]
        shr esi, 24
        and esi, 0xff
        call print_dword_decimal
        call println        
        
        mov edx, ebx_flags
        mov ecx, leaf_0a_msg3
        mov ebx, [ebx_value]
dump_CPUID_leaf_0a_loop:        
        mov esi, [edx]
        test esi, esi
        jz dump_CPUID_leaf_0a_done
        call puts
        mov esi, leaf_0a_msg2
        shr ebx, 1
        cmovc esi, ecx
        call puts
        add edx, 4
        jmp dump_CPUID_leaf_0a_loop
dump_CPUID_leaf_0a_done:                        
        pop edx
        pop ecx
        pop ebx        
        ret
        


;***** cpuid 模块的数据 *********
