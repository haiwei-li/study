;*************************************************
;* opcode.asm                                    *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************




;------------------------------------------------
; GetRegisterInfo()
; input:
;       esi - reigster ID
; output:
;       eax - Register Info pointer
;------------------------------------------------
GetRegisterInfo:
        mov eax, Register40
        lea eax, [eax + esi * 4]
        ret





DoOpcodeFuncTable:
Opcode_00       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_10       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_20       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_30       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_40       DD      0, 0, 0, 0, 0, 0, 0, 0, OpcodeInfo48, 0, 0, 0, 0, 0, 0, 0
Opcode_50       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_60       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_70       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_80       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_90       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_a0       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_b0       DD      OpcodeInfoB0, OpcodeInfoB1, OpcodeInfoB2, OpcodeInfoB3, OpcodeInfoB4, OpcodeInfoB5, OpcodeInfoB6, OpcodeInfoB7
                DD      OpcodeInfoB8, OpcodeInfoB9, OpcodeInfoBA, OpcodeInfoBB, OpcodeInfoBC, OpcodeInfoBD, OpcodeInfoBE, OpcodeInfoBF
Opcode_c0       DD      0, 0, 0, OpcodeInfoC3, 0, 0, 0, 0, 0, 0, 0, 0, 0, OpcodeInfoCD, 0, OpcodeInfoCF
Opcode_d0       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_e0       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
Opcode_f0       DD      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



MAKE_OPCODE_INFO        48, 'dec', OPCODE_FLAG_PREFIX

;;
;; opcode B0 - BF
;;
MAKE_OPCODE_INFO        B0, 'mov', 0
MAKE_OPCODE_INFO        B1, 'mov', 0
MAKE_OPCODE_INFO        B2, 'mov', 0
MAKE_OPCODE_INFO        B3, 'mov', 0
MAKE_OPCODE_INFO        B4, 'mov', 0
MAKE_OPCODE_INFO        B5, 'mov', 0
MAKE_OPCODE_INFO        B6, 'mov', 0
MAKE_OPCODE_INFO        B7, 'mov', 0
MAKE_OPCODE_INFO        B8, 'mov', 0
MAKE_OPCODE_INFO        B9, 'mov', 0
MAKE_OPCODE_INFO        BA, 'mov', 0
MAKE_OPCODE_INFO        BB, 'mov', 0
MAKE_OPCODE_INFO        BC, 'mov', 0
MAKE_OPCODE_INFO        BD, 'mov', 0
MAKE_OPCODE_INFO        BE, 'mov', 0
MAKE_OPCODE_INFO        BF, 'mov', 0



MAKE_OPCODE_INFO        E8, 'call', 0
MAKE_OPCODE_INFO        CD, 'int', 0
MAKE_OPCODE_INFO        C3, 'ret', 0
MAKE_OPCODE_INFO        CF, 'iret', 0

;;
;; 寄存器表
;;
MAKE_REGISTER_INFO      al
MAKE_REGISTER_INFO      cl
MAKE_REGISTER_INFO      dl
MAKE_REGISTER_INFO      bl
MAKE_REGISTER_INFO      ah
MAKE_REGISTER_INFO      ch
MAKE_REGISTER_INFO      dh
MAKE_REGISTER_INFO      bh
MAKE_REGISTER_INFO      spl
MAKE_REGISTER_INFO      bpl
MAKE_REGISTER_INFO      sil
MAKE_REGISTER_INFO      dil
MAKE_REGISTER_INFO      r8b
MAKE_REGISTER_INFO      r9b
MAKE_REGISTER_INFO      r10b
MAKE_REGISTER_INFO      r11b
MAKE_REGISTER_INFO      r12b
MAKE_REGISTER_INFO      r13b
MAKE_REGISTER_INFO      r14b
MAKE_REGISTER_INFO      r15b
MAKE_REGISTER_INFO      ax
MAKE_REGISTER_INFO      cx
MAKE_REGISTER_INFO      dx
MAKE_REGISTER_INFO      bx
MAKE_REGISTER_INFO      sp
MAKE_REGISTER_INFO      bp
MAKE_REGISTER_INFO      si
MAKE_REGISTER_INFO      di
MAKE_REGISTER_INFO      r8w
MAKE_REGISTER_INFO      r9w
MAKE_REGISTER_INFO      r10w
MAKE_REGISTER_INFO      r11w
MAKE_REGISTER_INFO      r12w
MAKE_REGISTER_INFO      r13w
MAKE_REGISTER_INFO      r14w
MAKE_REGISTER_INFO      r15w
MAKE_REGISTER_INFO      eax
MAKE_REGISTER_INFO      ecx
MAKE_REGISTER_INFO      edx
MAKE_REGISTER_INFO      ebx
MAKE_REGISTER_INFO      esp
MAKE_REGISTER_INFO      ebp
MAKE_REGISTER_INFO      esi
MAKE_REGISTER_INFO      edi
MAKE_REGISTER_INFO      r8d
MAKE_REGISTER_INFO      r9d
MAKE_REGISTER_INFO      r10d
MAKE_REGISTER_INFO      r11d
MAKE_REGISTER_INFO      r12d
MAKE_REGISTER_INFO      r13d
MAKE_REGISTER_INFO      r14d
MAKE_REGISTER_INFO      r15d
MAKE_REGISTER_INFO      rax
MAKE_REGISTER_INFO      rcx
MAKE_REGISTER_INFO      rdx
MAKE_REGISTER_INFO      rbx
MAKE_REGISTER_INFO      rsp
MAKE_REGISTER_INFO      rbp
MAKE_REGISTER_INFO      rsi
MAKE_REGISTER_INFO      rdi
MAKE_REGISTER_INFO      r8
MAKE_REGISTER_INFO      r9
MAKE_REGISTER_INFO      r10
MAKE_REGISTER_INFO      r11
MAKE_REGISTER_INFO      r12
MAKE_REGISTER_INFO      r13
MAKE_REGISTER_INFO      r14
MAKE_REGISTER_INFO      r15

