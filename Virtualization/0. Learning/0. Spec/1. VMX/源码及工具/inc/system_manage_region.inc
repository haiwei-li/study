;*************************************************
;* system_manage_region.inc                      *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

%ifndef _SYSTEM_MANAGE_REGION_INC
%define _SYSTEM_MANAGE_REGION_INC



%define SSE                                     0100h
%define SSE2                                    0200h
%define SSE3                                    0300h
%define SSSE                                    0301h
%define SSE4_1                                  0401h
%define SSE4_2                                  0402h

%define CPU_STATUS_PE                           1
%define CPU_STATUS_PG                           2
%define CPU_STATUS_PAE                          4
%define CPU_STATUS_PSE                          8
%define CPU_STATUS_LONG                         10h
%define CPU_STATUS_64                           20h
%define CPU_STATUS_COMPATIBILITY                40h
%define CPU_STATUS_VMXON                        100h
%define CPU_STATUS_SMEP                         1000h
%define CPU_STATUS_GUEST                        10000000h
%define CPU_STATUS_GUEST_FOCUS                  20000000h
%define CPU_STATUS_GUEST_EXIST                  40000000h
%define CPU_STATUS_VMM                          80000000h  


%define CPU_STATE_ACTIVE                        0
%define CPU_STATE_HLT                           1
%define CPU_STATE_SHUTDOWN                      2
%define CPU_STATE_WAIT_FOR_SIPI                 3


%define INST_STATUS_SSE                         1
%define INST_STATUS_RWFSBASE                    2
%define INST_STATUS_VMX                         4

%define DEBUG_STATUS_B0_ENABLE                  1
%define DEBUG_STATUS_B1_ENABLE                  2
%define DEBUG_STATUS_B2_ENABLE                  4
%define DEBUG_STATUS_B4_ENABLE                  8
%define DEBUG_STATUS_BS_ENABLE                  10h
%define DEBUG_STATUS_BD_ENABLE                  20h
%define DEBUG_STATUS_BT_ENABLE                  40h
%define DEBUG_STATUS_LBR_ENABLE                 100h
%define DEBUG_STATUS_BTF_ENABLE                 200h
%define DEBUG_STATUS_BTS_READY                  400h
%define DEBUG_STATUS_BTINT_READY                800h
%define DEBUG_STATUS_PEBS_READY                 1000h
%define DEBUG_STATUS_BTS_ENABLE                 2000h
%define DEBUG_STATUS_BTINT_ENABLE               4000h
%define DEBUG_STATUS_DS_READY                   8000h


%define DEBUG_BTS_AVAILABLE                     1
%define DEBUG_DS64_AVAILABLE                    2
%define DEBUG_PEBS_AVAILABLE                    4
%define DEBUG_PEBS_ENH_AVAILABLE                8
%define DEBUG_DS_CPL_AVAILABLE                  10h



%define PERF_FREEZE_SMM_AVAILABLE               1000h
%define PERF_FW_WRITE_AVAILABLE                 2000h
%define PERF_TRAP_REPORT_AVAILABLE              0040h
%define PERF_REG_REPORT_AVAILABLE               0080h
%define PERF_PEBS_ENH_AVAILABLE                 0100h

%define PERF_STATUS_PMI_ENABLE                  1
%define PERF_STATUS_PEBS_ENABLE                 2

;;
;; 对应于 CPUID.01H:ECX 标志位 
;;
%define CPU_FLAGS_SSE3                          1
%define CPU_FLAGS_GFMUL                         2
%define CPU_FLAGS_DS64                          4
%define CPU_FLAGS_MONITOR                       8
%define CPU_FLAGS_DSCPL                         10h
%define CPU_FLAGS_VMX                           20h
%define CPU_FLAGS_SMX                           40h
%define CPU_FLAGS_EST                           80h
%define CPU_FLAGS_THERMAL_MONITOR               100h
%define CPU_FLAGS_SSSE3                         200h
%define CPU_FLAGS_CONTEXT_ID                    400h
%define CPU_FLAGS_FMA                           1000h
%define CPU_FLAGS_CMPXCHG16B                    2000h
%define CPU_FLAGS_XPTR                          4000h
%define CPU_FLAGS_PDMC                          8000h
%define CPU_FLAGS_PCID                          20000h
%define CPU_FLAGS_DCA                           40000h
%define CPU_FLAGS_SSE41                         80000h                         
%define CPU_FLAGS_SSE42                         100000h
%define CPU_FLAGS_X2APIC                        200000h
%define CPU_FLAGS_MOVBE                         400000h
%define CPU_FLAGS_POPCNT                        800000h
%define CPU_FLAGS_TSC_DEADLINE                  1000000h
%define CPU_FLAGS_AES                           2000000h
%define CPU_FLAGS_XSAVE                         4000000h
%define CPU_FLAGS_OSXSAVE                       8000000h
%define CPU_FLAGS_AVX                           10000000h
%define CPU_FLAGS_F16C                          20000000h
%define CPU_FLAGS_RDRAND                        40000000h

;;
;; 对应于 CPUID.01H:EDX 标志位
;;
%define CPU_FLAGS_FPU                           1
%define CPU_FLAGS_VME                           2
%define CPU_FLAGS_DE                            4
%define CPU_FLAGS_PSE                           8
%define CPU_FLAGS_TSC                           10h
%define CPU_FLAGS_MSR                           20h
%define CPU_FLAGS_PAE                           40h
%define CPU_FLAGS_MCE                           80h
%define CPU_FLAGS_CMPXCHG8B                     100h
%define CPU_FLAGS_APIC                          200h
%define CPU_FLAGS_SEP                           800h
%define CPU_FLAGS_MTRR                          1000h
%define CPU_FLAGS_PGE                           2000h
%define CPU_FLAGS_MCA                           4000h
%define CPU_FLAGS_CMOV                          8000h
%define CPU_FLAGS_PAT                           10000h
%define CPU_FLAGS_PSE36                         20000h
%define CPU_FLAGS_PSN                           40000h
%define CPU_FLAGS_CLFLUSH                       80000h
%define CPU_FLAGS_DS                            200000h
%define CPU_FLAGS_ACPI                          400000h
%define CPU_FLAGS_MMX                           800000h
%define CPU_FLAGS_FXSAVE                        1000000h
%define CPU_FLAGS_SSE                           2000000h
%define CPU_FLAGS_SSE2                          4000000h
%define CPU_FLAGS_SS                            8000000h
%define CPU_FLAGS_HTT                           10000000h
%define CPU_FLAGS_TCC                           20000000h
%define CPU_FLAGS_PBE                           80000000h


;;
;; 最大支持 16 个 cpu
;;
CPU_COUNT_MAX                           EQU     16


;;
;; 每个 CPU 的 GDT 大小
;;
GDT_TABLE_SIZE                          EQU     100h


;;
;; selector 常量
;;
KernelCsSelector64                      EQU     08h
KernelSsSelector64                      EQU     10h
UserCsSelector32                        EQU     18h
UserSsSelector32                        EQU     20h
UserCsSelector64                        EQU     28h
UserSsSelector64                        EQU     30h
KernelCsSelector32                      EQU     38h
KernelSsSelector32                      EQU     40h
FsSelector                              EQU     48h
GsSelector                              EQU     50h
TssSelector32                           EQU     58h
NextSelector                            EQU     68h


;;
;; 虚拟机内存 domain 池, 每个虚拟机的物理内存从这个 domain 池中分配
;; 1)domain pool 物理基址为 0800_0000h
;; 2)每个 domain 为 8M
;;
;; 示例: 
;; VM1 domain: 0800_0000h 到 087F_FFFFh
;; VM2 domain: 0880_0000h 到 08FF_FFFFh
;; ... ...
;;
DOMAIN_SIZE                             EQU     (8 * 100000h)
DOMAIN_PHYSICAL_BASE                    EQU     08000000h
DOMAIN_BASE                             EQU     88000000h
DOMAIN_BASE64                           EQU     0FFFFF80088000000h
DOMAIN_POOL_SIZE                        EQU     8000000h





;;*
;;* 定义 Processor Control Block 结构, 使用于 gs 进行维护 
;*
;;* 说明: 
;;* 1) 每个 logical processor 有自己的一份 PCB 数据, 总共容纳 16 个 logical processor
;;* 2) 每份 PCB 数据共 4K size
;;* 3) 在 legacy 模式下使用 32 位数据, 在 long 模式下更新为 64 位数据
;;* 4) 大多数数据定义为 64 位宽(QWORD类型), 在 legacy 模式下使用低 32, long 模式下使用 full-width
;;* 


struc PCB
        ;;
        ;; 系统管理区域基址, gs:[0] 取得 PCB 管理区基址, 这个基址是 virtual address
        ;; 而 PhysicalBase 记录着物理地址!
        ;;
        .Base                   RESQ            1               ; 保存 PCB 基址
        .PhysicalBase           RESQ            1               ; PCB 物理基址
        .Size                   RESD            1               ; PCB size
        .SdaBase                RESQ            1               ; 指向系统数据区域
        .SdaPhysicalBase        RESQ            1               ; SDA 物理地址
        .SrtBase                RESQ            1               ; 指向系统服务例程表区域
        .SrtPhysicalBase        RESQ            1               ; SRT 物理地址
        .LsbBase                RESQ            1               ; 指向本地存储块
        .LsbPhysicalBase        RESQ            1               ; LSB 物理地址
        .ReturnStackPointer     RESQ            1               ; 指向 ReturnStack
        .PptPhysicalBase        RESQ            1

        ALIGNB 16
        .Ppt                    RESQ            4

        ;;
        ;; 处理器内存 domain 范围 
        ;;        
        .Domain                 RESQ            1               ; 内存 domain
        .DomainTop              RESQ            1               ; domain 顶部

        ;;
        ;; 当前与上一个优先级, 用于管理中断
        ;;
        .CurrentTpl             RESD            1
        .PrevTpl                RESD            1


        ALIGNB 4
        ;;
        ;; IPI 中断执行的 routine 入口
        ;;
        .IpiRoutinePointer      RESQ            1
        .IpiRoutineParameter    RESQ            1
        .IpiRoutineBottomHalf   RESQ            1

        ;;
        ;; idle loop routine 入口
        ;;
        .IdleLoopRoutine        RESQ            1



        ;;
        ;; 记录最后一次 status code
        ;;
        .LastStatusCode         RESD            1

        ;;
        ;; 记录处理器发生的 exception 位图
        ;; 1) 异常发生后 ExceptionBitMask 相应位置位
        ;;
        .ExceptionBitMask       RESD            1


        ;;
        ;; 记录 VMX 的 VMXON pointer
        ;;
        .VmxonPointer           RESQ            1
        .VmxonPhysicalPointer   RESQ            1

        ;;
        ;; 记录当前 VMCS region pointer
        ;;
        .VmcsPointer            RESQ            1
        .VmcsPhysicalPointer    RESQ            1
        
        ;;
        ;; 记录 4 个 VMCS 管理指针, 指向 VMCS_MANAGE_BLOCK
        ;;
        .VmcsA                  RESQ            1
        .VmcsB                  RESQ            1
        .VmcsC                  RESQ            1
        .VmcsD                  RESQ            1
        .CurrentVmbPointer      RESQ            1

        ;;
        ;; guest 队列管理记录
        ;;
        .GuestRunningQueue      RESQ            1
        .GuestReadyQueue        RESQ            1
        .GuestRunningIndex      RESD            1
        .GuestRunningStatus     RESD            1
        .GuestReadyIndex        RESD            1
        .GuestReadyStatus       RESD            1

        ALIGNB 8
        ;;
        ;; 每个 logical processor 支持 4 个 VMCS_MANAGE_BLOCK 结构
        ;;
        .GuestA                 RESB            VMCS_MANAGE_BLOCK_SIZE
        .GuestB                 RESB            VMCS_MANAGE_BLOCK_SIZE
        .GuestC                 RESB            VMCS_MANAGE_BLOCK_SIZE
        .GuestD                 RESB            VMCS_MANAGE_BLOCK_SIZE

        ALIGNB 8
        ;;
        ;; VMM 管理记录
        ;;
        .VmmStack               RESQ            1
        .VmmMsrLoadAddress      RESQ            1
        .VmmMsrLoadPhyAddress   RESQ            1


        ;;
        ;; Guest flag 值, 记录是否处于 Guest
        ;;
        .EptEnableFlag          RESB            1
        
        ;;
        ;; ##### 下面是 VMCS buffer　#######
        ;;
        .GuestStateBuf          RESB            GUEST_STATE_SIZE
        .HostStateBuf           RESB            HOST_STATE_SIZE
        .ExecutionControlBuf    RESB            EXECUTION_CONTROL_SIZE
        .ExitControlBuf         RESB            EXIT_CONTROL_SIZE
        .EntryControlBuf        RESB            ENTRY_CONTROL_SIZE
        .ExitInfoBuf            RESB            EXIT_INFO_SIZE

        ;;
        ;; #### 下面是 VM-exit 信息 buffer #####
        ;;
        .GuestExitInfo          RESB            100h
        

        ALIGNB 8
        .InvDesc                RESB            INV_DESC_SIZE


        ;;
        ;; GDT 表 selector
        ;;
        ;; GS 用于管理 PCB 区域, FS 用于管理 SDA 区域
        ;;
        .GsSelector             RESW            1
        .TssSelector            RESW            1
        .LdtSelector            RESW            1

      
        ALIGNB 4

        ;;
        ;; Task Status Segment 管理数据
        ;;
        .TssBase                RESQ            1               ; 记录 TSS 块的基址
        .TssPhysicalBase        RESQ            1               ; 记录 TSS 块物理地址
        .TssLimit               RESD            1               ; Tss limit
        .IomapBase              RESQ            1               ; 记录 IOMAP 块地址
        .IomapPhysicalBase      RESQ            1               ; 记录 IOMAP 块物理地址

        .GdtPointer             RESQ            1               ; 记录 GDT 地址 
        
        ;;
        ;; Local Descriptor Table 管理数据
        ;;
        .LdtBase                RESQ            1               ; 记录 LDT 表基址
        .LdtLimit               RESD            1               ; Ldt 表 limit
        .LdtTop                 RESQ            1               ; 记录 LDT 表的顶上地址
        .CurrentLdtBase         RESQ            1               ; 记录当前的 LDT 表地址        



        ;;
        ;; stack pointer 记录
        ;;
        .KernelStack            RESQ            1               ; kernel 代码使用
        .UserStack              RESQ            1               ; user 代码使用
        .SystemServiceStack     RESQ            1               ; 中断服务例程使用
        .FastSystemServiceStack RESQ            1               ; 快速调用服务例程使用



        ;;
        ;; context 区域指针
        ;;
        .ContextBase            RESQ            1
        .XMMStateImageBase      RESQ            1


        ;;
        ;; memory type 管理
        ;;
        .MemTypeRecordMaximum   RESD            1               ; 记录内存类型管理记录最大项
        .MemTypeRecordTop       RESD            1               ; 记录内存类型管理记录顶
        .MemTypeRecord          RESB            (MTMR_SIZE * 10)


        ;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        ;$                                                     $
        ;$                  下面是处理器信息块                  $       
        ;$                                                     $
        ;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

        .Vendor                 RESD            1               ; 处理器的厂商

        ;;
        ;; 记录处理器的频率,单位 MHz. 即: 每次/us(每us内ticks次数)!
        ;; 1) ProcessorFrequency: 处理器显示出来的频率
        ;; 2) TicksFrequency: 测量出来的处理器频率
        ;; 注意:
        ;; 1) ProcessorFrequency 与 TicksFrequency 有些偏差, 基于乘除运算下, 会产生误差
        ;; 2) ProcessorFrequency 稍微比 TicksFrequency 大
        ;; 2.1) 在一台 2.4GHz 处理器上, ProcessorFrequency 的值为 2400
        ;; 2.2) 那么 TicksFrequency 的值大约为 2394
        ;;

        .ProcessorFrequency     RESD            1               ; 处理器 core 频率, 
        .TicksFrequency         RESD            1               ; 这时测量出来的 ticks 频率数

        .LapicTimerFrequency    RESD            1               ; local timer 的计数频率, 单位为 us


        ;;
        ;; 处理器最大 CPUID leaf 号
        ;;
        .MaxBasicLeaf           RESD            1               ; 最大基本叶号
        .MaxExtendedLeaf        RESD            1               ; 最大扩展叶号

        ;;
        ;; 处理器基本信息
        ;;
        .CacheLineSize          RESD            1               ; cache line(字节单位)

        ;;
        ;; 处理器型号信息
        ;;
        .DisplayModel           RESB            1               ; 型号
        .DisplayFamily          RESB            1               ; 家族号
        
        ALIGNB 4

        ;;
        ;; CPUID.01H leaf
        ;;
        .CpuidLeaf01Eax         RESD            1
        .CpuidLeaf01Ebx         RESD            1
        .CpuidLeaf01Ecx         RESD            1
        .CpuidLeaf01Edx         RESD            1

        ;;
        ;; CPUID.02H leaf
        ;;
        .CpuidLeaf02Eax         RESD            1
        .CpuidLeaf02Ebx         RESD            1
        .CpuidLeaf02Ecx         RESD            1
        .CpuidLeaf02Edx         RESD            1

        ;;
        ;; CPUID.03H leaf
        ;;
        .CpuidLeaf03Eax         RESD            1
        .CpuidLeaf03Ebx         RESD            1
        .CpuidLeaf03Ecx         RESD            1
        .CpuidLeaf03Edx         RESD            1

        ;;
        ;; CPUID.04H leaf
        ;;
        .CpuidLeaf04Eax         RESD            1
        .CpuidLeaf04Ebx         RESD            1
        .CpuidLeaf04Ecx         RESD            1
        .CpuidLeaf04Edx         RESD            1

        ;;
        ;; CPUID.05H leaf
        ;;
        .CpuidLeaf05Eax         RESD            1
        .CpuidLeaf05Ebx         RESD            1
        .CpuidLeaf05Ecx         RESD            1
        .CpuidLeaf05Edx         RESD            1

        ;;
        ;; CPUID.06H leaf
        ;;
        .CpuidLeaf06Eax         RESD            1
        .CpuidLeaf06Ebx         RESD            1
        .CpuidLeaf06Ecx         RESD            1
        .CpuidLeaf06Edx         RESD            1

        ;;
        ;; CPUID.07H leaf
        ;;
        .CpuidLeaf07Eax         RESD            1
        .CpuidLeaf07Ebx         RESD            1
        .CpuidLeaf07Ecx         RESD            1
        .CpuidLeaf07Edx         RESD            1

        ;;
        ;; CPUID.08H leaf
        ;;
        .CpuidLeaf08Eax         RESD            1
        .CpuidLeaf08Ebx         RESD            1
        .CpuidLeaf08Ecx         RESD            1
        .CpuidLeaf08Edx         RESD            1

        ;;
        ;; CPUID.09H leaf
        ;;
        .CpuidLeaf09Eax         RESD            1
        .CpuidLeaf09Ebx         RESD            1
        .CpuidLeaf09Ecx         RESD            1
        .CpuidLeaf09Edx         RESD            1

        ;;
        ;; CPUID.0AH leaf
        ;;
        .CpuidLeaf0AEax         RESD            1
        .CpuidLeaf0AEbx         RESD            1
        .CpuidLeaf0AEcx         RESD            1
        .CpuidLeaf0AEdx         RESD            1

        ;;
        ;; CPUID.0BH leaf
        ;;
        .CpuidLeaf0BEax         RESD            1
        .CpuidLeaf0BEbx         RESD            1
        .CpuidLeaf0BEcx         RESD            1
        .CpuidLeaf0BEdx         RESD            1

%define PCB.FeatureEcx                  PCB.CpuidLeaf01Ecx
%define PCB.FeatureEdx                  PCB.CpuidLeaf01Edx
%define PCB.FeatureAddition             PCB.CpuidLeaf07Ebx


        ;;
        ;; 基本扩展信息
        ;;
        .ExtendedFeatureEcx     RESD            1               ; CPUID.80000001H:ECX
        .ExtendedFeatureEdx     RESD            1               ; CPUID.80000001H:EDX

        .MaxPhysicalAddr        RESD            1               ; 最大的物理地址宽度
        .MaxVirtualAddr         RESD            1               ; 最大的虚拟地址宽度

        ;;
        ;; SSE 指令支持 level, 分别为: 
        ;; 1) 0000h - 不支持
        ;; 2) 0100h - SSE
        ;; 3) 0200h - SSE2
        ;; 4) 0300h - SSE3,     0301h - SSSE3
        ;; 5) 0401h - SSE4.1,   0402h - SSE4.2
        ;;
        .SSELevel               RESD            1               ; 指示支持哪个级别的 SSE 指令



        ;;
        ;; MAXPHYADDR = 32 时: select mask = 00000000_FFFFFFFFh
        ;; MAXPHYADDR = 36 时: select mask = 0000000F_FFFFFFFFh
        ;; MAXPHYADDR = 40 时: select mask = 000000FF_FFFFFFFFh
        ;; MAXPHYADDR = 52 时: select mask = 000FFFFF_FFFFFFFFh
        ;;
        .MaxPhyAddrSelectMask   RESQ            1               ; 最大物理地址的 mask 位



        ;;
        ;; 处理器 ID, APIC 以及多线程相关信息
        ;;
        .LapicVersion           RESD            1               ; local APIC 版本
        .InitialApicId          RESD            1               ; 处理器初始 ID
        .ApicId                 RESD            1               ; 处理器 ID
        .LogicalId              RESD            1               ; 处理器逻辑 ID
        .MaxLogicalProcessor    RESD            1               ; package 内最大逻辑处理器数
        .MaxProcessorCore       RESD            1               ; package 内最大 core 数
        .ProcessorIndex         RESD            1               ; 处理器编号 #0, #1 ...
        .LapicBase              RESQ            1               ; local APIC 虚拟映射基址
        .LapicPhysicalBase      RESQ            1               ; local APIC 物理基址
        .IapicBase              RESQ            1               ; IO APIC 虚拟映射基址
        .IapicPhysicalBase      RESQ            1               ; IO APIC 物理基址


        ;;
        ;; 处理器的 package,core 以及 smt ID
        ;;
        .ProcessorTopology      RESB            TOPOLOGY_INFO_SIZE
        .LogicalProcessorCount  RESD            1               ; 处理器内总共有多少个 local processor
        .ProcessorCoreCount     RESD            1               ; 处理器内总共有多少个 processor core

        ;;
        ;;
        ;; 处理器 cache 信息, 定义 4 个 cache 信息结构
        ;;      1) L1D(level-1 data):           level-1 数据 cache
        ;;      2) L1I(level-1 Instruction):    level-1 指令 cache
        ;;      3) L2(level-2 unified):         level-2 统一的 cache
        ;;      4) L3(level-3 unified):         level-3 统一的 cache
        ;;
        .CacheLevel             RESD            1               ; cache 层数

        .L1D                    RESB            CACHE_INFO_SIZE ; level-1 data cache 信息
        .L1I                    RESB            CACHE_INFO_SIZE ; level-1 instruction cache 信息
        .MLC:                                                   ; MLC(Middle Level Cache)
        .L2                     RESB            CACHE_INFO_SIZE ; level-2 cache 信息
        .LLC:                                                   ; LLC(Last Level Cache)
        .L3                     RESB            CACHE_INFO_SIZE ; level-3 cache 信息


        ;;
        ;; 标志位
        ;;
        .IsMultiThreading       RESB            1               ; 处理器是否支持多线程
        .IsBsp                  RESB            1               ; 是否为 BSP 处理器
        .IsLapicEnable          RESB            1               ; 记录 Local APIC 是否开启
        .IsLx2ApicEnable        RESB            1               ; 是否为 x2APIC 模块
        .IsIapicEnable          RESB            1               ; 记录 IO APIC 是否开启


        ;;
        ;; 下面记录着处理器功能的开启位
        ;; [0] - PE 位
        ;; [1] - PG 位
        ;; [2] - PAE 位
        ;;
        ALIGNB 4
        .ProcessorStatus        RESQ            1
        
        ;;
        ;; 下面记录着处理器指令可用位
        ;;
        .InstructionStatus      RESQ            1

        ;;
        ;; 处理器当前的活动状态
        ;;
        .ActivityState          RESD            1

        ;;
        ;; 维护处理器 debug 功能
        ;;
        .DebugCapabilities      RESQ            1               ; 记录处理器的 debug 功能
        .DebugStatus            RESQ            1               ; 记录处理器的 debug 开启项

        ;;
        ;; 维护处理器的 performance 功能
        ;;
        .PerfCapabilities       RESQ            1               ; 记录处理器的 performance 功能
        .PerfStatus             RESQ            1               ; 记录处理器的 performance 开启项

        ;;
        ;; VMX capability information 记录
        ;;
        .VmxGlobalData:
        .VmxBasic               RESQ            1
        .PinBasedCtls           RESQ            1
        .ProcessorBasedCtls     RESQ            1
        .ExitCtls               RESQ            1
        .EntryCtls              RESQ            1
        .VmxMisc:
        .Misc                   RESQ            1
        .Cr0Fixed0              RESQ            1
        .Cr0Fixed1              RESQ            1
        .Cr4Fixed0              RESQ            1
        .Cr4Fixed1              RESQ            1
        .VmcsEnum               RESQ            1
        .ProcessorBasedCtls2    RESQ            1
        .EptVpidCap             RESQ            1       
        .VmFunction             RESQ            1

        ;;
        ;; CR0 & CR4 fixed 1 mask(固定为 1 值)
        ;;
        .Cr0FixedMask           RESQ            1
        .Cr4FixedMask           RESQ            1
        .VmcsMemoryType         RESD            1
        .EptMemoryType          RESD            1

        ;;
        ;; 如果 bit55 of IA32_VMX_BASIC 为 1 时, TrueFlag = 1
        ;;
        .TrueFlag               RESB            1


        ;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
        ;$                                              $
        ;$ 下面是处理器 context 信息与 State Image       $       
        ;$                                              $
        ;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

        ALIGNB 8
        .Context:


        .Eax:
        .Rax                    RESQ            1
        .Ecx:
        .Rcx                    RESQ            1
        .Edx:
        .Rdx                    RESQ            1
        .Ebx:
        .Rbx                    RESQ            1
        .Esp:
        .Rsp                    RESQ            1
        .Ebp:
        .Rbp                    RESQ            1
        .Esi:
        .Rsi                    RESQ            1
        .Edi:
        .Rdi                    RESQ            1

        .R8                     RESQ            1
        .R9                     RESQ            1
        .R10                    RESQ            1
        .R11                    RESQ            1
        .R12                    RESQ            1
        .R13                    RESQ            1
        .R14                    RESQ            1
        .R15                    RESQ            1

        .Eip:
        .Rip                    RESQ            1
        .ErrorCode              RESD            1


        .Dr0                    RESQ            1
        .Dr1                    RESQ            1
        .Dr2                    RESQ            1
        .Dr3                    RESQ            1
        .Dr6                    RESQ            1
        .Dr7                    RESQ            1
        .Es                     RESD            1
        .Cs                     RESD            1
        .Ss                     RESD            1
        .Ds                     RESD            1
        .Fs                     RESD            1
        .Gs                     RESQ            1
        .Cr3                    RESQ            1
        .Cr2                    RESQ            1
        .Cr4                    RESQ            1


        ALIGNB 8
        .ReturnStack:

%ifdef __X64
        .Rflags                 RESQ            1        
        .RetRip                 RESQ            1
        .RetCs                  RESQ            1
        .RetRsp                 RESQ            1
        .RetSs                  RESQ            1
%else
        .Eflags                 RESD            1
        .RetEip                 RESD            1
        .RetCs                  RESD            1
        .RetEsp                 RESD            1
        .RetSs                  RESD            1
%endif




        ;;
        ;; FPU 单元的 32 位的 state image 区域(共 108 字节)
        ;; *** 1) 头 28 个字节为 FPU environment 信息(使用于 FSTENV/FNSTENV 指令)
        ;; *** 2) 后 80 个字节为 FPU/MMX 的 stack 寄存器 image 信息(使用于 FSAVE/FNSAVE 指令)
        ;;

        ALIGNB 16
        .FpuStateImage:
        .FpuEnvironmentImage:   RESB            28
        .FpuStackImage:         RESB            80



        ;;
        ;; XMM image 区域, 使用于 FXSAVE/FXRSTOR 指令(512字节)
        ;;

        ALIGNB 16
        .XMMStateImage:         RESB            512



        ;;
        ;; 下面是处理器的 DS(Debug Store)管理指针
        ;; 1) 指向 DS 管理区记录
        ;;
        ALIGNB 4
        .BtsBasePointer         RESQ            1               ; Bts buffer base 指针
        .BtsIndexPointer        RESQ            1               ; Bts buffer index 指针
        .BtsMaximumPointer      RESQ            1               ; Bts maximum 指针
        .BtsThresholdPointer    RESQ            1               ; Bts threshold 指针
        .PebsBasePointer        RESQ            1               ; Pebs buffer base 指针
        .PebsIndexPointer       RESQ            1               ; Pebs index 指针
        .PebsMaximumPointer     RESQ            1               ; Pebs maximum 指针
        .PebsThresholdPointer   RESQ            1               ; Pebs threshold 指针
        .Counter0Pointer        RESQ            1               ; Counter0 指针
        .Counter1Pointer        RESQ            1               ; Counter1 指针
        .Counter2Pointer        RESQ            1               ; Counter2 指针
        .Counter3Pointer        RESQ            1               ; Counter3 指针
        
        ;;
        ;; DS 管理记录
        ;;
        .BtsRecordSize          RESD            1               ; Bts 记录长度
        .PebsRecordSize         RESD            1               ; PEBS 记录长度
        .PebsBufferIndex        RESQ            1               ; 记录着 PEBS 上一个 index 值

        ;;
        ;; 下面是 DS 管理区记录
        ;;
        ALIGNB 16
        .DSManageRecord         RESB            DSMR64_SIZE



        ;;                
        ;; 每个 PCB 块为 8K
        ;;
        RESB            (4096 * 2 - $)
                                

               
        PROCESSOR_CONTROL_BLOCK_SIZE    EQU     $
endstruc






;;************************************************************
;;* 定义 System Data AREA 结构, 用于维护系统管理, 使用于 fs 段 
;;*
;;* 说明: 
;;* 1) 这是系统运行所需要的数据结构, 所有处理器共享
;;************************************************************

struc SDA
        ;;
        ;; 系统数据区域, 提供所有处理器共用使用的数据
        ;;
        .Base                   RESQ            1               ; 此区域的地址(virtual address)
        .PhysicalBase           RESQ            1               ; 此区域的物理地址
        .Size                   RESD            1               ; 此区域的 size
        .PcbBase                RESQ            1               ; 指向 CPU0 的 PCB 块
        .PcbPhysicalBase        RESQ            1               ; 指向 CPU0 的 PCB 块

        ;;
        ;; 系统可用物理内存
        ;;
        .MemorySize             RESD            1               ; 以 KB 为单位
        .BootDriver             RESD            1               ; boot 的驱动器


        .ProcessorCount         RESD            1               ; 处理器计数
        .ApLockPointer          RESD            1               ; Ap 处理器执行锁指针
        .ApLongmode             RESD            1               ; AP 处理器是否进入 long mode
        .ApStartupRoutineEntry  RESD            1               ; AP 处理器的 Startup routine 入口地址
        .ApInitDoneCount        RESD            1               ; AP 处理器初始化完成计数
	    .ApStage		RESD		1		; AP 处于哪个 stage
        
        ;;
        ;; AP 执行锁
        ;;
        .Stage1LockPointer      RESD            1               ; stage1 锁
        .Stage2LockPointer      RESD            1               ; stage2 锁
        .Stage3LockPointer      RESD            1               ; stage3 锁

        ;;
        ;; 信号
        ;;
        .Signal                 RESD            1               ; 内部使用的信号
        .SignalPointer          RESQ            1               ; 引用外部提供的信号

        ;;
        ;; NMI handler 使用的功能号, 缺省为 0 值, 由硬件触发
        ;;
        .NmiIpiRequestMask      RESD            1
        .NmiIpiRoutine          RESQ            1
        
        ;;
        ;; 记录拥有焦点的 processor index 值
        ;;
        .InFocus                RESD            1


        ;;
        ;; 记录当前 video buffer 位置
        ;;
        .VideoBufferHead        RESQ            1
        .VideoBufferPtr         RESQ            1
        .VideoBufferLastChar    RESD            1

        ;;
        ;; keyboard buffer 管理记录
        ;;
        .KeyBufferHead          RESQ            1               ; 保存 LSB.LocalKeyBufferHead 值
        .KeyBufferPtrPointer    RESQ            1               ; 指向 local KeyBufferPtr
        .KeyBufferLength        RESD            1               ; 键盘缓冲区长度


        ;;
        ;;Decode Manage block 与 GPA map list
        ;;
        .DmbBase                RESQ            1               ; 记录 DMB 地址        
        .GmlBase                RESQ            1               ; 记录 GPA 映射列表地址


        ALIGNB 4
        ;;
        ;; system timer counter, 记录中断次数
        ;;        
        .TimerCount             RESD            1

        ;;
        ;; 记录最后一次出错的错误码
        ;;
        .LastStatusCode          RESD            1             


        ;;
        ;; 记录处理器空闲的 index mask 标志位(指示 BSP 空闲或忙状态)
        ;;
        .UsableProcessorMask    RESD            1
        .ProcessMask            RESQ            1


        ;;
        ;; 定义虚拟机 domain 管理记录
        ;;
        .DomainPhysicalBase     RESQ            1                       ; domain pool 物理基址
        .DomainBase             RESQ            1                       ; domain pool 虚拟基址

        ;;
        ;; 定义 DEBUG_RECORD_STRUCTURE 管理记录
        ;;
%ifdef DEBUG_RECORD_ENABLE
        .DrsBase                RESQ            1
        .DrsTop                 RESQ            1
        .DrsIndex               RESQ            1

        .DrsHeadPtr             RESQ            1
        .DrsTailPtr             RESQ            1

        .DrsMaxCount            RESD            1
        .DrsCount               RESD            1
%endif

        ;;
        ;; EXTINT_RTE 管理记录
        ;;
        .ExtIntRtePtr           RESQ            1
        .ExtIntRteIndex         RESQ            1
        .ExtIntRteCount         RESD            1


        ;;
        ;; BTS pool 与 PEBS pool 管理记录
        ;; 1) 用来动态分配 BTS 与 PEBS buffer
        ;; 2) 最多支持 16 个 BTS buffer 与 PEBS buffer
        ;; 
        ALIGNB 4
        .BtsPoolBase            RESQ            1               ; 维护 BTS buffer 的分配
        .BtsPoolTop             RESQ            1               ; Bts pool 顶部
        .BtsBufferSize          RESD            1               ; 每个 BTS buffer 的长度
        .BtsRecordMaximum       RESD            1               ; BTS 记录最大数
        .PebsPoolBase           RESQ            1               ; 维护 PEBS buffer 的分配
        .PebsPoolTop            RESQ            1               ; PEBS buffer 顶部
        .PebsBufferSize         RESD            1               ; 每个 PEBS buffer 的长度
        .PebsRecordMaximum      RESD            1               ; PEBS 记录最大数



        ALIGNB 16

        ;;
        ;; paging 管理记录
        ;;
        .XdValue                RESD            1               ; 保存 XD 中的值, 这个值需要开启 XD 功能
        .PtBase                 RESD            1               ; PT 表基址
        .PtTop                  RESD            1               ; PT 表顶端
        .PtPhysicalBase         RESD            1               ; PT 表物理基址
        .PdtBase                RESD            1               ; PDT 表基址
        .PdtTop                 RESD            1               ; PDT 表顶端
        .PdtPhysicalBase        RESD            1               ; PDT 表物理基址
        .PptBase                RESD            1               ; PPT 表基址
        .PptTop                 RESD            1               ; PPT 表顶端
        .PptPhysicalBase        RESD            1               ; PPT 表物理基址

        ;;
        ;; 下面是 legacy 模式下的 PPT 表
        ;;
        ALIGNB 32
        .Ppt                    RESQ            4               ; PPT 表项

        ;;
        ;; long-mode 下的 paging 管理记录
        ;;
        .PxtBase64              RESQ            1               ; PXT 基址
        .PptBase64              RESQ            1               ; PPT 表基址(Page Directory Pointer Table)
        .PdtBase64              RESQ            1               ; PDT 表基址
        .PtBase64               RESQ            1               ; PT 表基址
        .PxtTop64               RESQ            1               ; PXT 表顶端
        .PtTop64                RESQ            1               ; PT 表顶端　
        .PdtTop64               RESQ            1               ; PDT 表顶端
        .PptTop64               RESQ            1               ; PPT 表顶端
        .PxtPhysicalBase64      RESQ            1               ; PXT 物理基址
        .PptPhysicalBase64      RESQ            1               ; PPT 表物理基址

        ;;
        ;; 记录 PPT 表区域(2M)是否有效, 有效时表明已经映射 PPT 表
        ;;
        .PptValid               RESB            1               ; 


        ALIGNB 4

        ;;
        ;; 下面记录栈空间分配
        ;;
        .UserStackBase                  RESQ    1               ; 用户栈基址
        .UserStackPhysicalBase          RESQ    1
        .KernelStackBase                RESQ    1               ; kernel栈基址
        .KernelStackPhysicalBase        RESQ    1
        
        ;;
        ;; 下面记录 pool空间分配
        ;;
        .UserPoolBase           RESQ            1               ; 用户 pool 基址
        .UserPoolPhysicalBase   RESQ            1
        .KernelPoolBase         RESQ            1               ; Kernel pool 基址
        .KernelPoolPhysicalBase RESQ            1


        ;;
        ;; 下面记录 PCB pool 空间分配
        ;;
        .PcbPoolBase            RESQ            1               ; PCB pool 虚拟基址
        .PcbPoolTop             RESQ            1               ; PCB pool 顶部
        .PcbPoolPhysicalBase    RESQ            1               ; PCB pool 物理基址
        .PcbPoolPhysicalTop     RESQ            1               ; PCB pool 的顶部
        .PcbPoolSize            RESQ            1               ; PCB pool 的大小


        ;;
        ;; long-mode 下 paging 中的 PT pool 管理记录
        ;;
        .PtPoolPhysicalBase     RESQ            1               ; PT POOL 物理基址
        .PtPoolPhysicalTop      RESQ            1               ; PT POOL 顶部
        .PtPoolSize             RESQ            1               ; PT POOL 大小
        .PtPoolBase             RESQ            1               ; PT Pool 区域基址
        .PtPoolFree             RESB            1               ; PT Pool 是否空闲可用


        ALIGNB 4

        ;;
        ;; 备用 PT Pool 管理记录
        ;;
        .PtPool2PhysicalBase    RESQ            1
        .PtPool2PhysicalTop     RESQ            1
        .PtPool2Size            RESQ            1
        .PtPool2Base            RESQ            1
        .PtPool2Free            RESB            1


        ALIGNB 4
        ;;
        ;; TSS Pool, 用来为每个处理器分配自己的 TSS 块
        ;; 注意:
        ;; 1) 每个 TSS 分配 size 为: 100h 字节
        ;; 2) 共支持 16 个处理器
        ;;
        .TssPoolBase            RESQ            1               ; Tss pool 基址
        .TssPoolPhysicalBase    RESQ            1               ; Tss pool 物理基址
        .TssPoolTop             RESQ            1               ; Tss pool 顶部
        .TssPoolPhysicalTop     RESQ            1               ; Tss pool 物理顶部
        .TssPoolGranularity     RESD            1               ; Tss pool 分配的粒度, 默认为 100h 字节


        ;;
        ;; VMX ept(extended page table)管理记录
        ;;
        .EptPxtBase64           RESQ            1               ; PXT 虚拟地址
        .EptPxtPhysicalBase64   RESQ            1               ; PXT 物理地址
        .EptPxtTop64            RESQ            1               ; 
        .EptPxtPhysicalTop64    RESQ            1

        .EptPptBase64           RESQ            1               ; PPT 虚拟地址
        .EptPptPhysicalBase64   RESQ            1               ; PPT 物理地址
        .EptPptTop64            RESQ            1
        .EptPptPhysicalTop64    RESQ            1


        ;;
        ;; GDT selector
        ;;
        .FsSelector             RESW            1
        .KernelCsSelector       RESW            1
        .KernelSsSelector       RESW            1
        .UserCsSelector         RESW            1
        .UserSsSelector         RESW            1
        .User64CsSelector       RESW            1
        .User64SsSelector       RESW            1
        .SysenterCsSelector     RESW            1
        .SyscallCsSelector      RESW            1
        .SysretCsSelector       RESW            1


        ALIGNB 4

        ;;
        ;; Global Descriptor Table 管理记录
        ;;
        .GdtPointer:
        .GdtLimit               RESW            1               ; GDT 表 limit 值
        .GdtBase                RESQ            1               ; GDT 表 base 值

        ALIGNB 4
        .GdtTop                 RESQ            1               ; 记录 GDT 表当前顶上的描述符地址
        
        ;;
        ;; Interrupt Descriptor Table 管理记录
        ;;
        .IdtPointer:
        .IdtLimit               RESW            1               ; IDT 表 limit 值
        .IdtBase                RESQ            1               ; IDT 表 base 值

        ALIGNB 4
        .IdtTop                 RESQ            1               ; IDT 表顶部


                                RESB            (4096 * 1) - $


        ;;
        ;; 定义 Global Descriptor Table 数据区域(共4K)
        ;;
        .Gdt:
        .NullDesc               RESQ            1                   
                                RESB            (4096 * 2) - $


        ;;
        ;; 下面是 IDT 所在区域(共4K)
        ;;
        .Idt:                   RESB            (4096 * 3) - $


        ;;
        ;; 下面是 TSS 区域(共4K)
        ;;
        .Tss:                   RESB            (4096 * 4) - $


        ;;
        ;; 下面是 IOMAP 区域(共8K)
        ;;
        .Iomap:                 RESB            (4096 * 6) - $
        

        ;;
        ;; 下面是 LDT 区域
        .Ldt:                   RESB            (4096 * 7) - $


        ;;
        ;; 下面是 EPT-PXT 表区域
        ;;
        .EptPxt                 RESB            (4096 * 8) - $


        ;;
        ;; 下面是 BTS buffer 区域(共4K)
        ;;
        .BtsBuffer:             RESB            (4096 * 9) - $

        ;;
        ;; 下面是 PEBS buffer 区域(共16*4K)
        ;;
        .PebsBuffer:            RESB            (4096 * (9+16)) - $


%ifdef DEBUG_RECORD_ENABLE
        ;;
        ;; 下面是 DEBUG_RECORD_STRUCTURE 区域(默认为32K)
        ;;
        .DrsBuffer:             RESB            (4096 * (9+16) + DRS_AREA_SIZE) - $
%endif
        
        .DecodeManageBlock:     RESB            (4096 * (9+17) + DRS_AREA_SIZE) - $
        
        .GpaMappedList          RESB            (4096 * (9+18) + DRS_AREA_SIZE) - $
        .ExtIntRteBuffer        RESB            (4096 * (9+19) + DRS_AREA_SIZE) - $

        SYSTEM_DATA_AREA_SIZE   EQU     $
        SDA_SIZE                EQU     $
endstruc



;;
;; LSB(Local Storage Block, 本地存储块), 每个处理器拥有自己的 LSB 区域. 
;; 每个 LSB 结构为 8K, 保存处理器的 local video buffer, local keyboard buffer 等
;;

struc LSB
        .Base                   RESQ            1
        .PhysicalBase           RESQ            1

        ;;
        ;; local video buffer 管理记录
        ;;
        .LocalVideoBufferHead   RESQ            1
        .LocalVideoBufferPtr    RESQ            1
        .LocalVideoBufferLastChar       RESD    1
        .LocalVideoBufferSize   RESD            1
        
        ;;
        ;; local keyboard buffer 管理记录
        ;;        
        ALIGNB 8
        .LocalKeyBufferHead     RESQ            1
        .LocalKeyBufferPtr      RESQ            1
        .LocalKeyBufferSize     RESD            1
        

        ;;
        ;; local timer 管理记录
        ;;
        .LapicTimerRequestMask  RESD            1
        .LapicTimerRoutine      RESQ            1
        .LapicTimerCount        RESD            1

        ;;
        ;; 时间计数值
        ;;
        .Hour                   RESD            1
        .Minute                 RESD            1
        .Second                 RESD            1

        ;;
        ;; 本地 keyboard buffer 区域, 共 256 个字节, 保存按键扫描码
        ;;
        .LocalKeyBuffer         RESB            256
     
        .Reserved               RESB            4096 - $

        ;;
        ;; 本地 video buffer 区域, 存放处理器的屏幕信息
        ;; 4K, 存放约 25 * 80 * 2 信息
        ;;
        .LocalVideoBuffer       RESB            (4096 * 2 - $)

        

        LOCAL_STORAGE_BLOCK_SIZE        EQU     $
        LSB_SIZE                        EQU     $        
endstruc





;;
;; 定义系统服务例程表结构(system_service_routine_table)
;;

struc SRT
        ;;
        ;; 使用于 fs 管理, 接着 SDA 区域

        RESB    ((SYSTEM_DATA_AREA_SIZE + 0xfff) & 0xfffff000)

        ;;ALIGNB 8

        .Base                   RESQ            1               ; SSR 块的基址
        .PhysicalBase           RESQ            1               ; SSR 块的物理地址
        .Size                   RESD            1               ; 
        .Top                    RESQ            1
        .Index                  RESQ            1
        .ServiceRoutineVector   RESD            1               ; 系统服务例程的中断向量号


        ALIGNB 16
       
        ;;
        ;; 预留 64 个系统例程
        ;;
        .Entry                  RESQ            64
        SRT_TOP                 EQU             $

        SRT_SIZE                EQU             $
endstruc





;;
;; 定义 32 位的 TSS 结构
;;
STRUC tss32
        .task_link              RESW            1
                                RESW            1
        .esp0                   RESD            1
        .ss0                    RESW            1
                                RESW            1
        .esp1                   RESD            1
        .ss1                    RESW            1
                                RESW            1  
        .esp2                   RESD            1      
        .ss2                    RESW            1
                                RESW            1
        .cr3                    RESD            1
        .eip                    RESD            1
        .eflags                 RESD            1
        .eax                    RESD            1
        .ecx                    RESD            1
        .edx                    RESD            1
        .ebx                    RESD            1
        .esp                    RESD            1
        .ebp                    RESD            1
        .esi                    RESD            1
        .edi                    RESD            1
        .es                     RESW            1
                                RESW            1
        .cs                     RESW            1
                                RESW            1
        .ss                     RESW            1
                                RESW            1
        .ds                     RESW            1
                                RESW            1
        .fs                     RESW            1
                                RESW            1
        .gs                     RESW            1
                                RESW            1
        .ldt_selector           RESW            1
                                RESW            1
        .trap                   RESW            1               ; Trap 标志位
        .IomapBase              RESW            1

        TSS_LENGTH              EQU             $ - 1
ENDSTRUC 


STRUC TSS32
        .TaskLink               RESW            1
                                RESW            1
        .Esp0                   RESD            1
        .Ss0                    RESW            1
                                RESW            1
        .Esp1                   RESD            1
        .Ss1                    RESW            1
                                RESW            1  
        .Esp2                   RESD            1      
        .Ss2                    RESW            1
                                RESW            1
        .Cr3                    RESD            1
        .Eip                    RESD            1
        .Eflags                 RESD            1
        .Eax                    RESD            1
        .Ecx                    RESD            1
        .Edx                    RESD            1
        .Ebx                    RESD            1
        .Esp                    RESD            1
        .Ebp                    RESD            1
        .Esi                    RESD            1
        .Edi                    RESD            1
        .Es                     RESW            1
                                RESW            1
        .Cs                     RESW            1
                                RESW            1
        .Ss                     RESW            1
                                RESW            1
        .Ds                     RESW            1
                                RESW            1
        .Fs                     RESW            1
                                RESW            1
        .Gs                     RESW            1
                                RESW            1
        .LdtrSelector           RESW            1
                                RESW            1
        .Trap                   RESW            1               ; Trap 标志位
        .IoBitmapBase           RESW            1

        TSS_SIZE                EQU             $ - 1
ENDSTRUC 


;;
;; 定义 64 位的 TSS 结构
;;
STRUC tss64
                                RESD            1
        .rsp0                   RESQ            1
        .rsp1                   RESQ            1
        .rsp2                   RESQ            1
                                RESQ            1
        .ist1                   RESQ            1
        .ist2                   RESQ            1
        .ist3                   RESQ            1
        .ist4                   RESQ            1
        .ist5                   RESQ            1
        .ist6                   RESQ            1
        .ist7                   RESQ            1
                                RESQ            1
                                RESW            1
        .IomapBase              RESW            1
ENDSTRUC






%define VENDOR_INTEL            0
%define VENDOR_AMD              1
%define VENDOR_UNKNOWN          80000000h



;;
;; 下面定义处理器信息结构
;;
STRUC   ProcessorInfo
        .Vendor                  RESD           1               ; 处理器的厂商
        
        ;;
        ;; 处理器型号信息
        ;;
        .DisplayModel           RESB            1               ; 型号
        .DisplayFamily          RESB            1               ; 家族号
                                RESW            1
        .MaxPhysicalAddr        RESD            1               ; 最大的物理地址宽度
        .MaxVirtualAddr         RESD            1               ; 最大的虚拟地址宽度

ENDSTRUC


;;
;; 定义 cahce 类型
;;
CACHE_NONE                      EQU             0               ; 无
CACHE_DATA                      EQU             1               ; 数据 cache
CACHE_INSTRUCTION               EQU             2               ; 指令 cache
CACHE_UNIFIED                   EQU             3               ; 统一的 cache

CACHE_L1D                       EQU             1               ; level 1 的数据 cahce
CACHE_L1I                       EQU             2               ; level 1 的指令 cache
CACHE_MLC                       EQU             3               ; level 2 的统一 cache
CACHE_LLC                       EQU             3               ; level 3 的统一 cache


STRUC CacheInfo
        .Type                   RESW            1               ; cache 类型
        .Level                  RESW            1               ; cache 层级
        .Size                   RESD            1               ; cache size
        .Ways                   RESW            1               ; cache ways
        .Partitions             RESW            1               ; line partitions
        .LineSize               RESW            1               ; line size
                                RESW            1
        .Sets                   RESD            1               ; number of sets

        CACHE_INFO_SIZE         EQU     $
ENDSTRUC


;;
;; 处理器拓扑中的 level
;; 

LEVEL_THREAD                    EQU             1
LEVEL_CORE                      EQU             2
LEVEL_INVALID                   EQU             0


;;
;; 定义处理器 ID 的拓扑结构信息
;;
STRUC TopologyInfo
        .CoreId                 RESB            1               ; 保存 Core Id 值
        .ThreadId               RESB            1               ; 保存 SMT ID 值
        .CoreMaskWidth          RESB            1               ; core 域的 mask 宽度
        .ThreadMaskWidth        RESB            1               ; SMT 域的 mask 宽度
        .CoreSelectMask         RESD            1               ; core 域的 select mask 位
        .ThreadSelectMask       RESD            1               ; SMT 域的 select mask 位
        
        .PackageId              RESD            1               ; 处理器的 package id
        .ProcessorId            RESD            1               ; 32 位的处理器 Id 值

        .LogicalProcessorPerCore        RESD    1               ; 每个 core 内有多少个 local processor
        .LogicalProcessorPerPackage     RESD    1               ; 每个处理器物理 package 内有多少个 local processor

        TOPOLOGY_INFO_SIZE      EQU     $
ENDSTRUC


;;
;; MTMR(Memory Type Manange Record)结构
;;
STRUC MTMR
        .InUsed                 RESB            1               ; 记录是否在使用        　
        .Type                   RESB            1               ; 内存类型
        ALIGNB 4
        .Start                  RESQ            1               ; 内存起始位置
        .Length                 RESD            1               ; 内存范围长度

        MTMR_SIZE               EQU     $
ENDSTRUC 


;;
;; DSMR(Debug Store Manage Record)管理记录结构
;;
STRUC DSMR64
        .BtsBufferBase          RESQ            1
        .BtsIndex               RESQ            1
        .BtsMaximum             RESQ            1
        .BtsThreshold           RESQ            1
        .PebsBufferBase         RESQ            1
        .PebsIndex              RESQ            1
        .PebsMaximum            RESQ            1
        .PebsThreshold          RESQ            1
        .Counter0               RESQ            1
        .Counter1               RESQ            1
        .Counter2               RESQ            1
        .Counter3               RESQ            1
                                RESQ            1

        DSMR64_SIZE             EQU     $
ENDSTRUC

STRUC DSMR32
        .BtsBufferBase          RESD            1
        .BtsIndex               RESD            1
        .BtsMaximum             RESD            1
        .BtsThreshold           RESD            1
        .PebsBufferBase         RESD            1
        .PebsIndex              RESD            1
        .PebsMaximum            RESD            1
        .PebsThreshold          RESD            1
        .Counter0               RESD            1
        .Counter1               RESD            1
        .Counter2               RESD            1
        .Counter3               RESD            1
                                RESD            1

        DSMR32_SIZE             EQU     $
ENDSTRUC


;;
;; 定义每个处理器 BTS buffer 区域的分配粒度
;;
BTS_BUFFER_SIZE                 EQU             100h

;;
;; 定义每个处理器 PEBS buffer 区域的分配粒度
;;
PEBS_BUFFER_SIZE                EQU             400h


;;
;; 用于 pre-stage3 阶段的临时 longmode 环境
;;
struc PreStage3Env
        .GdtPointer:
        .GdtLimit       RESW    1
        .GdtBase        RESQ    1

        ALIGNB 4
        .IdtPointer:
        .IdtLimit       RESW    1
        .IdtBase        RESQ    1

;;
;; PreStageEnv.Gdt 共 40 字节
;; 1) 00h: NULL 描述符
;; 2) 08h: CS 描述符
;; 3) 10h: SS 描述符
;; 4) 18h: TSS 描述符(占16个字节)
;;        
PreStage3Env.CsSelector64  EQU     08h
PreStage3Env.CsSelector    EQU     10h
PreStage3Env.SsSelector    EQU     18h
PreStage3Env.TssSelector   EQU     20h
        
        ALIGNB 8
        .Gdt            RESQ    6                       ; 容纳 6 个基本的 longmode 段
        .Idt            RESQ    (32 * 2)                ; 容纳 32 个异常中断向量
        .Tss            RESB    104                     ; TSS 104 个字节
        
        RESB            0FF0h - $

        .KernelStack    RESQ    2

        PRE_STAGE3_ENV_SIZE     EQU     $
endstruc




;;
;; VMX  global data 结构 
;;

struc VGA
        .Basic                  RESQ    1
        .PinBasedCtls           RESQ    1
        .ProcessorBasedCtls     RESQ    1
        .ExitCtls               RESQ    1
        .EntryCtls              RESQ    1
        .Misc                   RESQ    1
        .Cr0Fixed0              RESQ    1
        .Cr0Fixed1              RESQ    1
        .Cr4Fixed0              RESQ    1
        .Cr4Fixed1              RESQ    1
        .VmcsEnum               RESQ    1
        .ProcessorBasedCtls2    RESQ    1
        .EptVpidCap             RESQ    1
        .TruePinBasedCtls       RESQ    1
        .TrueProcessorBasedCtls RESQ    1
        .TrueExitCtls           RESQ    1
        .TrueEntryCtls          RESQ    1
        
        ;;
        ;; 如果 bit55 of IA32_VMX_BASIC 为 1 时, 支持 4 个 capability 寄存器
        ;; 1) 支持时, TrueFlag 的值为 1
        ;; 2) 不支持时, TrueFlag 的值为 0
        ;;
        .TrueFlag               RESD    1

        VGA_SIZE        EQU     $
endstruc




;;
;; Decode Manage Block
;;
struc DMB
        .DecodeBufferHead       RESQ    1
        .DecodeBufferPtr        RESQ    1
        .DecodeEntry            RESQ    1

        .TargetCpuMode          RESD    1
        .DecodePrefixFlag       RESD    1
        .PrefixRex              RESB    1

        ALIGNB 8
        .DecodeBuffer           RESB    1
endstruc






%endif
