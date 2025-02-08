;*************************************************
;* ErrorCode.inc                                 *
;* Copyright (c) 2009-2013 邓志                  *
;* All rights reserved.                          *
;*************************************************

%ifndef __ERRORCODE_INC
%define __ERRORCODE_INC

%define STATUS_SUCCESS                                  0
%define STATUS_UNSUCCESS                                1
%define STATUS_NO_RESOURCE                              80000001h
%define STATUS_PROCESSOR_INDEX_EXCEED                   80010001h

%define STATUS_NO_FOCUS                                 80020002h


;;
;; VMX 方面的错误码
;;
%define STATUS_VMXON_UNSUCCESS                          80020001h
%define STATUS_VMXOFF_UNSUCCESS                         80020002h
%define STATUS_VMX_UNEXPECT                             80020003h

;;
;; guest 方面的错误
;;
%define STATUS_GUEST_PAGING_ERROR                       81020001h


%endif