;************************************************
;* vmcs.inc                                     *
;* Copyright (c) 2009-2013 邓志                 *
;* All rights reserved.                         *
;************************************************

%ifndef _VMCS_INC
%define _VMCS_INC


%define GUEST_FLAG_PE                           1
%define GUEST_FLAG_PG                           80000000h
%define GUEST_FLAG_IA32E                        4
%define GUEST_FLAG_V8086                        8
%define GUEST_FLAG_UNRESTRICTED                 10h
%define GUEST_FLAG_EPT                          20h
%define GUEST_FLAG_USER                         40h


;;
;; ####### VMB(VM Manage Block)结构 #######
;;

struc VMB
        .PhysicalBase           RESQ    1               ; VMCS region 物理地址
        .Base                   RESQ    1               ; VMCS region 虚拟地址
        .VsbBase                RESQ    1               ; VSB 基址
        .VsbPhysicalBase        RESQ    1               ; VSB 物理基址
        .DomainBase             RESQ    1               ; domain 虚拟基址
        .DomainPhysicalBase     RESQ    1               ; domain 物理基址
        .DomainPhysicalTop      RESQ    1               ; domain 物理地址顶部

        ;;
        ;; Guest 状态
        ;;
        .GuestStatus            RESD    1


        ALIGNB 8

        ;;
        ;; guest 环境入口点
        ;;
        .GuestEntry             RESQ    1
        .GuestStack             RESQ    1               ; guest 使用的栈

        ;;
        ;; VMM 入口
        ;;
        .HostEntry              RESQ    1
        .HostStack              RESQ    1

        ;;
        ;; 每个 VM 的 EP4TA
        ;;
        .Ep4taBase              RESQ    1               ; 指向 EPT PML4T 虚拟地址
        .Ep4taPhysicalBase      RESQ    1               ; 指向 EPT PML4T 物理地址

        
        ;;
        ;; 每个 VM 有自己的 VMX-preemption timer value 值
        ;;
        .VmxTimerValue          RESD    1

        ;;
        ;; 每个 logical processor 的每个VMCS的 VPID
        ;;
        .Vpid                   RESW    1
        



        ALIGNB 4
        .GuestFlags             RESD    1

        ;;
        ;; 某些情况下, 传给 VMM do_xxx函数的参数！
        ;;
        .DoProcessParam         RESD    1
        .VmmDumpVmcsMask        RESQ    1

        ;;
        ;; APIC-access address
        ;;
        .ApicAccessAddress      RESQ    1
        .ApicAccessPhyAddress   RESQ    1

        ;;
        ;; #### 下面的区域需要在初始化时分配页面 ####
        ;; 1) IoBitmap A page
        ;; 2) IoBitmap B page
        ;; 3) Virtual-access page
        ;; 4) MSR-Bitmap page
        ;; 5) VM-entry/VM-exit MSR store page
        ;; 6) VM-exit MSR load page
        ;; 7) IoVteBuffer page
        ;; 8) MsrVteBuffer page
        ;; 9) GpaHteBuffer page
        ;;

        ;;
        ;; I/O-Bitmap Address A & B
        ;;        
        .IoBitmapAddressA       RESQ    1
        .IoBitmapPhyAddressA    RESQ    1
        .IoBitmapAddressB       RESQ    1
        .IoBitmapPhyAddressB    RESQ    1

        ;;
        ;; Virtual-APIC address
        ;;
        .VirtualApicAddress     RESQ    1
        .VirtualApicPhyAddress  RESQ    1

        ;;
        ;; MSR-Bitmap Address
        ;;
        .MsrBitmapAddress       RESQ    1
        .MsrBitmapPhyAddress    RESQ    1


        ;;
        ;; VM-exit MSR-store Address
        ;; 
        .VmEntryMsrLoadAddress:       
        .VmExitMsrStoreAddress          RESQ    1
        .VmEntryMsrLoadPhyAddress:
        .VmExitMsrStorePhyAddress       RESQ    1

        ;;
        ;; VM-exit MSR-load Address
        ;;        
        .VmExitMsrLoadAddress           RESQ    1
        .VmExitMsrLoadPhyAddress        RESQ    1

        ;;
        ;; IO 值列表 buffer, 用来记录 guest 向 IO 端写入的值 
        ;;
        .IoVteBuffer                    RESQ    1
        .IoVteBufferPhyAddr             RESQ    1

        ;;
        ;; MSR 值列表 buffer, 用来记录 guest 向 MSR 写的值
        ;;
        .MsrVteBuffer                   RESQ    1
        .MsrVteBufferPhyAddr            RESQ    1

        ;;
        ;; EPT page-fault 处理例程表 buffer, 用来记录 GPA 的特殊处理
        ;;
        .GpaHteBuffer                   RESQ    1
        .GpaHteBufferPhyAddr            RESQ    1


        ;;
        ;; IO & MSR VTE 管理记录
        ;;
        .IoVteCount                     RESD    1
        .MsrVteCount                    RESD    1
        .GpaHteCount                    RESD    1
        .IoVteIndex                     RESQ    1
        .MsrVteIndex                    RESQ    1
        .GpaHteIndex                    RESQ    1


        .VmEntryMsrLoadCount:
        .VmExitMsrStoreCount            RESD    1
        .VmExitMsrLoadCount             RESD    1


        ;;
        ;; IO 操作标志位
        ;;
        .IoOperationFlags               RESD    1


        ;;
        ;; guest-GDT 管理块
        ;;       
        .GuestGmb                       RESB    GGMB_SIZE

        
        ALIGNB 4
        ;;
        ;;guest-IDT 管理块
        ;;
        .GuestImb                       RESB    GIMB_SIZE

        ;;
        ;; guest-TSS 管理块
        ;;
        .GuestTmb                       RESB    GTMB_SIZE


        ;;
        ;; guest-status 管理块
        ;; 
        .GuestSmb                       RESB    GSMB_SIZE


        ALIGNB 8
        ;;
        ;; EPTP list address
        ;;
        .EptpListAddress                RESQ    1


        ALIGNB 64
        ;;
        ;; posted-interrupt descriptor
        ;;
        PostedInterruptDesc             RESB    64


        VMB_SIZE                        EQU     $
        VMCS_MANAGE_BLOCK_SIZE          EQU     $
endstruc

%define IOP_FLAGS_8259_MASTER_INIT              1
%define IOP_FLAGS_8259_SLAVE_INIT               (1 << 1)


;;
;; VSB(VM Storage Block, 虚拟机存储块)
;;
struc VSB
        .Base                   RESQ            1
        .PhysicalBase           RESQ            1

        ;;
        ;; VM video buffer 管理记录
        ;;
        .VmVideoBufferHead      RESQ            1
        .VmVideoBufferPtr       RESQ            1
        .VmVideoBufferLastChar  RESD            1
        .VmVideoBufferSize      RESD            1
        
        ;;
        ;; VM keyboard buffer 管理记录
        ;;        
        ALIGNB 8
        .VmKeyBufferHead        RESQ            1
        .VmKeyBufferPtr         RESQ            1
        .VmKeyBufferSize        RESD            1
        

        ;;
        ;; guest 的 context 信息
        ;;
        .Context:
        .Rax                    RESQ            1
        .Rcx                    RESQ            1
        .Rdx                    RESQ            1
        .Rbx                    RESQ            1
        .Rsp                    RESQ            1
        .Rbp                    RESQ            1
        .Rsi                    RESQ            1
        .Rdi                    RESQ            1
        .R8                     RESQ            1
        .R9                     RESQ            1
        .R10                    RESQ            1
        .R11                    RESQ            1
        .R12                    RESQ            1
        .R13                    RESQ            1
        .R14                    RESQ            1
        .R15                    RESQ            1        
        .Rip                    RESQ            1
        .Rflags                 RESQ            1 

        ;;
        ;; FPU 单元 context
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
        ;; VM keyboard buffer 区域, 共 256 个字节, 保存按键扫描码
        ;;
        .VmKeyBuffer            RESB            256
        .Reserve                RESB            4096 - $


        ;;
        ;; VM video buffer 区域, 存放处理器的屏幕信息
        ;; 4K, 存放约 25 * 80 * 2 信息
        ;;
        .VmVideoBuffer          RESB            (4096 * 2 - $)

        

        VM_STORAGE_BLOCK_SIZE           EQU     $
        VSB_SIZE                        EQU     $        
endstruc


;;
;; I/O 值列表项结构
;;
struc IO_VTE
        .IoPort                         RESD    1
        .Value                          RESD    1

        IO_VTE_SIZE                     EQU     $
endstruc


;;
;; MSR 值列表项结构
;;
struc MSR_VTE
        .MsrIndex                       RESD    1
        .Value                          RESQ    1

        MSR_VTE_SIZE                    EQU     $
endstruc


;;
;; GPA handle table entry 结构
;;
struc GPA_HTE
        .GuestPhysicalAddress           RESQ    1
        .Handler                        RESQ    1

        GPA_HTE_SIZE                    EQU     $
endstruc


;;
;; 外部中断 route tabel entry
;;
struc EXTINT_RTE
        .ProcessorIndex                 RESD    1
        .Vector                         RESD    1
        .Flags                          RESD    1

        EXTINT_RTE_SIZE                 EQU     $
endstruc

%define RTE_8259_IRQ0                   1
%define RTE_8259_IRQ1                   (1 << 1)



;;
;; guest-IDT manage block
;;
struc GIMB
        .IdtPointer:
        .IdtLimit                       RESW    1
        .IdtBase                        RESQ    1

        .HookIdtLimit                   RESW    1
        .GpFlags                        RESD    1

        GIMB_SIZE                       EQU     $
endstruc


;;
;; guest-GDT manage block
;;
struc GGMB
        .GdtPointer:
        .GdtLimit                       RESW    1
        .GdtBase                        RESQ    1

        GGMB_SIZE                       EQU     $
endstruc


;;
;; guest-LDT manage block
;;
struc GLMB
        .LdtPointer:
        .LdtLimit                       RESW    1
        .LdtBase                        RESQ    1

        GLMB_SIZE                       EQU     $
endstruc


;;
;; guest-TSS manage block
;;
struc GTMB
        .TssSelector                    RESW    1
        .TssLimit                       RESD    1
        .TssAccessRights                RESD    1

        ALIGNB 8
        .TssBase                        RESQ    1


        GTMB_SIZE                       EQU     $
endstruc


;;
;; guest-status manage block
;;
struc GSMB
        .ProcessorStatus                RESD    1
        .InstructionStatus              RESD    1
        
        GSMB_SIZE                       EQU     $
endstruc





;;
;; posted-interrupt 描述符结构
;;
struc PI_DESC
        .Pir                            RESB    16
        .On:
        .Reserved                       RESB    16
endstruc



;;
;; ####### guest state area ############
;;

struc GUEST_STATE
        ;;
        ;; ***** guest register state *******
        ;;
        .Cr0                            RESQ            1
        .Cr3                            RESQ            1
        .Cr4                            RESQ            1
        .Dr7                            RESQ            1
        .Rsp                            RESQ            1
        .Rip                            RESQ            1
        .Rflags                         RESQ            1

        ;;
        ;; 16 位 selector 值(CS, SS, DS, ES, FS, GS, LDTR 和 TR)
        ;;
        .CsSelector                     RESW            1
        .SsSelector                     RESW            1
        .DsSelector                     RESW            1
        .EsSelector                     RESW            1
        .FsSelector                     RESW            1
        .GsSelector                     RESW            1
        .LdtrSelector                   RESW            1
        .TrSelector                     RESW            1
        
        ;;
        ;; base 值(64 位值)
        ;;
        .CsBase                         RESQ            1
        .SsBase                         RESQ            1
        .DsBase                         RESQ            1
        .EsBase                         RESQ            1
        .FsBase                         RESQ            1
        .GsBase                         RESQ            1
        .LdtrBase                       RESQ            1
        .TrBase                         RESQ            1

        ;;
        ;; 32 位 Segment limit
        ;;
        .CsLimit                        RESD            1
        .SsLimit                        RESD            1
        .DsLimit                        RESD            1
        .EsLimit                        RESD            1
        .FsLimit                        RESD            1
        .GsLimit                        RESD            1
        .LdtrLimit                      RESD            1
        .TrLimit                        RESD            1

        ;;
        ;; 32 位 Access right
        ;;
        .CsAccessRight                  RESD            1
        .SsAccessRight                  RESD            1
        .DsAccessRight                  RESD            1
        .EsAccessRight                  RESD            1
        .FsAccessRight                  RESD            1
        .GsAccessRight                  RESD            1
        .LdtrAccessRight                RESD            1
        .TrAccessRight                  RESD            1

        ;;
        ;; GDTR/IDTR base(64位) 和 limit(32位)
        ;;
        .GdtrBase                       RESQ            1
        .IdtrBase                       RESQ            1
        .GdtrLimit                      RESD            1
        .IdtrLimit                      RESD            1


        ;;
        ;; 64 位 MSR
        ;; 
        .DebugCtlMsr                    RESQ            1
        .SysenterCsMsr                  RESQ            1
        .SysenterEspMsr                 RESQ            1
        .SysenterEipMsr                 RESQ            1
        .PerfGlobalCtlMsr               RESQ            1
        .PatMsr                         RESQ            1
        .EferMsr                        RESQ            1

        ;;
        ;; SMBASE 寄存器
        ;;
        .SmBase                         RESQ            1


        ;;
        ;; ******* guest non-register state *******
        ;;
        .ActivityState                  RESD            1
        .InterruptibilityState          RESD            1
        .PendingDebugException          RESQ            1
        .VmcsLinkPointer                RESQ            1
        .VmxPreemptionTimerValue        RESD            1
        .Pdpte0                         RESQ            1
        .Pdpte1                         RESQ            1
        .Pdpte2                         RESQ            1
        .Pdpte3                         RESQ            1

        ;;
        ;; guest interrupt status
        ;;
        .GuestInterruptStatus:
        .Rvi                            RESB            1
        .Svi                            RESB            1


        GUEST_STATE_SIZE                EQU             $
endstruc




;;
;; ####### host state area ############
;;

struc HOST_STATE
        ;;
        ;; 64 位 control registers
        ;;
        .Cr0                            RESQ            1
        .Cr3                            RESQ            1
        .Cr4                            RESQ            1
        .Rsp                            RESQ            1
        .Rip                            RESQ            1

        ;;
        ;; 16 位 selector 值(CS, SS, DS, ES, FS, GS 和 TR)
        ;;
        .CsSelector                     RESW            1
        .SsSelector                     RESW            1
        .DsSelector                     RESW            1
        .EsSelector                     RESW            1
        .FsSelector                     RESW            1
        .GsSelector                     RESW            1
        .TrSelector                     RESW            1
        
        ;;
        ;; 64 位 base 值(FS, GS 和 TR)
        ;;
        .FsBase                         RESQ            1
        .GsBase                         RESQ            1
        .TrBase                         RESQ            1


        ;;
        ;; GDTR/IDTR base(64位)
        ;;
        .GdtrBase                       RESQ            1
        .IdtrBase                       RESQ            1


        ;;
        ;; 64 位 MSR
        ;; 
        .SysenterCsMsr                  RESQ            1
        .SysenterEspMsr                 RESQ            1
        .SysenterEipMsr                 RESQ            1
        .PerfGlobalCtlMsr               RESQ            1
        .PatMsr                         RESQ            1
        .EferMsr                        RESQ            1


        HOST_STATE_SIZE                 EQU             $
endstruc



;;
;; ####### VM-execution control fields ############
;;

struc EXECUTION_CONTROL
        .PinControl                     RESD            1
        .ProcessorControl1              RESD            1
        .ProcessorControl2              RESD            1
        .ExceptionBitmap                RESD            1
        .PfErrorCodeMask                RESD            1
        .PfErrorCodeMatch               RESD            1
        .IoBitmapAddressA               RESQ            1
        .IoBitmapAddressB               RESQ            1
        .TscOffset                      RESQ            1
        .Cr0GuestHostMask               RESQ            1
        .Cr0ReadShadow                  RESQ            1
        .Cr4GuestHostMask               RESQ            1
        .Cr4ReadShadow                  RESQ            1        
        .Cr3TargetCount                 RESD            1
        .Cr3Target0                     RESQ            1
        .Cr3Target1                     RESQ            1
        .Cr3Target2                     RESQ            1
        .Cr3Target3                     RESQ            1
        
        ;;
        ;; APIC virtualization 有关域
        ;;
        .ApicAccessAddress              RESQ            1
        .VirtualApicAddress             RESQ            1
        .TprThreshold                   RESD            1
        .EoiBitmap0                     RESQ            1
        .EoiBitmap1                     RESQ            1
        .EoiBitmap2                     RESQ            1
        .EoiBitmap3                     RESQ            1
        .PostedInterruptVector          RESW            1
        ALIGNB 4
        .PostedInterruptDescriptorAddr  RESQ            1

        .MsrBitmapAddress               RESQ            1
        .ExecutiveVmcsPointer           RESQ            1
        .EptPointer                     RESQ            1
        .Vpid                           RESW            1

        ALIGNB 4
        .PleGap                         RESD            1
        .PleWindow                      RESD            1

        ALIGNB 4
        .VmFunctionControl              RESQ            1
        .EptpListAddress                RESQ            1

        
        EXECUTION_CONTROL_SIZE          EQU             $
endstruc


;;
;; ####### VM-exit control fields ############
;;
struc EXIT_CONTROL
        .VmExitControl                  RESD            1
        .MsrStoreCount                  RESD            1
        .MsrStoreAddress                RESQ            1
        .MsrLoadCount                   RESD            1
        .MsrLoadAddress                 RESQ            1

        EXIT_CONTROL_SIZE               EQU             $
endstruc


;;
;; ####### VM-entry control fields ############
;;
struc ENTRY_CONTROL
        .VmEntryControl                 RESD            1
        .MsrLoadCount                   RESD            1
        .MsrLoadAddress                 RESQ            1
        .InterruptionInfo               RESD            1
        .ExceptionErrorCode             RESD            1
        .InstructionLength              RESD            1
        
        ;;
        ;; vmware 上的一个 bug:
        ;; 1) VM-entry instruction length 是32位字段
        ;; 2) 在 vmware 上却读写 64 位!
        ;; 3) 这里额外保留一个 dword 值
        ;;  
                                        RESD            1

        ENTRY_CONTROL_SIZE              EQU             $
endstruc



;;
;; ####### VM-exit information fields ############
;;
struc EXIT_INFO
        ;;
        ;; 基本信息
        ;;
        .ExitReason                     RESD            1
        .ExitQualification              RESQ            1
        .GuestLinearAddress             RESQ            1
        .GuestPhysicalAddress           RESQ            1

        ;;
        ;; 由 event 引发 VM exit 的信息
        ;;
        .InterruptionInfo               RESD            1
        .InterruptionErrorCode          RESD            1        

        ;;
        ;; 在 event delivery 期间引发 VM exit 的信息
        ;;
        .IdtVectoringInfo               RESD            1
        .IdtVectoringErrorCode          RESD            1

        ;;
        ;; 由指令执行而引发 VM exit 的信息
        ;;
        .InstructionLength              RESD            1  
        .InstructionInfo                RESD            1

        .IoRcx                          RESQ            1
        .IoRsi                          RESQ            1
        .IoRdi                          RESQ            1
        .IoRip                          RESQ            1

        ;;
        ;; VMX 指令错误信息
        ;;
        .InstructionError               RESD            1


        EXIT_INFO_SIZE                  EQU             $
endstruc







;-------------------------------------------------------
; SET_PINBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)置 Pinbased VM-execution control 位
;-------------------------------------------------------
%macro SET_PINBASED_CTLS 1
        GetVmcsField    CONTROL_PINBASED
        or eax, %1

%if __BITS__ == 64
        or eax, [gs: PCB.PinBasedCtls]
        and eax, [gs: PCB.PinBasedCtls + 4]
%else
        mov esi, PCB.PinBasedCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]  
%endif
        SetVmcsField    CONTROL_PINBASED, eax
%endmacro



;-------------------------------------------------------
; CLEAR_PINBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)清 Pinbased VM-execution control 位
;-------------------------------------------------------
%macro CLEAR_PINBASED_CTLS 1
        GetVmcsField    CONTROL_PINBASED
        and eax, ~%1

%if __BITS__ == 64
        or eax, [gs: PCB.PinBasedCtls]
        and eax, [gs: PCB.PinBasedCtls + 4]
%else
        mov esi, PCB.PinBasedCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    CONTROL_PINBASED, eax
%endmacro



;-------------------------------------------------------
; SET_PRIMARAY_PROCBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)置 primary processor-based VM-execution control 位
;-------------------------------------------------------
%macro SET_PRIMARY_PROCBASED_CTLS 1
        GetVmcsField    CONTROL_PROCBASED_PRIMARY
        or eax, %1

%if __BITS__ == 64
        or eax, [gs: PCB.ProcessorBasedCtls]
        and eax, [gs: PCB.ProcessorBasedCtls + 4]
%else
        mov esi, PCB.ProcessorBasedCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    CONTROL_PROCBASED_PRIMARY, eax
%endmacro



;-------------------------------------------------------
; CLEAR_PRIMARY_PROCBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)清 primary processor-based VM-execution control 位
;-------------------------------------------------------
%macro CLEAR_PRIMARY_PROCBASED_CTLS 1
        GetVmcsField    CONTROL_PROCBASED_PRIMARY
        and eax, ~%1

%if __BITS__ == 64
        or eax, [gs: PCB.ProcessorBasedCtls]
        and eax, [gs: PCB.ProcessorBasedCtls + 4]
%else
        mov esi, PCB.ProcessorBasedCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    CONTROL_PROCBASED_PRIMARY, eax
%endmacro



;-------------------------------------------------------
; SET_SECONDARY_PROCBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)置 secondary processor-based VM-execution control 位
;-------------------------------------------------------
%macro SET_SECONDARY_PROCBASED_CTLS 1
        GetVmcsField    CONTROL_PROCBASED_SECONDARY
        or eax, %1

%if __BITS__ == 64
        or eax, [gs: PCB.ProcessorBasedCtls2]
        and eax, [gs: PCB.ProcessorBasedCtls2 + 4]
%else
        mov esi, PCB.ProcessorBasedCtls2
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    CONTROL_PROCBASED_SECONDARY, eax
%endmacro


;-------------------------------------------------------
; CLEAR_SECONDARY_PROCBASED_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)清 secondary processor-based VM-execution control 位
;-------------------------------------------------------
%macro CLEAR_SECONDARY_PROCBASED_CTLS 1
        GetVmcsField    CONTROL_PROCBASED_SECONDARY
        and eax, ~%1

%if __BITS__ == 64
        or eax, [gs: PCB.ProcessorBasedCtls2]
        and eax, [gs: PCB.ProcessorBasedCtls2 + 4]
%else
        mov esi, PCB.ProcessorBasedCtls2
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    CONTROL_PROCBASED_SECONDARY, eax
%endmacro


;-------------------------------------------------------
; SET_VM_EXIT_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)置 VM-exit control 位
;-------------------------------------------------------
%macro SET_VM_EXIT_CTLS 1
        GetVmcsField    VMEXIT_CONTROL
        or eax, %1

%if __BITS__ == 64
        or eax, [gs: PCB.ExitCtls]
        and eax, [gs: PCB.ExitCtls + 4]
%else
        mov esi, PCB.ExitCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    VMEXIT_CONTROL, eax
%endmacro


;-------------------------------------------------------
; CLEAR_VM_EXIT_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)清 VM-exit control 位
;-------------------------------------------------------
%macro CLEAR_VM_EXIT_CTLS 1
        GetVmcsField    VMEXIT_CONTROL
        and eax, ~%1

%if __BITS__ == 64
        or eax, [gs: PCB.ExitCtls]
        and eax, [gs: PCB.ExitCtls + 4]
%else
        mov esi, PCB.ExitCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    VMEXIT_CONTROL, eax
%endmacro


;-------------------------------------------------------
; SET_VM_ENTRY_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)置 VM-entry control 位
;-------------------------------------------------------
%macro SET_VM_ENTRY_CTLS 1
        GetVmcsField    VMENTRY_CONTROL
        or eax, %1

%if __BITS__ == 64
        or eax, [gs: PCB.EntryCtls]
        and eax, [gs: PCB.EntryCtls + 4]
%else
        mov esi, PCB.EntryCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]        
%endif

        SetVmcsField    VMENTRY_CONTROL, eax
%endmacro


;-------------------------------------------------------
; CLEAR_VM_ENTRY_CTLS
; input:
;       %1 - control bit
; 描述:
;       1)清 VM-entry control 位
;-------------------------------------------------------
%macro CLEAR_VM_ENTRY_CTLS 1
        GetVmcsField    VMENTRY_CONTROL
        and eax, ~%1

%if __BITS__ == 64
        or eax, [gs: PCB.EntryCtls]
        and eax, [gs: PCB.EntryCtls + 4]
%else
        mov esi, PCB.EntryCtls
        or eax, [gs: esi]
        and eax, [gs: esi + 4]
%endif
        SetVmcsField    VMENTRY_CONTROL, eax
%endmacro




;-------------------------------------------------------
; SET_EXCEPTION_BITMAP
; input:
;       %1 - vector
; 描述: 
;       1) 设置 Exception Bitmap 位
;-------------------------------------------------------
%macro SET_EXCEPTION_BITMAP 1
        GetVmcsField    CONTROL_EXCEPTION_BITMAP
        or eax, (1 << %1)
        SetVmcsField    CONTROL_EXCEPTION_BITMAP, eax
%endmacro


;-------------------------------------------------------
; CLEAR_EXCEPTION_BITMAP
; input:
;       %1 - vector
; 描述: 
;       1) 清 Exception Bitmap 位
;-------------------------------------------------------
%macro CLEAR_EXCEPTION_BITMAP 1
        GetVmcsField    CONTROL_EXCEPTION_BITMAP
        and eax, ~(1 << %1)
        SetVmcsField    CONTROL_EXCEPTION_BITMAP, eax
%endmacro



;-------------------------------------------------------
; MAKE_SEGMENT_UNUSABLE
; input:
;       %1 - vector
; 描述: 
;       1) 清 Exception Bitmap 位
;-------------------------------------------------------
%macro MAKE_SEGMENT_UNUSABLE    1
        GetVmcsField    %1
        or eax, SEG_U
        SetVmcsField    %1, eax     
%endmacro


%endif