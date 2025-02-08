;*************************************************
;* Decode.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

%include "..\inc\Decode\opcode.inc"



;-------------------------------------------------
; Decode()
; input:
;       esi - buffer of encode
;       edi - buffer of out
; output:
;       eax - decode status code
;-------------------------------------------------
Decode:
        push ebx
        push edx

        mov eax, DECODE_STATUS_FAILURE        
        REX.Wrxb
        mov edx, esi
        
        REX.Wrxb
        test esi, esi
        jz Decode.done
        REX.Wrxb
        test edi, edi
        jz Decode.done

Decode.loop:        
        movzx ebx, BYTE [edx]                                   ; 读 opcode
        mov ebx, [DoOpcodeFuncTable + ebx * 4]                  ; 读 OpcodeInfo
        test ebx, ebx
        jz Decode.done        
        mov ebx, [ebx]                                          ; 读 DoOpcodeXX 函数
        test ebx, ebx
        jz Decode.done
        
        REX.Wrxb
        mov esi, edx
        call ebx                                                ; 调用 DoOpcodeXX(...)
        
        ;;
        ;; 是否需要继续
        ;;
        test eax, DECODE_STATUS_CONTINUE
        jz Decode.done       
        and eax, 0Fh
        REX.Wrxb
        add edx, eax
        jmp Decode.loop
        
Decode.done:
        pop edx
        pop ebx
        ret


%include "..\lib\Decode\opcode.asm"
%include "..\lib\Decode\DoOpcode.asm"