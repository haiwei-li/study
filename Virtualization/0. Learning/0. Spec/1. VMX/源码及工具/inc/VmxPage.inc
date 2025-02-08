;*************************************************
;* VmxPage.inc                                   *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


%ifndef _VMX_PAGE_INC
%define _VMX_PAGE_INC



;;
;; EPT(Extended Page Table)说明: 
;; 1) PXT 表区域: SDA.EptPxt
;; 2) PPT 表区域: C0A0_0000h ~ C0BF_FFFFh 共 2M 空间, 对应物理地址 A0_0000h ~ BF_FFFFh
;; 3) PDT 表由 get_ept_page() 函数动态分配
;; 4) PT 表由 get_ept_page() 函数动态分配
;;

EPT_PPT_BASE                    EQU     0C0A00000h              ;; EPT PPT 表虚拟地址
EPT_PPT_PHYSICAL_BASE           EQU     0A00000h                ;; EPT PPT 表物理地址

;;
;; 在 longmode 下: 
;; 1) PXT 表区域: SDA.EptPxt
;; 2) PPT 表区域: FFFF_F800_C0A0_0000h - FFFF_F800_C0BF_FFFFh
;;

EPT_READ                        EQU     1
EPT_WRITE                       EQU     2
EPT_EXECUTE                     EQU     4
EPT_FIXING                      EQU     10000000h
EPT_PS                          EQU     80h
EPT_IPAT                        EQU     40h
EPT_VALID_FLAG                  EQU     800h

;;
;; 定义 EPT table entry 类别
;;
EPT_PML4E                       EQU     0010000000000000h
EPT_PDPTE                       EQU     0020000000000000h
EPT_PDE                         EQU     0030000000000000h
EPT_PTE                         EQU     0040000000000000h
EPT_LEVEL_MASK                  EQU     0070000000000000h

EPT_PML4E32                     EQU     00100000h
EPT_PDPTE32                     EQU     00200000h
EPT_PDE32                       EQU     00300000h
EPT_PTE32                       EQU     00400000h
EPT_LEVEL_MASK32                EQU     00700000h


EPT_FORCE                       EQU     20000000h
FIX_MISCONF                     EQU     08000000h
FIX_ACCESS                      EQU     04000000h
GET_PTE                         EQU     1 << 24
GET_PAGE_FRAME                  EQU     1 << 25


;;
;; 定义 EPT violation 相关的常量
;;
EPT_VIOLATION_TRANSLATION       EQU     100h                    ;; translation 位, 指示是否在 guest paging-structure内发生 EPT violation



;;
;; 定义 EPT misconfiguration 的定义码
;;
EPT_MISCONF_NONREADABLE         EQU     10001h                  ;; 由于不可读引起
EPT_MISCONF_ONLYEXECUTE         EQU     10002h                  ;; 由于 only-execute, 但VMX不支持而引起
EPT_MISCONF_RESERVED            EQU     10004h                  ;; 由于保留位不为0引起
EPT_MISCONF_MEMTYPE             EQU     10008h                  ;; 由于 memory type 而引起




DUMP_PAGE_NEST                  EQU     1


;;
;; 定义 guest-physical address 映射列表结构
;;
struc GML
        .GuestPhysicalAddress   RESQ    1                       ;; 需要映射的 GPA
        .HostPhysicalAddress    RESQ    1                       ;; 目标 HPA
        .EptPageCount           RESD    1                       ;; 页面数量
        .EptPageAttribute       RESD    1                       ;; 页面属性
endstruc


%endif
