;*************************************************
;* DoOpcode.asm                                  *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



;-------------------------------------------------
; DoOpcode48()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcode48:
        push ebp
        push ebx
        
%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif

        REX.Wrxb
        mov ebx, [ebp + SDA.DmbBase]
        test DWORD [ebx + DMB.TargetCpuMode], TARGET_CODE64
        jz DoOpcode48.@1
        or DWORD [ebx + DMB.DecodePrefixFlag], DECODE_PREFIX_REX
        mov al, [esi]                                   ; 读 encode
        mov [ebx + DMB.PrefixRex], al                   ; 保存 REX prefix
        mov eax, DECODE_STATUS_CONTINUE | 1
        jmp DoOpcode48.done
        
DoOpcode48.@1:
        mov esi, InstructionMsg48
        call strcpy
        mov BYTE [edi], ' '
        REX.Wrxb
        INCv edi
        mov esi, Register40
        call strcpy
        mov BYTE [edi], 0
        REX.Wrxb
        INCv edi
        mov eax, 1
        
DoOpcode48.done:
        pop ebx
        pop ebp
        ret



DoOpcodeB0:
        mov eax, DECODE_STATUS_FAILURE
        ret
        
DoOpcodeB1:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeB2:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeB3:
        mov eax, DECODE_STATUS_FAILURE
        ret
        
DoOpcodeB4:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeB5:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeB6:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeB7:
        mov eax, DECODE_STATUS_FAILURE
        ret


;-------------------------------------------------
; DoOpcodeB8()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcodeB8:
        push ebx
        
        REX.Wrxb
        mov ebx, esi
        mov eax, DECODE_STATUS_OUTBUFFER
        
        REX.Wrxb
        test edi, edi
        jz DoOpcodeB8.done                              ; 目标 buffer 为空
        
        mov esi, InstructionMsgB8
        call strcpy                                     ; 写入指令名
        mov BYTE [edi], ' '
        REX.Wrxb
        INCv edi
        mov esi, Register40                             ; 写入寄存器名
        call strcpy
        mov BYTE [edi], ','
        REX.Wrxb
        INCv edi
        mov esi, [ebx + 1]
        call dword_to_string                            ; 定入立即数字符串
        mov BYTE [edi], 0
        REX.Wrxb
        INCv edi        
        
        mov eax, 5                                      ; 返回 encode 长度
        
DoOpcodeB8.done:
        pop ebx        
        ret




DoOpcodeB9:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBA:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBB:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBC:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBD:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBE:
        mov eax, DECODE_STATUS_FAILURE
        ret

DoOpcodeBF:
        mov eax, DECODE_STATUS_FAILURE
        ret


;-------------------------------------------------
; DoOpcodeCD()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcodeCD:
        push ebx        
        REX.Wrxb
        mov ebx, esi
        mov esi, InstructionMsgCD
        call strcpy                                     ; 写入指令名
        mov BYTE [edi], ' '
        REX.Wrxb
        INCv edi        
        REX.Wrxb
        movzx esi, BYTE [ebx + 1]
        call byte_to_string                            ; 定入立即数字符串
        mov BYTE [edi], 0
        REX.Wrxb
        INCv edi                
        mov eax, 2                                      ; 返回 encode 长度
        pop ebx
        ret

;-------------------------------------------------
; DoOpcodeC3()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcodeC3:
        push ebx        
        REX.Wrxb
        mov ebx, esi
        mov esi, InstructionMsgC3
        call strcpy                                     ; 写入指令名
        mov BYTE [edi], 0
        REX.Wrxb
        INCv edi                
        mov eax, 1                                      ; 返回 encode 长度
        pop ebx
        ret


;-------------------------------------------------
; DoOpcodeCF()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcodeCF:
        mov esi, InstructionMsgCF
        call strcpy                                     ; 写入指令名
        mov BYTE [edi], 0
        REX.Wrxb
        INCv edi                
        mov eax, 1                                      ; 返回 encode 长度
        ret


        
        
;-------------------------------------------------
; DoOpcodeE8()
; input:
;       esi - buffer of encodes
;       edi - buffer of out
; output:
;       eax - bits 7:0 返回长度值
;             bits 31:8 返回码
;-------------------------------------------------
DoOpcodeE8:
        ret        