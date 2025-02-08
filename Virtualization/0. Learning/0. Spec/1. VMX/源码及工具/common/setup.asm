;*************************************************
; setup.asm                                      *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


;;
;; 这个 setup 模式是共用的, 放在 ..\common\ 目录下
;; 用于写入磁盘的第 1 号扇区 ！
;;

%include "..\inc\support.inc"
%include "..\inc\protected.inc"
%include "..\inc\system_manage_region.inc"
%include "..\inc\apic.inc"


;;
;; 说明: 
;; 1) 模块开始点是 SETUP_SEGMENT
;; 2) 模块头的存放是"模块 size"
;; 3) load_module() 函数将模块加载到 SETUP_SEGMENT 位置上
;; 4) SETUP 模块的"入口点"是: SETUP_SEGMENT + 0x18
        
        [SECTION .text]
        org SETUP_SEGMENT


;;
;; 在 0x8000 区域定义引导管理块 (LOADER_BLOCK)
;;         
SetupLenth      DD SETUP_LENGTH                 ; 这个模块的 size
CpuIndex        DD 0FFFFFFFFh                   ; CPU index
CurrentVideo    DD 0B8000h					    ; CurrentVideo
ApStage1Lock    DD 1                            ; stage1(setup)阶段的锁
ApStage2Lock    DD 1                            ; stage2(protected)阶段的锁
ApStage3Lock    DD 1                            ; stage3(long)阶段的锁    
MMap.Size       DQ 0
MMap.Base:      DQ 0                            ; 内存区域的地起地址
MMap.Length:    DQ 0                            ; 内存区域的长度
MMap.Type:      DD 0                            ; 内存区域的类型:


;;
;; 模块当前运行在 16 位实模式下
;;
        bits 16
        
SetupEntry:                                             ; 这是模块代码的入口点. 
        cli
        cld
        NMI_DISABLE
        call enable_a20  
        DISABLE_8259 

        lock inc DWORD [CpuIndex]
        call check_cpu_environment
        call get_system_memory
        call protected_mode_enter
                

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;; 下面是 32 位代码 ;;;;;;;;;;;;;;;;;;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        
        bits 32

        ;;
        ;; 下面进行数据的初始化设置:
        ;; 1) 首先, 初始化 SDA(System Data Area)区域数据
        ;; 2) 然后, 初始化 PCB(Processor Control Block)区域数据
        ;;
        ;; 说明:
        ;; 1) SDA 数据是所有处理器共享, 所以必须先初始化
        ;; 2) PCB 数据是 logical processor 数据, 共支持 16 个 PCB 块
        ;; 3) PCB 数据是动态分配, 每个 PCB 块基址不同
        ;; 
        ;;
        ;; fs 段说明: 
        ;;      1) fs 指向 SDA(System Data Area)区域, 是所有 logical processor 共享的数据区域
        ;; 注意: 
        ;;      1) 需要在支持 64 位的处理器上才能直接写 IA_FS_BASE 寄存器！
        ;;      2) 否则, 需要开启保护模式来加载 FS 段基址
        ;;      3) GS 段基址在后续代码中更新
        ;;        
        call init_system_data_area


PcbInitEntry:
        ;;
        ;; 设置 PCB(Processor Control Block)内容
        ;; 说明: 
        ;; 1) 此处为 logical processor 的 PCB 初始化入口(包括 BSP 与 AP)
        ;; 2) 每个 logical processor 都需要经过下面的 PCB 数据初始化
        ;; 
        call init_processor_control_block
        call init_apic
        call init_processor_basic_info
        call init_processor_topology_info
        call init_debug_capabilities_info
        call init_memory_type_manage
        call init_perfmon_unit

%ifndef DBG
        ;;
        ;; Stage1 阶段最后工作, 检查是否为 BSP
        ;; 1) 是, 则发送 INIT-SIPI-SIPI 序列
        ;; 2) 否, 则等待接收 SIPI 
        ;;
        cmp BYTE [gs: PCB.IsBsp], 1
        jne ApStage1End

        ;;
        ;; 这是 BSP 第1阶段的最后工作: 
        ;; 1) 发送 INIT-SIPI-SIPI 序列给 AP 
        ;; 2) 等待所有 AP 第1阶段完成
        ;; 3) 转入下阶段工作
        ;;
        call wait_for_ap_stage1_done
%endif         

        ;;
        ;; 检查是否需要进入 longmode
        ;; 1) 是, 跳过 stage2, 进入 stage3 阶段(longmode 模式)
        ;; 2) 否, 进入 stage2 阶段
        ;;
        cmp DWORD [fs: SDA.ApLongmode], 1
        mov eax, [PROTECTED_SEGMENT+4]
        cmove eax, [LONG_SEGMENT+4]
        jmp eax


%ifndef DBG      
        ;;
        ;; AP第1阶段最后工作说明: 
        ;; 1) 增加 ApInitDoneCount 计数值
        ;; 1) AP 等待第2阶段锁(等待 BSP 开放 stage2 锁)
        ;;
        
ApStage1End:  
        ;;
        ;; 增加完成计数
        ;;
        lock inc DWORD [fs: SDA.ApInitDoneCount]

        ;;
        ;; 开放第1阶段 AP Lock
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage1LockPointer]
        xchg [ebx], eax

%ifdef TRACE
	call dump_trace_message
%endif
        ;;
        ;; 检查是否需要进入 longmode
        ;; 1) 是, 跳过 stage2, 等待 stage3 锁, 进入 stage3 阶段(longmode 模式)
        ;; 2) 否, 等待 stage2 锁, 进入 stage2 阶段
        ;;
        cmp DWORD [fs: SDA.ApLongmode], 1
        je ApStage1End.WaitStage3

        ;;
        ;; 现在等待 stage2 的锁开放
        ;;
        mov esi, [fs: SDA.Stage2LockPointer]
        call get_spin_lock
        ;;
        ;; 进入 stage2
        ;;
        jmp [PROTECTED_SEGMENT+8]
        
ApStage1End.WaitStage3:
        ;;
        ;; 现在等待 stage3 锁开放
        ;;
        mov esi, [fs: SDA.Stage3LockPointer]
        call get_spin_lock                
        ;;
        ;; 进入 stage3
        ;; 
        jmp [LONG_SEGMENT+8]


%endif

    

;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$      AP Stage1 Startup Routine       $
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


        bits 16

times 4096 - ($ - $$)   DB      0


ApStage1Entry:

        cli
        cld

        ;;
        ;; real mode 初始环境
        ;;
        xor ax, ax
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov sp, BOOT_SEGMENT
        jmp WORD 0 : ApStage1Entry.Next
ApStage1Entry.Next:        
       
        ;;
        ;; 检查 ApLock, 是否允许 AP 进入 startup routine 执行
        ;;
        xor eax, eax
        xor esi, esi
        inc esi
        
        ;;
        ;; 获得自旋锁
        ;;
AcquireApStage1Lock:
        lock cmpxchg [ApStage1Lock], esi
        jz AcquireApStage1LockOk
        
CheckApStage1Lock:
        mov eax, [ApStage1Lock]
        test eax, eax 
        jz AcquireApStage1Lock
        pause
        jmp CheckApStage1Lock
        

        
AcquireApStage1LockOk:
        ;;
        ;; AP stage1 前期处理
        ;;
        lock inc DWORD [CpuIndex]
        call check_cpu_environment
        call protected_mode_enter



        bits 32
        
%if 0
;; 下面是为测试而增加 !!
        call init_processor_control_block
        call init_apic
        call init_processor_basic_info
        call init_processor_topology_info
        call init_debug_capabilities_info
        call init_memory_type_manage
        call init_perfmon_unit


        ;;
        ;; 增加完成计数
        ;;
        lock inc DWORD [fs: SDA.ApInitDoneCount]
        ;;
        ;; 开放第1阶段 AP Lock
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage1LockPointer]
        xchg [ebx], eax

call dump_trace_message
        ;;
        ;; 现在等待 stage2 的锁开放
        ;;
        mov esi, [fs: SDA.Stage2LockPointer]
        call get_spin_lock

        ;;
        ;; 进入 stage2
        ;;
        jmp [PROTECTED_SEGMENT+8]
        

%endif
        ;;
        ;; 转入 PCB 初始化
        ;; 
        mov eax, PcbInitEntry
        jmp eax
        

   

;-----------------------------------------
; dump_trace_message():
; 说明:
;       打印 trace 信息
;-----------------------------------------
dump_trace_message:
        mov esi, Status.CpuIdMsg        
        call __puts
        mov esi, [gs: PCB.LogicalId]
        call __dump_hex
        mov esi, ','
        call __putc
        cmp DWORD [fs: SDA.ApLongmode], 1
        mov esi, Stage1.Msg2
        je dump_trace_message.@1
        mov esi, Stage1.Msg1
dump_trace_message.@1:
        call __puts
        ret




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 下面是 include 进来的函数模块        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        bits 16
                
%include "..\lib\crt16.asm"                 
 
  
        bits 32
;;
;; 下面代码使用在 stage1 阶段
;;        
%include "..\lib\print.asm"
%include "..\lib\crt.asm"        
%include "..\lib\LocalVideo.asm"
%include "..\lib\system_data_manage.asm" 
%include "..\lib\mem.asm"
%include "..\lib\page32.asm"
%include "..\lib\apic.asm"
%include "..\lib\ioapic.asm"
%include "..\lib\pci.asm"
%include "..\lib\mtrr.asm"
%include "..\lib\debug.asm"
%include "..\lib\perfmon.asm"
%include "..\lib\pic8259a.asm"
%include "..\lib\smp.asm"
%include "..\lib\stage1.asm"
%include "..\lib\services.asm"
%include "..\lib\data.asm"





        [SECTION .data]
        ALIGN 16

;;
;; stage1 的 GDT 与 TSS 区域
;;
setup.Gdt     times (16*128)  DB 0
setup.Tss     times (16*128)  DB 0

        
;;
;; 模块长度
;;
SETUP_LENGTH    EQU     $ - SETUP_SEGMENT



; end of setup        
