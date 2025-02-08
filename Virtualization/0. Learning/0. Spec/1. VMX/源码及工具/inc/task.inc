;*************************************************
;* task.inc                                      *
;* Copyright (c) 2009-2013 µÀ÷æ                  *
;* All rights reserved.                          *
;*************************************************



%ifndef TASK_INC
%define TASK_INC

;;
;; task_table Ω·ππ
;;
struc TASK_TABLE
        .AccessLock             RESD            1
        .TaskQueue              RESQ            1
endstruc



%endif

