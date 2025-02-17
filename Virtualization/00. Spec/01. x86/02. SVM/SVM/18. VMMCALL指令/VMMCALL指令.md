VMMCALL Instruction

该指令是作为guest明确调用VMM的一种方式.  不执行CPL检查, 因此VMM可以决定是否在用户级别将此指令合法化. 

如果未拦截VMMCALL指令, 则该指令将引发#UD异常. 