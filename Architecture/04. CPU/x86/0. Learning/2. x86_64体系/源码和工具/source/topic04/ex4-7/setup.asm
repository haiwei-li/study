; setup.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


; 这是一个空白模块示例，设为 setup 模块
; 用于写入磁盘的第 2 个扇区 ！
;

%include "..\inc\support.inc"

;
; setup 模块是运行在 16 位实模式下

        bits 16
        
        
;
; 模块开始点是 SETUP_SEG - 2，减 2 是因为要算上模块头的存放的“模块 size”
; load_module 加载到 SETUP_SEG-2，实际效果是 SETUP 模块会被加载到“入口点”即：setup_entry
;
        org SETUP_SEG - 2
        
;
; 在模块的开头 word 大小的区域里存放模块的大小，
; load_module 会根据这个 size 加载模块到内存

SETUP_BEGIN:

setup_length    dw (SETUP_END - SETUP_BEGIN)    ; SETUP_END-SETUP_BEGIN 是这个模块的 size


setup_entry:                                    ; 这是模块代码的入口点
        
        call test_CPUID
        test ax, ax
        jz no_support
        
@@1:
        mov ecx, [sub_leaves]
        mov esi, ecx
        mov di, value_address
        call get_hex_string
        mov si, msg
        call puts
        mov si, value_address
        call puts
        mov si, msg2
        call puts
        
        mov eax, 04
        cpuid
        
        
        mov [eax_value], eax
        mov [ebx_value], ebx
        mov [ecx_value], ecx
        mov [edx_value], edx
        
        inc dword [sub_leaves]
        call print_cache_info
        test eax, eax
        jnz @@1
        
        mov si, msg1
        call puts

        jmp $
        
no_support:        
        mov si, [message_table + eax * 2]
        call puts
        jmp $


sub_leaves              dd 0
msg                     db '---------- Now: ECX = 0x', 0
msg1                    db '---- END ----', 0
msg2                    db ' ----------', 13, 10, 0


eax_value               dd 0        
eax_message             db 'eax: 0x', 0
ebx_value               dd 0
ebx_message             db 'ebx: 0x', 0
ecx_value               dd 0
ecx_message             db 'ecx: 0x', 0
edx_value               dd 0
edx_message             db 'edx: 0x', 0

value_address           dd 0, 0, 0

support_message         db 'support CPUID instruction', 13, 10, 0
no_support_message      db 'no support CPUID instruction', 13, 10, 0                
message_table           dw no_support_message, support_message, 0


;------------------------------------
; print_register_value()
; input:
;                esi - regiser value
;------------------------------------
print_register_value:
        jmp do_print_register_value
        
register_value_message  db '---- Register Value Information ----', 13, 10, 0        
register_table          dw eax_value, ebx_value, ecx_value, edx_value, 0
        
do_print_register_value:
        mov si, register_value_message
        call puts
                
        xor ecx, ecx

do_print_register_value_loop:        
        movzx ebx, word [register_table + ecx * 2]
        mov esi, [ebx]
        mov di, value_address
        call get_dword_hex_string
        
        lea si, [ebx + 4]
        call puts
        mov si, value_address
        call puts
        call println
        
        inc ecx
        cmp ecx, 3
        jle do_print_register_value_loop

        ret

;------------------------------------
; print_cpu_model()
;-----------------------------------
print_cpu_model:
        jmp do_print_cpu_model
@message        db '---- Processor Model Information ----', 13, 10, 0
model           db 'Model: 0x', 0
family          db 'Family: 0x', 0
stepping        db 'Stepping: 0x', 0
type            db 'Processor Type: 0x', 0
extended_model  db 'Extended Model ID: 0x', 0
extended_family db 'Extended Family ID: 0x',0

do_print_cpu_model:
        mov si, @message
        call puts
        
        mov eax, [eax_value]
        mov esi, eax
        and esi, dword 0xf0
        shr esi, 4
        mov di, value_address
        call get_hex_string
        mov si, model
        call puts
        mov si, value_address
        call puts
        call println
        
        mov esi, eax
        and esi, dword 0xf00
        shr esi, 8
        mov di, value_address
        call get_hex_string
        mov si, family
        call puts
        mov si, value_address
        call puts
        call println        

        mov esi, eax
        and esi, dword 0x0f
        mov di, value_address
        call get_hex_string
        mov si, stepping
        call puts
        mov si, value_address
        call puts
        call println        

        mov esi, eax
        and esi, dword 0x3000
        shr esi, 12
        mov di, value_address
        call get_hex_string
        mov si, type
        call puts
        mov si, value_address
        call puts
        call println        
        ret


;------------------------------------
; print_cpu_model()
;-----------------------------------
print_cpu_clflush:
        jmp do_print_cpu_clflush
cpu_clflush_message     db '---- Cache line size & logic processors number ----', 13, 10, 0
clflush_line_size       db 'Cache line size(bytes): 0x', 0
maximum_core            db 'Logic processor: 0x',  0

do_print_cpu_clflush:
        mov si, cpu_clflush_message
        call puts
        mov ebx, [ebx_value]
        mov esi, ebx
        and esi, dword 0xf00
        shr esi, 8
        lea esi, [esi*8]
        mov di, value_address
        call get_hex_string
        mov si, clflush_line_size 
        call puts
        mov si, value_address
        call puts
        call println
        mov esi, ebx
        and esi, dword 0xf0000
        shr esi, 16
        mov di, value_address
        call get_hex_string
        mov si, maximum_core
        call puts
        mov si, value_address
        call puts
        call println
        ret
        
        
;------------------------------------
; print_cache_model()
;-----------------------------------
print_cache_info:
        jmp do_print_cache_info
        
data_cache              db 'Data Cache', 0
instruction_cache       db 'Instruction Cache', 0
unified_cache           db 'Unified Cache', 0
cache_message_table     dw 0, data_cache, instruction_cache, unified_cache, 0

line_size               dd 0
partitions              dd 0
ways                    dd 0
set                     dd 0

cache_type              db 'cache type:  ', 0
cache_level             db 'cache level:  0x', 0
cache_size              db 'cache size:  0x', 0
cache_ways              db 'ways:  0x', 0
cache_sets              db 'sets:  0x', 0

do_print_cache_info:
        push ebx
        push ecx
        push edx
        
        mov eax, [ebx_value]
        mov ebx, eax
        and ebx, 0x0fff
        inc ebx
        mov [line_size], ebx            ; get line size
        mov ebx, eax
        and ebx, 0x3ff000
        shr ebx, 12                                                
        inc ebx
        mov [partitions], ebx           ; get line partitions
        mov ebx, eax
        shr ebx, 22
        inc ebx
        mov [ways], ebx                 ; get ways
        mov eax, [ecx_value]
        inc eax
        mov [set], eax                  ; get sets
        
        mov ebx, [eax_value]
        mov eax, ebx
        and eax, 0x0f
        test eax, eax
        jz do_print_cache_info_done
        push eax
        
; 打印 cache type
        mov si, cache_type
        call puts        
        mov si, word [cache_message_table + eax * 2]
        call puts
        call println

; 打印 cache level
        mov si, cache_level
        call puts
        mov esi, ebx
        and esi, 0xe0
        shr esi, 5
        mov di, value_address
        call get_hex_string
        mov si, value_address
        call puts
        call println

; 打印 cache size
        mov si, cache_size
        call puts

;; 计算 cache size 值
; cache size = line_size * partions * ways * sets
        xor edx, edx
        mov eax, [line_size]
        mov ebx, [partitions]
        mul ebx
        mov ebx, [ways]        
        mul ebx
        mov ebx, [set]
        mul ebx
        
        mov esi, eax
        mov di, value_address
        call get_dword_hex_string
        mov si, value_address
        call puts
        call println
        
; 打印 cache ways
        mov si, cache_ways
        call puts
        mov esi, [ways]
        mov di, value_address
        call get_hex_string;
        mov si, value_address
        call puts
        call println
        
; 打印 cache sets        
        mov si, cache_sets
        call puts
        mov esi, [set]
        mov di, value_address
        call get_dword_hex_string;
        mov si, value_address
        call puts
        call println
        
        pop eax
do_print_cache_info_done:        
        pop edx
        pop ecx
        pop ebx
        ret
        
;
; 以下是这个模块的函数导入表
; 使用了 lib16 库的里的函数

FUNCTION_IMPORT_TABLE:

puts:                   jmp LIB16_SEG + LIB16_PUTS * 3
putc:                   jmp LIB16_SEG + LIB16_PUTC * 3
get_hex_string:         jmp LIB16_SEG + LIB16_GET_HEX_STRING * 3
test_CPUID:             jmp LIB16_SEG + LIB16_TEST_CPUID * 3
get_dword_hex_string:   jmp LIB16_SEG + LIB16_GET_DWORD_HEX_STRING * 3
println                 jmp LIB16_SEG + LIB16_PRINTLN * 3


SETUP_END:

; end of setup        