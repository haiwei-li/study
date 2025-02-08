;*************************************************
;* LocalVideo.asm                                *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************




;-------------------------------------------------
; flush_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 刷 local video buffer 数据到 video
;-------------------------------------------------        
flush_video_buffer:
        push ebp
        push ecx
        push ebx


do_flush_video_buffer:        
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        

        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]
        
        ;;
        ;; 从 LocalVideBufferHead 开始到 LocalVideoBufferPtr
        ;; 刷新到 target video buffer 中
        ;;
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]        
        REX.Wrxb
        mov ecx, [ebp + LSB.LocalVideoBufferPtr]
        REX.Wrxb
        mov esi, [ebp + LSB.LocalVideoBufferHead]
        REX.Wrxb
        sub ecx, esi
                
        jmp do_flush_local_video_buffer
        
        
        
;-------------------------------------------------
; flush_local_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 刷新整个 local video buffer
;-------------------------------------------------        
flush_local_video_buffer:
        push ebp
        push ecx                
        push ebx

        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif    

        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]
            
        ;;
        ;; 将 LocalVideoBufferHead 开始的整屏区域复制到 target video buffer
        ;;
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]
        REX.Wrxb
        mov esi, [ebp + LSB.LocalVideoBufferHead]
        mov ecx, 25 * 80 * 2
        


do_flush_local_video_buffer:        

%ifdef __X64
        DB 41h, 89h, 0C8h                               ; mov r8d, ecx 
%endif      

        REX.Wrxb
        mov edi, [ebx + SDA.VideoBufferHead]
        call memcpy
        
        ;;
        ;; 更新 SDA.VideoBufferPtr:
        ;; 1) SDA.VideoBufferPtr = (LocalVideoBufferPtr - LocalVideoBufferHead) + ViodeBufferHead
        ;;
        REX.Wrxb
        mov edi, [ebp + LSB.LocalVideoBufferPtr]
        REX.Wrxb
        sub edi, [ebp + LSB.LocalVideoBufferHead]
        REX.Wrxb
        add edi, [ebx + SDA.VideoBufferHead]        
        REX.Wrxb
        mov [ebx + SDA.VideoBufferPtr], edi
        
        ;;
        ;; 更新 SDA.VideoBufferLastChar
        ;;
        mov eax, [ebp + LSB.LocalVideoBufferLastChar]
        mov [ebx + SDA.VideoBufferLastChar], eax
        
        pop ebx
        pop ecx
        pop ebp
        ret        



;-------------------------------------------------
; store_local_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 将整个屏幕保存在当前的 local video buffer
;-------------------------------------------------  
store_local_video_buffer:
        push ebp
        push ecx
        push ebx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]            ; ebx = SDA
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]            ; ebp = LSB
        
        ;;
        ;; 复制屏幕内容
        ;;
        
        REX.Wrxb
        mov edi, [ebp + LSB.LocalVideoBufferHead]
        REX.Wrxb
        mov esi, [ebx + SDA.VideoBufferHead]
        
%ifdef __X64
        REX.wrxB
        mov eax, 25 * 80 * 2                    ; mov r8d, 25 * 80 * 2
%else
        mov ecx, 25 * 80 * 2
%endif        
        call memcpy
        
        ;;
        ;; 更新 LocalVideoBufferPtr 和 LocalVideoBufferLastChar
        ;;
        REX.Wrxb
        mov eax, [ebx + SDA.VideoBufferPtr]
        REX.Wrxb
        mov [ebp + LSB.LocalVideoBufferPtr], eax
        mov eax, [ebp + SDA.VideoBufferLastChar]
        mov [ebp + LSB.LocalVideoBufferLastChar], eax
        
        pop ebx                
        pop ecx
        pop ebp
        ret        
        
        
        
        
        
        
        
        
%if 0
;-------------------------------------------------
; flush_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 刷 local video buffer 数据到 video
;-------------------------------------------------        
flush_video_buffer:
        push ebp
        push ecx
        push ebx


do_flush_video_buffer:        
        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif        

        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]
        
        ;;
        ;; 从 LocalVideBufferHead 开始到 LocalVideoBufferPtr
        ;; 刷新到 target video buffer 中
        ;;
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]        
        REX.Wrxb
        mov ecx, [ebp + LSB.LocalVideoBufferPtr]
        REX.Wrxb
        mov esi, [ebp + LSB.LocalVideoBufferHead]
        REX.Wrxb
        sub ecx, esi
                
        jmp do_flush_local_video_buffer
        
        
        
        %endif
        
;-------------------------------------------------
; flush_vm_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 刷新整个 VM video buffer
;-------------------------------------------------        
flush_vm_video_buffer:
        push ebp
        push ecx                
        push ebx
        push edx

        
%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif    

        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]
        
        
        
        ;;
        ;; 将 VmVideoBufferHead 开始的整屏区域复制到 target video buffer
        ;;         
        REX.Wrxb
        mov edx, [ebp + PCB.CurrentVmbPointer]
        REX.Wrxb
        mov edx, [edx + VMB.VsbBase]                    ; edx = VSB        
        REX.Wrxb
        mov esi, [edx + VSB.VmVideoBufferHead]
        mov ecx, 25 * 80 * 2
        

do_flush_vm_video_buffer:        

%ifdef __X64
        DB 41h, 89h, 0C8h                               ; mov r8d, ecx 
%endif      

        REX.Wrxb
        mov edi, [ebx + SDA.VideoBufferHead]
        call memcpy
        
        ;;
        ;; 更新 SDA.VideoBufferPtr:
        ;; 1) SDA.VideoBufferPtr = (VmVideoBufferPtr - VmVideoBufferHead) + ViodeBufferHead
        ;;
        REX.Wrxb
        mov edi, [edx + VSB.VmVideoBufferPtr]
        REX.Wrxb
        sub edi, [edx + VSB.VmVideoBufferHead]
        REX.Wrxb
        add edi, [ebx + SDA.VideoBufferHead]        
        REX.Wrxb
        mov [ebx + SDA.VideoBufferPtr], edi
        
        ;;
        ;; 更新 SDA.VideoBufferLastChar
        ;;
        mov eax, [edx + VSB.VmVideoBufferLastChar]
        mov [ebx + SDA.VideoBufferLastChar], eax
        
        pop edx
        pop ebx
        pop ecx
        pop ebp
        ret        


%if 0
;-------------------------------------------------
; store_local_video_buffer()
; input:
;       none
; output:
;       none
; 描述: 
;       1) 将整个屏幕保存在当前的 local video buffer
;-------------------------------------------------  
store_local_video_buffer:
        push ebp
        push ecx
        push ebx

%ifdef __X64
        LoadGsBaseToRbp
%else
        mov ebp, [gs: PCB.Base]
%endif
        
        REX.Wrxb
        mov ebx, [ebp + PCB.SdaBase]            ; ebx = SDA
        REX.Wrxb
        mov ebp, [ebp + PCB.LsbBase]            ; ebp = LSB
        
        ;;
        ;; 复制屏幕内容
        ;;
        
        REX.Wrxb
        mov edi, [ebp + LSB.LocalVideoBufferHead]
        REX.Wrxb
        mov esi, [ebx + SDA.VideoBufferHead]
        
%ifdef __X64
        REX.wrxB
        mov eax, 25 * 80 * 2                    ; mov r8d, 25 * 80 * 2
%else
        mov ecx, 25 * 80 * 2
%endif        
        call memcpy
        
        ;;
        ;; 更新 LocalVideoBufferPtr 和 LocalVideoBufferLastChar
        ;;
        REX.Wrxb
        mov eax, [ebx + SDA.VideoBufferPtr]
        REX.Wrxb
        mov [ebp + LSB.LocalVideoBufferPtr], eax
        mov eax, [ebp + SDA.VideoBufferLastChar]
        mov [ebp + LSB.LocalVideoBufferLastChar], eax
        
        pop ebx                
        pop ecx
        pop ebp
        ret                
        %endif