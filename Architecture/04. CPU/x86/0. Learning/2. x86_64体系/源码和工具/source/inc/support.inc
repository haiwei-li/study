; support.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.


;*
;* 定义所有实验代码的支持头文件
;*

%ifndef SUPPORT_INC
%define SUPPORT_INC


%include "..\inc\CPU.inc"
%include "..\inc\lib.inc"
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
        
;*
;* 定义各个工作 segment
;*

; # BOOT_SEG 为 MBR 工作段
; # SETUP_SEG 为加载后的保护模式初始设置段，sector 0 后的扇区将加载到此处
; # LIB16_SEG 是实模式下的库，被加载到 8C00h 内存处
; # LIB32_SEG 是保护模式下的库，被加载到 0F000h 内存处
; # PROTECTED_SEG 是保护模式下的运行代码，被加载到 9000h 内存处
; # LONG_SEG 是 long mode 运行的代码，被加载到 10000h 内存处

BOOT_SEG                equ     7c00h
SETUP_SEG               equ     8000h
LIB16_SEG               equ     8A00h
PROTECTED_SEG           equ     9000h
LIB32_SEG               equ     0F000h
LONG_SEG                equ     10000h

;* 
;* change log: LIB32_SEG 被修改到 0E000h 内存处!
;*
;* change log: LIB32_SEG 被修改到 0F000h 内存处!
;*


;*
;* 定义磁盘映像扇区
;*

; # BOOT_SECTOR 为磁盘的 sector 0
; # SETUP_SECTOR 为磁盘的 sector 1
; # LIB16_SECTOR 为磁盘的 sector 20
; # LONG_SECTOR 在磁盘的 sector 40
; # PROTECTED 模块修改到到 64 扇区
; # LONG 模块修改到 128 扇区
; # LIB32 模块修改到 192 扇区

BOOT_SECTOR             equ     0
SETUP_SECTOR            equ     1
LIB16_SECTOR            equ     20
LIB32_SECTOR            equ     192
PROTECTED_SECTOR        equ     64
LONG_SECTOR             equ     128

;*
;* change log: 修改了 PROTECTED_SECTOR, LIB32_SECTOR, LONG_SECTOR 的扇区位置
;*

;* 
;* 下面是 merge 合并工具的配置实例
;* 根据上面的磁盘扇区结构写入映像文件
;* 
; # ..\..\common\uboot,0,c.img,63,1     # uboot 写入 c.img 63 号扇区
; # ..\..\common\setup,0,c.img,1,4      # setup 写入 c.img 1 号扇区
; # ..\..\lib\lib16,0,c.img,20,2        # lib16 写入 c.img 20 号扇区
; # ..\..\lib\lib32,0,c.img,192,10      # 1ib32 写入 c.img 192 号扇区
; # protected,0,c.img,64,30             # protected 写入 c.img 64 号扇区
; # long,0,c.img,128,20                 # long 写入 c.img 128 号扇区






;*
;* floppy 参数
;*

; # SPT(sector per track): 每磁道上的 sector 数
; # HPC(head per cylinder): 每个 cylinder 的 head 数

%define SPT             18
%define HPC             2



;*
;* 以下为宏义
;*


;------------------------------------------------
; 宏: LBA_TO_CHS
; 描述:
;       参数 1: 物理 sector 号
;-----------------------------------------------
%macro LBA_TO_CHS 1
        mov ax, %1                      ; paramter
        mov cl, SPT
        div cl                          ; al = LBA / SPT, ah = LBA % SPT        
; cylinder = LBA / SPT / HPC
        mov ch, al
        shr ch, (HPC / 2)               ; ch = cylinder                
; head = (LBA / SPT ) % HPC
        mov dh, al
        and dh, 1                       ; dh = head
; sector = LBA % SPT + 1
        mov cl, ah
        inc cl                          ; cl = sector
%endmacro



%endif