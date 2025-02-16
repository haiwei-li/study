; keycode.inc
; Copyright (c) 2009-2012 mik 
; All rights reserved.



%ifndef KEYCODE_INC
%define KEYCODE_INC


;----------------------------
; KEY ASCII CODE 
;----------------------------        
%define KEY_NULL                        0
%define KEY_ESC                         0x1b
%define KEY_BS                          0x08
%define KEY_TAB                         0x09
%define KEY_ENTER                       0x0d
%define KEY_FS                          0x1c
%define KEY_CTRL                        0x00
%define KEY_SHIFT                       0x0f
%define KEY_PRINTSCREEN                 0x00
%define KEY_ALT                         0x00
%define KEY_SPACE                       0x20
%define KEY_CAPS                        0x00
%define KEY_F1                          0x00
%define KEY_F2                          0x00
%define KEY_F3                          0x00
%define KEY_F4                          0x00
%define KEY_F5                          0x00
%define KEY_F6                          0x00
%define KEY_F7                          0x00
%define KEY_F8                          0x00
%define KEY_F9                          0x00
%define KEY_F10                         0x00
%define KEY_F11                         0x00
%define KEY_F12                         0x00
%define KEY_NUM                         0x00
%define KEY_SCROLL                      0x00
%define KEY_HOME                        0x00
%define KEY_PAGEUP                      0x00
%define KEY_UP                          0x00
%define KEY_PAGEDOWN                    0x00
%define KEY_END                         0x00
%define KEY_INSERT                      0x00
%define KEY_DEL                         0x00
%define KEY_LEFT                        0x00
%define KEY_RIGHT                       0x00
%define KEY_DOWN                        0x00
%define KEY_SUB                         0x00
%define KEY_ADD                         0x00
%define KEY_MUL                         0x00
%define KEY_DIV                         0x00



;------------------------------------------------------
; key scan code
;-------------------------------------------------------
%define NULL_SCAN_CODE                  0
%define ESC_SCAN_CODE                   0x01
%define BS_SCAN_CODE                    0x0e
%define TAB_SCAN_CODE                   0x0f
%define CTRL_SCAN_CODE                  0x1d
%define LSHIFT_SCAN_CODE                0x2a
%define RSHIFT_SCAN_CODE                0x36
%define PRINTSCREEN_SCAN_CODE           0x37
%define ALT_SCAN_CODE                   0x38
%define SPACE_SCAN_CODE                 0x39
%define CAPS_SCAN_CODE                  0x3a
%define F1_SCAN_CODE                    0x3b
%define F2_SCAN_CODE                    0x3c
%define F3_SCAN_CODE                    0x3d
%define F4_SCAN_CODE                    0x3e
%define F5_SCAN_CODE                    0x3f
%define F6_SCAN_CODE                    0x40
%define F7_SCAN_CODE                    0x41
%define F8_SCAN_CODE                    0x42
%define F9_SCAN_CODE                    0x43
%define F10_SCAN_CODE                   0x44
%define NUM_SCAN_CODE                   0x45
%define SCROLL_SCAN_CODE                0x46
%define HOME_SCAN_CODE                  0x47
%define PAGEUP_SCAN_CODE                0x49
%define UP_SCAN_CODE                    0x48
%define PAGEDOWN_SCAN_CODE              0x51
%define END_SCAN_CODE                   0x4f
%define INSERT_SCAN_CODE                0x52
%define DEL_SCAN_CODE                   0x53
%define LEFT_SCAN_CODE                  0x4b
%define RIGHT_SCAN_CODE                 0x4d
%define DOWN_SCAN_CODE                  0x50
%define SUB_SCAN_CODE                   0x4a
%define ADD_SCAN_CODE                   0x4e
%define MUL_SCAN_CODE                   0x37
%define DIV_SCAN_CODE                   0x35
%define ENTER_SCAN_CODE                 0x1c


%endif