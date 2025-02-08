;*************************************************
; stage1.asm                                     *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************




	bits 16

;-------------------------------------------------------------------
; set_stage1_gdt:
; input:
;       esi - GDT 表基址 
; output:
;       eax - 返回 GDT pointer
; 描述: 
;       1) 初始化临时的 GDT 数据
;	2) 此函数运行在 16 位 real-mode 下 
;-------------------------------------------------------------------
set_stage1_gdt:
        push edx
        add esi, 10h
        xor eax, eax

        ;;
        ;; 设置基本 GDT 表项
        ;; 1) entry 0:          NULL descriptor
        ;; 2) entry 1,2:        64-bit kernel code/data 描述符
        ;; 3) entry 3,4:        32-bit user code/data 描述符
        ;; 4) entry 5,6:        64-bit user code/data 描述符
        ;; 5) entry 7,8:        32-bit kernel code/data 描述符                
        ;; 6) entry 9,10:       fs/gs 段使用
        ;; 

	    ;;		
        ;; NULL descriptor
        ;;
        mov [esi], eax
        mov [esi+4], eax

        ;;
        ;; 64-bit Kernel CS/SS 描述符设置说明: 
        ;; 1)在 x64 体系下描述符可以设置为: 
        ;;      * CS = 00209800_00000000h (L=P=1, G=D=0, C=R=A=0)
        ;;      * SS = 00009200_00000000h (L=1, G=B=0, W=1, E=A=0)
        ;; 2) 在 VMX 架构下, 在VM-exit 返回 host 后会将描述符设置为: 
        ;;      * CS = 00AF9B00_0000FFFFh (G=L=P=1, D=0, C=0, R=A=1, limit=4G)
        ;;      * SS = 00CF9300_0000FFFFh (G=P=1, B=1, E=0, W=A=1, limit=4G)
        ;;
        ;; 3) 因此, 为了与 host 的描述符达成一致, 这里将描述符设为: 
        ;;      * CS = 00AF9A00_0000FFFFh (G=L=P=1, D=0, C=A=0, R=1, limit=4G)
        ;;      * SS = 00CF9200_0000FFFFh (G=P=1, B=1, E=A=0, W=1, limit=4G)  
        ;
        mov DWORD [esi+KernelCsSelector64],   0000FFFFh
        mov DWORD [esi+KernelCsSelector64+4], 00AF9A00h
        mov DWORD [esi+KernelSsSelector64],   0000FFFFh
        mov DWORD [esi+KernelSsSelector64+4], 00CF9200h   

        ;;
        ;; 32-bit User CS/SS 描述符
        ;;
        mov DWORD [esi+UserCsSelector32],   0000FFFFh
        mov DWORD [esi+UserCsSelector32+4], 00CFFA00h
        mov DWORD [esi+UserSsSelector32],   0000FFFFh
        mov DWORD [esi+UserSsSelector32+4], 00CFF200h

        ;;
        ;; 64-bit User CS/SS 描述符
        ;;
        mov DWORD [esi+UserCsSelector64], eax
        mov DWORD [esi+UserCsSelector64+4], 0020F800h
        mov DWORD [esi+UserSsSelector64], eax
        mov DWORD [esi+UserSsSelector64+4], 0000F200h

        ;;
        ;; 32-bit Kernel CS/SS 描述符
        ;;
        mov DWORD [esi+KernelCsSelector32],   0000FFFFh
        mov DWORD [esi+KernelCsSelector32+4], 00CF9A00h
        mov DWORD [esi+KernelSsSelector32],   0000FFFFh
        mov DWORD [esi+KernelSsSelector32+4], 00CF9200h  

        ;;
        ;; FS base = 12_0000h, limit = 1M, DPL = 0
        ;;
        mov DWORD [esi+FsSelector],   0000FFFFh
        mov DWORD [esi+FsSelector+4], 000F9212h


        ;;
        ;; GS base = 10_0000h + index * PCB_SIZE
        ;;
        mov eax, PCB_SIZE
        mul DWORD [CpuIndex] 
        add eax, PCB_PHYSICAL_BASE
        mov [esi+GsSelector+4], eax
        mov WORD [esi+GsSelector],    0FFFFh
        mov [esi+GsSelector+2], eax
        mov WORD [esi+GsSelector+5],  0F92h

        ;;
        ;; TSS description
        ;;
        mov edx, [CpuIndex]
        shl edx, 7
        add edx, setup.Tss
        mov [esi+TssSelector32+4], edx
        mov WORD [esi+TssSelector32], 067h
        mov [esi+TssSelector32+2], edx
        mov WORD [esi+TssSelector32+5], 0089h

        ;;
        ;; 设置 TSS 内容
        ;;
        mov eax, [CpuIndex]
        shl eax, 13
        lea eax, [eax+KERNEL_STACK_PHYSICAL_BASE+0FF0h]
        mov WORD [edx+tss32.ss0], KernelSsSelector32
        mov [edx+tss32.esp0], eax
        mov WORD [edx+tss32.IomapBase], 0

        ;;
        ;; GDT pointer: 此时 GDT base 使用物理地址
        ;;
        lea eax, [esi-10h]
        mov WORD  [eax], 12 * 8 - 1		; GDT limit
        mov DWORD [eax+2], esi			; GDT base
        pop edx
        ret




	    bits 32

;-------------------------------------------------------------------
; set_global_gdt:
; input:
;       esi - GDT 地址
; output:
;       none
; 描述: 
;       1) 初始化 SDA 区域的 GDT 数据
;	    2) 此函数运行在 32 位 protected-mode 下
;-------------------------------------------------------------------
set_global_gdt:
        add esi, 10h
        xor eax, eax

        ;;
        ;; 设置基本 GDT 表项
        ;; 1) entry 0:          NULL descriptor
        ;; 2) entry 1,2:        64-bit kernel code/data 描述符
        ;; 3) entry 3,4:        32-bit user code/data 描述符
        ;; 4) entry 5,6:        64-bit user code/data 描述符
        ;; 5) entry 7,8:        32-bit kernel code/data 描述符                
        ;; 6) entry 9,10:       fs/gs 段使用
        ;; 7) entry 11,12:      TSS 描述符动态增加
        ;; 

        ;;		
        ;; NULL descriptor
        ;;
        mov [esi], eax
        mov [esi+4], eax	


        ;;
        ;; 64-bit Kernel CS/SS 描述符设置说明: 
        ;; 1)在 x64 体系下描述符可以设置为: 
        ;;      * CS = 00209800_00000000h (L=P=1, G=D=0, C=R=A=0)
        ;;      * SS = 00009200_00000000h (L=1, G=B=0, W=1, E=A=0)
        ;; 2) 在 VMX 架构下, 在VM-exit 返回 host 后会将描述符设置为: 
        ;;      * CS = 00AF9B00_0000FFFFh (G=L=P=1, D=0, C=0, R=A=1, limit=4G)
        ;;      * SS = 00CF9300_0000FFFFh (G=P=1, B=1, E=0, W=A=1, limit=4G)
        ;;
        ;; 3) 因此, 为了与 host 的描述符达成一致, 这里将描述符设为: 
        ;;      * CS = 00AF9A00_0000FFFFh (G=L=P=1, D=0, C=A=0, R=1, limit=4G)
        ;;      * SS = 00CF9200_0000FFFFh (G=P=1, B=1, E=A=0, W=1, limit=4G)  
        ;
        mov DWORD [esi+KernelCsSelector64],   0000FFFFh
        mov DWORD [esi+KernelCsSelector64+4], 00AF9A00h
        mov DWORD [esi+KernelSsSelector64],   0000FFFFh
        mov DWORD [esi+KernelSsSelector64+4], 00CF9200h   

        ;;
        ;; 32-bit User CS/SS 描述符
        ;;
        mov DWORD [esi+UserCsSelector32],   0000FFFFh
        mov DWORD [esi+UserCsSelector32+4], 00CFFA00h
        mov DWORD [esi+UserSsSelector32],   0000FFFFh
        mov DWORD [esi+UserSsSelector32+4], 00CFF200h

        ;;
        ;; 64-bit User CS/SS 描述符
        ;;
        mov DWORD [esi+UserCsSelector64], eax
        mov DWORD [esi+UserCsSelector64+4], 0020F800h
        mov DWORD [esi+UserSsSelector64], eax
        mov DWORD [esi+UserSsSelector64+4], 0000F200h

        ;;
        ;; 32-bit Kernel CS/SS 描述符
        ;;
        mov DWORD [esi+KernelCsSelector32],   0000FFFFh
        mov DWORD [esi+KernelCsSelector32+4], 00CF9A00h
        mov DWORD [esi+KernelSsSelector32],   0000FFFFh
        mov DWORD [esi+KernelSsSelector32+4], 00CF9200h  

        ;;
        ;; FS base = 8002_0000h, limit = 1M, DPL = 0
        ;;
        mov DWORD [esi+FsSelector],   0000FFFFh
        mov DWORD [esi+FsSelector+4], 800F9202h
        mov DWORD [esi+GsSelector],   0000FFFFh
        mov DWORD [esi+GsSelector+4], 800F9200h 
	
        ;;
        ;; GS base = PCB.Base, limit = 1M, DPL = 0
        ;;
        mov eax, [gs: PCB.Base] 
        mov [esi+GsSelector+4], eax
        mov WORD [esi+GsSelector],    0FFFFh
        mov [esi+GsSelector+2], eax
        mov WORD [esi+GsSelector+5],  0F92h


        ;;
        ;; TSS description
        ;;
        mov eax, [gs: PCB.TssBase] 
        mov [esi+TssSelector32+4], eax
        mov DWORD [esi+TssSelector32+2], eax
        mov WORD [esi+TssSelector32+5], 0089h
        neg eax
        lea eax, [eax+SDA_BASE+SDA.Iomap+2000h-1]
        mov [esi+TssSelector32], ax

        ;;
        ;; GDT pointer: 此时 GDT base 使用虚拟地址
        ;;
        lea eax, [esi-10h]
        mov esi, [CpuIndex]
        shl esi, 8
        add esi, SDA_BASE+SDA.Gdt+10h
        mov WORD  [eax], 12 * 8 - 1		; GDT limit
        mov DWORD [eax+2], esi			; GDT base

        ;;
        ;; 注意, 为了适应在 64-bit 环境里
        ;; 1) 当需要进入 longmode 时, 需要额外增加一个空的 GDT 描述符 ！
        ;;
        cmp DWORD [fs: SDA.ApLongmode], 1
        jne set_global_gdt.@0
        mov DWORD [esi+TssSelector32+8], 0
        mov DWORD [esi+TssSelector32+12], 0
        mov WORD [eax], 13 * 8 - 1 
        
set_global_gdt.@0:
        ;;
        ;; 设置 TSS 内容
        ;;
        mov esi, [gs: PCB.TssPhysicalBase]
        mov ax, [fs: SDA.KernelSsSelector]
        mov [esi+tss32.ss0], ax
        
        ;;
        ;; 分配一个 kernel 使用的 stack, 作为中断服务例程使用
        ;;
        mov eax, 2000h
        lock add [fs:SDA.KernelStackPhysicalBase], eax
        lock xadd [fs: SDA.KernelStackBase], eax
        add eax, 0FF0h
        mov [esi+tss32.esp0], eax
        
        add eax, 1000h
        mov [gs: PCB.KernelStack], eax
        mov DWORD [gs: PCB.KernelStack+4], 0FFFFF800h

        ;;
        ;; 设置 IOmap 基址
        ;;
        mov eax, SDA_BASE+SDA.Iomap
        sub eax, [gs: PCB.TssBase]
        mov [esi+tss32.IomapBase], ax                           ; Iomap 偏移量
        ret


;-------------------------------------------------------------------
; init_system_data_area()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 初始化系統数据区域(SDA)
;       2) 此函数执行在 32-bit 保护模式下
;-------------------------------------------------------------------
init_system_data_area:
        push ecx
        push edx
        ;;
        ;; 地址说明: 
        ;; 1) 所有的地址值使用 64 位
        ;; 2) 低 32 位使用在 legacy 模式下, 映射 32 位值
        ;; 3) 高 32 位使用在 64-bit 模式下, 映射 64 位值
        ;;
        
        
        ;;
        ;; SDA 基本信息说明: 
        ;; 1) SDA.Base 值: 
        ;;      1.1) legacy 下 SDA_BASE = 8002_0000h
        ;;      1.2) 64-bit 下 SDA_BASE = ffff_f800_8000_0000h
        ;; 2) SDA.PhysicalBase 值: 
        ;;      2.1) legacy 与 64-bit 下保持不变, 为 12_0000h
        ;; 3) SDA.PcbBase 值: 
        ;;      3.1) 指向 BSP 的 PCB 区域, 即: 8000_0000h
        ;; 4) SDA.PcbPhysicalBase 值: 
        ;;      4.1) 指向 BSP 的 PCB 物理地址, 即: 10_0000h
        ;;
        mov edx, 0FFFFF800h                                             ; 64 位地址中的高 32 位
        xor ecx, ecx
        
        mov DWORD [fs: SDA.Base], SDA_BASE                              ; SDA 虚拟地址
        mov [fs: SDA.Base + 4], edx
        mov DWORD [fs: SDA.PhysicalBase], SDA_PHYSICAL_BASE             ; SDA 物理地址
        mov [fs: SDA.PhysicalBase + 4], ecx
        mov DWORD [fs: SDA.PcbBase], PCB_BASE                           ; 指向 BSP 的 PCB 区域
        mov [fs: SDA.PcbBase + 4], edx
        mov DWORD [fs: SDA.PcbPhysicalBase], PCB_PHYSICAL_BASE          ; 指向 BSP 的 PCB 区域
        mov [fs: SDA.PcbPhysicalBase + 4], ecx
        mov [fs: SDA.ProcessorCount], ecx                               ; 清 processor count
        mov DWORD [fs: SDA.Size], SDA_SIZE                              ; SDA size
        mov DWORD [fs: SDA.VideoBufferHead], 0B8000h
        mov DWORD [fs: SDA.VideoBufferHead + 4], ecx
        mov DWORD [fs: SDA.VideoBufferPtr], 0B8000h
        mov DWORD [fs: SDA.VideoBufferPtr + 4], ecx
        mov DWORD [fs: SDA.TimerCount], ecx
        mov DWORD [fs: SDA.LastStatusCode], ecx
        mov DWORD [fs: SDA.UsableProcessorMask], ecx                    ; UsableProcessorMask 指示不可用
        mov DWORD [fs: SDA.ProcessMask], ecx                            ; process queue = 0, 无任务
        mov DWORD [fs: SDA.ProcessMask + 4], ecx
        mov DWORD [fs: SDA.NmiIpiRequestMask], ecx
        
        ;;
        ;; 更新物理内存 size
        ;;
        mov eax, [MMap.Size]
        mov ecx, [MMap.Size + 4]
        shrd eax, ecx, 10                                               ; 转换为 KB 单位
        mov [fs: SDA.MemorySize], eax
               
        ;;
        ;; 保存boot驱动器
        ;;
        mov al, [7C03h]
        mov [fs: SDA.BootDriver], al
        
        ;;
        ;; 如果需要进入 longmode 则定义 __X64 符号
        ;; 1)SDA.ApLongmode = 1 时, 进入所有处理器进入 longmode 模式
        ;; 2) SDA.ApLongmode = 0 时, 使用 legacy 环境
        ;;
%ifdef  __X64
        mov DWORD [fs: SDA.ApLongmode], 1
%else
        mov DWORD [fs: SDA.ApLongmode], 0
%endif              
        
        
        ;;
        ;; 初始化 PCB pool 分配管理记录
        ;; 1) PCB pool 用来分每个 logical processor 分配私有的 PCB 块
        ;; 2) 共支持 16 个 logical processor
        ;; 3) PCB pool 基址为 PCB_BASE = 8000_0000h, PCB_POOL_SIZE = 128K
        ;; 4) PCB pool 物理地址 PCB_PHYSICAL_BASE = 10_0000h
        ;;
        mov DWORD [fs: SDA.PcbPoolBase], PCB_BASE                       ; PCB pool 基址
        mov [fs: SDA.PcbPoolBase+4], edx
        mov DWORD [fs: SDA.PcbPoolPhysicalBase], PCB_PHYSICAL_POOL      ; PCB pool 物理基址
        mov DWORD [fs: SDA.PcbPoolPhysicalBase+4], ecx
        mov DWORD [fs: SDA.PcbPoolPhysicalTop], SDA_PHYSICAL_BASE-1     ; PCB pool 顶部
        mov DWORD [fs: SDA.PcbPoolPhysicalTop+4], ecx
        mov DWORD [fs: SDA.PcbPoolTop], PCB_BASE+PCB_POOL_SIZE-1
        mov DWORD [fs: SDA.PcbPoolTop+4], edx
        mov DWORD [fs: SDA.PcbPoolSize], PCB_POOL_SIZE
        
        ;;
        ;; 初始化 TSS 分配 pool 记录
        ;; 1) TSS pool 用来为每个 logical processor 分配私有的 TSS 块
        ;; 2) 每次分配的额度 TssPoolGranularity = 100h 字节
        ;;
        mov DWORD [fs: SDA.TssPoolBase], SDA_BASE + SDA.Tss             ; TSS pool 基址
        mov [fs: SDA.TssPoolBase+4], edx
        mov DWORD [fs: SDA.TssPoolPhysicalBase], SDA_PHYSICAL_BASE+SDA.Tss
        mov [fs: SDA.TssPoolPhysicalBase+4], ecx
        mov DWORD [fs: SDA.TssPoolTop], SDA_BASE+SDA.Tss+0FFFh          ; TSS pool 顶部
        mov DWORD [fs: SDA.TssPoolTop+4], edx
        mov DWORD [fs: SDA.TssPoolPhysicalTop], SDA_PHYSICAL_BASE+SDA.Tss+0FFFh
        mov DWORD [fs: SDA.TssPoolPhysicalTop+4], ecx
        mov DWORD [fs: SDA.TssPoolGranularity], 100h                    ; TSS 块分配粒度为 100h 字节
        
        ;;
        ;; 设置 GDT selector
        ;;
        mov WORD [fs: SDA.KernelCsSelector],   KernelCsSelector32
        mov WORD [fs: SDA.KernelSsSelector],   KernelSsSelector32
        mov WORD [fs: SDA.UserCsSelector],     UserCsSelector32
        mov WORD [fs: SDA.UserSsSelector],     UserSsSelector32
        mov WORD [fs: SDA.FsSelector],         FsSelector
        mov WORD [fs: SDA.SysenterCsSelector], KernelCsSelector32
        mov WORD [fs: SDA.SyscallCsSelector],  KernelCsSelector32
        mov WORD [fs: SDA.SysretCsSelector],   UserCsSelector32	

        ;;
        ;; 更新 IDT pointer
        ;; 1) 此时 IDT base 使用物理地址
        ;;
        mov DWORD [fs: SDA.IdtBase], SDA_PHYSICAL_BASE+SDA.Idt
        mov [fs: SDA.IdtBase+4], edx
        mov WORD [fs: SDA.IdtLimit], 256 * 16 - 1                       ; 默认保存 255 个 vector(为 longmode 下)
        mov DWORD [fs: SDA.IdtTop], SDA_PHYSICAL_BASE+SDA.Idt           ; top 指向 base
        mov [fs: SDA.IdtTop+4], edx
        
        ;;
        ;; 初始 SRT(系统服务例程表)信息
        ;;
        mov DWORD [fs: SRT.Base], SDA_BASE+SRT.Base                   ; SRT 基址
        mov [fs: SRT.Base+4], edx
        mov DWORD [fs: SRT.PhysicalBase], SDA_PHYSICAL_BASE + SRT.Base  ; SRT 物理基址
        mov [fs: SRT.PhysicalBase + 4], ecx
        mov DWORD [fs: SRT.Size], SRT_SIZE - SDA_SIZE
        mov DWORD [fs: SRT.Top], SRT_TOP
        mov DWORD [fs: SRT.Top + 4], edx
        mov DWORD [fs: SRT.Index], SDA_BASE + SRT.Entry
        mov DWORD [fs: SRT.Index + 4], edx
        mov DWORD [fs: SRT.ServiceRoutineVector], SYS_SERVICE_CALL      ; 系统服务例程向量号
                

        ;;
        ;; 初始化 paging 管理值(legacy 模式下)
        ;;
        mov DWORD [fs: SDA.XdValue], 0                                  ; XD 位清 0
        mov DWORD [fs: SDA.PtBase], PT_BASE                             ; PT 表基址为 0C0000000h
        mov DWORD [fs: SDA.PtTop], PT_TOP                               ; PT 表顶端为 0C07FFFFFh
        mov DWORD [fs: SDA.PtPhysicalBase], PT_PHYSICAL_BASE            ; PT 表物理基址为 200000h
        mov DWORD [fs: SDA.PdtBase], PDT_BASE                           ; PDT 表基址为 0C0600000h
        mov DWORD [fs: SDA.PdtTop], PDT_TOP                             ; PDT 表顶端为 0C0603FFFh        
        mov DWORD [fs: SDA.PdtPhysicalBase], PDT_PHYSICAL_BASE          ; PDT 表物理基址为 800000h
        
        ;;
        ;; 初始 legacy 模式下的 PPT 记录
        ;; 1) PPT 表物理基址 = SDA_PHYSICAL_BASE + SDA.Ppt
        ;; 2) PPT 表基址 = SDA_BASE + SDA.Ppt
        ;; 3) PPT 表顶端 = SDA_BASE + SDA.Ppt + 31
        ;;
        mov DWORD [fs: SDA.PptPhysicalBase], PPT_PHYSICAL_BASE
        mov DWORD [fs: SDA.PptBase], PPT_BASE
        mov DWORD [fs: SDA.PptTop], PPT_TOP
      
        ;;
        ;; 初始化 long-mode 下的 page 管理值
        ;;
        mov eax, 0FFFFF6FBh
        mov DWORD [fs: SDA.PtBase64], 0
        mov DWORD [fs: SDA.PtBase64 + 4], 0FFFFF680h
        mov DWORD [fs: SDA.PdtBase64], 40000000h
        mov DWORD [fs: SDA.PdtBase64 + 4], eax
        mov DWORD [fs: SDA.PptBase64], 7DA00000h
        mov DWORD [fs: SDA.PptBase64 + 4], eax
        mov DWORD [fs: SDA.PxtBase64], 7DBED000h
        mov DWORD [fs: SDA.PxtBase64 + 4], eax
        mov DWORD [fs: SDA.PtTop64], 0FFFFFFFFh
        mov DWORD [fs: SDA.PtTop64 + 4], 0FFFFF6FFh
        mov DWORD [fs: SDA.PdtTop64], 7FFFFFFFh
        mov DWORD [fs: SDA.PdtTop64 + 4], eax
        mov DWORD [fs: SDA.PptTop64], 7DBFFFFFh
        mov DWORD [fs: SDA.PptTop64 + 4], eax
        mov DWORD [fs: SDA.PxtTop64], 7DBEDFFFh
        mov DWORD [fs: SDA.PxtTop64 + 4], eax
        mov DWORD [fs: SDA.PxtPhysicalBase64], PXT_PHYSICAL_BASE64
        mov DWORD [fs: SDA.PxtPhysicalBase64 + 4], 0
        mov DWORD [fs: SDA.PptPhysicalBase64], PPT_PHYSICAL_BASE64
        mov DWORD [fs: SDA.PptPhysicalBase64 + 4], 0
        mov BYTE [fs: SDA.PptValid], 0
        
        ;;
        ;; PT pool 管理记录:
        ;; 1) 主 PT pool 区域: 220_0000h - 2ff_ffffh(ffff_f800_8220_000h)
        ;; 2) 备用 Pt pool 区域: 20_0000h - 09f_ffffh(ffff_f800_8020_0000h)
        ;;
        mov DWORD [fs: SDA.PtPoolPhysicalBase], PT_POOL_PHYSICAL_BASE64
        mov DWORD [fs: SDA.PtPoolPhysicalBase + 4], 0
        mov DWORD [fs: SDA.PtPoolPhysicalTop], PT_POOL_PHYSICAL_TOP64
        mov DWORD [fs: SDA.PtPoolPhysicalTop + 4], 0
        mov DWORD [fs: SDA.PtPoolSize], PT_POOL_SIZE
        mov DWORD [fs: SDA.PtPoolSize + 4], 0
        mov DWORD [fs: SDA.PtPoolBase], 82200000h
        mov DWORD [fs: SDA.PtPoolBase + 4], 0FFFFF800h
        
        mov DWORD [fs: SDA.PtPool2PhysicalBase], PT_POOL2_PHYSICAL_BASE64
        mov DWORD [fs: SDA.PtPool2PhysicalBase + 4], 0
        mov DWORD [fs: SDA.PtPool2PhysicalTop], PT_POOL2_PHYSICAL_TOP64
        mov DWORD [fs: SDA.PtPool2PhysicalTop + 4], 0
        mov DWORD [fs: SDA.PtPool2Size], PT_POOL2_SIZE
        mov DWORD [fs: SDA.PtPool2Size + 4], 0
        mov DWORD [fs: SDA.PtPool2Base], 80200000h
        mov DWORD [fs: SDA.PtPool2Base + 4], 0FFFFF800h
        
        mov BYTE [fs: SDA.PtPoolFree], 1
        mov BYTE [fs: SDA.PtPool2Free], 1

        ;;
        ;; VMX Ept(extended page table)管理记录
        ;; 1) PXT 表区域: FFFF_F800_C0A0_0000h - FFFF_F800_C0BF_FFFFh(A0_0000h - BF_FFFFh)
        ;; 2) PPT 表区域: 在 SDA 内
        ;;
        mov eax, [fs: SDA.Base]
        mov edx, [fs: SDA.PhysicalBase]
        add eax, SDA.EptPxt - SDA.Base
        add edx, SDA.EptPxt - SDA.Base        
        mov DWORD [fs: SDA.EptPxtBase64], eax
        mov DWORD [fs: SDA.EptPxtPhysicalBase64], edx
        mov DWORD [fs: SDA.EptPptBase64], 0C0A00000h
        mov DWORD [fs: SDA.EptPptPhysicalBase64], 0A00000h
        add eax, (200000h - 1)
        mov DWORD [fs: SDA.EptPxtTop64], eax
        mov DWORD [fs: SDA.EptPptTop64], 0C0BFFFFFh
                
        mov DWORD [fs: SDA.EptPxtBase64 + 4], 0FFFFF800h
        mov DWORD [fs: SDA.EptPxtPhysicalBase64 + 4], 0
        mov DWORD [fs: SDA.EptPptBase64 + 4], 0FFFFF800h
        mov DWORD [fs: SDA.EptPptPhysicalBase64 + 4], 0
        mov DWORD [fs: SDA.EptPxtTop64 + 4], 0FFFFF800h
        mov DWORD [fs: SDA.EptPptTop64 + 4], 0FFFFF800h
        
        
        
        ;;
        ;; 初始化 stack 和 pool 管理信息
        ;; 1) legacy 下:  KERNEL_STACK_BASE  = ffe0_0000h
        ;;                USER_STACK_BASE    = 7fe0_0000h
        ;;                KERNEL_POOL_BASE   = 8320_0000h
        ;;                USER_POOL_BASE     = 7300_1000h
        ;;
        ;; 2) 64-bit 下:  KERNEL_STACK_BASE64 = ffff_ff80_ffe0_0000h
        ;;                USER_STACK_BASE64   = 0000_0000_7fe0_0000h
        ;;                KERNEL_POOL_BASE64  = ffff_f800_8320_0000h
        ;;                USER_POOL_BASE64    = 0000_0000_7300_1000h
        ;;
        ;; 3) 物理地址:   KERNEL_STACK_PHYSICAL_BASE = 0104_0000h
        ;;               USER_STACK_PHYSICAL_BASE    = 0101_0000h
        ;;               KERNEL_POOL_PHYSICAL_BASE   = 0320_0000h
        ;;               USER_POOL_PHYSICAL_BASE     = 0300_1000h
        ;;
        xor ecx, ecx
        mov DWORD [fs: SDA.UserStackBase], USER_STACK_BASE
        mov [fs: SDA.UserStackBase+4], ecx
        mov DWORD [fs: SDA.UserStackPhysicalBase], USER_STACK_PHYSICAL_BASE
        mov [fs: SDA.UserStackPhysicalBase + 4], ecx
        mov DWORD [fs: SDA.KernelStackBase], KERNEL_STACK_BASE
        mov DWORD [fs: SDA.KernelStackBase + 4], 0FFFFFF80h
        mov DWORD [fs: SDA.KernelStackPhysicalBase], KERNEL_STACK_PHYSICAL_BASE
        mov [fs: SDA.KernelStackPhysicalBase + 4], ecx
        mov DWORD [fs: SDA.UserPoolBase], USER_POOL_BASE
        mov [fs: SDA.UserPoolBase + 4], ecx
        mov DWORD [fs: SDA.UserPoolPhysicalBase], USER_POOL_PHYSICAL_BASE
        mov [fs: SDA.UserPoolPhysicalBase + 4], ecx
        mov DWORD [fs: SDA.KernelPoolBase], KERNEL_POOL_BASE
        mov DWORD [fs: SDA.KernelPoolBase + 4], 0FFFFF800h
        mov DWORD [fs: SDA.KernelPoolPhysicalBase], KERNEL_POOL_PHYSICAL_BASE
        mov [fs: SDA.KernelPoolPhysicalBase + 4], ecx

        ;;
        ;; 初始化 BTS Pool 与 PEBS pool 管理记录
        ;;
        mov edx, 0FFFFF800h
        mov ebx, [fs: SDA.Base]
        lea eax, [ebx + SDA.BtsBuffer]
        mov [fs: SDA.BtsPoolBase], eax                          ; BTS Pool 基址
        mov [fs: SDA.BtsPoolBase + 4], edx
        add eax, 0FFFh                                          ; 4K size
        mov DWORD [fs: SDA.BtsBufferSize], 100h                 ; 每个 BTS buffer 默认为 100h 
        mov [fs: SDA.BtsPoolTop], eax                           ; BTS pool 顶端
        mov [fs: SDA.BtsPoolTop + 4], edx
        mov DWORD [fs: SDA.BtsRecordMaximum], 10                ; 每个 BTS buffer 最多容纳 10 条记录
        lea eax, [ebx + SDA.PebsBuffer]
        mov [fs: SDA.PebsPoolBase], eax                         ; PEBS Pool 基址
        mov [fs: SDA.PebsPoolBase + 4], edx
        add eax, 3FFFh                                          ; 16K size
        mov DWORD [fs: SDA.PebsBufferSize], 400h                ; 每个 PEBS buffer 默认为 400h
        mov [fs: SDA.PebsPoolTop], eax                          ; PEBS pool 顶端
        mov [fs: SDA.PebsPoolTop + 4], edx
        mov DWORD [fs: SDA.PebsRecordMaximum], 5                ; 每个 Pebs buffer 最多容纳 5 条记录
        
        
        ;;
        ;; 初始化 VM domain pool 管理记录
        ;;
        mov DWORD [fs: SDA.DomainPhysicalBase], DOMAIN_PHYSICAL_BASE
        mov DWORD [fs: SDA.DomainPhysicalBase + 4], 0
        mov DWORD [fs: SDA.DomainBase], DOMAIN_BASE
        mov DWORD [fs: SDA.DomainBase + 4], 0FFFFF800h
        
        ;;
        ;; 初始化 GPA 映射列表管理记录
        ;;
        mov eax, SDA_BASE + SDA.GpaMappedList
        mov [fs: SDA.GmlBase], eax
        mov DWORD [fs: SDA.GmlBase + 4], 0FFFFF800h

%ifdef DEBUG_RECORD_ENABLE
        ;;
        ;; 初始化 DRS 管理记录
        ;; 1) DrsBase = DrsBuffer
        ;; 2) DrsHeadPtr = DrsTailPtr = DrsBuffer
        ;; 3) DrsIndex = DrsBuffer
        ;; 4) DrsCount = 0
        ;;
        mov eax, [fs: SDA.Base]
        lea eax, [eax + SDA.DrsBuffer]
        mov [fs: SDA.DrsBase], eax
        mov DWORD [fs: SDA.DrsBase + 4], 0FFFFF800h
        mov [fs: SDA.DrsHeadPtr], eax
        mov DWORD [fs: SDA.DrsHeadPtr + 4], 0FFFFF800h
        mov [fs: SDA.DrsTailPtr], eax
        mov DWORD [fs: SDA.DrsTailPtr + 4], 0FFFFF800h        
        mov [fs: SDA.DrsIndex], eax
        mov DWORD [fs: SDA.DrsIndex + 4], 0FFFFF800h
        mov DWORD [fs: SDA.DrsCount], 0
        add eax, MAX_DRS_COUNT * DRS_SIZE
        mov [fs: SDA.DrsTop], eax
        mov DWORD [fs: SDA.DrsTop + 4], 0FFFFF800h        
        mov DWORD [fs: SDA.DrsMaxCount], MAX_DRS_COUNT
        
        ;;
        ;; 初始化头节点 PrevDrs 与 NextDrs
        ;;
        mov edx, [fs: SDA.PhysicalBase]
        add edx, SDA.DrsBuffer
        xor eax, eax
        mov [edx + DRS.PrevDrs], eax
        mov [edx + DRS.PrevDrs + 4], eax
        mov [edx + DRS.NextDrs], eax
        mov [edx + DRS.NextDrs + 4], eax      
        mov DWORD [edx + DRS.RecordNumber], 0
%endif        
        

        ;;
        ;; 初始化 DMB 记录
        ;;
        mov eax, [fs: SDA.Base]
        add eax, SDA.DecodeManageBlock
        mov [fs: SDA.DmbBase], eax
        mov DWORD [fs: SDA.DmbBase + 4], 0FFFFF800h
        add eax, DMB.DecodeBuffer
        mov edx, [fs: SDA.PhysicalBase]
        mov [edx + SDA.DecodeManageBlock + DMB.DecodeBufferHead], eax
        mov [edx + SDA.DecodeManageBlock + DMB.DecodeBufferPtr], eax
        mov DWORD [edx + SDA.DecodeManageBlock + DMB.DecodeBufferHead + 4], 0FFFFF800h
        mov DWORD [edx + SDA.DecodeManageBlock + DMB.DecodeBufferPtr + 4], 0FFFFF800h        
        
        ;;
        ;; 初始化 EXTINT_RTE 管理记录
        ;;
        mov eax, [fs: SDA.Base]
        add eax, SDA.ExtIntRteBuffer
        mov [fs: SDA.ExtIntRtePtr], eax
        mov DWORD [fs: SDA.ExtIntRtePtr + 4], 0FFFFF800h
        mov [fs: SDA.ExtIntRteIndex], eax
        mov DWORD [fs: SDA.ExtIntRteIndex + 4], 0FFFFF800h
        mov DWORD [fs: SDA.ExtIntRteCount], 0
        
        ;;
        ;; 配置 pic8259 及异常处理例程, 缺省的中断服务例程
        ;;
        call setup_pic8259
        call install_default_exception_handler
        call install_default_interrupt_handler        
                
        ;;
        ;; 设置 AP 的 startup routine 入口地址
        ;;
        mov eax, ApStage1Entry
        mov [fs: SDA.ApStartupRoutineEntry], eax
        mov DWORD [fs: SDA.Stage1LockPointer], ApStage1Lock
        mov DWORD [fs: SDA.Stage2LockPointer], ApStage2Lock
        mov DWORD [fs: SDA.Stage3LockPointer], ApStage3Lock
        mov DWORD [fs: SDA.ApStage], 0
        
        pop edx
        pop ecx
        ret
        




;-------------------------------------------------------------------
; alloc_pcb_base()
; input:
;       none
; output:
;       eax - PCB 物理地址
;       edx - PCB 虚拟地址
; 描述: 
;       1) 每个处理器的 PCB 地址使用 alloc_pcb_base() 来分配
;       2) edx:eax - 返回 PCB 块的虚拟地址和对应的物理地址
;       2) 在 stage1(legacy 下未分页)使用
;-------------------------------------------------------------------
alloc_pcb_base:
        push ebx
        mov eax, [CpuIndex]
        mov ebx, PCB_SIZE
        mul ebx
        mov edx, eax
        add edx, [fs: SDA.PcbPoolBase]
        add eax, [fs: SDA.PcbPoolPhysicalBase]
        mov ebx, eax
        mov esi, PCB_SIZE
        mov edi, eax
        call zero_memory
        mov eax, ebx                        
        pop ebx
        ret



;-------------------------------------------------------------------
; alloc_tss_base()
; input:
;       none
; output:
;       eax - Tss 块物理地址
;       edx - Tss 块虚拟地址
; 描述:
;       1) 从 TSS POOL 里分配一个 TSS 块空间       
;       2) 如果 TSS Pool 用完, 分配失败, 返回 0 值
;       3) 在 stage1 阶段调用
;-------------------------------------------------------------------
alloc_tss_base:
        push ebx
        mov eax, [CpuIndex]
        shl eax, 8                              ; CpuIndex * 100h
        mov edx, eax
        add edx, [fs: SDA.TssPoolBase]
        add eax, [fs: SDA.TssPoolPhysicalBase]
        mov edi, ebx
        mov esi, 100h
        call zero_memory
        mov eax, ebx
        pop ebx
        ret
        


;-------------------------------------------------------------------
; alloc_stage1_kernel_stack_4k_base()
; input:
;       none
; output:
;       eax - stack base
; 描述: 
;       1) 分配 stage1 阶段使用的 kernel stack
;-------------------------------------------------------------------
alloc_stage1_kernel_stack_4k_base:
        mov eax, 4096
        mov edx, eax
        lock xadd [fs: SDA.KernelStackPhysicalBase], eax
        lock xadd [fs: SDA.KernelStackBase], edx 
        ret


;-------------------------------------------------------------------
; alloc_stage1_kernel_pool_base()
; input:
;       esi - 页数量
; output:
;       eax - 虚拟地址
;       edx - 物理地址
; 描述: 
;       1) 在　stage1 阶段分配的 kernel pool
;       2) 返回物理地址
;-------------------------------------------------------------------
alloc_stage1_kernel_pool_base:
        push ecx
        lea ecx, [esi - 1]
        mov eax, 4096
        shl eax, cl
        mov edx, eax
        lock xadd [fs: SDA.KernelPoolBase], eax 
        lock xadd [fs: SDA.KernelPoolPhysicalBase], edx
        pop ecx
        ret
        
        

;-----------------------------------------------------------------------
; init_processor_control_block()
; input:
;       none
; output:
;       none
; 描述:
;       1) 初始化处理器的 PCB 区域
;-----------------------------------------------------------------------
init_processor_control_block:
        push edx
        push ecx
        push ebx
        
        ;;
        ;; 分配 PCB 地址
        ;;
        call alloc_pcb_base                             ; edx:eax = VA:PA
        mov [gs: PCB.PhysicalBase], eax
        mov [gs: PCB.Base], edx
        mov DWORD [gs: PCB.PhysicalBase+4], 0
        mov DWORD [gs: PCB.Base+4], 0FFFFF800h
        mov ebx, edx

        ;;
        ;; 分配 TSS 块
        ;;
        call alloc_tss_base                             ; edx:eax 返回 VA:PA 
        mov [gs: PCB.TssPhysicalBase], eax
        mov [gs: PCB.TssBase], edx
        mov DWORD [gs: PCB.TssPhysicalBase+4], 0
        mov DWORD [gs: PCB.TssBase+4], 0FFFFF800h
        mov DWORD [gs: PCB.TssLimit], (1000h+2000h-1)
        mov DWORD [gs: PCB.IomapBase], SDA_BASE+SDA.Iomap
        mov DWORD [gs: PCB.IomapBase+4], 0FFFFF800h
        mov DWORD [gs: PCB.IomapPhysicalBase], SDA_PHYSICAL_BASE+SDA.Iomap      

        ;;
        ;; 设置 GDT 表
        ;;
        mov eax, [CpuIndex]
        shl eax, 8
        lea esi, [eax+SDA_PHYSICAL_BASE+SDA.Gdt]
        lea eax, [eax+SDA_BASE+SDA.Gdt]
        mov [gs: PCB.GdtPointer], eax
        mov DWORD [gs: PCB.GdtPointer+4], 0FFFFF800h
        call set_global_gdt

        ;;
        ;; Gs/Tss selector
        ;;
        mov WORD [gs: PCB.GsSelector], GsSelector
        mov WORD [gs: PCB.TssSelector], TssSelector32 

        ;;
        ;; 更新 PCB 基本记录
        ;; 1) 地址的高 32 位使用在 64-bit 模式下
 
        mov DWORD [gs: PCB.Size], PCB_SIZE
        mov eax, [fs: SDA.Base]
        mov [gs: PCB.SdaBase], eax                      ; 指向 SDA 区域
        mov DWORD [gs: PCB.SdaBase+4], 0FFFFF800h
        add eax, SRT.Base                               ; SRT 区域基址(位于 SDA 之后)
        mov [gs: PCB.SrtBase], eax                      ; 指向 System Service Routine Table 区域    
        mov DWORD [gs: PCB.SrtBase+4], 0FFFFF800h
        mov eax, [fs: SDA.PhysicalBase]     
        mov [gs: PCB.SdaPhysicalBase], eax
        add eax, SRT.Base
        mov [gs: PCB.SrtPhysicalBase], eax
        mov eax, [gs: PCB.PhysicalBase]
        add eax, PCB.Ppt
        mov [gs: PCB.PptPhysicalBase], eax

        ;;
        ;; 更新 ReturnStackPointer
        ;;
        lea eax, [ebx+PCB.ReturnStack]
        mov [gs: PCB.ReturnStackPointer], eax
        mov DWORD [gs: PCB.ReturnStackPointer+4], 0FFFFF800h
        
        ;;
        ;; 缺省的 TPR 级别为 3
        ;;
        mov BYTE [gs: PCB.CurrentTpl], INT_LEVEL_THRESHOLD
        mov BYTE [gs: PCB.PrevTpl], 0
        

        ;;
        ;; 设置 LDT 管理信息
        ;; 注意: 
        ;; 1) LDT 此时为空, 这里使用虚拟地址
        ;; 2) 地址高 32 位使用在 64-bit 模式下
        ;;
        mov DWORD [gs: PCB.LdtBase], SDA_BASE+SDA.Ldt
        mov DWORD [gs: PCB.LdtBase+4], 0FFFFF800h
        mov DWORD [gs: PCB.LdtTop], SDA_BASE+SDA.Ldt
        mov DWORD [gs: PCB.LdtTop+4], 0FFFFF800h
        

        
        ;;
        ;; 更新 context 区域指针
        ;; 1) 在 stage1 使用物理地址
        ;;
        lea eax, [ebx+PCB.Context]
        mov [gs: PCB.ContextBase], eax
        lea eax, [ebx+PCB.XMMStateImage]
        mov [gs: PCB.XMMStateImageBase], eax

        ;;
        ;; 分配本地存储块
        ;;
        mov esi, LSB_SIZE+0FFFh
        shr esi, 12
        call alloc_stage1_kernel_pool_base                              ; edx:eax = PA:VA
        mov [gs: PCB.LsbBase], eax
        mov DWORD [gs: PCB.LsbBase+4], 0FFFFF800h
        mov [gs: PCB.LsbPhysicalBase], edx
        mov DWORD [gs: PCB.LsbPhysicalBase+4], 0        
        mov ecx, eax                                                    ; ecx = LSB
        
        ;;
        ;; 清空 LSB 块
        ;;
        mov esi, LSB_SIZE
        mov edi, edx
        call zero_memory
                
        ;;
        ;; 更新 LSB 基本信息
        ;;
        mov [edx+LSB.Base], ecx
        mov DWORD [edx+LSB.Base+4], 0FFFFF800h                      ; LSB.Base
        mov [edx+LSB.PhysicalBase], edx
        mov DWORD [edx+LSB.PhysicalBase+4], 0                       ; LSB.PhysicalBase
        
        ;;
        ;; local video buffer 记录
        ;;
        lea esi, [ecx+LSB.LocalVideoBuffer]
        mov [edx+LSB.LocalVideoBufferHead], esi
        mov DWORD [edx+LSB.LocalVideoBufferHead+4], 0FFFFF800h      ; LSB.LocalVideoBufferHead
        mov [edx+LSB.LocalVideoBufferPtr], esi
        mov DWORD [edx+LSB.LocalVideoBufferPtr+4], 0FFFFF800h       ; LSB.LocalVideoBufferPtr
        
        ;;
        ;; local keyboard buffer 记录
        ;;
        lea esi, [ecx+LSB.LocalKeyBuffer]
        mov [edx+LSB.LocalKeyBufferHead], esi
        mov DWORD [edx+LSB.LocalKeyBufferHead+4], 0FFFFF800h        ; LSB.LocalKeyBufferHead
        mov [edx+LSB.LocalKeyBufferPtr], esi
        mov DWORD [edx+LSB.LocalKeyBufferPtr+4], 0FFFFF800h         ; LSB.LocalKeyBufferPtr 
        mov DWORD [edx+LSB.LocalKeyBufferSize], 256                   ; LSB.LocalKeyBufferPtr = 256
               
        
        ;;
        ;; 更新 VMCS 管理指针(虚拟指针)
        ;; 1) VmcsA 指向 GuestA
        ;; 2) VmcsB 指向 GuestB
        ;; 3) VmcsC 指向 GuestC
        ;; 4) VmcsD 指向 GuestD
        ;;
        mov edx, 0FFFFF800h
        mov ecx, [gs: PCB.Base]
        lea eax, [ecx+PCB.GuestA]
        mov [gs: PCB.VmcsA], eax
        mov [gs: PCB.VmcsA+4], edx
        lea eax, [ecx+PCB.GuestB]
        mov [gs: PCB.VmcsB], eax
        mov [gs: PCB.VmcsB+4], edx        
        lea eax, [ecx+PCB.GuestC]
        mov [gs: PCB.VmcsC], eax
        mov [gs: PCB.VmcsC+4], edx     
        lea eax, [ecx+PCB.GuestD]
        mov [gs: PCB.VmcsD], eax
        mov [gs: PCB.VmcsD+4], edx                             
        

        ;;
        ;; 更新处理器状态
        ;; 
        lidt [fs: SDA.IdtPointer]
        mov eax, CPU_STATUS_PE
        or DWORD [gs: PCB.ProcessorStatus], eax
                
        pop ebx
        pop ecx
        pop edx
        ret



;-----------------------------------------------------------------------
; install_default_exception_handler()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 安装默认的异常处理例程
;-----------------------------------------------------------------------
install_default_exception_handler:
        push ecx
        xor ecx, ecx
install_default_exception_handler.loop:        
        mov esi, ecx
        mov edi, [ExceptionHandlerTable+ecx*8]
        call install_kernel_interrupt_handler32
        inc ecx
        cmp ecx, 20
        jb install_default_exception_handler.loop
        pop ecx
        ret
        
        
        
;-----------------------------------------------------
; local_interrupt_default_handler()
; 描述: 
;       处理器的 local 中断源缺省服务例程
;-----------------------------------------------------
local_interrupt_default_handler:
        push ebp
        push eax
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif

        test DWORD [ebp+PCB.ProcessorStatus], CPU_STATUS_PG
        REX.Wrxb
        mov eax, [ebp+PCB.LapicBase]
        REX.Wrxb
        cmovz eax, [ebp+PCB.LapicPhysicalBase]
        mov DWORD [eax+ESR], 0
        mov DWORD [eax+EOI], 0
        pop eax
        pop ebp
        REX.Wrxb
        iret        



;-----------------------------------------------------
; install_default_interrupt_handler()
; 描述:
;       安装默认的中断服务例程
;-----------------------------------------------------
install_default_interrupt_handler:
        push ecx
        xor ecx, ecx
        
        ;;
        ;; 说明:
        ;; 1) 安装 local vector table 服务例程
        ;; 2) 安装 IPI 服务例程
        ;; 3) 安装系统服务例程(40h 中断调用)
        ;;
     
        ;;
        ;; 安装缺省的 local 中断源服务例程
        ;;
        call install_default_local_interrupt_handler

        ;;
        ;; PIC8259 相应的中断服务例程
        ;;
        mov esi, PIC8259A_IRQ0_VECTOR
        mov edi, timer_8259_handler
        call install_kernel_interrupt_handler32

        mov esi, PIC8259A_IRQ1_VECTOR
        mov edi, keyboard_8259_handler
        call install_kernel_interrupt_handler32

%if 0
        call init_ioapic_keyboard
%endif

        ;;
        ;; 建立 IRQ1 中断服务例程
        ;;
        mov esi, IOAPIC_IRQ1_VECTOR
        mov edi, ioapic_keyboard_handler
        call install_kernel_interrupt_handler32

        
        ;;
        ;; 安装 IPI 服务例程
        ;;       
        mov esi, IPI_VECTOR
        mov edi, dispatch_routine
        call install_kernel_interrupt_handler32
        
        mov esi, IPI_ENTRY_VECTOR
        mov edi, goto_entry
        call install_kernel_interrupt_handler32

        ;;
        ;; 安装系统调用服务例程
        ;;
        mov esi, [fs: SRT.ServiceRoutineVector]
        mov edi, sys_service_routine
        call install_user_interrupt_handler32

        pop ecx
        ret
         


;-----------------------------------------------------
; install_default_local_interrupt_handler()
; 描述: 
;       安装缺省 local interrupt
;-----------------------------------------------------
install_default_local_interrupt_handler:
        mov esi, LAPIC_PERFMON_VECTOR
        mov edi, local_interrupt_default_handler
        call install_kernel_interrupt_handler32
        
        mov esi, LAPIC_TIMER_VECTOR
        mov edi, local_interrupt_default_handler
        call install_kernel_interrupt_handler32
        
        mov esi, LAPIC_ERROR_VECTOR
        mov edi, local_interrupt_default_handler
        call install_kernel_interrupt_handler32       
        ret




        

;-----------------------------------------------------
; wait_for_ap_stage1_done()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 发送 INIT-SIPI-SIPI 消息序给 AP
;       2) 等待 AP 完成第1阶段工作
;-----------------------------------------------------
wait_for_ap_stage1_done:
        push ebx
        push edx
        
        ;;
        ;; local APIC 第1阶段使用物理地址
        ;;
        mov ebx, [gs: PCB.LapicPhysicalBase]
        
        ;;
        ;; 发送 IPIs, 使用 INIT-SIPI-SIPI 序列
        ;; 1) 从 SDA.ApStartupRoutineEntry 提取 startup routine 地址
        ;;      
        mov DWORD [ebx+ICR0], 000c4500h                         ; 发送 INIT IPI, 使所有 processor 执行 INIT
        mov esi, 10 * 1000                                      ; 延时 10ms
        call delay_with_us
        
        ;;
        ;; 下面发送两次 SIPI, 每次延时 200us
        ;; 1) 提取 Ap Startup Routine 地址
        ;;
        mov edx, [fs: SDA.ApStartupRoutineEntry]
        shr edx, 12                                             ; 4K 边界
        and edx, 0FFh
        or edx, 000C4600h                                       ; Start-up IPI

        ;;
        ;; 首次发送 SIPI
        ;;
        mov DWORD [ebx+ICR0], edx                               ; 发送 Start-up IPI
        mov esi, 200                                            ; 延时 200us
        call delay_with_us
        
        ;;
        ;; 再次发送 SIPI
        ;;
        mov DWORD [ebx+ICR0], edx                               ; 再次发送 Start-up IPI
        mov esi, 200
        call delay_with_us

        ;;
        ;; 开放第1阶段 AP Lock
        ;;
        xor eax, eax
        mov ebx, [fs: SDA.Stage1LockPointer]
        xchg [ebx], eax

        ;;
        ;; BSP 已完成工作, 计数值为 1
        ;;
        mov DWORD [fs: SDA.ApInitDoneCount], 1

        ;;
        ;; 等待 AP 完成 stage1 工作:
        ;; 检查处理器计数 ProcessorCount 是否等于 LocalProcessorCount 值
        ;; 1)是, 所有 AP 完成 stage1 工作
        ;; 2)否, 在等待
        ;;
wait_for_ap_stage1_done.@0:        
        xor eax, eax
        lock xadd [fs: SDA.ApInitDoneCount], eax
        cmp eax, CPU_COUNT_MAX
        jae wait_for_ap_stage1_done.ok
        cmp eax, [gs: PCB.LogicalProcessorCount]
        jae wait_for_ap_stage1_done.ok
        pause
        jmp wait_for_ap_stage1_done.@0
         
wait_for_ap_stage1_done.ok:
        ;;
        ;;  AP 处于 stage1 状态
        ;;
        mov DWORD [fs: SDA.ApStage], 1
        pop edx
        pop ebx
        ret
        



