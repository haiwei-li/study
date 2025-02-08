%ifndef _LOADER_BLOCK_INC
%define _LOADER_BLOCK_INC


;;
;; 定义 LOADER_BLOCK
;;

struc LOADER_BLOCK
        .ModuleSize     RESD    1           ; 模块 size
        .CpuIndex       RESD    1           ; CPU index
        .CurrentVideo   RESD    1           ; 记录 video 当前位置
        .Stage1Lock     RESD    1           ; stage1 lock
        .Stage2Lock     RESD    1           ; stage2 lock
        .Stage3Lock     RESD    1           ; stage3 lock
        .MMapSize       RESQ    1           ; size
        .MMapBase       RESQ    1           ; 内存区域起始地位
        .MMapLength     RESQ    1           ; 内存区域长度
        .MMapType       RESD    1           ; 内存区域类型
endstruc



;;
;; 引导块基址
;;
LoaderBase              EQU     0x8000



%endif
