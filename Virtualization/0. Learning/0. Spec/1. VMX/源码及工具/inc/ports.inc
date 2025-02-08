; ports.inc
; Copyright (c) 2009-2010 mik 
; All rights reserved.


%ifndef PORTS_INC
%define PORTS_INC
        
        
; *** PS/2 system control port A        
SYSTEM_CONTROL_PORTA                    equ     0x92        
        

; *** CMOS RAM index register port 
CMOS_RAM_INDEX_PORT                     equ     0x70
NMI_EN_PORT                             equ     0x70


; *** PIC-8259 ports ****

MASTER_ICW1_PORT                        equ     0x20
MASTER_ICW2_PORT                        equ     0x21
MASTER_ICW3_PORT                        equ     0x21
MASTER_ICW4_PORT                        equ     0x21
MASTER_OCW1_PORT                        equ     0x21
MASTER_OCW2_PORT                        equ     0x20
MASTER_OCW3_PORT                        equ     0x20

SLAVE_ICW1_PORT                         equ     0xa0
SLAVE_ICW2_PORT                         equ     0xa1
SLAVE_ICW3_PORT                         equ     0xa1
SLAVE_ICW4_PORT                         equ     0xa1
SLAVE_OCW1_PORT                         equ     0xa1
SLAVE_OCW2_PORT                         equ     0xa0
SLAVE_OCW3_PORT                         equ     0xa0

MASTER_MASK_PORT                        equ     0x21
MASTER_EOI_PORT                         equ     0x20
MASTER_IMR_PORT                         equ     0x21
MASTER_IRR_PORT                         equ     0x20
MASTER_ISR_PORT                         equ     0x20

SLAVE_MASK_PORT                         equ     0xa1
SLAVE_EOI_PORT                          equ     0xa0
SLAVE_IMR_PORT                          equ     0xa1
SLAVE_IRR_PORT                          equ     0xa0
SLAVE_ISR_PORT                          equ     0xa0


; *** PIT-8253 ports ***
PIT_COUNTER0_PORT                       equ     0x40
PIT_COUNTER1_PORT                       equ     0x41
PIT_COUNTER2_PORT                       equ     0x42
PIT_CONTROL_PORT                        equ     0x43


; PCIÅäÖÃ¶Ë¿Ú
CONFIG_ADDRESS                          equ     0xcf8
CONFIG_DATA                             equ     0xcfc

; Reset control register
RESET_CONTROL_REGISTER                  equ     0xcf9
FAST_A20_INIT_REGISTER                  equ     0x92

; APM ¿ØÖÆ¶Ë¿Ú        
APM_CONTROL_PORT_REGISTER               equ     0xb2
APM_CNT                                 equ     0xb2
APM_STS                                 equ     0xb3


; **** keyboard controller & encoder ports *******
I8408_DATA_PORT                         equ     0x60
I8408_COMMAND_PORT                      equ     0x60
I8402_STATUS_PORT                       equ     0x64
I8402_COMMAND_PORT                      equ     0x64



%endif        