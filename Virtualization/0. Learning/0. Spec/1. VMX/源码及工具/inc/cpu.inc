;*************************************************
; cpu.inc                                        *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


%ifndef CPU_INC
%define CPU_INC

%include "..\inc\ports.inc"



;*
;* 定义 prefix
;*
%define REX_W                   DB 48h
%define O16                     DB 66h
%define O32                     DB 66h
%define O64                     DB 48h
%define A16                     DB 67h
%define A32                     DB 67h

%define PREFIX_LOCK             DB 0F0h
%define PREFIX_ES               DB 26h
%define PREFIX_CS               DB 2Eh
%define PREFIX_SS               DB 36h
%define PREFIX_DS               DB 3Eh
%define PREFIX_FS               DB 64h
%define PREFIX_GS               DB 65h


%define iret64                  DB 48h, 0CFh
%define ret16                   DB 66h, 0CBh
%define retf32                  DB 66h, 0CBh
%define retf64                  DB 48h, 0CBh
%define sysexit64               DB 48h, 0Fh, 35h
%define sysret64                DB 48h, 0Fh, 07h

%define LoadFsBaseToRbp         DB 64h, 48h, 8Bh, 2ch, 25h, 00h, 00h, 00h, 00h
%define LoadGsBaseToRbp         DB 65h, 48h, 8Bh, 2ch, 25h, 00h, 00h, 00h, 00h
%define LoadFsBaseToRbx         DB 64h, 48h, 8Bh, 1ch, 25h, 00h, 00h, 00h, 00h
%define LoadGsBaseToRbx         DB 65h, 48h, 8Bh, 1ch, 25h, 00h, 00h, 00h, 00h



;* 定义 lea rax, [rip] 指令的 encode
;* 因为: nasm 语言层上不支持 [rip] 寻址
%define GET_RIP                 DB 48h, 8Dh, 05h, 00h, 00h, 00h, 00h
%define GetRip                  GET_RIP
%define LoadRipToRax            GET_RIP







;;
;; rflags 标志位
;;
%define FLAGS_CF                1
%define FLAGS_PF                4
%define FLAGS_AF                10h
%define FLAGS_ZF                40h
%define FLAGS_SF                80h
%define FLAGS_TF                100h
%define FLAGS_IF                200h
%define FLAGS_DF                400h
%define FLAGS_OF                800h
%define FLAGS_NT                4000h
%define FLAGS_RF                10000h
%define FLAGS_VM                20000h
%define FLAGS_AC                40000h
%define FLAGS_VIF               80000h
%define FLAGS_VIP               100000h
%define FLAGS_ID                200000h


;;
;; CR0 寄存器控制位
;;
%define CR0_PE                  1
%define CR0_MP                  2
%define CR0_EM                  4
%define CR0_TS                  8
%define CR0_ET                  10h
%define CR0_NE                  20h
%define CR0_WP                  10000h
%define CR0_AM                  40000h
%define CR0_NW                  20000000h
%define CR0_CD                  40000000h
%define CR0_PG                  80000000h

;;
;;CR4 寄存器控制位
;;
%define CR4_VME                 1
%define CR4_PVI                 2
%define CR4_TSD                 4
%define CR4_DE                  8
%define CR4_PSE                 10h
%define CR4_PAE                 20h
%define CR4_MCE                 40h
%define CR4_PGE                 80h
%define CR4_PCE                 100h
%define CR4_OSFXSR              200h
%define CR4_OSXMMEXCPT          400h
%define CR4_VMXE                2000h
%define CR4_SMXE                4000h
%define CR4_PCIDE               20000h
%define CR4_OSXSAVE             40000h
%define CR4_SMEP                100000h

%define EFER_SCE                1h
%define EFER_LME                100h
%define EFER_LMA                400h
%define EFER_NXE                800h




; SMM 模式的基地址
%define SMBASE                  30000H


%define IA32_APIC_BASE                  1BH
%define IA32_FEATURE_CONTROL            3AH
%define IA32_SMM_MONITOR_CTL            9BH
%define IA32_SMBASE                     9EH
%define IA32_MISC_ENABLE                1A0H
%define IA32_CPU_DCA_CAP                1F9H
%define IA32_MONITOR_FILTER_LINE_SIZE   06H
%define IA32_TIME_STAMP_COUNTER         10H
%define IA32_TSC_COUNTER                10H


;***** 定义 MTRR 寄存器的地址 ******

;下面是 Fixed-rang MTRR 寄存器的定义　
%define IA32_MTRR_FIX64K_00000                                       250H
%define IA32_MTRR_FIX16K_80000                                       258H
%define IA32_MTRR_FIX16K_A0000                                       259H
%define IA32_MTRR_FIX4K_C0000                                        268H
%define IA32_MTRR_FIX4K_C8000                                        269H
%define IA32_MTRR_FIX4K_D0000                                        26AH
%define IA32_MTRR_FIX4K_D8000                                        26BH
%define IA32_MTRR_FIX4K_E0000                                        26CH
%define IA32_MTRR_FIX4K_E8000                                        26DH
%define IA32_MTRR_FIX4K_F0000                                        26EH
%define IA32_MTRR_FIX4K_F8000                                        26FH

; 下面是 MTRR 的功能寄存器定义
%define IA32_MTRRCAP                                                 0FEH
%define IA32_MTRR_DEF_TYPE                                           2FFH

; 下面定义 MTRR 的 PHYSBASE/PHYSMASK 寄存器
%define IA32_MTRR_PHYSBASE0                                        200H
%define IA32_MTRR_PHYSMASK0                                        201H
%define IA32_MTRR_PHYSBASE1                                        202H
%define IA32_MTRR_PHYSMASK1                                        203H
%define IA32_MTRR_PHYSBASE2                                        204H
%define IA32_MTRR_PHYSMASK2                                        205H
%define IA32_MTRR_PHYSBASE3                                        206H
%define IA32_MTRR_PHYSMASK3                                        207H
%define IA32_MTRR_PHYSBASE4                                        208H
%define IA32_MTRR_PHYSMASK4                                        209H
%define IA32_MTRR_PHYSBASE5                                        20AH
%define IA32_MTRR_PHYSMASK5                                        20BH
%define IA32_MTRR_PHYSBASE6                                        20CH
%define IA32_MTRR_PHYSMASK6                                        20DH
%define IA32_MTRR_PHYSBASE7                                        20EH
%define IA32_MTRR_PHYSMASK7                                        20FH
%define IA32_MTRR_PHYSBASE8                                        210H
%define IA32_MTRR_PHYSMASK8                                        211H
%define IA32_MTRR_PHYSBASE9                                        212H
%define IA32_MTRR_PHYSMASK9                                        213H

; 下面是 SMRR 寄存器
%define IA32_SMRR_PHYSBASE                                         1F2H
%define IA32_SMRR_PHYSMASK                                         1F3H

; 下面是 PAT 寄存器
%define IA32_PAT                                                   277H


; 下面是对特殊指令提供支持的 MSR 寄存器定义
%define IA32_SYSENTER_CS                                           174H
%define IA32_SYSENTER_ESP                                          175H
%define IA32_SYSENTER_EIP                                          176H


;; 下面是 x64 体系的支持
%define IA32_EFER                                                  0C0000080H
%define IA32_STAR                                                  0C0000081H
%define IA32_LSTAR                                                 0C0000082H
%define IA32_FMASK                                                 0C0000084H
%define IA32_FS_BASE                                               0C0000100H
%define IA32_GS_BASE                                               0C0000101H
%define IA32_KERNEL_GS_BASE                                        0C0000102H



; ##### 为 AMD 机器定义 #######
%define MSR_SMI_ON_IO_TRAP0                                        0C0010050H
%define MSR_SMI_ON_IO_TRAP1                                        0C0010051H
%define MSR_SMI_ON_IO_TRAP2                                        0C0010052H
%define MSR_SMI_ON_IO_TRAP3                                        0C0010053H
%define MSR_SMI_ON_IO_TRAP_CTL_STS                                 0C0010054H


;; 与 dubug/performance monitoring 相关的 MSRs

%define IA32_PEBS_ENABLE                                           3F1H
;; general-purpose counter 寄存器
%define IA32_PERFEVTSEL0                                           186H
%define IA32_PERFEVTSEL1                                           187H
%define IA32_PERFEVTSEL2                                           188H
%define IA32_PERFEVTSEL3                                           189H
%define IA32_PMC0                                                  0C1H
%define IA32_PMC1                                                  0C2H
%define IA32_PMC2                                                  0C3H
%define IA32_PMC3                                                  0C4H
%define IA32_A_PMC0                                                4C1H
%define IA32_A_PMC1                                                4C2H
%define IA32_A_PMC2                                                4C3H
%define IA32_A_PMC3                                                4C4H

;; fixed-counter 寄存器
%define IA32_FIXED_CTR0                                            309H
%define MSR_PERF_FIXED_CTR0                                        309H
%define IA32_FIXED_CTR1                                            30AH
%define MSR_PERF_FIXED_CTR1                                        30AH
%define IA32_FIXED_CTR2                                            30BH
%define MSR_PERF_FIXED_CTR2                                        30BH

%define IA32_FIXED_CTR_CTRL                                        38DH
%define MSR_PERF_FIXED_CTR_CTRL                                    38DH

%define IA32_PERF_STATUS                                           198H
%define IA32_PERF_CTL                                              199H

%define IA32_PERF_CAPABILITIES                                     345H
%define IA32_PERF_GLOBAL_STATUS                                    38EH
%define MSR_PERF_GLOBAL_STATUS                                     38EH
%define MSR_PERF_GLOBAL_CTRL                                       38FH
%define IA32_PERF_GLOBAL_CTRL                                      38FH
%define IA32_PERF_GLOBAL_OVF_CTRL                                  390H
%define MSR_PERF_GLOBAL_OVF_CTRL                                   390H

%define MSR_PEBS_LD_LAT                                            3F6H

%define IA32_DS_AREA                                               600H
%define IA32_TSC_DEADLINE                                          6E0H


;;; 下面是 06_25H(DisplayFamily_DisplayModel) 处理器的 MSRs,  适用于 Nehalem/Westmere 微架构

%define MSR_LBR_SELECT                                             1C8H
%define MSR_LASTBRANCH_TOS                                         1C9H
%define IA32_DEBUGCTL                                              1D9H
%define MSR_LER_FROM_LIP                                           1DDH
%define MSR_LER_TO_LIP                                             1DEH
%define MSR_PEBS_ENABLE                                            3F1H
%define MSR_LASTBRANCH_0_FROM_IP                                   680H
%define MSR_LASTBRANCH_1_FROM_IP                                   681H
%define MSR_LASTBRANCH_2_FROM_IP                                   682H
%define MSR_LASTBRANCH_3_FROM_IP                                   683H
%define MSR_LASTBRANCH_4_FROM_IP                                   684H
%define MSR_LASTBRANCH_5_FROM_IP                                   685H
%define MSR_LASTBRANCH_6_FROM_IP                                   686H
%define MSR_LASTBRANCH_7_FROM_IP                                   687H
%define MSR_LASTBRANCH_8_FROM_IP                                   688H
%define MSR_LASTBRANCH_9_FROM_IP                                   689H
%define MSR_LASTBRANCH_10_FROM_IP                                  68AH
%define MSR_LASTBRANCH_11_FROM_IP                                  68BH
%define MSR_LASTBRANCH_12_FROM_IP                                  68CH
%define MSR_LASTBRANCH_13_FROM_IP                                  68DH
%define MSR_LASTBRANCH_14_FROM_IP                                  68EH
%define MSR_LASTBRANCH_15_FROM_IP                                  68FH
%define MSR_LASTBRANCH_0_TO_IP                                     6C0H
%define MSR_LASTBRANCH_1_TO_IP                                     6C1H
%define MSR_LASTBRANCH_2_TO_IP                                     6C2H
%define MSR_LASTBRANCH_3_TO_IP                                     6C3H
%define MSR_LASTBRANCH_4_TO_IP                                     6C4H
%define MSR_LASTBRANCH_5_TO_IP                                     6C5H
%define MSR_LASTBRANCH_6_TO_IP                                     6C6H
%define MSR_LASTBRANCH_7_TO_IP                                     6C7H
%define MSR_LASTBRANCH_8_TO_IP                                     6C8H
%define MSR_LASTBRANCH_9_TO_IP                                     6C9H
%define MSR_LASTBRANCH_10_TO_IP                                    6CAH
%define MSR_LASTBRANCH_11_TO_IP                                    6CBH
%define MSR_LASTBRANCH_12_TO_IP                                    6CCH
%define MSR_LASTBRANCH_13_TO_IP                                    6CDH
%define MSR_LASTBRANCH_14_TO_IP                                    6CEH
%define MSR_LASTBRANCH_15_TO_IP                                    6CFH


; Nehalem 微架构的辅助 TSC 寄存器
%define IA32_TSC_AUX                                                0C0000103H


%define MSR_FSB_FREQ                                            0CDH
%define IA32_MPERF                                              0E7H
%define IA32_APERF                                              0E8H
%define IA32_PLATFORM_ID                                        17H
%define MSR_PLATFORM_ID                                         17H
%define MSR_PERF_STATUS                                         198H


;
; 下面是关于 VMX 的 MSR 
;
%define IA32_VMX_BASIC                                          480H
%define IA32_VMX_PINBASED_CTLS                                  481H
%define IA32_VMX_PROCBASED_CTLS                                 482H
%define IA32_VMX_EXIT_CTLS                                      483H
%define IA32_VMX_ENTRY_CTLS                                     484H
%define IA32_VMX_MISC                                           485H
%define IA32_VMX_CR0_FIXED0                                     486H
%define IA32_VMX_CR0_FIXED1                                     487H
%define IA32_VMX_CR4_FIXED0                                     488H
%define IA32_VMX_CR4_FIXED1                                     489H
%define IA32_VMX_VMCS_ENUM                                      48AH
%define IA32_VMX_PROCBASED_CTLS2                                48BH
%define IA32_VMX_EPT_VPID_CAP                                   48CH
%define IA32_VMX_TRUE_PINBASED_CTLS                             48DH
%define IA32_VMX_TRUE_PROCBASED_CTLS                            48EH
%define IA32_VMX_TRUE_EXIT_CTLS                                 48FH
%define IA32_VMX_TRUE_ENTRY_CTLS                                490H
%define IA32_VMX_VMFUNC                                         491H


;;
;; x2APIC local APIC 寄存器
;;
%define IA32_X2APIC_APICID                                      802H
%define IA32_X2APIC_VERSION                                     803H
%define IA32_X2APIC_TPR                                         808H
%define IA32_X2APIC_PPR                                         80AH
%define IA32_X2APIC_EOI                                         80BH
%define IA32_X2APIC_LDR                                         80DH
%define IA32_X2APIC_SVR                                         80FH
%define IA32_X2APIC_ISR0                                        810H
%define IA32_X2APIC_ISR1                                        811H
%define IA32_X2APIC_ISR2                                        812H
%define IA32_X2APIC_ISR3                                        813H
%define IA32_X2APIC_ISR4                                        814H
%define IA32_X2APIC_ISR5                                        815H
%define IA32_X2APIC_ISR6                                        816H
%define IA32_X2APIC_ISR7                                        817H
%define IA32_X2APIC_TMR0                                        818H
%define IA32_X2APIC_TMR1                                        819H
%define IA32_X2APIC_TMR2                                        81AH
%define IA32_X2APIC_TMR3                                        81BH
%define IA32_X2APIC_TMR4                                        81CH
%define IA32_X2APIC_TMR5                                        81DH
%define IA32_X2APIC_TMR6                                        81EH
%define IA32_X2APIC_TMR7                                        81FH
%define IA32_X2APIC_IRR0                                        820H
%define IA32_X2APIC_IRR1                                        821H
%define IA32_X2APIC_IRR2                                        822H
%define IA32_X2APIC_IRR3                                        823H
%define IA32_X2APIC_IRR4                                        824H
%define IA32_X2APIC_IRR5                                        825H
%define IA32_X2APIC_IRR6                                        826H
%define IA32_X2APIC_IRR7                                        827H
%define IA32_X2APIC_ESR                                         828H
%define IA32_X2APIC_LVT_CMCI                                    82FH
%define IA32_X2APIC_ICR                                         830H
%define IA32_X2APIC_LVT_TIMER                                   832H
%define IA32_X2APIC_LVT_THERMAL                                 833H
%define IA32_X2APIC_LVT_PMI                                     834H
%define IA32_X2APIC_LVT_LINT0                                   835H
%define IA32_X2APIC_LVT_LINT1                                   836H
%define IA32_X2APIC_LVT_ERROR                                   837H
%define IA32_X2APIC_INIT_COUNT                                  838H
%define IA32_X2APIC_CUR_COUNT                                   839H
%define IA32_X2APIC_DIV_CONF                                    83EH
%define IA32_X2APIC_SELF_IPI                                    83FH





;; ########## 关于 CPU 的一些宏定义 ##############


; ---------------------------------------------
; retf64
; input:
;       none
; output:
;       none
; 描述: 
;       1) 64位operand 的 retf
; ---------------------------------------------
%macro retf64   0
        DB 48h, 0CBh
%endmacro


; ---------------------------------------------
; retfn64
; input:
;       %1 - bytes
; output:
;       none
; 描述: 
;       1) 64位operand 的 retf
; ---------------------------------------------
%macro retfn64   1
        DB 48h, 0CAh
        DW %1
%endmacro




; ---------------------------------------------
; JMP_RIP_OFFSET32:
; 描述: 
;       1) 这个宏执行 jmp [rip + offset32] 指令
; ---------------------------------------------
%macro JMP_RIP_OFFSET32 1
        DW 25FFh                         ; jmp [rip + offset32] opcode
        DD %1
%endmacro


; ---------------------------------------------
; DECv:
; 描述: 
;       1) 这个宏使用 FF /1 opcode 的 dec 指令
; ---------------------------------------------
%macro DECv 1
%if %1==eax
        DW 0C8FFh
%elif %1==ecx
        DW 0C9FFh
%elif %1==edx
        DW 0CAFFh
%elif %1==ebx
        DW 0CBFFh
%elif %1==esp
        DW 0CCFFh
%elif %1==ebp
        DW 0CDFFh
%elif %1==esi
        DW 0CEFFh
%elif %1==edi
        DW 0CFFFh
%endif
%endmacro


; ---------------------------------------------
; INCv:
; 描述: 
;       1) 这个宏使用 FF /1 opcode 的 dec 指令
; ---------------------------------------------
%macro INCv 1
%if %1==eax
        DW 0C0FFh
%elif %1==ecx
        DW 0C1FFh
%elif %1==edx
        DW 0C2FFh
%elif %1==ebx
        DW 0C3FFh
%elif %1==esp
        DW 0C4FFh
%elif %1==ebp
        DW 0C5FFh
%elif %1==esi
        DW 0C6FFh
%elif %1==edi
        DW 0C7FFh
%endif
%endmacro

; ---------------------------------------------
; PUSHr
; input:
;       %1 - register
; output:
;       none
; 描述: 
;       1) 定义 push [mem] 指令
; ---------------------------------------------
%macro PUSHr    1
%if %1==eax
        DB 50h
%elif %1==ecx
        DB 51h
%elif %1==edx
        DB 52h
%elif %1==ebx
        DB 53h
%elif %1==esp
        DB 54h
%elif %1==ebp
        DB 55h
%elif %1==esi
        DB 56h
%elif %1==edi
        DB 57h
%elif %1==rax
        DB 50h
%elif %1==rcx
        DB 51h
%elif %1==rdx
        DB 52h
%elif %1==rbx
        DB 53h
%elif %1==rsp
        DB 54h
%elif %1==rbp
        DB 55h
%elif %1==rsi
        DB 56h
%elif %1==rdi
        DB 57h
%endif
%endmacro


; ---------------------------------------------
; POPr
; input:
;       %1 - register
; output:
;       none
; 描述: 
;       1) 定义 push [mem] 指令
; ---------------------------------------------
%macro POPr    1
%if %1==eax
        DB 58h
%elif %1==ecx
        DB 59h
%elif %1==edx
        DB 5Ah
%elif %1==ebx
        DB 5Bh
%elif %1==esp
        DB 5Ch
%elif %1==ebp
        DB 5Dh
%elif %1==esi
        DB 5Eh
%elif %1==edi
        DB 5Fh
%elif %1==rax
        DB 58h
%elif %1==rcx
        DB 59h
%elif %1==rdx
        DB 5Ah
%elif %1==rbx
        DB 5Bh
%elif %1==rsp
        DB 5Ch
%elif %1==rbp
        DB 5Dh
%elif %1==rsi
        DB 5Eh
%elif %1==rdi
        DB 5Fh
%endif
%endmacro


; ---------------------------------------------
; LOADv
; ---------------------------------------------
%macro LOADv    2

        REX.Wrxb
%if %1 == rax
        DB 0B8h  
%elif %1 == eax
        DB 0B8h
%elif %1 == rcx
        DB 0B9h  
%elif %1 == ecx
        DB 0B9h
%elif %1 == rdx
        DB 0BAh  
%elif %1 == edx
        DB 0BAh
%elif %1 == rbx
        DB 0BBh  
%elif %1 == ebx
        DB 0BBh
%elif %1 == rsp
        DB 0BCh  
%elif %1 == esp
        DB 0BCh
%elif %1 == rbp
        DB 0BDh  
%elif %1 == ebp
        DB 0BDh
%elif %1 == rsi
        DB 0BEh  
%elif %1 == esi
        DB 0BEh
%elif %1 == rdi
        DB 0BFh  
%elif %1 == edi
        DB 0BFh
%endif

%ifdef __X64
        DQ      %2
%else
        DD      %2
%endif
%endmacro



; ---------------------------------------------
; PUSH_MEM
; input:
;       %1 - address
; output:
;       none
; 描述: 
;       1) 定义 push [mem] 指令
; ---------------------------------------------
%macro PUSH_MEM 1
        DB 0FFh, 34h, 25h
        DD %1
%endmacro




; ---------------------------------------------
; POP_MEM
; input:
;       %1 - address
; output:
;       none
; 描述: 
;       1) 定义 pop [mem] 指令
; ---------------------------------------------
%macro POP_MEM 1
        DB 8Fh, 04h, 25h
        DD %1
%endmacro





; ---------------------------------------------
; 宏: REX.W
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.W 0
%ifndef __STAGE1
        %ifdef __X64
                DB 48h
        %endif
%endif
%endmacro



; ---------------------------------------------
; 宏: REX.wrxb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wrxb 0
%ifndef __STATE1
        %ifdef __X64
                DB 40h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.wrxB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wrxB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 41h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.wrXb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wrXb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 42h
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.wrXB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wrXB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 43h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.wRxb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wRxb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 44h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.wRxB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wRxB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 45h
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.wRXb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wRXb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 46h
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.wRXB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.wRXB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 47h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.Wrxb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.Wrxb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 48h
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.WrxB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WrxB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 49h
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.WrXb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WrXb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Ah
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.WrXB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WrXB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Bh
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.WRxb
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WRxb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Ch
        %endif
%endif
%endmacro

; ---------------------------------------------
; 宏: REX.WRxB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WRxB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Dh
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.WrxB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WRXb 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Eh
        %endif
%endif
%endmacro


; ---------------------------------------------
; 宏: REX.WRXB
; 描述: 
;       1) 定义 REX prefix
; ---------------------------------------------
%macro REX.WRXB 0
%ifndef __STAGE1
        %ifdef __X64
                DB 4Fh  
        %endif
%endif
%endmacro




;----------------------------------------------------------
; StoreToPcb:
; input:
;       %1 - offset(基于PCB)
;       %2 - value
; output:
;       none
; 描述: 
;       1) 在 32 位下编译, 目标平台为 x64, 保存 PCB 数据
;----------------------------------------------------------
%macro StoreToPcb 2
        ;;
        ;; 执行 mov [gs: PCB.xxx], Reg 指令
        ;;
        PREFIX_GS                       ; GS

%if %2 == rax
        REX.Wrxb                        ; REX
        DB 89h                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %2 == eax
        DB 89h
        DB 04h
%elif %2 == rcx
        REX.Wrxb
        DB 89h
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %2 == ecx
        DB 89h
        DB 0Ch
%elif %2 == rdx
        REX.Wrxb
        DB 89h
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %2 == edx
        DB 89h
        DB 14h  
%elif %2 == rbx
        REX.Wrxb
        DB 89h
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %2 == ebx
        DB 89h
        DB 1Ch  
%elif %2 == rsp
        REX.Wrxb
        DB 89h
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %2 == esp
        DB 89h
        DB 24h 
%elif %2 == rbp
        REX.Wrxb
        DB 89h
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %2 == ebp
        DB 89h
        DB 2Ch  
%elif %2 == rsi
        REX.Wrxb
        DB 89h
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %2 == esi
        DB 89h
        DB 34h  
%elif %2 == rdi
        REX.Wrxb
        DB 89h
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%elif %2 == edi
        DB 89h
        DB 3Ch  
%elif %2 == r8
        REX.WRxb                        ; REX
        DB 89h                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %2 == r9
        REX.WRxb
        DB 89h
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %2 == r10
        REX.WRxb
        DB 89h
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %2 == r11
        REX.WRxb
        DB 89h
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %2 == r12
        REX.WRxb
        DB 89h
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %2 == r13
        REX.WRxb
        DB 89h
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %2 == r14
        REX.WRxb
        DB 89h
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %2 == r15
        REX.WRxb
        DB 89h
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%endif
        
        DB 25h                          ; SIB.index = 4, base = 5
        DD %1                           ; offset
%endmacro


;----------------------------------------------------------
; LoadFromPcb:
; input:
;       %1 - reg
;       %2 - offset(基于PCB)
; output:
;       none
; 描述: 
;       1) 在 32 位下编译, 目标平台为 x64, 读取 PCB 数据
;----------------------------------------------------------
%macro LoadFromPcb 2
        ;;
        ;; 执行 mov Reg, [gs: PCB.xxx] 指令
        ;;
        PREFIX_GS                       ; GS

%if %1 == rax
        REX.Wrxb                        ; REX
        DB 8Bh                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %1 == eax
        DB 8Bh
        DB 04h
%elif %1 == rcx
        REX.Wrxb
        DB 8Bh
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %1 == ecx
        DB 8Bh
        DB 0Ch
%elif %1 == rdx
        REX.Wrxb
        DB 8Bh
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %1 == edx
        DB 8Bh
        DB 14h  
%elif %1 == rbx
        REX.Wrxb
        DB 8Bh
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %1 == ebx
        DB 8Bh
        DB 1Ch  
%elif %1 == rsp
        REX.Wrxb
        DB 8Bh
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %1 == esp
        DB 8Bh
        DB 24h 
%elif %1 == rbp
        REX.Wrxb
        DB 8Bh
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %1 == ebp
        DB 8Bh
        DB 2Ch  
%elif %1 == rsi
        REX.Wrxb
        DB 8Bh
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %1 == esi
        DB 8Bh
        DB 34h  
%elif %1 == rdi
        REX.Wrxb
        DB 8Bh
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%elif %1 == edi
        DB 8Bh
        DB 3Ch  
%elif %1 == r8
        REX.WRxb                        ; REX
        DB 8Bh                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %1 == r9
        REX.WRxb
        DB 8Bh
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %1 == r10
        REX.WRxb
        DB 8Bh
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %1 == r11
        REX.WRxb
        DB 8Bh
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %1 == r12
        REX.WRxb
        DB 8Bh
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %1 == r13
        REX.WRxb
        DB 8Bh
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %1 == r14
        REX.WRxb
        DB 8Bh
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %1 == r15
        REX.WRxb
        DB 8Bh
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%endif
        
        DB 25h                          ; SIB.index = 4, base = 5
        DD %2                           ; ofgset
%endmacro



;----------------------------------------------------------
; StoreToSda:
; input:
;       %1 - offset(基于SDA)
;       %2 - value
; output:
;       none
; 描述: 
;       1) 在 32 位下编译, 目标平台为 x64, 保存 SDA 数据
;----------------------------------------------------------
%macro StoreToSda 2
        ;;
        ;; 执行 mov [fs: SDA.xxx], Reg 指令
        ;;
        PREFIX_FS                       ; FS

%if %2 == rax
        REX.Wrxb                        ; REX
        DB 89h                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %2 == eax
        DB 89h
        DB 04h
%elif %2 == rcx
        REX.Wrxb
        DB 89h
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %2 == ecx
        DB 89h
        DB 0Ch
%elif %2 == rdx
        REX.Wrxb
        DB 89h
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %2 == edx
        DB 89h
        DB 14h  
%elif %2 == rbx
        REX.Wrxb
        DB 89h
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %2 == ebx
        DB 89h
        DB 1Ch  
%elif %2 == rsp
        REX.Wrxb
        DB 89h
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %2 == esp
        DB 89h
        DB 24h 
%elif %2 == rbp
        REX.Wrxb
        DB 89h
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %2 == ebp
        DB 89h
        DB 2Ch  
%elif %2 == rsi
        REX.Wrxb
        DB 89h
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %2 == esi
        DB 89h
        DB 34h  
%elif %2 == rdi
        REX.Wrxb
        DB 89h
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%elif %2 == edi
        DB 89h
        DB 3Ch  
%elif %2 == r8
        REX.WRxb                        ; REX
        DB 89h                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %2 == r9
        REX.WRxb
        DB 89h
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %2 == r10
        REX.WRxb
        DB 89h
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %2 == r11
        REX.WRxb
        DB 89h
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %2 == r12
        REX.WRxb
        DB 89h
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %2 == r13
        REX.WRxb
        DB 89h
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %2 == r14
        REX.WRxb
        DB 89h
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %2 == r15
        REX.WRxb
        DB 89h
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%endif
        
        DB 25h                          ; SIB.index = 4, base = 5
        DD %1                           ; offset
%endmacro


;----------------------------------------------------------
; LoadFromSda:
; input:
;       %1 - reg
;       %2 - offset(基于SDA)
; output:
;       none
; 描述: 
;       1) 在 32 位下编译, 目标平台为 x64, 读取 SDA 数据
;----------------------------------------------------------
%macro LoadFromSda 2
        ;;
        ;; 执行 mov Reg, [fs: SDA.xxx] 指令
        ;;
        PREFIX_FS                       ; FS

%if %1 == rax
        REX.Wrxb                        ; REX
        DB 8Bh                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %1 == eax
        DB 8Bh
        DB 04h
%elif %1 == rcx
        REX.Wrxb
        DB 8Bh
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %1 == ecx
        DB 8Bh
        DB 0Ch
%elif %1 == rdx
        REX.Wrxb
        DB 8Bh
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %1 == edx
        DB 8Bh
        DB 14h  
%elif %1 == rbx
        REX.Wrxb
        DB 8Bh
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %1 == ebx
        DB 8Bh
        DB 1Ch  
%elif %1 == rsp
        REX.Wrxb
        DB 8Bh
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %1 == esp
        DB 8Bh
        DB 24h 
%elif %1 == rbp
        REX.Wrxb
        DB 8Bh
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %1 == ebp
        DB 8Bh
        DB 2Ch  
%elif %1 == rsi
        REX.Wrxb
        DB 8Bh
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %1 == esi
        DB 8Bh
        DB 34h  
%elif %1 == rdi
        REX.Wrxb
        DB 8Bh
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%elif %1 == edi
        DB 8Bh
        DB 3Ch  
%elif %1 == r8
        REX.WRxb                        ; REX
        DB 8Bh                          ; MOV opcode
        DB 04h                          ; ModRM.reg = 0, r/m = 4
%elif %1 == r9
        REX.WRxb
        DB 8Bh
        DB 0Ch                          ; ModRM.reg = 1, r/m =4
%elif %1 == r10
        REX.WRxb
        DB 8Bh
        DB 14h                          ; ModRM.reg = 2, r/m =4
%elif %1 == r11
        REX.WRxb
        DB 8Bh
        DB 1Ch                          ; ModRM.reg = 3, r/m =4
%elif %1 == r12
        REX.WRxb
        DB 8Bh
        DB 24h                          ; ModRM.reg = 4, r/m =4
%elif %1 == r13
        REX.WRxb
        DB 8Bh
        DB 2Ch                          ; ModRM.reg = 5, r/m =4
%elif %1 == r14
        REX.WRxb
        DB 8Bh
        DB 34h                          ; ModRM.reg = 6, r/m =4
%elif %1 == r15
        REX.WRxb
        DB 8Bh
        DB 3Ch                          ; ModRM.reg = 7, r/m =4
%endif
        
        DB 25h                          ; SIB.index = 4, base = 5
        DD %2                           ; offset
%endmacro


;----------------------------------------------
; IO_DELAY()
;----------------------------------------------
%macro IO_DELAY 0
    out 0x80, al
%endmacro




; ---------------------------------------------
; macro: FAST_A20_ENABLE
; description:
;       set 0x92[1] to enable A20 line
;----------------------------------------------
%macro FAST_A20_ENABLE  0
        in al, SYSTEM_CONTROL_PORTA                                ; port 0x92
        or al, 0x02                                                ; set A20 bit
        and al, 0xfe                                               ; do not reset
        out SYSTEM_CONTROL_PORTA, al
%endmacro

%macro FAST_A20_DISABLE 0
        in al, SYSTEM_CONTROL_PORTA                                ; port 0x92
        and al, 0xfd                                                ; clear A20 bit
        out SYSTEM_CONTROL_PORTA, al
%endmacro


;------------------------------------------------
; macro: NMI_DISABLE
; description:
;       设置 NMI_EN 寄存器的 bit 7 为 1
;------------------------------------------------
%macro NMI_DISABLE 0
        in al, NMI_EN_PORT                                        ; port 0x70
        or al, 0x80                                               ; disable all NMI source
        out NMI_EN_PORT, al
%endmacro



;------------------------------------------------
; macro: NMI_ENABLE
; description:
;       set 0x70[7] to 0
;------------------------------------------------
%macro NMI_ENABLE 0
        in al, NMI_EN_PORT                                      ; port 0x70
        and al, 0x7f                                            ; enable NMI source
        out NMI_EN_PORT, al
%endmacro


;------------------------------------------------
;-----------------------------------------------
%macro DISABLE_8259 0
    mov al, 0xff
    out 0xa1, al
    IO_DELAY
    mov al, 0xfb
    out 0x21, al
    IO_DELAY
%endmacro

;-----------------------------------------------
; macro: RESET_CPU
; description:
;       执行处理器硬件 RESET
;-----------------------------------------------
%macro RESET_CPU 0
        mov dx, RESET_CONTROL_REGISTER                         ; reset 控制寄存器在端口 0CF9H
        mov al, 06h
        out dx, al
        hlt
        jmp $-1
%endmacro


;---------------------------------------------
; macro INIT_CPU
; description:
;       引发处理器产生 INIT# 信号
;----------------------------------------------
%macro INIT_CPU 0
        mov dx, FAST_A20_INIT_REGISTER                        ; port 92
        in al, dx
        or al, 1                                              ; INIT_NOW
        out dx, al
%endmacro






;---------------------------------------------
; WAIT_UNTIL_EQU
; input:
;       %1 - 源值
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 等待直到 %1 == %2
;---------------------------------------------
%macro WAIT_UNTIL_EQU 2
%%0:
        REX.Wrxb
	cmp DWORD %1, %2
	je %%1
	pause
	jmp %%0
%%1:	
%endmacro






;---------------------------------------------
; WAIT_UNTIL_EQU32
; input:
;       %1 - 内存变量
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 等待直到 %1 == %2
;---------------------------------------------
%macro WAIT_UNTIL_EQU32 2
%%0:
	cmp DWORD %1, %2
	je %%1
	pause
	jmp %%0
%%1:	
%endmacro




;---------------------------------------------
; WAIT_UNTIL_NEQ
; input:
;       %1 - 内存变量
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 等待直到 %1 != %2
;---------------------------------------------
%macro WAIT_UNTIL_NEQ 2
%%0:
        REX.Wrxb
	cmp DWORD %1, %2
	jne %%1
	pause
	jmp %%0
%%1:	
%endmacro





;---------------------------------------------
; WAIT_UNTIL_NEQ32
; input:
;       %1 - 源值
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 等待直到 %1 != %2
;---------------------------------------------
%macro WAIT_UNTIL_NEQ32 2
%%0:
	cmp DWORD %1, %2
	jne %%1
	pause
	jmp %%0
%%1:	
%endmacro




;---------------------------------------------
; MWAIT_IDLE_WITH_NEQ
; input:
;       %1 - 源内存地址
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 使用 MONITOR/MWAIT 优化 idle
;---------------------------------------------
%macro MWAIT_IDLE_WITH_NEQ 2
;;
;; 说明: 
;;      1) 参数1 提供一个内存操作数, 参数2是一个目标值
;;      2) 比较内存操作数的值是否等于目标值, 不等于的话进入 mwait idle
;;
;; 示例: 
;;      MWAIT_IDLE_WITH_NEQ [eax], 1            ; 当 [eax] != 1 时, 进入 mwait idle
;;

        ;;
        ;; 下面使用 monitor 进行监控内存操作数
        ;;
        REX.Wrxb
        lea eax, %1                             ; eax = 监控源内存地址
        xor ecx, ecx                            ; ecx = 0
        xor edx, edx                            ; edx = 0
        monitor

        ;;
        ;; 检查内存操作数是否改变
        ;;
        REX.Wrxb
        cmp DWORD %1, %2
        je %%0                                  ; 比较两个值, 相等时直接返回
        sti                                     ; C1-state mwait
        xor eax, eax
        xor ecx, ecx
        mwait

%%0:	        
%endmacro





;---------------------------------------------
; MWAIT_IDLE_WITH_NEQ32
; input:
;       %1 - 源内存变量
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 使用 MONITOR/MWAIT 优化 idle
;---------------------------------------------
%macro MWAIT_IDLE_WITH_NEQ32 2
;;
;; 说明: 
;;      1) 参数1 提供一个内存操作数, 参数2是一个目标值
;;      2) 比较内存操作数的值是否等于目标值, 不等于的话进入 mwait idle
;;
;; 示例: 
;;      MWAIT_IDLE_WITH_NEQ32 [eax], 1          ; 当 [eax] != 1 时, 进入 idle loop, 直到 [eax] == 1 为止
;;

        ;;
        ;; 下面使用 monitor 进行监控内存操作数
        ;;
        REX.Wrxb
        lea eax, %1                             ; 监控源内存地址
        xor ecx, ecx                            ; ecx = edx = 0
        xor edx, edx
        monitor

        ;;
        ;; 检查内存操作数是否改变
        ;;
        cmp DWORD %1, %2
        je %%0                                  ; 比较两个值, 不相等时进入 mwait idle
        sti                                     ; C1-state
        xor eax, eax
        xor ecx, ecx
        mwait
%%0:	        
%endmacro



;---------------------------------------------
; MWAIT_IDLE_WITH_EQU
; input:
;       %1 - 内存变量
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 使用 MONITOR/MWAIT 优化 idle
;---------------------------------------------
%macro MWAIT_IDLE_WITH_EQU 2
;;
;; 说明: 
;;      1) 参数1 提供一个内存操作数, 参数2是一个目标值
;;      2) 比较内存操作数的值是否等于目标值, 等于的话进入 idle
;;
;; 示例: 
;;      MWAIT_IDLE_WITH_EQU [eax], 0            ; 当 [eax] == 0 时, 进入 mwait idle
;;

        ;;
        ;; 下面使用 monitor 进行监控内存操作数
        ;;
        REX.Wrxb
        lea eax, %1                             ; 监控源内存地址
        xor ecx, ecx                            ; ecx = edx = 0
        xor edx, edx
        monitor

        ;;
        ;; 检查内存操作数是否改变
        ;;
        REX.Wrxb
        cmp DWORD %1, %2
        jne %%0                                 ; 比较两个值, 不相等时退出
        sti
        xor eax, eax
        xor ecx, ecx
        mwait
%%0:	        
%endmacro





;---------------------------------------------
; MWAIT_IDLE_WITH_EQU32
; input:
;       %1 - 内存变量
;       %2 - 目标值
; output:
;       none
; 描述: 
;       1) 使用 MONITOR/MWAIT 优化 idle
;---------------------------------------------
%macro MWAIT_IDLE_WITH_EQU32 2
;;
;; 说明: 
;;      1) 参数1 提供一个内存操作数, 参数2是一个目标值
;;      2) 比较内存操作数的值是否等于目标值, 等于的话进入 idle
;;
;; 示例: 
;;      MWAIT_IDLE_WITH_EQU32 [eax], 0          ; 当 [eax] == 0 时, 进入 mwait idle
;;

        ;;
        ;; 下面使用 monitor 进行监控内存操作数
        ;;
        REX.Wrxb
        lea eax, %1                             ; 监控源内存地址
        xor ecx, ecx                            ; ecx = edx = 0
        xor edx, edx
        monitor

        ;;
        ;; 检查内存操作数是否改变
        ;;
        cmp DWORD %1, %2
        jne %%0                                 ; 比较两个值, 不相等时退出
        sti
        xor eax, eax
        xor ecx, ecx
        mwait
%%0:	        
%endmacro







%endif

