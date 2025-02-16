结合 书籍《x86/x64 体系探索及编程》

书中例子和工具: http://www.mouseos.com/books/x86-64/

http://www.broadview.com.cn/book/1129

- sources: 文件里包括了本书所有章节的完整源码
- merge: 文件里包括了本书实验里所使用的工具


实验清单:

1. 实验1-1: 测试 byte 内的 bit 排列.

2. 实验1-2: 打印各种编码及信息.

3. 实验2-1: hello world 程序.

4. 实验2-2: 测试 les 指令.

5. 实验3-1: 使用 nasm 生成空白映像.

6. 实验3-2: 在真实机器上测试 boot 代码.

7. 实验3-3: 测试分从 floppy 和 hard disk 启动.

8. 实验4-1: 测试是否支持 CPUID 指令.

9. 实验4-2: 获得 basic 和 extended 功能号.

10. 实验4-3: 分别使用 0Dh 和 0Eh, 以及 80000008h 和 80000009h 来运行获得信息.

11. 实验4-4: 获得处理器的 DisplayFamily 与 DisplayModel.

12. 实验4-5: 查看 CPU 的 cache line size 和 Maximum logic processor.

13. 实验4-6: 使用 CPUID.EAX=02H 查看 cache 及 TLB 信息.

14. 实验4-7: 使用 CPUID.EAX=04H/ECX=n 来查看 cache 及 TLB 信息.

15. 实验5-1: 尝试改变 IOPL 和 IF 标志位(p88 页)

16. 实验5-2: 利用 IO Bitmap 的设置来决定 IO 空间访问权(p89 页)

17. 实验5-3: 实现一个 single-debug 例子.

18. 实验5-4: 测试 Alignment Check 功能.

19. 实验5-5: 测试 sti 指令.

20. 实验6-1: 测试在 TS=1, EM=1 时, 对执行 X87FPU 和 MMX/SSE 指令的影响.

21. 实验6-2: 测试在 CD=0, NW=1.

22. 实验6-3: 测试 CR4.TSD 对 RDTSC 和 RDTSCP 指令的影响.

23. 实验6-4: 检查处理器对扩展功能的支持, 以及 CR0 和 CR4 当前的设置.

24. 实验6-5: 测试 long-mode 支持度.

25. 实验7-1: 测试 Fix64K 区域的 memory 类型.

26. 实验7-2: 枚举出所有的 Variable-range 区域及类型.

27. 实验7-3: 测试 SYSENTER/SYSEXIT 指令.

28. 实验7-4: 对 MONITOR/MWAIT 指令进行 disable 看看结果如何. 接下来尝试修改监视的 line size 查看结果如何.

29. 实验8-1: 将 IVT 位置重定位在 600H 地址上.

30. 实验8-2: 在实模式下使用 4G 的空间

31. 实验9-1: 在打开 D_OPEN 和关闭 O_OPEN 两种情况下进行对 SMRAM 区域的探测, 以及测试 SMI handler.

32. 实验10-1: 使用 call 指令进行任务切换, 并使用 iret 指令切换回来.

33. 实验10-2: 使用 TSS 从 0 级切换到 3 级, 再切换回 0 级.

34. 实验10-3: 伪造一个任务嵌套环境, 使用 iret 指令发起任务切换.

35. 实验10-4: 使用 Task-gate 进行任务切换.

36. 实验10-5: 编写一个中断服务例程.

37. 实验10-6: 在 Interrupt handler 里使用 IST 指针.

38. 实验10-7: 测试 INTO、INT3, 以及 BOUND 指令.

39. 实验10-8: 从 64 位里返回到 compatibility 模式.

40. 实验10-9: 从 compatibility 里返回到 64 位模式.

41. 实验10-10: 使用 IRET 指令进行切换.

42. 实验10-11: 测试 SYSENTER/SYSEXIT 指令.

43. 实验10-12: 测试三个版本的系统服务例程.

44. 实验11-1: 得到 MAXPHYADDR 值.

45. 实验11-2: 使用与测试 32 位 paging.

46. 实验11-3: 使用与测试 PAE paging.

47. 实验11-4: 在 #PF handler 里修复由 XD 引起的错误.

48. 实验11-5: 使用和测试 SMEP 功能.

49. 实验11-6: 使用和测试 IA-32e paging 模式.

50. 实验11-7: 一个未刷新 TLB 产生的后果.

51. 实验11-8: 当 XD 由 0 修改为 1 时的情形.

52. 实验12-1: 直接从实模式转入到 long-mode.

53. 实验12-2: 从 long-mode 返回到实模式中.

54. 实验13-1: 测试 general detect 产生的 #DB 异常.

55. 实验13-2: 测试执行断点指令产生的 #DB 异常.

56. 实验13-3: 测试 single-step 与 general detect 条件.

57. 实验13-4: 测试 single-step 与执行断点条件同时触发.

58. 实验13-5: 测试 general detect 与执行断点条件同时触发.

59. 实验13-6: 测试多个条件同时触发.

60. 实验13-7: 测试数据断点的有效范围.

61. 实验13-8: 测试 rep movsb 中的数据断点.

62. 实验13-9: 测试 I/O 断点.

63. 实验13-10: 测试 task switch 时的 debug 异常.

64. 实验14-1: 使用 LBR 捕捉 branch trace 记录.

65. 实验14-2: 观察 LBR stack.

66. 实验14-3: 过滤 near relative call/ret 分支.

67. 实验14-4: 测试 jmp 分支的过滤条件.

68. 实验14-5: 观察 #DB 异常下的 LBR 机制.

69. 实验14-6: 测试 64 位模式下的 LBR stack.

70. 实验14-7: 测试 64 位下过滤 CPL=0 的记录.

71. 实验14-8: 测试 single-step on branch.

72. 实验14-9: 测试环形回路 BTS buffer 的工作.

73. 实验14-10: 测试 BTS buffer 满时的 DS 中断.

74. 实验14-11: 测试 BTS buffer 的过滤功能.

75. 实验14-12: 测试 64 位模式下的 BTS 机制.

76. 实验14-13: 在 64 位模式下统计 PMI handler 调用次数.

77. 实验15-1: 枚举 CPUID 0A leaf 信息.

78. 实验15-2: 测试 IA32_PMC0 计数器.

79. 实验15-3: 测试 counter 溢出时的 PMI 中断.

80. 实验15-4: 测试在 PMI 中冻结 counter 机制.

81. 实验15-5: 测试 PEBS 中断.

82. 实验15-6: 测试 64 位模式下的 PEBS 中断.

83. 实验15-7: 测试 PEBS buffer 满时中断.

84. 实验15-8: 测试 PMI 与 PEBS 中断同时触发.

85. 实验15-9: 多个 PMI 同时触发.

86. 实验15-10: 测试 load latency 监控事件.

87. 实验15-11: 使用 Fixed 计数器.

88. 实验15-12: 对比 TSC 与 CPU_CLK_UNHALTED.REF 事件.

89. 实验15-13: 测量 CPI 值.


90. 实验16-1: 产生一个 #DF 异常.

91. 实验17-1: 观察 IMR、IRR 和 ISR 寄存器.

92. 实验17-2: 测试 special mask mode 模式.

93. 实验18-1: 检测是否支持 local APIC 与 x2APIC.

94. 实验18-2: 测试 APIC base 的重定位.

95. 实验18-3: 打印 local APIC 寄存器列表.

96. 实验18-4: 从 x2APIC ID 里提取 Package_ID、Core_ID 及 SMT_ID 值.

97. 实验18-5: 从 xAPIC ID 里提取 Package/Core/SMT ID
值.

98. 实验18-6: 枚举所有的 processor 和 APIC ID 值.

99. 实验18-7: 给 APIC ID 为 01 的处理器发送 IPI 消息.

100. 实验18-8: 广播 IPI 消息到 system bus 上所有处理器.

101. 实验18-9: 使用 logical 目标模式发送 IPI.

102. 实验18-10: system bus 上处理器初始化及相互通信.

103. 实验18-11: 测试 APIC timer 的 one-shot 模式.

104. 实验18-12: 测试 IPI 消息中的 APIC error 中断.

105. 实验18-13: 通过 LINT0 屏蔽来自 8259 控制器的中断请求.

106. 实验18-14: 通过 LINT1 屏蔽来自外部的 NMI 请求.

107. 实验18-15: 测试 logical processor 1 的 PMI.

108. 实验19-1: 使用 I/O APIC 处理键盘中断.

109. 实验19-2: 使用 HPET timer 的 10 分钟计时器.

110. 实验20-1: 打印 x87 FPU 的全部信息.

111. 实验20-2: 打印 status 寄存器信息及 stack 明细信息.

112. 实验20-3: 测试 unordered 比较操作.

113. 实验20-4: 测试 #MF handler 和重启指令.

114. 实验20-5: 测试 DOS compatibility 模式.

115. 实验20-6: 测试进程切换中的 x87 FPU 延时切换.

116. 实验21-1: 测试 #XM 异常 handler.

117. 实验21-2: 使用 string 处理指令解决寻找首个不同字符位置.

118. 实验21-3: 测试使用 sse4 版本的 strlen(​)函数.


