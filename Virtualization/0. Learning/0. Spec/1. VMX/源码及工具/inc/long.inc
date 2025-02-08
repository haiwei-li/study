; long.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.

%ifndef LONG_INC
%define LONG_INC



;-----------------------------------------------
; MAKE_SEGMENT_ATTRIBUTE(): ∫Í◊È∫œ∂Œ Ù–‘
; input:
;                %1: type, %2: DPL, %3: G,  %4: D/B
;-----------------------------------------------
%macro MAKE_SEGMENT_ATTRIBUTE 4
        mov eax, (%1 | %2 << 5 | %3 << 15 | %4 << 14 | 0x90 | 0x2000)
%endmacro


%endif
