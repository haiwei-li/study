;************************************************
;* vmx.inc                                      *
;* Copyright (c) 2009-2013 邓志                 *
;* All rights reserved.                         *
;************************************************

%ifndef _VMX_INC
%define _VMX_INC



;;******************************************************
;; VMX 的 VMCS region 地址
;;******************************************************

%define VMX_REGION_PHYSICAL_BASE                        1100000h
%define VMX_REGION_VIRTUAL_BASE                         0B0000000h

;;
;; 默认下, 每个 VM 拥有 8M 内存区域
;;
%define VM_MEMORY_SIZE                                  800000h


;;
;; VMM 处理代码
;;
%define VMM_PROCESS_DUMP_VMCS                           0
%define VMM_PROCESS_RESUME                              1
%define VMM_PROCESS_LAUNCH                              2
%define VMM_PROCESS_IGNORE                              3


%define DO_PROCESS_DUMP_VMCS                            0
%define DO_PROCESS_RESUME                               1
%define DO_PROCESS_DECODE                               2


;;
;; 测试使用的事件 vector 
;;
%define EVENT_INJECT_TEST_VECTOR                        0F0h


;;
;; 中断类型值
;;

%define INTERRUPT_TYPE_EXTERNAL_INTERRUPT               000h
%define INTERRUPT_TYPE_NMI                              200h
%define INTERRUPT_TYPE_HARDWARE_EXCEPTION               300h
%define INTERRUPT_TYPE_SOFTWARE_INTERRUPT               400h
%define INTERRUPT_TYPE_PRIVILEGED_SOFTWARE_EXCEPTION    500h
%define INTERRUPT_TYPE_SOFTWARE_EXCEPTION               600h
%define INTERRUPT_TYPE_OTHER                            700h
%define ERROR_CODE_FLAG                                 800h
%define FIELD_VALID_FLAG                                80000000h


%define INJECT_NMI                                      (FIELD_VALID_FLAG | INTERRUPT_TYPE_NMI | 02h)
%define INJECT_PENDING_MTF_VMEXIT                       (FIELD_VALID_FLAG | INTERRUPT_TYPE_OTHER)
%define INJECT_PRIVILEGED_SOFTWARE_EXCEPTION            (FIELD_VALID_FLAG | INTERRUPT_TYPE_PRIVILEGED_SOFTWARE_EXCEPTION)
%define INJECT_EXTERNAL_INTERRUPT                       (FIELD_VALID_FLAG | INTERRUPT_TYPE_EXTERNAL_INTERRUPT)
%define INJECT_HARDWARE_EXCEPTION                       (FIELD_VALID_FLAG | INTERRUPT_TYPE_HARDWARE_EXCEPTION)
%define INJECT_SOFTWARE_EXCEPTION                       (FIELD_VALID_FLAG | INTERRUPT_TYPE_SOFTWARE_EXCEPTION)
%define INJECT_SOFTWARE_INTERRUPT                       (FIELD_VALID_FLAG | INTERRUPT_TYPE_SOFTWARE_INTERRUPT)


;;
;; 注入的硬件异常
;;
%define INJECT_EXCEPTION_DF                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 8)
%define INJECT_EXCEPTION_TS                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 10)
%define INJECT_EXCEPTION_NP                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 11)
%define INJECT_EXCEPTION_SS                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 12)
%define INJECT_EXCEPTION_GP                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 13)
%define INJECT_EXCEPTION_PF                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 14)
%define INJECT_EXCEPTION_AC                             (INJECT_HARDWARE_EXCEPTION | ERROR_CODE_FLAG | 17)
%define INJECT_EXCEPTION_MC                             (INJECT_HARDWARE_EXCEPTION | 18)
%define INJECT_EXCEPTION_BR                             (INJECT_HARDWARE_EXCEPTION | 5)
%define INJECT_EXCEPTION_UD                             (INJECT_HARDWARE_EXCEPTION | 6)
%define INJECT_EXCEPTION_DB                             (INJECT_HARDWARE_EXCEPTION | 1)

;;
;; 注入的软件异常
;;
%define INJECT_EXCEPTION_BP                             (INJECT_SOFTWARE_EXCEPTION | 3)
%define INJECT_EXCEPTION_OF                             (INJECT_SOFTWARE_EXCEPTION | 4)


;;
;; 注入的系统服务例程　
;;
%define INJECT_SYSTEM_SERVICE                           (INJECT_SOFTWARE_INTERRUPT | SYSTEM_SERVICE_VECTOR)




;;
;; #### VMCS region index for GUEST-STATE AREA ####
;;
%define GUEST_CR0                                       6800h
%define GUEST_CR3                                       6802h
%define GUEST_CR4                                       6804h
%define GUEST_DR7                                       681Ah
%define GUEST_RSP                                       681Ch
%define GUEST_RIP                                       681Eh
%define GUEST_RFLAGS                                    6820h
%define GUEST_ES_SELECTOR                               800h
%define GUEST_CS_SELECTOR                               802h
%define GUEST_SS_SELECTOR                               804h
%define GUEST_DS_SELECTOR                               806h
%define GUEST_FS_SELECTOR                               808h
%define GUEST_GS_SELECTOR                               80Ah
%define GUEST_LDTR_SELECTOR                             80Ch
%define GUEST_TR_SELECTOR                               80Eh
%define GUEST_ES_BASE                                   6806h
%define GUEST_CS_BASE                                   6808h
%define GUEST_SS_BASE                                   680Ah
%define GUEST_DS_BASE                                   680Ch
%define GUEST_FS_BASE                                   680Eh
%define GUEST_GS_BASE                                   6810h
%define GUEST_LDTR_BASE                                 6812h
%define GUEST_TR_BASE                                   6814h
%define GUEST_ES_LIMIT                                  4800h
%define GUEST_CS_LIMIT                                  4802h
%define GUEST_SS_LIMIT                                  4804h
%define GUEST_DS_LIMIT                                  4806h
%define GUEST_FS_LIMIT                                  4808h
%define GUEST_GS_LIMIT                                  480Ah
%define GUEST_LDTR_LIMIT                                480Ch
%define GUEST_TR_LIMIT                                  480Eh
%define GUEST_ES_ACCESS_RIGHTS                          4814h
%define GUEST_CS_ACCESS_RIGHTS                          4816h
%define GUEST_SS_ACCESS_RIGHTS                          4818h
%define GUEST_DS_ACCESS_RIGHTS                          481Ah
%define GUEST_FS_ACCESS_RIGHTS                          481Ch
%define GUEST_GS_ACCESS_RIGHTS                          481Eh
%define GUEST_LDTR_ACCESS_RIGHTS                        4820h
%define GUEST_TR_ACCESS_RIGHTS                          4822h
%define GUEST_GDTR_BASE                                 6816h
%define GUEST_IDTR_BASE                                 6818h
%define GUEST_GDTR_LIMIT                                4810h
%define GUEST_IDTR_LIMIT                                4812h
%define GUEST_IA32_DEBUGCTL_FULL                        2802h
%define GUEST_IA32_DEBUGCTL_HIGH                        2803h
%define GUEST_IA32_SYSENTER_CS                          482Ah
%define GUEST_IA32_SYSENTER_ESP                         6824h
%define GUEST_IA32_SYSENTER_EIP                         6826h
%define GUEST_IA32_PERF_GLOBAL_CTRL_FULL                2808h
%define GUEST_IA32_PERF_GLOBAL_CTRL_HIGH                2809h
%define GUEST_IA32_PAT_FULL                             2804h
%define GUEST_IA32_PAT_HIGH                             2805h
%define GUEST_IA32_EFER_FULL                            2806h
%define GUEST_IA32_EFER_HIGH                            2807h
%define GUEST_SMBASE                                    4828h
%define GUEST_ACTIVITY_STATE                            4826h
%define GUEST_INTERRUPTIBILITY_STATE                    4824h
%define GUEST_PENDING_DEBUG_EXCEPTION                   6822h
%define GUEST_VMCS_LINK_POINTER_FULL                    2800h
%define GUEST_VMCS_LINK_POINTER_HIGH                    2801h
%define GUEST_VMX_PREEMPTION_TIMER_VALUE                482Eh
%define GUEST_PDPTE0_FULL                               280Ah
%define GUEST_PDPTE0_HIGH                               280Bh
%define GUEST_PDPTE1_FULL                               280Ch
%define GUEST_PDPTE1_HIGH                               280Dh
%define GUEST_PDPTE2_FULL                               280Eh
%define GUEST_PDPTE2_HIGH                               280Fh
%define GUEST_PDPTE3_FULL                               2810h
%define GUEST_PDPTE3_HIGH                               2811h
%define GUEST_INTERRUPT_STATUS                          810h


;;
;; #### VMCS region index for HOST-STATE AREA ####
;;
%define HOST_CR0                                        6C00h
%define HOST_CR3                                        6C02h
%define HOST_CR4                                        6C04h
%define HOST_RSP                                        6C14h
%define HOST_RIP                                        6C16h
%define HOST_ES_SELECTOR                                0C00h
%define HOST_CS_SELECTOR                                0C02h
%define HOST_SS_SELECTOR                                0C04h
%define HOST_DS_SELECTOR                                0C06h
%define HOST_FS_SELECTOR                                0C08h
%define HOST_GS_SELECTOR                                0C0Ah
%define HOST_TR_SELECTOR                                0C0Ch
%define HOST_FS_BASE                                    6C06h
%define HOST_GS_BASE                                    6C08h
%define HOST_TR_BASE                                    6C0Ah
%define HOST_GDTR_BASE                                  6C0Ch
%define HOST_IDTR_BASE                                  6C0Eh
%define HOST_IA32_SYSENTER_CS                           4C00h
%define HOST_IA32_SYSENTER_ESP                          6C10h
%define HOST_IA32_SYSENTER_EIP                          6C12h
%define HOST_IA32_PERF_GLOBAL_CTRL_FULL                 2C04h
%define HOST_IA32_PERF_GLOBAL_CTRL_HIGH                 2C05h
%define HOST_IA32_PAT_FULL                              2C00h
%define HOST_IA32_PAT_HIGH                              2C01h
%define HOST_IA32_EFER_FULL                             2C02h
%define HOST_IA32_EFER_HIGH                             2C03h


;;
;; #### VMCS region index for VM-EXECUTION CONTROL FIELDS ####
;;
%define CONTROL_PINBASED                                4000h
%define CONTROL_PROCBASED_PRIMARY                       4002h
%define CONTROL_PROCBASED_SECONDARY                     401Eh
%define CONTROL_EXCEPTION_BITMAP                        4004h
%define CONTROL_PAGE_FAULT_ERROR_CODE_MASK              4006h
%define CONTROL_PAGE_FAULT_ERROR_CODE_MATCH             4008h
%define CONTROL_IOBITMAPA_ADDRESS_FULL                  2000h
%define CONTROL_IOBITMAPA_ADDRESS_HIGH                  2001h
%define CONTROL_IOBITMAPB_ADDRESS_FULL                  2002h
%define CONTROL_IOBITMAPB_ADDRESS_HIGH                  2003h
%define CONTROL_TSC_OFFSET_FULL                         2010h
%define CONTROL_TSC_OFFSET_HIGH                         2011h
%define CONTROL_CR0_GUEST_HOST_MASK                     6000h
%define CONTROL_CR0_READ_SHADOW                         6004h
%define CONTROL_CR4_GUEST_HOST_MASK                     6002h
%define CONTROL_CR4_READ_SHADOW                         6006h
%define CONTROL_CR3_TARGET_VALUE0                       6008h
%define CONTROL_CR3_TARGET_VALUE1                       600Ah
%define CONTROL_CR3_TARGET_VALUE2                       600Ch
%define CONTROL_CR3_TARGET_VALUE3                       600Eh
%define CONTROL_CR3_TARGET_COUNT                        400Ah
%define CONTROL_APIC_ACCESS_ADDRESS_FULL                2014h
%define CONTROL_APIC_ACCESS_ADDRESS_HIGH                2015h
%define CONTROL_VIRTUAL_APIC_ADDRESS_FULL               2012h
%define CONTROL_VIRTUAL_APIC_ADDRESS_HIGH               2013h
%define CONTROL_TPR_THRESHOLD                           401Ch
%define CONTROL_EOIEXIT_BITMAP0_FULL                    201Ch
%define CONTROL_EOIEXIT_BITMAP0_HIGH                    201Dh
%define CONTROL_EOIEXIT_BITMAP1_FULL                    201Eh
%define CONTROL_EOIEXIT_BITMAP1_HIGH                    201Fh
%define CONTROL_EOIEXIT_BITMAP2_FULL                    2020h
%define CONTROL_EOIEXIT_BITMAP2_HIGH                    2021h
%define CONTROL_EOIEXIT_BITMAP3_FULL                    2022h
%define CONTROL_EOIEXIT_BITMAP3_HIGH                    2023h
%define CONTROL_POSTED_INTERRUPT_NOTIFICATION_VECTOR    2h
%define CONTROL_POSTED_INTERRUPT_DESCRIPTOR_ADDRESS_FULL        2016h
%define CONTROL_POSTED_INTERRUPT_DESCRIPTOR_ADDRESS_HIGH        2017h
%define CONTROL_MSR_BITMAP_ADDRESS_FULL                 2004h
%define CONTROL_MSR_BITMAP_ADDRESS_HIGH                 2005h
%define CONTROL_EXECUTIVE_VMCS_POINTER_FULL             200Ch
%define CONTROL_EXECUTIVE_VMCS_POINTER_HIGH             200Dh
%define CONTROL_EPT_POINTER_FULL                        201Ah
%define CONTROL_EPT_POINTER_HIGH                        201Bh
%define CONTROL_VPID                                    0h
%define CONTROL_PLE_GAP                                 4020h
%define CONTROL_PLE_WINDOW                              4022h
%define CONTROL_VM_FUNCTION_FULL                        2018h
%define CONTROL_VM_FUNCTION_HIGH                        2019h
%define CONTROL_EPTP_LIST_FULL                          2024h
%define CONTROL_EPTP_LIST_HIGH                          2025h



;;
;; #### VMCS region index for VM-EXIT CONTROL FIELDS ####
;;
%define VMEXIT_CONTROL                                  400Ch
%define VMEXIT_MSR_STORE_COUNT                          400Eh
%define VMEXIT_MSR_STORE_ADDRESS_FULL                   2006h
%define VMEXIT_MSR_STORE_ADDRESS_HIGH                   2007h
%define VMEXIT_MSR_LOAD_COUNT                           4010h
%define VMEXIT_MSR_LOAD_ADDRESS_FULL                    2008h
%define VMEXIT_MSR_LOAD_ADDRESS_HIGH                    2009h


;;
;; #### VMCS region index for VM-ENTRY CONTROL FIELDS ####
;;

%define VMENTRY_CONTROL                                 4012h
%define VMENTRY_MSR_LOAD_COUNT                          4014h
%define VMENTRY_MSR_LOAD_ADDRESS_FULL                   200Ah
%define VMENTRY_MSR_LOAD_ADDRESS_HIGH                   200Bh
%define VMENTRY_INTERRUPTION_INFORMATION                4016h
%define VMENTRY_EXCEPTION_ERROR_CODE                    4018h
%define VMENTRY_INSTRUCTION_LENGTH                      401Ah


;;
;; #### VMCS region index for VM-EXIT INFORMATION FIELDS ####
;;

%define EXIT_REASON                                     4402h
%define EXIT_QUALIFICATION                              6400h
%define GUEST_LINEAR_ADDRESS                            640Ah
%define GUEST_PHYSICAL_ADDRESS_FULL                     2400h
%define GUEST_PHYSICAL_ADDRESS_HIGH                     2401h
%define VMEXIT_INTERRUPTION_INFORMATION                 4404h
%define VMEXIT_INTERRUPTION_ERROR_CODE                  4406h
%define IDT_VECTORING_INFORMATION                       4408h
%define IDT_VECTORING_ERROR_CODE                        440Ah
%define VMEXIT_INSTRUCTION_LENGTH                       440Ch
%define VMEXIT_INSTRUCTION_INFORMATION                  440Eh
%define IO_RCX                                          6402h
%define IO_RSI                                          6404h
%define IO_RDI                                          6406h
%define IO_RIP                                          6408h
%define VM_INSTRUCTION_ERROR                            4400h




;;
;; ####### Basic Exit Reasons ######
;;

%define EXIT_NUMBER_EXCEPTION_MNI                       0
%define EXIT_NUMBER_EXTERNAL_INTERRUPT                  1
%define EXIT_NUMBER_TRIPLE_FAULT                        2
%define EXIT_NUMBER_INIT                                3
%define EXIT_NUMBER_SIPI                                4
%define EXIT_NUMBER_IOSMI                               5
%define EXIT_NUMBER_SMI                                 6
%define EXIT_NUMBER_INTERRUPT_WINDOW                    7
%define EXIT_NUMBER_NMI_WINDOW                          8
%define EXIT_NUMBER_TASK_SWITCH                         9
%define EXIT_NUMBER_CPUID                               10
%define EXIT_NUMBER_GETSEC                              11
%define EXIT_NUMBER_HLT                                 12
%define EXIT_NUMBER_INVD                                13
%define EXIT_NUMBER_INVLPG                              14
%define EXIT_NUMBER_RDPMC                               15
%define EXIT_NUMBER_RDTSCC                              16
%define EXIT_NUMBER_RSM                                 17
%define EXIT_NUMBER_VMCALL                              18
%define EXIT_NUMBER_VMCLEAR                             19
%define EXIT_NUMBER_VMLAUNCH                            20
%define EXIT_NUMBER_VMPTRLD                             21
%define EXIT_NUMBER_VMPTRSD                             22
%define EXIT_NUMBER_VMREAD                              23
%define EXIT_NUMBER_VMRESUME                            24
%define EXIT_NUMBER_VMWRITE                             25
%define EXIT_NUMBER_VMXOFF                              26
%define EXIT_NUMBER_VMXON                               27
%define EXIT_NUMBER_CR_ACCESS                           28
%define EXIT_NUMBER_MOV_DR                              29
%define EXIT_NUMBER_IO_ACCESS                           30
%define EXIT_NUMBER_RDMSR                               31
%define EXIT_NUMBER_WRMSR                               32
%define EXIT_NUMBER_VMENTRY_FAILURE_GUEST_STATE         33
%define EXIT_NUMBER_VMENTRY_FAILURE_MSR_LOADING         34
%define EXIT_NUMBER_MWAIT                               36
%define EXIT_NUMBER_MTF                                 37
%define EXIT_NUMBER_MONITOR                             39
%define EXIT_NUMBER_PAUSE                               40
%define EXIT_NUMBER_VMENTRY_FAILURE_MCA                 41
%define EXIT_NUMBER_TPR_BELOW_THRESHOLD                 43
%define EXIT_NUMBER_APIC_ACCESS                         44
%define EXIT_NUMBER_EOI                                 45
%define EXIT_NUMBER_GDTR_IDTR_ACCESS                    46
%define EXIT_NUMBER_LDTR_TR_ACCESS                      47
%define EXIT_NUMBER_EPT_VIOLATION                       48
%define EXIT_NUMBER_EPT_MISCONFIGURATION                49
%define EXIT_NUMBER_INVEPT                              50
%define EXIT_NUMBER_RDTSCP                              51
%define EXIT_NUMBER_VMX_PREEMPTION_TIMER                52
%define EXIT_NUMBER_INVVPID                             53
%define EXIT_NUMBER_WBINVD                              54
%define EXIT_NUMBER_XSETBV                              55
%define EXIT_NUMBER_APIC_WRITE                          56
%define EXIT_NUMBER_RDRAND                              57
%define EXIT_NUMBER_INVPCID                             58
%define EXIT_NUMBER_VMFUNC                              59



;;
;; ###### VM instruction error number ######
;;





;;
;; 内存类型: 
;; 1) Uncacheable(UC)
;; 2) WriteBack(WB)
;;

%define MEM_TYPE_UC                                     0
%define MEM_TYPE_WB                                     6
%define MEM_TYPE_WT                                     4
%define MEM_TYPE_WP                                     5
%define MEM_TYPE_WC                                     1

;;
;; EPT 页结构内存类型
;;
%define EPT_MEM_WB                                      (MEM_TYPE_WB << 3)
%define EPT_MEM_UC                                      (MEM_TYPE_UC << 3)
%define EPT_MEM_WT                                      (MEM_TYPE_WT << 3)
%define EPT_MEM_WP                                      (MEM_TYPE_WP << 3)
%define EPT_MEM_WC                                      (MEM_TYPE_WC << 3)


;;
;; segment 中的 access rights 值
;;
%define TYPE_cewa                                       0               ; expand-up data
%define TYPE_cewA                                       1               ; expand-up/accessed data
%define TYPE_ceWa                                       2               ; expand-up/writable data
%define TYPE_ceWA                                       3               ; expand-up/writable/accessed data
%define TYPE_cEwa                                       4               ; expand-down data
%define TYPE_cEwA                                       5               ; expand-down/accessed data
%define TYPE_cEWa                                       6               ; expand-down/writable data
%define TYPE_cEWA                                       7               ; expand-down/writable/access data
%define TYPE_Ccra                                       8               ; non-conforming code
%define TYPE_CcrA                                       9               ; non-conforming/accessed code
%define TYPE_CcRa                                       10              ; non-conforming/readable code
%define TYPE_CcRA                                       11              ; non-conforming/readable/accessed code
%define TYPE_CCra                                       12              ; conforming code
%define TYPE_CCrA                                       13              ; conforming/Accessed code
%define TYPE_CCRa                                       14              ; conforming/readable code
%define TYPE_CCRA                                       15              ; conforming/readable/Accessed code

%define TYPE_LDT                                        2               ; LDT
%define TYPE_TSS16                                      1               ; 16-bit available TSS
%define TYPE_BUSY_TSS16                                 3               ; 16-bit busy TSS
%define TYPE_TSS32                                      9               ; 32-bit available TSS
%define TYPE_BUSY_TSS32                                 11              ; 32-bit busy TSS
%define TYPE_BUSY_TSS64                                 11              ; 64-bit busy TSS


%define TYPE_SYS                                        0               ; system segment
%define TYPE_NON_SYS                                    10h             ; code or data
%define SEG_P                                           80h             ; segment present
%define SEG_G                                           8000h           ; granularity
%define SEG_D                                           4000h           ; 32-bit segment
%define SEG_U                                           10000h          ; segment unusable
%define SEG_L                                           2000h           ; 64-bit code
%define CSEG_64                                         SEG_L           
%define CSEG_32                                         SEG_D           
%define CSEG_MASK                                       6000h

%define SEG_uGDlP                                       0C080h          ; G=D=P=1,L=U=0
%define SEG_uGdLP                                       0A080h          ; G=L=P=1, U=D=0
%define SEG_ugdLP                                       02080h          ; L=P=1, G=U=D=0
%define SEG_Ugdlp                                       10000h          ; U=1, G=D=L=P=0
%define SEG_ugdlP                                       80h             ; U=G=D=L=0, P=1
%define SEG_ugDlP                                       4080h           ; U=G=L=0, D=P=1


%define DPL_0                                           0
%define DPL_1                                           20h
%define DPL_2                                           40h
%define DPL_3                                           60h


;;
;; access rights 标志位
;;
%define ACCESS_RIGHT_S                                  (1 << 4)
%define ACCESS_RIGHT_P                                  (1 << 7)
%define ACCESS_RIGHT_AVL                                (1 << 12)
%define ACCESS_RIGHT_L                                  (1 << 13)
%define ACCESS_RIGHT_D                                  (1 << 14)
%define ACCESS_RIGHT_G                                  (1 << 15)
%define ACCESS_RIGHT_U                                  (1 << 16)


;;
;; PFEC 值定义
;;
%define PFEC_iruwp                                      0h              ; I=R=U=W=P=0
%define PFEC_iruWP                                      3h              ; I=R=U=0, W=P=1
%define PFEC_irUwP                                      5h              ; I=R=W=0, U=P=1
%define PFEC_irUWP                                      7h              ; I=R=0, U=W=P=1
%define PFEC_iRuwP                                      9h              ; I=U=W=0, R=P=1
%define PFEC_iRuWP                                      0Bh             ; I=U=0, R=W=P=1
%define PFEC_iRUwP                                      0Dh             ; I=W=0, R=U=P=1
%define PFEC_iRUWP                                      0Fh             ; I=0, R=U=W=P=1
%define PFEC_IruWP                                      13h             ; R=U=W=0, I=P=1
%define PFEC_IrUwP                                      15h             ; R=U=W=0, I=P=1
%define PFEC_IrUWP                                      17h             ; R=U=W=0, I=P=1
%define PFEC_IRuwP                                      19h             ; R=U=W=0, I=P=1
%define PFEC_IRuWP                                      1Bh             ; R=U=W=0, I=P=1
%define PFEC_IRUwP                                      1Dh             ; R=U=W=0, I=P=1
%define PFEC_IRUWP                                      1Fh             ; R=U=W=0, I=P=1

%define PFEC_MASK                                       0FFFFFFFFh      ; 忽略 U/S 位 (bit 2)




;;
;; ####### guest activity state 值 ######
;;

%define GUEST_STATE_ACTIVE                              0
%define GUEST_STATE_HLT                                 1
%define GUEST_STATE_SHUTDOWN                            2
%define GUEST_STATE_WAIT_FOR_SIPI                       3



;;
;; ####### guest interruptibility state 值 ######
;;

%define GUEST_BLOCKING_BY_STI                           01h
%define GUEST_BLOCKING_BY_MOVSS                         02h
%define GUEST_BLOCKING_BY_SMI                           04h
%define GUEST_BLOCKING_BY_NMI                           08h


;;
;; ####### guest pending debug exception 值 ######
;;
%define GUEST_PENDING_DEBUG_B0                          01h
%define GUEST_PENDING_DEBUG_B1                          02h
%define GUEST_PENDING_DEBUG_B2                          04h
%define GUEST_PENDING_DEBUG_B3                          08h
%define GUEST_PENDING_DEBUG_BS                          4000h
%define GUEST_PENDING_DEBUG_ENABLED                     1000h                  

%define DB_TYPE_SINGLE_STEP                             4000h
%define DB_TYPE_BREAKPOINT                              1000h



;;
;; ####### exception control fields 常量 ######
;;
%define EXTERNAL_INTERRUPT_EXITING                      01h
%define NMI_EXITING                                     08h
%define VIRTUAL_NMI                                     20h
%define ACTIVATE_VMX_PREEMPTION_TIMER                   40h
%define PROCESS_POSTED_INTERRUPT                        80h

%define INTERRUPT_WINDOW_EXITING                        04h
%define USE_TSC_OFFSETTING                              08h
%define HLT_EXITING                                     80h
%define INVLPG_EXITING                                  200h
%define MWAIT_EXITING                                   400h
%define RDPMC_EXITING                                   800h
%define RDTSC_EXITING                                   1000h
%define CR3_LOAD_EXITING                                8000h
%define CR3_STORE_EXITING                               10000h
%define CR8_LOAD_EXITING                                80000h
%define CR8_STORE_EXITING                               100000h
%define USE_TPR_SHADOW                                  200000h
%define NMI_WINDOW_EXITING                              400000h
%define MOV_DR_EXITING                                  800000h
%define UNCONDITIONAL_IO_EXITING                        1000000h
%define USE_IO_BITMAP                                   2000000h
%define MONITOR_TRAP_FLAG                               8000000h
%define USE_MSR_BITMAP                                  10000000h
%define MONITOR_EXITING                                 20000000h
%define PAUSE_EXITING                                   40000000h
%define ACTIVATE_SECONDARY_CONTROL                      80000000h

%define VIRTUALIZE_APIC_ACCESS                          01h
%define ENABLE_EPT                                      02h
%define DESCRIPTOR_TABLE_EXITING                        04h
%define ENABLE_RDTSCP                                   08h
%define VIRTUALIZE_X2APIC_MODE                          10h
%define ENABLE_VPID                                     20h
%define WBINVD_EXITING                                  40h
%define UNRESTRICTED_GUEST                              80h
%define APIC_REGISTER_VIRTUALIZATION                    100h
%define VIRTUAL_INTERRUPT_DELIVERY                      200h
%define PAUSE_LOOP_EXITING                              400h
%define RDRAND_EXITING                                  800h
%define ENABLE_INVPCID                                  1000h
%define ENABLE_VM_FUNCTION                              2000h

;;
;; ####### vm exit control fields 常量 ######
;;
%define SAVE_DEBUG_CONTROL                              10h
%define HOST_ADDRESS_SPACE_SIZE                         200h
%define VMEXIT_LOAD_IA32_PREF_GLOBAL_CTRL               1000h
%define ACKNOWLEDGE_INTERRUPT_ON_EXIT                   8000h
%define VMEXIT_SAVE_IA32_PAT                            40000h
%define VMEXIT_LOAD_IA32_PAT                            80000h
%define VMEXIT_SAVE_IA32_EFER                           100000h
%define VMEXIT_LOAD_IA32_EFER                           200000h
%define SAVE_VMX_PREEMPTION_TIMER_VALUE                 400000h


;;
;; ####### vm entry control fields 常量 ######
;;
%define VMENTRY_LOAD_DEBUG_CONTROL                      10h
%define IA32E_MODE_GUEST                                200h
%define ENTRY_TO_SMM                                    400h
%define DEACTIVE_DUAL_MONITOR_TREATMENT                 800h
%define VMENTRY_LOAD_IA32_PERF_GLOBAL_CTRL              2000h
%define VMENTRY_LOAD_IA32_PAT                           4000h
%define VMENTRY_LOAD_IA32_EFER                          8000h


;;
;; ####### vm function control ######
;;
%define EPTP_SWITCHING                                  01h





;;
;; ####### VM-exit 原因码 ######
;;
%define EXIT_REASON_MTF                                 37





;----------------------------------------------
; DoVmWrite
; input:
;       %1 - vmcs ID
;       %2 - value (memory)
; output:
;       none
;----------------------------------------------
%macro DoVmWrite 2
%if __BITS__ == 64
%if %1 == eax
        mov rax, rax
%elif %1 == ecx
        mov rax, rcx
%elif %1 == edx
        mov rax, rdx
%elif %1 == ebx
        mov rax, rbx
%elif %1 == esp
        mov rax, rsp
%elif %1 == ebp
        mov rax, rbp
%elif %1 == esi
        mov rax, rsi
%elif %1 == edi
        mov rax, rdi
%else
        mov rax, %1
%endif

        vmwrite rax, %2
%else
        mov eax, %1
        vmwrite eax, %2
%endif
%endmacro


;----------------------------------------------
; DoVmRead
; input:
;       %1 - vmcs ID
;       %2 - target value (memory)
; output:
;       %2 - target value
;----------------------------------------------
%macro DoVmRead 2
%if __BITS__ == 64
%if %1 == eax
        mov rax, rax
%elif %1 == ecx
        mov rax, rcx
%elif %1 == edx
        mov rax, rdx
%elif %1 == ebx
        mov rax, rbx
%elif %1 == esp
        mov rax, rsp
%elif %1 == ebp
        mov rax, rbp
%elif %1 == esi
        mov rax, rsi
%elif %1 == edi
        mov rax, rdi
%else
        mov rax, %1
%endif
        vmread %2, rax
%else
        mov eax, %1
        vmread %2, eax
%endif
%endmacro



;----------------------------------------------
; GetVmcsField
; input:
;       %1 - VMCS ID
; output:
;       eax - field value
;----------------------------------------------
%macro GetVmcsField     1
%if __BITS__ == 64
        mov rsi, %1
        vmread rax, rsi
%else
        mov esi, %1
        vmread eax, esi
%endif        
%endmacro



;----------------------------------------------
; SetVmcsField
; input:
;       %1 - VMCS ID
;       %2 - value
; output:
;       none
;----------------------------------------------
%macro SetVmcsField     2
%if __BITS__ == 64
        mov esi, %1

%if %2 == eax
        mov rdi, rax
%elif %2 == ecx
        mov rdi, rcx
%elif %2 == edx
        mov rdi, rdx
%elif %2 == ebx
        mov rdi, rbx
%elif %2 == esp
        mov rdi, rsp
%elif %2 == ebp
        mov rdi, rbp
%elif %2 == esi
        mov rdi, rsi
%elif %2 == edi
        mov rdi, rdi
%else
        mov rdi, %2
%endif
        vmwrite rsi, rdi



%else
        ;;
        ;; 32 位下编译
        ;;
        mov esi, %1

%if %2 == eax
        REX.Wrxb
        mov edi, eax
%elif %2 == ecx
        REX.Wrxb
        mov edi, ecx
%elif %2 == edx
        REX.Wrxb
        mov edi, edx
%elif %2 == ebx
        REX.Wrxb
        mov edi, ebx
%elif %2 == esp
        REX.Wrxb
        mov edi, esp
%elif %2 == ebp
        REX.Wrxb
        mov edi, ebp
%elif %2 == esi
        REX.Wrxb
        mov edi, esi
%elif %2 == edi
        REX.Wrxb
        mov edi, edi
%else
%if %2 > 0FFFFFFFFh
        REX.Wrxb
        mov edi, %2
%else
        mov edi, %2
%endif
%endif
        vmwrite esi, edi
%endif
%endmacro






;----------------------------------------------
; 宏 MakeControlBits
; input:
;       %1 - 最初设置的 control 值
;       %2 - Ctls MSR 的地址
; output:
;       %1 - 最终的 control 值
;
; 使用示例: 
;       mov eax, 0EE04h                                 ; 用户设置 VM-entrt control 域值放在 eax 
;       MakeControlBits eax, ebp + VGA.EnterCtls        ; 合成最终的 VM-entry control 值返回在 eax
;----------------------------------------------
%macro MakeControlBits 2
        ;;
        ;; 说明:
        ;; 1) 或上 allowed 0-setting 值
        ;; 2) 与上 allowed 1-setting 值
        ;;
        or %1, [%2]                     ; 低 32 位为 allowed 0-setting 
        and %1, [%2 + 4]                ; 高 32 位为 allowed 1-setting
%endmacro
        




;----------------------------------------------
; STORE_GUREST_CONTEXT
; input:
;       none
; output:
;       none
; 描述: 
;       1) 保存 guest context
;----------------------------------------------
%macro STORE_GUEST_CONTEXT 0

%if __BITS__ == 64
        ;;
        ;; 在 64 位下编译
        ;;
        mov [gs: PCB.Rax], rax
        mov [gs: PCB.Rcx], rcx
        mov [gs: PCB.Rdx], rdx
        mov [gs: PCB.Rbx], rbx
        mov [gs: PCB.Rbp], rbp
        mov [gs: PCB.Rsi], rsi
        mov [gs: PCB.Rdi], rdi
        mov [gs: PCB.R8], r8
        mov [gs: PCB.R9], r9
        mov [gs: PCB.R10], r10
        mov [gs: PCB.R11], r11
        mov [gs: PCB.R12], r12
        mov [gs: PCB.R13], r13
        mov [gs: PCB.R14], r14
        mov [gs: PCB.R15], r15
        mov eax, GUEST_RSP
        vmread [gs: PCB.Rsp], rax
        mov eax, GUEST_RIP
        vmread [gs: PCB.Rip], rax
%else
        ;;
        ;; 在 32 位下编译
        ;;
        %ifdef __X64
                StoreToPcb        PCB.Rax, rax
                StoreToPcb        PCB.Rcx, rcx
                StoreToPcb        PCB.Rdx, rdx
                StoreToPcb        PCB.Rbx, rbx
                StoreToPcb        PCB.Rbp, rbp
                StoreToPcb        PCB.Rsi, rsi
                StoreToPcb        PCB.Rdi, rdi
                StoreToPcb        PCB.R8, r8
                StoreToPcb        PCB.R9, r9
                StoreToPcb        PCB.R10, r10
                StoreToPcb        PCB.R11, r11
                StoreToPcb        PCB.R12, r12
                StoreToPcb        PCB.R13, r13
                StoreToPcb        PCB.R14, r14
                StoreToPcb        PCB.R15, r15
        %else
                StoreToPcb        PCB.Eax, eax
                StoreToPcb        PCB.Ecx, ecx
                StoreToPcb        PCB.Edx, edx
                StoreToPcb        PCB.Ebx, ebx
                StoreToPcb        PCB.Ebp, ebp
                StoreToPcb        PCB.Esi, esi
                StoreToPcb        PCB.Edi, edi 
        %endif

        ;;
        ;; 保存 guest 的 RSP 及 RIP 值
        ;;
        mov eax, GUEST_RSP
        mov esi, PCB.Esp
        vmread [gs: esi], eax
        mov eax, GUEST_RIP
        mov esi, PCB.Eip
        vmread [gs: esi], eax
%endif

%endmacro



;----------------------------------------------
; RESTORE_GUREST_CONTEXT
; input:
;       none
; output:
;       none
; 描述: 
;       1) 恢复 guest context
;----------------------------------------------
%macro RESTORE_GUEST_CONTEXT 0

%if __BITS__ == 64
        ;;
        ;; 在 64 位下编译
        ;;
        mov rax, [gs: PCB.Rax]
        mov rcx, [gs: PCB.Rcx]
        mov rdx, [gs: PCB.Rdx]
        mov rbx, [gs: PCB.Rbx]
        mov rbp, [gs: PCB.Rbp]
        mov rsi, [gs: PCB.Rsi]
        mov rdi, [gs: PCB.Rdi]
        mov r8, [gs: PCB.R8]
        mov r9, [gs: PCB.R9]
        mov r10, [gs: PCB.R10]
        mov r11, [gs: PCB.R11]
        mov r12, [gs: PCB.R12]
        mov r13, [gs: PCB.R13]
        mov r14, [gs: PCB.R14]
        mov r15, [gs: PCB.R15]
%else
        ;;
        ;; 在 32 位下编译
        ;;
        %ifdef __X64
                LoadFromPcb     rax, PCB.Rax
                LoadFromPcb     rcx, PCB.Rcx
                LoadFromPcb     rdx, PCB.Rdx
                LoadFromPcb     rbx, PCB.Rbx
;;                LoadFromPcb     rsp, PCB.Rsp
                LoadFromPcb     rbp, PCB.Rbp
                LoadFromPcb     rsi, PCB.Rsi
                LoadFromPcb     rdi, PCB.Rdi
                LoadFromPcb     r8, PCB.R8
                LoadFromPcb     r9, PCB.R9
                LoadFromPcb     r10, PCB.R10
                LoadFromPcb     r11, PCB.R11
                LoadFromPcb     r12, PCB.R12
                LoadFromPcb     r13, PCB.R13
                LoadFromPcb     r14, PCB.R14
                LoadFromPcb     r15, PCB.R15
        %else
                LoadFromPcb     eax, PCB.Eax
                LoadFromPcb     ecx, PCB.Ecx
                LoadFromPcb     edx, PCB.Edx
                LoadFromPcb     ebx, PCB.Ebx
;;                LoadFromPcb     esp, PCB.Esp
                LoadFromPcb     ebp, PCB.Ebp
                LoadFromPcb     esi, PCB.Esi
                LoadFromPcb     edi, PCB.Edi
        %endif
%endif
%endmacro





%endif
