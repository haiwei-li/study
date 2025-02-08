;*************************************************
;* DeubgRecord.inc                               *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


%ifndef __DEBUG_RECORD_INC
%define __DEBUG_RECORD_INC



;;
;; DRS 区域默认为 32K
;;
%ifdef DEBUG_RECORD_ENABLE
DRS_AREA_SIZE                   EQU     8000h
%else
DRS_AREA_SIZE                   EQU     0
%endif


;;
;; DES(DEBUG_RECORD_STRUCTURE)结构用来保存 debug 信息, 跟踪执行
;;
struc DRS
        .ProcessorIndex         RESD            1
        .RecordNumber           RESD            1

        ALIGNB 8
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

        .Rflags                 RESQ            1
        .Cs                     RESQ            1
        .Rip                    RESQ            1

        ;;
        ;; debug 点记录信息
        ;;
        .Line                   RESD            1
        .FileName               RESQ            1
        
        ;;
        ;; 附加信息
        ;;
        .AppendMsg              RESQ            1

        ;;
        ;; 前缀与后缀信息
        ;;
        .PrefixMsg              RESQ            1
        .PostfixMsg             RESQ            1
        .Address                RESD            1
        
        ALIGNB 8
        ;;
        ;; 链表指针
        ;;
        .PrevDrs                RESQ            1
        .NextDrs                RESQ            1
        
        
        DRS_SIZE                EQU             $
        MAX_DRS_COUNT           EQU             (DRS_AREA_SIZE / DRS_SIZE)

endstruc








;-----------------------------------------------------
; DEBUG_RECORD
; input:
;       msg - 附注信息
; output:
;       none
; 描述: 
;       1) 插入一条 debug 记录到 DRS 区域
;       2) %1 参数是附注信息
; 使用示例: 
;       DEBUG_RECORD "hello, world"
;-----------------------------------------------------
%macro DEBUG_RECORD  1
%ifdef DEBUG_RECORD_ENABLE        
        %%Line          EQU     __LINE__

        ;;
        ;; 下面在 64 位下编译
        ;;
%if __BITS__ == 64
        pushf
        push rbp
        push rbx
        push rax
        push rcx
        mov rbp, [fs: SDA.Base]                         ; rbp = SDA

        mov rbx, [rbp + SDA.DrsTailPtr]                 ; rbx 指向 DRS 链表尾
        mov rax, [rbp + SDA.DrsIndex]                   ; rax 指向 DRS 区域内的下一个结点


        ;;
        ;; index 超出了 DRS 区域顶部, 则不记录
        ;;
        cmp rax, [rbp + SDA.DrsTop]
        jae %%done

        ;;
        ;; 更新记录号
        ;;
        mov ecx, [rbx + DRS.RecordNumber]
        inc ecx
        mov [rax + DRS.RecordNumber], ecx

        ;;
        ;; 更新 DRS 链表结点
        ;;
        mov [rax + DRS.PrevDrs], rbx                    ; DrsIndex->PrevDrs = DRsTailPtr
        mov [rbx + DRS.NextDrs], rax                    ; DrsTailPtr->NextDrs = DrsIndex
        mov rbx, rax                                    ; rbx 指向下一条 DRS 记录

        ;;
        ;; 更新 DrsIndex
        ;;
        mov eax, DRS_SIZE
        lock xadd [rbp + SDA.DrsIndex], rax


        ;;
        ;; 开始记录 debug record 信息
        ;;
        mov eax, [gs: PCB.ProcessorIndex]
        mov [rbx + DRS.ProcessorIndex], eax             ; 记录 processor index
        mov QWORD [rbx + DRS.Rip], %%IP                 ; 记录 RIP
        mov rax, [rsp + 32]                             ; 读 rflags
        mov [rbx + DRS.Rflags], rax                     ; 记录 Rflags

        ;;
        ;; 记录文件名和行数
        ;;
        mov DWORD [rbx + DRS.Line], %%Line
        mov QWORD [rbx + DRS.FileName], %%File

        ;;
        ;; 附加信息
        ;;
        mov QWORD [rbx + DRS.AppendMsg], %%Msg
        mov QWORD [rbx + DRS.PrefixMsg], 0
        mov QWORD [rbx + DRS.PostfixMsg], 0
        mov DWORD [rbx + DRS.Address], 0

        
        jmp %%1

%%File  DB      __FILE__, 0                             ; 保存文件名
%%Msg   DB      %1, 0                                   ; 保存附注信息

%%1:


        ;;
        ;; 更新 DRS count
        ;;
        lock inc DWORD [rbp + SDA.DrsCount]


%else
        ;;
        ;; 在 32 位下编译
        ;;

        pushf
        push ebp
        push ebx
        push eax
        push ecx

%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif

        REX.Wrxb
        mov ebx, [ebp + SDA.DrsTailPtr]                 ; ebx 指向 DRS 链表尾
        REX.Wrxb
        mov eax, [ebp + SDA.DrsIndex]                   ; eax 指向下一个 DRS 结点


        REX.Wrxb
        cmp eax, [ebp + SDA.DrsTop]
        jae %%done

        ;;
        ;; 更新记录号
        ;;
        mov ecx, [ebx + DRS.RecordNumber]
        INCv ecx
        mov [eax + DRS.RecordNumber], ecx

        ;;
        ;; 更新 PrevDrs
        ;;
        REX.Wrxb
        mov [eax + DRS.PrevDrs], ebx                    ; DrsIndex->PrevDrs = DrsTailPtr
        REX.Wrxb
        mov [ebx + DRS.NextDrs], eax                    ; DrsTailPtr->NextDrs = DrsIndex
        REX.Wrxb
        mov ebx, eax                                    ; rbx 指向下一条 DRS 记录

        ;;
        ;; 更新 DrsIndex
        ;;
        mov eax, DRS_SIZE
        PREFIX_LOCK
        REX.Wrxb
        xadd [ebp + SDA.DrsIndex], eax


        ;;
        ;; 开始记录 debug record 信息
        ;;
        mov eax, PCB.ProcessorIndex
        mov eax, [gs: eax]
        mov [ebx + DRS.ProcessorIndex], eax             ; 记录 processor index
        mov eax, %%IP        
        REX.Wrxb
        mov [ebx + DRS.Rip], eax                        ; 记录 RIP

%ifdef __X64
        REX.Wrxb
        mov eax, [esp + 32]                             ; 读 rflags
%else
        mov eax, [esp + 16]                             ; 读 eflags
%endif
        REX.Wrxb
        mov [ebx + DRS.Rflags], eax                     ; 记录 Rflags


        ;;
        ;; 记录文件名和行数
        ;;
        mov DWORD [ebx + DRS.Line], %%Line
        REX.Wrxb
        mov DWORD [ebx + DRS.FileName], %%file

        ;;
        ;; 附加信息
        ;;
        REX.Wrxb
        mov DWORD [ebx + DRS.AppendMsg], %%msg
        REX.Wrxb
        mov DWORD [ebx + DRS.PrefixMsg], 0
        REX.Wrxb
        mov DWORD [ebx + DRS.PostfixMsg], 0
        mov DWORD [ebx + DRS.Address], 0

        jmp %%1

%%file  DB      __FILE__, 0                             ; 保存文件名
%%msg   DB      %1, 0                                   ; 保存附注信息

%%1:
        ;;
        ;; 记录 count
        ;;
        lock inc DWORD [ebp + SDA.DrsCount]
%endif

        

        ;;
        ;; 记录 context
        ;;

%if __BITS__ == 64
        mov rax, [rsp + 8]                              ; rax
        mov [rbx + DRS.Rax], rax                        
        mov rax, [rsp + 16]                             ; rbx
        mov [rbx + DRS.Rbx], rax
        mov rax, [rsp + 24]                             ; rbp
        mov [rbx + DRS.Rbp], rax
        lea rax, [rsp + 40]                             ; rsp
        mov [rbx + DRS.Rsp], rax        
        mov rax, [rsp]
        mov [rbx + DRS.Rcx], rax                        ; rcx
        mov [rbx + DRS.Rdx], rdx                        ; rdx
        mov [rbx + DRS.Rsi], rsi                        ; rsi
        mov [rbx + DRS.Rdi], rdi                        ; rdi
        mov [rbx + DRS.R8], r8                          ; r8
        mov [rbx + DRS.R9], r9                          ; r9
        mov [rbx + DRS.R10], r10                        ; r10
        mov [rbx + DRS.R11], r11                        ; r11
        mov [rbx + DRS.R12], r12                        ; r12
        mov [rbx + DRS.R13], r13                        ; r13
        mov [rbx + DRS.R14], r14                        ; r14
        mov [rbx + DRS.R15], r15                        ; r15
%else

%ifdef __X64
        REX.Wrxb
        mov eax, [esp + 8]                              ; rax
        REX.Wrxb
        mov [ebx + DRS.Rax], eax                        
        REX.Wrxb
        mov eax, [esp + 16]                             ; rbx
        REX.Wrxb
        mov [ebx + DRS.Rbx], eax
        REX.Wrxb
        mov eax, [esp + 24]                             ; rbp
        REX.Wrxb
        mov [ebx + DRS.Rbp], eax
        REX.Wrxb
        lea eax, [esp + 40]                             ; rsp
        REX.Wrxb
        mov [ebx + DRS.Rsp], eax
        REX.Wrxb
        mov eax, [esp]
        REX.Wrxb
        mov [ebx + DRS.Rcx], eax                        ; rcx
        REX.Wrxb
        mov [ebx + DRS.Rdx], edx                        ; rdx
        REX.Wrxb
        mov [ebx + DRS.Rsi], esi                        ; rsi
        REX.Wrxb
        mov [ebx + DRS.Rdi], edi                        ; rdi
        REX.WRxb
        mov [ebx + DRS.R8], eax                         ; r8
        REX.WRxb
        mov [ebx + DRS.R9], ecx                         ; r9
        REX.WRxb
        mov [ebx + DRS.R10], edx                        ; r10
        REX.WRxb
        mov [ebx + DRS.R11], ebx                        ; r11
        REX.WRxb
        mov [ebx + DRS.R12], esp                        ; r12
        REX.WRxb
        mov [ebx + DRS.R13], ebp                        ; r13
        REX.WRxb
        mov [ebx + DRS.R14], esi                        ; r14
        REX.WRxb
        mov [ebx + DRS.R15], edi                        ; r15
%else
        mov eax, [esp + 4]                              ; eax
        mov [ebx + DRS.Rax], eax                        
        mov eax, [esp + 8]                              ; ebx
        mov [ebx + DRS.Rbx], eax
        mov eax, [esp + 12]                             ; ebp
        mov [ebx + DRS.Rbp], eax
        lea eax, [esp + 20]                             ; esp
        mov [ebx + DRS.Rsp], eax
        mov eax, [esp]
        mov [ebx + DRS.Rcx], eax                        ; ecx
        mov [ebx + DRS.Rdx], edx                        ; edx
        mov [ebx + DRS.Rsi], esi                        ; esi
        mov [ebx + DRS.Rdi], edi                        ; edi

%endif          ;; // __X64
       
%endif          ;; // __BITS__



%%done:
        ;;
        ;; 更新 SDA.DrsTailPtr 记录和 DRS.NextDrs 指针
        ;;

%if __BITS__ == 64
        mov [rbp + SDA.DrsTailPtr], rbx
        mov QWORD [rbx + DRS.NextDrs], 0
%else
        REX.Wrxb
        mov [ebp + SDA.DrsTailPtr], ebx           
        REX.Wrxb
        mov DWORD [ebx + DRS.NextDrs], 0          
%endif

          
        ;;
        ;; 恢复 context
        ;;

%if __BITS__ == 64
        pop rcx
        pop rax
        pop rbx
        pop rbp
        popfq
%else
        pop ecx
        pop eax
        pop ebx
        pop ebp
        REX.Wrxb
        popf
%endif

%%IP:

%endif          ;; DEBUG_RECORD_ENABLE
%endmacro





;; *+-----------------------------------------
;; * DEBUG_RECORD_S 宏存在 bug !
;; * 不要使用 DEBUG_RECORD_S 插入DebugRecord 点
;; *------------------------------------------+



;-----------------------------------------------------
; DEBUG_RECORD_S
; input:
;       msg - 附注信息
; output:
;       none
; 描述: 
;       1) 插入一条 debug 记录到 DRS 区域
;       2) DEBUG_RECORD 的 stack 版本, DRS 记录保存在当前栈里
; 使用示例: 
;       DEBUG_RECORD_S "hello, world"
;-----------------------------------------------------
%macro DEBUG_RECORD_S  1

%ifdef DEBUG_RECORD_ENABLE        
        %%Line     EQU     __LINE__

%define DRS_STACK_SIZE          ((DRS_SIZE + 15) & 0FFFFFFF0h)

%if __BITS__ == 64

        lea rsp, [rsp - DRS_STACK_SIZE]
        ;;
        ;; 保存 context
        ;;
        mov [rsp + DRS.Rax], rax
        mov [rsp + DRS.Rcx], rcx
        mov [rsp + DRS.Rdx], rdx
        mov [rsp + DRS.Rbx], rbx
        lea rax, [rsp + DRS_STACK_SIZE]
        mov [rsp + DRS.Rsp], rax
        mov [rsp + DRS.Rbp], rbp
        mov [rsp + DRS.Rsi], rsi
        mov [rsp + DRS.Rdi], rdi
        mov [rsp + DRS.R8], r8
        mov [rsp + DRS.R9], r9
        mov [rsp + DRS.R10], r10
        mov [rsp + DRS.R11], r11
        mov [rsp + DRS.R12], r12
        mov [rsp + DRS.R13], r13
        mov [rsp + DRS.R14], r14
        mov [rsp + DRS.R15], r15        
               
        pushf
        pop rax
        mov [rsp + DRS.Rflags], rax
        mov eax, [gs: PCB.ProcessorIndex]
        mov [rsp + DRS.ProcessorIndex], eax
        mov QWORD [rsp + DRS.Rip], %%IP
        mov DWORD [rsp + DRS.Line], %%Line
        mov QWORD [rsp + DRS.FileName], %%File
        mov QWORD [rsp + DRS.AppendMsg], %%Msg


        mov rbp, [fs: SDA.Base]

        cmp DWORD [rbp + SDA.DrsCount], 0
        jne %%0

        ;;
        ;; 当前结点属于 head
        ;;
        mov [rbp + SDA.DrsHeadPtr], rsp
        mov [rbp + SDA.DrsTailPtr], rsp
%%0:

        ;;
        ;; 挂接 DRS 链
        ;;        
        mov rbx, [rbp + SDA.DrsTailPtr]                 ; DRS 链表尾部
        mov [rbx + DRS.NextDrs], rsp
        mov [rsp + DRS.PrevDrs], rbx
        mov QWORD [rsp + DRS.NextDrs], 0

        ;;
        ;; 更新记录号
        ;;
        mov ecx, [rbx + DRS.RecordNumber]
        inc ecx
        mov [rsp + DRS.RecordNumber], ecx

        ;;
        ;; 更新 count 及 DrsTailPtr
        ;;
        lock inc DWORD [rbp + SDA.DrsCount]
        mov [rbp + SDA.DrsTailPtr], rsp
        jmp %%done


%%File  DB      __FILE__, 0                             ; 保存文件名
%%Msg   DB      %1, 0                                   ; 保存附注信息



%else

        ;;
        ;; 在 32 位下编译
        ;;
%ifdef __X64
        REX.Wrxb
        lea esp, [esp - DRS_STACK_SIZE]

        REX.Wrxb
        mov [esp + DRS.Rax], eax                        ; rax
        REX.Wrxb
        mov [esp + DRS.Rcx], ecx                        ; rcx
        REX.Wrxb
        mov [esp + DRS.Rdx], edx                        ; rdx
        REX.Wrxb
        mov [esp + DRS.Rbx], ebx                        ; rbx      
        REX.Wrxb
        lea eax, [esp + DRS_STACK_SIZE]
        REX.Wrxb
        mov [esp + DRS.Rsp], eax                        ; rsp
        REX.Wrxb
        mov [esp + DRS.Rbp], ebp                        ; rbp
        REX.Wrxb
        mov [esp + DRS.Rsi], esi                        ; rsi
        REX.Wrxb
        mov [esp + DRS.Rdi], edi                        ; rdi
        REX.WRxb
        mov [esp + DRS.R8], eax                         ; r8
        REX.WRxb
        mov [esp + DRS.R9], ecx                         ; r9
        REX.WRxb
        mov [esp + DRS.R10], edx                        ; r10
        REX.WRxb
        mov [esp + DRS.R11], ebx                        ; r11
        REX.WRxb
        mov [esp + DRS.R12], esp                        ; r12
        REX.WRxb
        mov [esp + DRS.R13], ebp                        ; r13
        REX.WRxb
        mov [esp + DRS.R14], esi                        ; r14
        REX.WRxb
        mov [esp + DRS.R15], edi                        ; r15

%else
        lea esp, [esp - DRS_STACK_SIZE]
        mov [esp + DRS.Rax], eax                        ; eax
        mov [esp + DRS.Rcx], ecx                        ; ecx
        mov [esp + DRS.Rdx], edx                        ; edx
        mov [esp + DRS.Rbx], ebx                        ; ebx 
        lea eax, [esp + DRS_STACK_SIZE]     
        mov [esp + DRS.Rsp], eax                        ; esp
        mov [esp + DRS.Rbp], ebp                        ; ebp
        mov [esp + DRS.Rsi], esi                        ; esi
        mov [esp + DRS.Rdi], edi                        ; edi

%endif          ;; // __X64



%ifdef __X64
        LoadFsBaseToRbp
%else
        mov ebp, [fs: SDA.Base]
%endif

        mov eax, PCB.ProcessorIndex
        mov eax, [gs: eax]
        mov [esp + DRS.ProcessorIndex], eax
        pushf
        pop eax
        REX.Wrxb
        mov [esp + DRS.Rflags], eax
        REX.Wrxb
        mov DWORD [esp + DRS.Rip], %%IP
        mov DWORD [esp + DRS.Line], %%Line
        REX.Wrxb
        mov DWORD [esp + DRS.FileName], %%file
        REX.Wrxb
        mov DWORD [esp + DRS.AppendMsg], %%msg



        cmp DWORD [ebp + SDA.DrsCount], 0
        jne %%0

        ;;
        ;; 当前结点属于 head
        ;;
        REX.Wrxb
        mov [ebp + SDA.DrsHeadPtr], esp
        REX.Wrxb
        mov [ebp + SDA.DrsTailPtr], esp
%%0:


        ;;
        ;; 挂接 DRS 链
        ;;
        REX.Wrxb
        mov ebx, [ebp + SDA.DrsTailPtr]                         ; DRS 链表尾部
        REX.Wrxb
        mov [ebx + DRS.NextDrs], esp
        REX.Wrxb
        mov [esp + DRS.PrevDrs], ebx
        REX.Wrxb
        mov DWORD [esp + DRS.NextDrs], 0

        ;;
        ;; 更新记录号
        ;;
        mov ecx, [ebx + DRS.RecordNumber]
        INCv ecx
        mov [esp + DRS.RecordNumber], ecx

        ;;
        ;; 更新 count
        ;;
        lock inc DWORD [ebp + SDA.DrsCount]
        REX.Wrxb
        mov [ebp + SDA.DrsTailPtr], esp

        jmp %%done        

%%file  DB      __FILE__, 0                             ; 保存文件名
%%msg   DB      %1, 0                                   ; 保存附注信息


%endif          ;; // __BITS__



%%done:
        ;;
        ;; 恢复 context
        ;;

%if __BITS__ == 64
        push QWORD [rsp + DRS.Rflags]
        popfq
        mov rcx, [rsp + DRS.Rcx]
        mov rax, [rsp + DRS.Rax]
        mov rbx, [rsp + DRS.Rbx]
        mov rbp, [rsp + DRS.Rbp]
%else
        push DWORD [esp + DRS.Rflags]
        REX.Wrxb
        popf
        REX.Wrxb
        mov ecx, [esp + DRS.Rcx]
        REX.Wrxb
        mov eax, [esp + DRS.Rax]
        REX.Wrxb
        mov ebx, [esp + DRS.Rbx]
        REX.Wrxb
        mov ebp, [esp + DRS.Rbp]
%endif

%%IP:

%endif          ;; DEBUG_RECORD_ENABLE
%endmacro




;-----------------------------------------------------
; DEBUG_RECORD_USER_S
; input:
;       msg - 附注信息
; output:
;       none
; 描述: 
;       1) 插入一条 debug 记录到 DRS 区域
;       2) DEBUG_RECORD_S 的 User 版本, 供 USER 权限下使用
; 使用示例: 
;       DEBUG_RECORD_USER_S "hello, world"
;-----------------------------------------------------
%macro DEBUG_RECORD_USER_S      1

%ifdef DEBUG_RECORD_ENABLE        
        %%Line     EQU     __LINE__

%define DRS_STACK_SIZE          ((DRS_SIZE + 15) & 0FFFFFFF0h)

%if __BITS__ == 64

        lea rsp, [rsp - DRS_STACK_SIZE]
        ;;
        ;; 保存 context
        ;;
        mov [rsp + DRS.Rax], rax
        mov [rsp + DRS.Rcx], rcx
        mov [rsp + DRS.Rdx], rdx
        mov [rsp + DRS.Rbx], rbx
        lea rax, [rsp + DRS_STACK_SIZE]
        mov [rsp + DRS.Rsp], rax
        mov [rsp + DRS.Rbp], rbp
        mov [rsp + DRS.Rsi], rsi
        mov [rsp + DRS.Rdi], rdi
        mov [rsp + DRS.R8], r8
        mov [rsp + DRS.R9], r9
        mov [rsp + DRS.R10], r10
        mov [rsp + DRS.R11], r11
        mov [rsp + DRS.R12], r12
        mov [rsp + DRS.R13], r13
        mov [rsp + DRS.R14], r14
        mov [rsp + DRS.R15], r15        
               
        pushf
        pop rax
        mov [rsp + DRS.Rflags], rax

        ;;
        ;; 读 PCB.ProcessorIndex
        ;;        
        UserReadPcbData         PCB.ProcessorIndex, 4
        mov [rsp + DRS.ProcessorIndex], eax
        mov QWORD [rsp + DRS.Rip], %%IP
        mov QWORD [rsp + DRS.Line], %%Line
        mov QWORD [rsp + DRS.FileName], %%File
        mov QWORD [rsp + DRS.AppendMsg], %%Msg


        ;;
        ;; 是否为 Head
        ;;
        UserReadSdaData         SDA.DrsCount, 4                 ; 读 SDA.DrsCount
        test eax, eax
        jnz %%0

        ;;
        ;; 当前结点属于 head
        ;;
        UserWriteSdaData        SDA.DrsHeadPtr, 8, rsp
        UserWriteSdaData        SDA.DrsTailPtr, 8, rsp
%%0:

        ;;
        ;; 挂接 DRS 链
        ;;        
        UserReadSdaData         SDA.DrsTailPtr, 8
        mov [rsp + DRS.PrevDrs], rax
        lea rbx, [rax + DRS.NextDrs]
        UserWriteSysData        rbx, rsp
        mov QWORD [rsp + DRS.NextDrs], 0

        ;;
        ;; 更新 count 及 DrsTailPtr
        ;;
        UserReadSdaData         SDA.DrsCount, 4
        inc eax
        UserWriteSdaData        SDA.DrsCount, 4, rax
        UserWriteSdaData        SDA.DrsTailPtr, 8, rsp
        
        jmp %%done


%%File  DB      __FILE__, 0                             ; 保存文件名
%%Msg   DB      %1, 0                                   ; 保存附注信息



%else

        ;;
        ;; 在 32 位下编译
        ;;
%ifdef __X64
        REX.Wrxb
        lea esp, [esp - DRS_STACK_SIZE]

        REX.Wrxb
        mov [esp + DRS.Rax], eax                        ; rax
        REX.Wrxb
        mov [esp + DRS.Rcx], ecx                        ; rcx
        REX.Wrxb
        mov [esp + DRS.Rdx], edx                        ; rdx
        REX.Wrxb
        mov [esp + DRS.Rbx], ebx                        ; rbx      
        REX.Wrxb
        lea eax, [esp + DRS_STACK_SIZE]
        REX.Wrxb
        mov [esp + DRS.Rsp], eax                        ; rsp
        REX.Wrxb
        mov [esp + DRS.Rbp], ebp                        ; rbp
        REX.Wrxb
        mov [esp + DRS.Rsi], esi                        ; rsi
        REX.Wrxb
        mov [esp + DRS.Rdi], edi                        ; rdi
        REX.WRxb
        mov [esp + DRS.R8], eax                         ; r8
        REX.WRxb
        mov [esp + DRS.R9], ecx                         ; r9
        REX.WRxb
        mov [esp + DRS.R10], edx                        ; r10
        REX.WRxb
        mov [esp + DRS.R11], ebx                        ; r11
        REX.WRxb
        mov [esp + DRS.R12], esp                        ; r12
        REX.WRxb
        mov [esp + DRS.R13], ebp                        ; r13
        REX.WRxb
        mov [esp + DRS.R14], esi                        ; r14
        REX.WRxb
        mov [esp + DRS.R15], edi                        ; r15

%else
        lea esp, [esp - DRS_STACK_SIZE]
        mov [esp + DRS.Rax], eax                        ; eax
        mov [esp + DRS.Rcx], ecx                        ; ecx
        mov [esp + DRS.Rdx], edx                        ; edx
        mov [esp + DRS.Rbx], ebx                        ; ebx 
        lea eax, [esp + DRS_STACK_SIZE]     
        mov [esp + DRS.Rsp], eax                        ; esp
        mov [esp + DRS.Rbp], ebp                        ; ebp
        mov [esp + DRS.Rsi], esi                        ; esi
        mov [esp + DRS.Rdi], edi                        ; edi

%endif

        pushf
        pop eax
        REX.Wrxb
        mov [esp + DRS.Rflags], eax
        UserReadPcbData         PCB.ProcessorIndex, 4
        mov [esp + DRS.ProcessorIndex], eax
        REX.Wrxb
        mov DWORD [esp + DRS.Rip], %%IP
        mov DWORD [esp + DRS.Line], %%Line
        REX.Wrxb
        mov DWORD [esp + DRS.FileName], %%file
        REX.Wrxb
        mov DWORD [esp + DRS.AppendMsg], %%msg



        UserReadSdaData         SDA.DrsCount, 4                 ; 读 SDA.DrsCount
        test eax, eax
        jnz %%0

        ;;
        ;; 当前结点属于 head
        ;;
        UserWriteSdaData        SDA.DrsHeadPtr, 0, esp
        UserWriteSdaData        SDA.DrsTailPtr, 0, esp
%%0:

        ;;
        ;; 挂接 DRS 链
        ;;        
        UserReadSdaData         SDA.DrsTailPtr, 0
        REX.Wrxb
        mov [esp + DRS.PrevDrs], eax
        REX.Wrxb
        lea ebx, [eax + DRS.NextDrs]
        UserWriteSysData        ebx, esp
        REX.Wrxb
        mov DWORD [esp + DRS.NextDrs], 0

        ;;
        ;; 更新 count 及 DrsTailPtr
        ;;
        UserReadSdaData         SDA.DrsCount, 4
        inc eax
        UserWriteSdaData        SDA.DrsCount, 4, eax
        UserWriteSdaData        SDA.DrsTailPtr, 0, esp



        jmp %%done        

%%file  DB      __FILE__, 0                             ; 保存文件名
%%msg   DB      %1, 0                                   ; 保存附注信息


%endif          ;; // __BITS__



%%done:
        ;;
        ;; 恢复 context
        ;;

%if __BITS__ == 64
        push QWORD [rsp + DRS.Rflags]
        popfq
        mov rax, [rsp + DRS.Rax]
        mov rbx, [rsp + DRS.Rbx]
        mov rbp, [rsp + DRS.Rbp]
        mov rsi, [rsp + DRS.Rsi]
        mov rdi, [rsp + DRS.Rdi]
%else
        push DWORD [esp + DRS.Rflags]
        REX.Wrxb
        popf
        REX.Wrxb
        mov eax, [esp + DRS.Rax]
        REX.Wrxb
        mov ebx, [esp + DRS.Rbx]
        REX.Wrxb
        mov ebp, [esp + DRS.Rbp]
        REX.Wrxb
        mov esi, [esp + DRS.Rsi]
        REX.Wrxb
        mov edi, [esp + DRS.Rdi]

%endif          ;; // __BITS__

%%IP:

%endif          ;; DEBUG_RECORD_ENABLE
%endmacro




%endif

