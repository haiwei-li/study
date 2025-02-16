; creg.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.

%ifndef CREG_INC
%define CREG_INC

;; 打印 control register 信息

        bits 32


;---------------------------------------
; print_flags_value()
; input:
;       esi- eflags 值
;---------------------------------------
dump_flags_value:
        jmp do_print_flags_value
pfv_msg1  db '<eflags>:', 0
cf        db 'cf', 0
pf        db 'pf', 0
af        db 'af', 0
zf        db 'zf', 0
sf        db 'sf', 0 
tf        db 'tf', 0
if        db 'if', 0
df        db 'df', 0
of        db 'of', 0
iopl      db 'IOPL=', 0
nt        db 'NT', 0
rf        db 'rf', 0
vm        db 'VM', 0
ac        db 'AC', 0
vif       db 'VIF', 0
vip       db 'VIP', 0
id        db 'ID', 0

flags_table:
        dd id, vip, vif, ac, vm, rf, 0, nt, 0, 0, of, df, if, tf, sf, zf, 0, af, 0, pf, 0, cf, -1

do_print_flags_value:        
        push ebx
        push ecx
        push edx
        mov edx, esi
        
        mov esi, pfv_msg1
        call puts

; 打印 IOPL 值
        mov esi, iopl
        call puts
        mov esi, edx
        shr esi, 12
        and esi, 3
        call print_dword_decimal
        call printblank

; 打印 eflags 标志位
        mov esi, edx
        shl esi, 10
        call reverse
        mov esi, eax
        mov edi, flags_table
        call dump_flags
        call println
        pop edx
        pop ecx
        pop ebx
        ret
        
        

        



;-------------------------------------
; dump_CR0()
; input:
;                esi: CR0
;-------------------------------------        
dump_CR0:
        jmp do_dump_CR0
pe        db 'pe', 0
mp        db 'mp', 0
em         db 'em', 0
ts        db 'ts', 0
et        db 'et', 0
ne        db 'ne', 0
wp        db 'wp', 0
am        db 'am', 0
nw        db 'nw', 0
cd        db 'cd', 0
pg        db 'pg', 0

cr0_flags        dd pg, cd, nw, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                 dd am, 0, wp, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                 dd ne, et, ts, em, mp, pe, -1

dump_cr0_msg     db '<CR0>: ', 0                        
do_dump_CR0:
        push ecx
        mov ecx, esi
        mov esi, dump_cr0_msg
        call puts
        mov esi, ecx
        call reverse        
        mov esi, eax
        mov edi, cr0_flags
        call dump_flags
        call println
        pop ecx
        ret

;-------------------------------------
; dump_CR4()
; input:
;                esi: CR4
;-------------------------------------        
dump_CR4:
        jmp do_dump_CR4
vme         db 'vme', 0
pvi         db 'pvi', 0
tsd         db 'tsd', 0
de          db 'de', 0
pse         db 'pse', 0
pae         db 'pae', 0
mce         db 'mce', 0
pge         db 'pge', 0
pce         db 'pce', 0
osfxsr      db 'osfxsr', 0
osxmmexcpt  db 'osxmmexcpt', 0
vmxe        db 'vmxe', 0
smxe        db 'smxe', 0
pcide       db 'pcide', 0
osxsave     db 'osxsave', 0
smep        db 'smep', 0        
                
cr4_flags   dd 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
            dd smep, 0, osxsave, pcide, 0, 0, smxe, vmxe
            dd 0, 0, osxmmexcpt, osfxsr, pce, pge, mce, pae, pse, de, tsd, pvi,vme, -1
                        
dump_cr4_msg        db '<CR4>: ', 0                        
do_dump_CR4:
        push ecx
        mov ecx, esi
        mov esi, dump_cr4_msg
        call puts
        mov esi, ecx
        call reverse
        mov esi, eax
        mov edi, cr4_flags
        call dump_flags
        call println
        pop ecx
        ret                

%endif