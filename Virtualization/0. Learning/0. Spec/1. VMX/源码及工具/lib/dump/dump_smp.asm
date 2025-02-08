;*************************************************
;* dump_smp.asm                                  *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************



dump_processor_topology_info:
        push ebx
        mov ebx, [gs: PCB.Base]
        add ebx, PCB.ProcessorTopology
        mov esi, Smp.TopologyInfoMsg
        call puts
        mov esi, Smp.ProcessorIdMsg
        call puts
        mov esi, [ebx + TopologyInfo.ProcessorId]
        call print_dword_value
        call println
        mov esi, Smp.CoreIdMsg
        call puts
        movzx esi, BYTE [ebx + TopologyInfo.CoreId]
        call print_byte_value
        call println
        mov esi, Smp.ThreadIdMsg
        call puts
        movzx esi, BYTE [ebx + TopologyInfo.ThreadId]
        call print_byte_value        
        call println
        mov esi, Smp.CoreMaskWidthMsg
        call puts
        movzx esi, BYTE [ebx + TopologyInfo.CoreMaskWidth]
        call print_decimal32
        call println
        mov esi, Smp.CoreSelectMaskMsg
        call puts
        mov esi, [ebx + TopologyInfo.CoreSelectMask]
        call print_dword_value
        call println
        mov esi, Smp.ThreadMaskWidthMsg
        call puts
        movzx esi, BYTE [ebx + TopologyInfo.ThreadMaskWidth]
        call print_decimal32
        call println
        mov esi, Smp.ThreadSelectMaskMsg
        call puts
        mov esi, [ebx + TopologyInfo.ThreadSelectMask]
        call print_dword_value
        call println        
        mov esi, Smp.LppcMsg
        call puts
        mov esi, [ebx + TopologyInfo.LogicalProcessorPerCore]
        call print_decimal32
        call println
        mov esi, Smp.LpppMsg
        call puts
        mov esi, [ebx + TopologyInfo.LogicalProcessorPerPackage]
        call print_decimal32
        call println
        pop ebx
        ret