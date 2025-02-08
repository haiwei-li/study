;*************************************************
;* data.asm                                      *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              报告 CPU 状态的字符串            ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Status.Msg                      db 'System Status = ', 0
Status.CpusMsg                  db '[CPUs]:', 0
Status.CpuModelMsg              db '[CpuModel]:', 0
Status.StageMsg                 db '[Stage]:', 0
Status.CpuIdMsg                 db '[CpuIndex]:', 0
Status.VmxMsg                   db '[VMX]:', 0
Status.EptMsg                   db '[Ept]:', 0
Status.HostGuestMsg             db '[Host/Guest]:', 0
Status.EnableMsg                db 'Enable', 0
Status.DisableMsg               db 'Disable', 0
Status.HostMsg                  db 'Host ', 0
Status.GuestMsg                 db 'Guest', 0

Status.Msg1                     db '<Esc>:reset,  <Pgup>:PageUp, <Pgdn>:PageDown', 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              long.asm 使用的数据              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Stage2.Msg                      db 'AP stage2 initialize done!', 10, 0
Stage2.Msg2			db 'enter stage2 ProtectedEntry', 10, 0
Stage1.Msg1                     db 'AP stage1 initialize done! waiting for stage2 lock...', 10, 0
Stage1.Msg2                     db 'AP stage1 initialize done! waiting for stage3 lock...', 10, 0
Stage3.Msg                      db '>>> now: enter Ap Stage3', 10, 0
Stage3.Msg1                     db 'AP stage3 initialize done!', 10, 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              crt.asm 使用的数据               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

crt.chars                       db '0123456789ABCDEF', 0
crt.quotient                    dq 0                            ; 保存商值
crt.remainder                   dq 0                            ; 保存余数
crt.digit_array:
        times 400               db 0                            ; 数字数组, 容纳 400 位十进制数

crt.float_const10               dt 10.0                         ; 浮点常数值
crt.value                       dd 0
crt.point                       dd 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      system_data_manage.asm 使用的数据       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SDA.ErrMsg1                     db '[CPU halt]: Your CPU is not support APIC !', 0
SDA.ErrMsg2                     db '[CPU halt]: Your CPU is not support Intel64 or AMD64 !', 0

;;
;; 下面信息用来诊断
;;
SDA.PcbInfoMsg                  db '========== PCB info ==========', 10, 0
SDA.SdaInfoMsg                  db '========== SDA info ==========', 10, 0
SDA.CpuInfoMsg                  db '========== CPU info ==========', 10, 0

SDA.BaseMsg                     db '[Base]:', 0
SDA.PhysicalBaseMsg             db '[PhysicalBase]:', 0
SDA.TssSelectorMsg              db '[TssSelector]:', 0
SDA.TssBaseMsg                  db '[TssBase]:', 0




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      ioapic.asm 使用的常量数据               ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Ioapic.WaitResetMsg             db '[[[STATUS]]]: press <ESC> for reset...', 0



;*** 键盘 ASCII 码表 *****
Ioapic.KeyMap:
                                db KEY_NULL, KEY_ESC, "1234567890-=", KEY_BS
                                db KEY_TAB, "qwertyuiop[]", KEY_ENTER, KEY_CTRL
                                db "asdfghjkl;'`", KEY_SHIFT, "\zxcvbnm,./"
                                db KEY_SHIFT, KEY_PRINTSCREEN, KEY_ALT, KEY_SPACE, KEY_CAPS
                                db KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10
                                db KEY_NUM, KEY_SCROLL, KEY_HOME, KEY_UP, KEY_PAGEUP, KEY_SUB, KEY_LEFT, KEY_ENTER
                                db KEY_RIGHT, KEY_ADD, KEY_END, KEY_DOWN, KEY_PAGEDOWN, KEY_INSERT, KEY_DEL
                                db 0, 0, 0, KEY_F11, KEY_F12, 0, 0, 0





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      services.asm 使用的常量数据             ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Services.EflagsMsg              db 'EFLAGS: ', 0

Services.RegisterMsg:
                                db 'EAX: ', 0
        REG_MSG_LENGTH  EQU $ - Services.RegisterMsg                
                                db 'ECX: ', 0
                                db 'EDX: ', 0
                                db 'EBX: ', 0
                                db 'ESP: ', 0
                                db 'EBP: ', 0
                                db 'ESI: ', 0
                                db 'EDI: ', 0

Services.ExceptionReportMsg     db '> exception report =======', 10, 0
Services.RegisterContextMsg     db '--------------- register context ------------', 10, 0
Services.ProcessorIdMsg         db '====== <processor#', 0
Services.CsIpMsg                db 'CS:IP=', 0
Services.ErrorCodeMsg           db 'ErrorCode=', 0   


Services.ExcetpionMsgTable      db '#DE', 0
                                db '#DB', 0
                                db 'NMI', 0
                                db '#BP', 0
                                db '#OF', 0
                                db '#BR', 0
                                db '#UD', 0
                                db '#NM', 0
                                db '#DF', 0
                                db 0,0,0,0
                                db '#TS', 0
                                db '#NP', 0
                                db '#SS', 0
                                db '#GP', 0
                                db '#PF', 0
                                db 0, 0, 0, 0
                                db '#MF', 0
                                db '#AC', 0
                                db '#MC', 0
                                db '#XM', 0

Services.Cr2Msg                 db 'CR2: ', 0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      services64.asm 使用的常量数据           ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Services64.RegisterMsg          db 'RAX: ', 0
                                db 'RCX: ', 0
                                db 'RDX: ', 0
                                db 'RBX: ', 0
                                db 'RSP: ', 0                                
                                db 'RBP: ', 0
                                db 'RSI: ', 0
                                db 'RDI: ', 0
                                db 'R8:  ', 0
                                db 'R9:  ', 0                                                                
                                db 'R10: ', 0
                                db 'R11: ', 0
                                db 'R12: ', 0
                                db 'R13: ', 0
                                db 'R14: ', 0
                                db 'R15: ', 0




Drs.Msg                         db '============== debug record <#', 0
Drs.Msg1                        db '> ==============', 10, 0
Drs.CpuIndexMsg                 db '[CPU', 0
Drs.CpuIndexMsg1                db ']: ', 0
Drs.StatusMsg                   db '<Esc>:quit,  <Pgup>:PageUp,  <Pgdn>:PageDown   <Enter>:MsgList', 0
Drs.RipMsg                      db 'RIP: ', 0
Drs.RflagsMsg                   db 'Rflags: ', 0
Drs.FnLineMsg                   db '[FileName:Line]: ', 0
Drs.Msg2                        db 10, '               *** NO RECORD ***', 10, 0
Drs.Msg3                        db 10, '            *** DRS record bottom  ***', 10, 0
Drs.Msg4                        db 10, '            *** DRS record TOP ****', 10, 0

Drs.ListMsg                     db '============ msg list record ============', 10, 0
Drs.ListMsg1                    db '<Up>:Scroll Up  <Down>:Scroll Down  <Space>:Update  <Enter>:DebugRecord', 0
Drs.ExitReasonMsg               db '[Exit Reason]: ', 0



Lbr.Msg0                        db  '----------------------------- LBR STACK -------------------------------', 10, 0	
Lbr.FromIp                      db 'from_ip_', 0
Lbr.Msg1                        db ': 0x', 0
Lbr.Top                         db ' <-- TOP --> ', 0
Lbr.Msg2                        db '             ', 0
Lbr.ToIp                        db 'to_ip_', 0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      smp.asm 使用的常量数据                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Smp.TopologyInfoMsg             db '========= Processor Topology Info Report =========', 10, 0
Smp.CoreIdMsg                   db 'CoreId: ', 0
Smp.ProcessorIdMsg              db 'ProcessorId: ', 0
Smp.ThreadIdMsg                 db 'ThreadId: ', 0
Smp.CoreMaskWidthMsg            db 'CoreMaskWidth: ', 0
Smp.CoreSelectMaskMsg           db 'CoreSelectMask: ', 0
Smp.ThreadMaskWidthMsg          db 'ThreadMaskWidth: ', 0
Smp.ThreadSelectMaskMsg         db 'ThreadSelectMask: ', 0
Smp.LppcMsg                     db 'LogicalProcessorPerCore: ', 0
Smp.LpppMsg                     db 'LogicalProcessorPerPackage: ', 0

ALIGN 4
Smp.Signal                      DD 1


Ept.DumpMsg1                    db '========== dump GPA (', 0
Ept.DumpMsg2                    db ') ===========', 10, 0
Ept.DumpGuestMsg1               db '=== dump guest-linear address (', 0
Ept.DumpGuestMsg2               db ') ====', 10, 0
Ept.Pml4eMsg                    db '[PML4E]      : ', 0
Ept.PdpteMsg                    db '[PDPTE]      : ', 0
Ept.PdeMsg                      db '[PDE]        : ', 0
Ept.PteMsg                      db '[PTE]        : ', 0
Ept.NotPresentMsg               db '[Not present]: ', 0
Ept.NestPml4eMsg                db '---> [PML4E]      : ', 0
Ept.NestPdpteMsg                db '---> [PDPTE]      : ', 0
Ept.NestPdeMsg                  db '---> [PDE]        : ', 0
Ept.NestPteMsg                  db '---> [PTE]        : ', 0
Ept.NestNotPresentMsg           db '---> [Not present]: ', 0

Ept.EntryMsg                    dd Ept.NotPresentMsg, Ept.Pml4eMsg, Ept.PdpteMsg, Ept.PdeMsg, Ept.PteMsg, 0
Ept.NestEntryMsg                dd Ept.NestNotPresentMsg, Ept.NestPml4eMsg, Ept.NestPdpteMsg, Ept.NestPdeMsg, Ept.NestPteMsg, 0
Ept.GuestEntryMsg               dd Ept.Pml4eMsg, Ept.PdpteMsg, Ept.PdeMsg, Ept.PteMsg, 0
Ept.DumpPageFlag                dd 0
