;****************************************************************
;* support.inc                                                  *
;* Copyright (c) 2009-2013 邓志                                 *
;* All rights reserved.                                         *
;****************************************************************



;;
;; 包含所有代码所需要的头文件
;;


%ifndef _SUPPORT_INC
%define _SUPPORT_INC


%include "..\inc\CPU.inc"
%include "..\inc\clib.inc"
%include "..\inc\ports.inc"
%include "..\inc\pci.inc"
%include "..\inc\debug.inc"
%include "..\inc\apic.inc"
%include "..\inc\float.inc"        
%include "..\inc\task.inc"
%include "..\inc\sse.inc"
%include "..\inc\perfmon.inc"
%include "..\inc\page.inc"
%include "..\inc\ioapic.inc"
%include "..\inc\keycode.inc"
%include "..\inc\hpet.inc"
%include "..\inc\vmx.inc"
%include "..\inc\VmxExit.inc"
%include "..\inc\vmcs.inc"
%include "..\inc\VmxVmm.inc"
%include "..\inc\VmxLib.inc"
%include "..\inc\ErrorCode.inc"
%include "..\inc\ScanCode.inc"
%include "..\inc\system_manage_region.inc"
%include "..\inc\LibDef.inc"
%include "..\inc\services.inc"
%include "..\inc\DebugRecord.inc"
%include "..\inc\VmxPage.inc"
%include "..\inc\Decode\Opcode.inc"
%include "..\inc\loader_block.inc"



;; #
;; # 定义各个模块的内存段
;; #
BOOT_SEGMENT            EQU     7C00h                   ;; boot 模块加载到 7C00h
SETUP_SEGMENT           EQU     8000h                   ;; setup 模块加载到 8000h
PROTECTED_SEGMENT       EQU     20000h                  ;; protected 模块加载到 20000h
LONG_SEGMENT            EQU     20000h                  ;; long 模块加载到 20000h 
GUEST_BOOT_SEGMENT      EQU     10000h                  ;; guest 的 boot 模块加载到 10000h
GUEST_KERNEL_SEGMENT    EQU     11000h                  ;; guest 的 kernel 模块加载到 11000h




;; #
;; # 定义各个模块的映像内的位置
;; #
BOOT_SECTOR             EQU     0                       ;; boot 模块在 0 号扇区
SETUP_SECTOR            EQU     1                       ;; setup 模块在 1 号扇区
PROTECTED_SECTOR        EQU     64                      ;; protected 模块在 64 号扇区
LONG_SECTOR             EQU     256                     ;; long 模块在 256 号扇区
GUEST_BOOT_SECTOR       EQU     512                     ;; guest boot 模块在 512 号扇区
GUEST_KERNEL_SECTOR     EQU     520                     ;; guest kernel 模块在 520 号扇区



;; # 
;; # 下面是 merge 合并工具的配置示例
;; # 根据上面的磁盘扇区结构写入映像文件(c.img)
;; 
;; # ..\..\common\boot,0,c.img,63,1                     ## boot 写入 c.img 文件 63 号扇区
;; # ..\..\common\setup,0,c.img,1,60                    ## setup 写入 c.img 文件 1 号扇区
;; # ..\..\common\long,0,c.img,256,120                  ## long 写入 c.img 文件 256 号扇区
;; # ..\..\lib\Guest\GuestBoot,0,c.img,512,2            ## GuestBoot 写入 c.img 文件 512 号扇区
;; # ..\..\lib\Guest\GuestKernel,0,c.img,520,20         ## GuestKerenl 写入 c.img 文件 520 号扇区


%endif
