;*************************************************
; guest_ex.asm                                   *
; Copyright (c) 2009-2013 邓志                   *
; All rights reserved.                           *
;*************************************************

        
        ;;
        ;; 例子 ex7-2: 模拟 guest 任务切换
        ;; 注意: 必须编译为 guest 使用 legacy 保护模式
        ;; 编译命令可以为: 
        ;;      1) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE -D__X64
        ;;      2) build -DDEBUG_RECORD_ENABLE -DGUEST_ENABLE
        ;;


%ifndef GUEST_X64
        ;;
        ;; 新任务所使用的 TSS selector
        ;;
        NewTssSelector          EQU     GuestReservedSel0    
        TargetTaskSelector      EQU     GuestReservedSel0    


        ;;
        ;; 构造一个 TSS 描述符
        ;;
        sgdt [GuestEx.GdtPointer]
        mov ebx, [GuestEx.GdtBase]
        mov DWORD [ebx + NewTssSelector + 4], GuestEx.Tss
        mov DWORD [ebx + NewTssSelector + 2], GuestEx.Tss
        mov WORD [ebx + NewTssSelector], 67h        
        mov WORD [ebx + NewTssSelector + 5], 89h

        ;;
        ;; 构造一个 task-gate 描述符
        ;;
        sidt [GuestEx.IdtPointer]
        mov ebx, [GuestEx.IdtBase]
        mov WORD [ebx + 60h * 8 + 2], NewTssSelector
        mov BYTE [ebx + 60h * 8 + 5], 85h
        

        ;;
        ;; 设置新任务的 TSS 块内容
        ;;
        mov ebx, GuestEx.Tss
        mov DWORD [ebx + TSS32.Esp], 7F00h
        mov WORD [ebx + TSS32.Ss], GuestKernelSs32
        mov eax, cr3
        mov [ebx + TSS32.Cr3], eax
        mov DWORD [ebx + TSS32.Eip], GuestEx.NewTask
        mov DWORD [ebx + TSS32.Eflags], FLAGS_IF | 02h
        mov WORD [ebx + TSS32.Cs], GuestKernelCs32
        mov WORD [ebx + TSS32.Ds], GuestKernelSs32
        
       
        ;;
        ;; ### 下面进行任务切换操作. ###
        ;; 注意: 不要使用 INT 指令！
        ;;       因为, 在例子 ex7-4 里拦截了执行 INT 指令, 并没有对中断的任务切换进行处理 ！！
        ;;       所以, 这里使用 CALL 指令进行任务切换 ！！
        ;;     
        call    TargetTaskSelector : 0
        
        ;;
        ;; 打印切换回来的信息
        ;;
        mov esi, GuestEx.Msg2
        call PutStr


        jmp $
   
        
;; 
;; #### 目标任务 ####
;;     
GuestEx.NewTask:
        mov esi, GuestEx.Msg1
        call PutStr
        clts
        iret


%endif


;;
;; GDT 表指针
;;
GuestEx.GdtPointer:
        GuestEx.GdtLimit        dw      0
        GuestEx.GdtBase         dd      0


GuestEx.IdtPointer:
        GuestEx.IdtLimit        dw      0
        GuestEx.IdtBase         dd      0
        
        
;;
;; TSS 区域
;;
ALIGNB 4
GuestEx.Tss:    times 104       db      0



GuestEx.Msg1    db      'now, switch to new task', 10, 0
GuestEx.Msg2    db      'now, switch back old task', 10, 0
                