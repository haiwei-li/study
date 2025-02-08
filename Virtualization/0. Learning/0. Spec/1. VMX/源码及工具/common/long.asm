;*************************************************
; long.asm                                       *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************


;;
;; 这段代码将切换到 long mode 运行
;;

%include "..\inc\support.inc"
%include "..\inc\protected.inc"
%include "..\inc\services.inc"
%include "..\inc\system_manage_region.inc"


        
        org LONG_SEGMENT
        
        DD      LONG_LENGTH                             ; long 模块长度
        DD      BspLongEntry                            ; BSP 入口地址
        DD      ApStage3Routine                         ; AP 入口地址


        ;;
        ;; 说明: 
        ;; 1) 此时, 处理器处于 stage1 阶段(即, 未分页保护模式)
        ;; 2) stage3 阶段将切换到 longmode         
        ;;
        bits 32        
        
BspLongEntry:               
        ;;
        ;; 进入 longmode 前准备工作, 初始化 stage3 阶段的基本页表结构
        ;; 包括: 
        ;;      1) compatibility 模式基本运行区域: LONG_SEGMENT
        ;;      2) setup 模块运行区域: SETUP_SEGMENT
        ;;      3) 64-bit 基本运行区域: ffff_ff80_4000_0000h
        ;;      4) video 区域: b_8000h                
        ;;      5) SDA 区域映射到: ffff_f800_8002_0000h
        ;;      6) 映射页表池 PT Pool 和备用 PT Pool 区域
        ;;      7) LAPIC 与 IAPIC 基址(所有logical processor 地址一致)
        ;;
        call init_longmode_basic_page32
        
        ;;
        ;; 更新 stage3 阶段的 GDT/IDT pointer 
        ;;
        call update_stage3_gdt_idt_pointer
        
ApLongEntry:                     
        ;;
        ;; 映射 stage3 阶段的 PCB 区域
        ;;
        call map_stage3_pcb

        ;;
        ;; 更新 stage3 的 kernel stack
        ;; 1) 需要开启分页前及更新 FS 段前执行
        ;; 2) 将调整后的 kernel stack 保存在 PCB.KernelStack 内
        ;;        
        call update_stage3_kernel_stack        

        ;;
        ;; 读 GS base 值, 以备下一步更新
        ;;
        mov esi, [gs: PCB.Base]
        mov edi, [gs: PCB.Base + 4]

        ;;
        ;; 加载 longmode 下的 PXT 表
        ;;
        mov eax, [fs: SDA.PxtPhysicalBase64]
        mov cr3, eax

        ;;
        ;; 进入 long-mode 前先更新 GS.selector
        ;;
        mov ax, [gs: PCB.GsSelector]
        mov gs, ax

        ;;
        ;; 下面将切换到 longmode !
        ;; 说明: 
        ;; 1) longmode_enter() 函数将切换到 64-bit 模式
        ;; 2) longmode_enter() 返回后处于 64-bit 的执行环境
        ;; 3) 更新 GS base 
        ;; 4) 需要进一步进行后续的 longmode 环境初始化
        ;;

        ;;
        ;; 设置 EFER 寄存器, 开启 long mode
        ;;
        mov ecx, IA32_EFER
        rdmsr 
        bts eax, 8                                      ; EFER.LME = 1
        wrmsr

        ;;
        ;; 激活 long mode, 进入 compatibility 模式
        ;;
        mov eax, cr0
        bts eax, 31
        mov cr0, eax                                    ; EFER.LMA = 1   
                                

        ;;
        ;; 转入 64-bit 模式
        ;;
        jmp KernelCsSelector64 : ($ + 7)
        


        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;;;;;;  下面是 64-bit 代码  ;;;;;;;;;;;;;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        bits 64
    
        ;;
        ;; 更新 FS/GS 段
        ;;  
        mov eax, SDA_BASE
        mov edx, 0FFFFF800h
        mov ecx, IA32_FS_BASE
        wrmsr
        mov eax, esi
        mov edx, edi
        mov ecx, IA32_GS_BASE
        wrmsr
        
        ;;
        ;; 刷新 segment selector 和 cache 部分
        ;;
        mov ax, KernelSsSelector64
        mov ds, ax
        mov es, ax
        mov ss, ax
        mov rsp, [gs: PCB.KernelStack] 
        
        ;;
        ;; 更新处理器状态
        ;;
        or DWORD [gs: PCB.ProcessorStatus], CPU_STATUS_PG | CPU_STATUS_LONG | CPU_STATUS_64
        

                
        ;;
        ;; 刷新 GDTR/IDTR
        ;;
        lgdt [fs: SDA.GdtPointer]
        lidt [fs: SDA.IdtPointer]

        ;;
        ;; 更新 TSS 环境
        ;;
        call update_stage3_tss
        
        ;;
        ;; 安装缺省中断处理程序
        ;;
        call install_default_interrupt_handler
        
        ;;
        ;; 更新 GS 段信息
        ;;
        call update_stage3_gs_segment

        ;;
        ;; 配置 SYSENTER/SYSEXIT 使用环境
        ;;
        call setup_sysenter
                       
        
%ifndef DBG               
        ;;
        ;; stage3 阶段最后工作, 检查是否为 BSP        
        ;; 1) 是, 则等待 AP 完成 stage3 阶段工作(即: 等待所有 AP 完成切换到 long mode)
        ;; 2) 否, 则转入 ApStage3End
        ;;
        cmp BYTE [gs: PCB.IsBsp], 1
        jne ApStage3End
        
        call init_sys_service_call

        ;;
        ;; 等待所有 AP 完成 stage3 阶段工作
        ;;
        call wait_for_ap_stage3_done

        ;;
        ;; 将处理器切入到 VMX root 模式
        ;;        
        call vmx_operation_enter

%endif
        ;;
        ;; 当前处理器拥有焦点
        ;;         
        mov eax, [gs: PCB.ProcessorIndex] 
        mov [fs: SDA.InFocus], eax

        ;;
        ;; 更新 SDA.KeyBuffer 记录
        ;;        
        mov rbx, [gs: PCB.LsbBase]
        mov rax, [rbx + LSB.LocalKeyBufferHead]
        mov [fs: SDA.KeyBufferHead], rax
        lea rax, [rbx + LSB.LocalKeyBufferPtr]
        mov [fs: SDA.KeyBufferPtrPointer], rax
        mov eax, [rbx + LSB.LocalKeyBufferSize]
        mov [fs: SDA.KeyBufferLength], eax
        
                        
        ;;
        ;; 打开键盘
        ;;
        call enable_8259_keyboard

        sti
        NMI_ENABLE
                        
        ;;
        ;; 更新系统状态
        ;;
        call update_system_status    
        
        
        
;;============================================================================;;
;;                      所有处理器初始化完成                                   ;;
;;============================================================================;;

        bits 64
        
        ;;
        ;; 下面是实验例子的源代码
        ;;        
        %include "ex.asm"
        

       ;;
       ;; 等待重启
       ;;
        call wait_esc_for_reset
        





;;
;; 下面是 APs 的 pre-stage3 入口
;; 说明: 
;;      1) 每个 AP 在 stage2 阶段里, 需要等待 stage3 lock 有效后才允许进入
;;      2) ApStage3Routine 跳转到 ApLongEntry 执行属于 APs 流程
;;
        
        
        bits 32

ApStage3Routine:        

%ifdef TRACE
        mov esi, Stage3.Msg
        call puts
%endif        
        jmp ApLongEntry






;;
;; 下面是 APs 在 stage3 阶段的最后工作
;; 说明: 
;       1) 增加处理器计数
;;      2) 开放 stage3 lock, 允许其它的 APs 进入执行
;;      3) 将 AP 放入 HLT 状态
;;

        bits 64

ApStage3End:        
        
%ifdef TRACE
        mov esi, Stage3.Msg1
        call puts
%endif        


        ;;
        ;; 增加完成计数
        ;;
        lock inc DWORD [fs: SDA.ApInitDoneCount]      
          
        ;;
        ;; 1) 开放 stage3 锁, 允许其他 AP 进入 stage3
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage3LockPointer]        
        xchg [rbx], eax

        ;;
        ;; 设置 UsableProcessMask 值, 指示 logical processor 处于可用状态
        ;;
        mov eax, [gs: PCB.ProcessorIndex]                       ; 处理器 index 
        lock bts DWORD [fs: SDA.UsableProcessorMask], eax       ; 设 Mask 位
                        
        ;;
        ;; 进入 VMX operation 模式
        ;;
        call vmx_operation_enter
        
        ;;
        ;; 更新系统状态
        ;;
        call update_system_status

        ;;
        ;; 记录处理器的 HLT 状态
        ;;
        mov DWORD [gs: PCB.ActivityState], CPU_STATE_HLT
        
       
        ;;
        ;; AP 进入 stage3 阶段最终状态:  HLT 状态
        ;;
        sti
                
        hlt
        jmp $-1
        



        bits 32
        
%include "..\lib\crt.asm"
%include "..\lib\LocalVideo.asm"
%include "..\lib\mem.asm"
%include "..\lib\page32.asm"
%include "..\lib\system_data_manage.asm"
%include "..\lib\apic.asm"
%include "..\lib\ioapic.asm"
%include "..\lib\pci.asm"
%include "..\lib\pic8259a.asm"
%include "..\lib\services.asm"
%include "..\lib\Decode\Decode.asm"
%include "..\lib\Vmx\VmxInit.asm"
%include "..\lib\Vmx\Vmx.asm"
%include "..\lib\Vmx\VmxException.asm"
%include "..\lib\Vmx\VmxVmcs.asm"
%include "..\lib\Vmx\VmxDump.asm"
%include "..\lib\Vmx\VmxLib.asm"
%include "..\lib\Vmx\VmxPage.asm"
%include "..\lib\Vmx\VmxVMM.asm"
%include "..\lib\Vmx\VmxExit.asm"
%include "..\lib\Vmx\VmxMsr.asm"
%include "..\lib\Vmx\VmxIo.asm"
%include "..\lib\Vmx\VmxApic.asm"
%include "..\lib\DebugRecord.asm"
%include "..\lib\smp.asm"
%include "..\lib\dump\dump_apic.asm"
%include "..\lib\dump\dump_debug.asm"
%include "..\lib\stage3.asm"



        bits 64
;;
;; *** include 其它 64 位库 *****
;;
%include "..\lib\crt64.asm"
%include "..\lib\page64.asm"
%include "..\lib\services64.asm"
%include "..\lib\smp64.asm"
%include "..\lib\Vmx\VmxPage64.asm"


;;
;; 数据
;;
%include "..\lib\data.asm"



LONG_LENGTH     EQU     $ - $$
                