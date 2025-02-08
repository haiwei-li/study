;*************************************************
;* ScanCode.inc                                  *
;* Copyright (c) 2009-2013 µËÖ¾                  *
;* All rights reserved.                          *
;*************************************************


%ifndef _SCANCODE_INC
%define _SCANCODE_INC

%define SC_ESC                          01
%define SC_1                            02
%define SC_2                            03
%define SC_3                            04
%define SC_4                            05
%define SC_5                            06
%define SC_6                            07
%define SC_7                            08
%define SC_8                            09
%define SC_9                            0Ah
%define SC_0                            0Bh
%define SC_TAB                          0Fh                        
%define SC_CTRL                         1Dh
%define SC_LSHIFT                       2Ah
%define SC_RSHIFT                       36h
%define SC_PRTSC                        37h
%define SC_ALT                          38h
%define SC_SPACE                        39h
%define SC_CAPS                         3Ah
%define SC_F1                           3Bh
%define SC_F2                           3Ch
%define SC_F3                           3Dh
%define SC_F4                           3Eh
%define SC_F5                           3Fh
%define SC_F6                           40h
%define SC_F7                           41h
%define SC_F8                           42h
%define SC_F9                           43h
%define SC_F10                          44h
%define SC_NUM                          45h
%define SC_SCROLL                       46h
%define SC_HOME                         47h
%define SC_UP                           48h
%define SC_PGUP                         49h
%define SC_LEFT                         4Bh
;;%define SC_ENTER                        4Ch
%define SC_ENTER                        1Ch
%define SC_RIGHT                        4Dh
%define SC_END                          4Fh
%define SC_DOWN                         50h
%define SC_PGDN                         51h
%define SC_INS                          52h
%define SC_DEL                          53h

;;
;; ×ÖÄ¸
;;
%define SC_Q                            10h
%define SC_W                            11h
%define SC_E                            12h
%define SC_R                            13h
%define SC_T                            14h
%define SC_Y                            15h
%define SC_U                            16h
%define SC_I                            17h
%define SC_O                            18h
%define SC_P                            19h
%define SC_A                            1Eh
%define SC_S                            1Fh
%define SC_D                            20h
%define SC_F                            21h
%define SC_G                            22h
%define SC_H                            23h
%define SC_J                            24h
%define SC_K                            25h
%define SC_L                            26h
%define SC_Z                            2Ch
%define SC_X                            2Dh
%define SC_C                            2Eh
%define SC_V                            2Fh
%define SC_B                            30h
%define SC_N                            31h
%define SC_M                            32h



;;
;; ×Ö·û±êÊ¶
;;
%define CHAR_FLAG_BACKSLASH             1                               ;; ·´Ð±¸Ü



%endif