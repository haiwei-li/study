;*************************************************
; page.inc                                       *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************



%ifndef _PAGE_INC
%define _PAGE_INC






;; 定义 table entry 及属性位

%define P                                       1
%define RW                                      2
%define US                                      4
%define PWT                                     8
%define PCD                                     10h
%define A                                       20h
%define D                                       40h
%define PS                                      80h
%define PAT                                     80h
%define G                                       100h
;;;%define PAT                                     1000h
%define XD                                      80000000h
%define PHY_ADDR                                40000000h
%define FORCE                                   20000000h        
%define INGORE                                  10000000h
%define GET_PHY_PAGE_FRAME                      08000000h

%define PAGE_P                                  1
%define PAGE_READ                               0
%define PAGE_WRITE                              2
%define PAGE_USER                               4
%define PAGE_SYSTEM                             0
%define PAGE_PWT                                8
%define PAGE_PCD                                10h
%define PAGE_ACCESS                             20h
%define PAGE_DIRTY                              40h
%define PAGE_PS                                 80h
%define PAGE_2M                                 80h
%define PAGE_PAT                                80h
%define PAGE_GLOBAL                             100h
;;%define PAGE_PAT                                1000h
%define PAGE_XD                                 80000000h
%define PHY_ADDR                                40000000h
%define MAP_FORCE                               20000000h        
%define MAP_INGORE                              10000000h
%define MAP_GET_PAGE_FRAME                      08000000h
%define PAGE_VALID                              800h


%define MAPPING_SUCCESS                         0
%define MAPPING_VALID                           0
%define MAPPING_USED                            80000000h
%define MAPPING_UNSUCCESS                       80000001h
%define MAPPING_ATTRIBUTE_MISMATCH              40000000h
%define MAPPING_PAGE_FRAME_MISMATCH             40000001h
%define MAPPING_PDT_ADDRESS_MISMATCH            40000002h
%define MAPPING_PT_ADDRESS_MISMATCH             40000004h
%define MAPPING_PS_MISMATCH                     40000008h
%define MAPPING_RW_MISMATCH                     40000010h
%define MAPPING_US_MISMATCH                     40000020h
%define MAPPING_XD_MISMATCH                     40000040h
%define MAPPING_ADDRESS_INVALID                 20000000h
%define MAPPING_NO_RESOURCE                     STATUS_NO_RESOURCE

%define MAPPING_FIXED_FAILURE                   10000001h


%define UNMAPPED_SUCCESS                        0
%define UNMAPPING_ADDRESS_INVALID               20000000h

%define UNMAP_FLAG_CLEAN			1





;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$      legacy 32-bit 环境下的系统参数          $$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


%define SYSTEM_DATA_AREA                        80000000h
%define USER_STACK_BASE                         7FE00000h
%define KERNEL_STACK_BASE                       0FFE00000h
%define SYSTEM_DATA_PHYSICAL_AREA               100000h
%define USER_STACK_PHYSICAL_BASE                1010000h
%define KERNEL_STACK_PHYSICAL_BASE              1040000h
%define USER_STACK_SIZE                         30000h
%define KERNEL_STACK_SIZE                       20000h

%define KERNEL_POOL_BASE                        83200000h
%define KERNEL_POOL_PHYSICAL_BASE               03200000h
%define USER_POOL_BASE                          73001000h
%define USER_POOL_PHYSICAL_BASE                 03001000h
%define KERNEL_POOL_SIZE                        4E00000h
%define USER_POOL_SIZE                          1FF000h


;;
;; 说明:
;; 1) PT_BASE  = c000_0000h
;; 2) PT_TOP   = PT_BASE + (4 * 512 * 512 * 8) - 1
;; 3) PDT_BASE = (PT_BASE >> 12 * 8) + PT_BASE = c060_0000h
;; 4) PDT_TOP  = (PT_TOP  >> 12 * 8) + PT_BASE = c060_3fffh
;; 5) PPT_BASE = (PDT_BASE >> 12 * 8) + PT_BASE = c060_3000h
;; 6) PPT_TOP  = (PDT_TOP >> 12 * 8) + PT_BASE = c060_301Fh
;;

PT_BASE                 EQU             0C0000000h
PT_TOP                  EQU             0C07FFFFFh
PDT_BASE                EQU             0C0600000h
PDT_TOP                 EQU             0C0603FFFh
PPT_BASE                EQU             0C0603000h
PPT_TOP                 EQU             0C060301Fh

PDT0_BASE               EQU             PDT_BASE
PDT1_BASE               EQU             (PDT_BASE + 1000h)
PDT2_BASE               EQU             (PDT_BASE + 2000h)
PDT3_BASE               EQU             (PDT_BASE + 3000h)


;;
;; 定义 PAE 模式下 PT 和 PDT 的物理地址
;; 1) PT_PHYSICAL_BASE  = 20_0000h
;; 2) PDT_PHYSICAL_BASE = PT_PHYSICAL_BASE + (PDT_BASE - PT_BASE) = 20_0000h + 60_0000h = 80_0000h                                                                                                                                                                                              
;; 3) PPT 表在 SDA 区域内

PT_PHYSICAL_BASE        EQU             200000h
PDT_PHYSICAL_BASE       EQU             800000h
PPT_PHYSICAL_BASE       EQU             803000h

PDT0_PHYSICAL_BASE	EQU		800000h
PDT1_PHYSICAL_BASE	EQU		801000h
PDT2_PHYSICAL_BASE	EQU		802000h
PDT3_PHYSICAL_BASE	EQU		803000h






;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
;$      longmode 64-bit 环境下的系统参数        $$
;$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$


%define SYSTEM_DATA_AREA64                      0FFFFF80000000000h
%define USER_STACK_BASE64                       7FE00000h
%define KERNEL_STACK_BASE64                     0FFFFFF80FFE00000h
%define SYSTEM_DATA_PHYSICAL_AREA64             100000h
%define USER_STACK_PHYSICAL_BASE64              1010000h
%define KERNEL_STACK_PHYSICAL_BASE64            1040000h

%define KERNEL_POOL_BASE64                      0FFFFF80083200000h
%define KERNEL_POOL_PHYSICAL_BASE64             03200000h
%define USER_POOL_BASE64                        73001000h
%define USER_POOL_PHYSICAL_BASE64               03001000h


%define KERNEL_CODE_BASE64                      0FFFFFF8040000000h
%define USER_CODE_BASE64                        004000000h


%ifdef __X64
%define SYSTEM_DATA_SPACE_BASE                  0FFFFF80080000000h
%else
%define SYSTEM_DATA_SPACE_BASE                  80000000h
%endif

%define SYSTEM_DATA_SPACE_BASE32                80000000h

;; 
;; 一. 区域说明：
;; 1) 页转换表结构将映射到最高端地址区域
;; 2) 页转换表结构虚拟地址区域从 ffff_f680_0000_0000 到 ffff_f6ff_ffff_ffff 共 512G 空间
;; 3) PXT_BASE64 = ffff_f6fb_7dbe_d000，是 PML4T表（Page Map Level 4 Table）的基址
;; 4) PPT_BASE64 = ffff_f6fb_7da0_0000，是 PDPT表（Page Directory Pointer Table）的基址
;; 5) PDT_BASE64 = ffff_f6fb_4000_0000，是 PDT表（Page Directory Table）的基址
;; 6) PT_BASE64  = ffff_f680_0000_0000，是 PT表（Page Table）的基址
;;

;;
;; 二. PXT 映射说明：
;; 1) PXT 表区域共 4K，从 ffff_f6fb_7dbe_d000 到 ffff_f6fb_7dbe_dfff
;; 2) PXT_BASE64 = (PPT_BASE64 >> 12 * 8) + PT_BASE64 = (ffff_f6fb_7da0_0000 >> 12 * 8) + ffff_f680_0000_0000
;; 3) PXT_TOP64  = (PPT_TOP64  >> 12 * 8) + PT_BASE64 = (ffff_f6fb_7dbf_ffff >> 12 * 8) + ffff_f680_0000_0000
;;
;; 因此：PXT 表映射 PPT 表区域！
;;

;;
;; 三. PPT 映射说明：
;; 1) PPT 表区域 2M，从 ffff_f6fb_7da0_0000 到 ffff_f6fb_7dbf_ffff
;; 2) PPT_BASE64 = (PDT_BASE64 >> 12 * 8) + PT_BASE64 = (ffff_f6fb_4000_0000 >> 12 * 8) + ffff_f680_0000_0000
;; 3) PPT_TOP64  = (PDT_BASE64 >> 12 * 8) + PT_BASE64 = (ffff_f6fb_7fff_ffff >> 12 * 8) + ffff_f680_0000_0000
;;
;; 因此：PPT 表映射 PDT 表区域！
;;

;;
;; 四. PDT 映射说明：
;; 1) PDT 表区域共 1G，从 ffff_f6fb_4000_0000 到 ffff_f6fb_7fff_ffff
;; 2) PDT_BASE64 = (PT_BASE64 >> 12 * 8) + PT_BASE64 = (ffff_f680_0000_0000 >> 12 * 8) + ffff_f680_0000_0000
;; 3) PDT_TOP64  = (PT_TOP64  >> 12 * 8) + PT_BASE64 = (ffff_f6ff_ffff_ffff >> 12 * 8) + ffff_f680_0000_0000

;; 因此：PDT 表映射 PT 表区域
;;


;;
;; 五. 自映射说明
;; 1) PT, PDT, PPT 以及 PXT 表区域是重叠在一起的，区域空间大小共 512G
;; 2) PXT 表自己映射自己 4K
;; 3) PPT 表自己映射自己 2M
;;


;;
;; PT 表区域　
;;
PT_BASE64               EQU             0FFFFF68000000000h
PT_TOP64                EQU             0FFFFF6FFFFFFFFFFh

;;
;; PDT 表区域
;;
PDT_BASE64              EQU             0FFFFF6FB40000000h
PDT_TOP64               EQU             0FFFFF6FB7FFFFFFFh

;;
;; PPT 表区域
;;
PPT_BASE64              EQU             0FFFFF6FB7DA00000h
PPT_TOP64               EQU             0FFFFF6FB7DBFFFFFh

;;
;; PXT 表区域
;;
PXT_BASE64              EQU             0FFFFF6FB7DBED000h
PXT_TOP64               EQU             0FFFFF6FB7DBEDFFFh



;;
;; 定义区域 size：
;; 1) PT_SIZE  = 80_0000_0000h（512G）
;; 2) PDT_SIZE = 4000_0000h（1G）
;; 3) PPT_SIZE = 20_0000h（2M）
;; 4) PXT_SIZE = 1000h（4K）
;;
PT_SIZE                 EQU             8000000000h
PDT_SIZE                EQU             40000000h
PPT_SIZE                EQU             200000h
PXT_SIZE                EQU             1000h



;;
;; 页转换表物理地址动态分配说明
;; 1) PDT 和 PT 表按需分配
;; 2) 物理地址从 PT_POOL_PHYSICAL_BASE64 里分配
;; 3) 每次分配  4K 空间
;;


;;
;; PPT 表物理地址：
;; 1) PPT_PHYSICAL_BASE64  = 200_0000h（32M 地址）
;;
;; PXT 表物理地址:
;; 1) PXT_PHYSICAL_BASE64  = PXT_BASE64 - PPT_BASE64 + PPT_PHYSICAL_BASE64 = 21e_d000h
;;

PPT_PHYSICAL_BASE64             EQU             2000000h
PXT_PHYSICAL_BASE64             EQU             21ed000h


;;
;; 页表 pool 地址
;; 说明:
;; 1) 位置在 PPT_PHYSICAL_BASE64 后面（默认值为 220_0000h）
;; 2) PDT 和 PT 物理地址都从这个 pool 里分配
;; 3) PT_POOL_TOP64 = 300_0000h - 1 = 2ff_ffffh
;; 4) PT_POOL_SIZE 空间为 14M
;; 5) 虚拟地址 ffff_f800_8220_0000h 映射到 PT Pool 物理空间上
;;
PT_POOL_PHYSICAL_BASE64         EQU             (PPT_PHYSICAL_BASE64 + PPT_SIZE)
PT_POOL_PHYSICAL_TOP64          EQU             2FFFFFFh
PT_POOL_SIZE                    EQU             (PT_POOL_PHYSICAL_TOP64 - PT_POOL_PHYSICAL_BASE64 + 1)
PT_POOL_BASE64                  EQU             0FFFFF80082200000h


;;
;; 页表备用 pool 地址
;; 说明:
;; 1) 当页表池 PT Pool 用完后，使用备用的 PT pool 区域
;; 2) 备用的 PT Pool 是原 legacy 模式下的 PT 区域（共 8M 空间: 20_0000h - 0A0_0000h)
;; 3) 虚拟地址 ffff_f800_8020_0000h 映射到备用 PT Pool 物理空间上
;;
PT_POOL2_PHYSICAL_BASE64        EQU             PT_PHYSICAL_BASE
PT_POOL2_PHYSICAL_TOP64         EQU             (PT_PHYSICAL_BASE + 800000h - 1)
PT_POOL2_SIZE                   EQU             800000h
PT_POOL2_BASE64                 EQU             0FFFFF80080200000h



%endif
