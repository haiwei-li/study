

实时时钟: RTC 时钟, 用于提供年、月、日、时、分、秒和星期等的实时时间信息, 由后备电池供电, 当你晚上关闭系统和早上开启系统时, RTC 仍然会保持正确的时间和日期. 

系统时钟: 是一个存储于系统内存中的逻辑时钟. 用于系统的计算, 比如超时产生的中断异常, 超时计算就是由系统时钟计算的. 这种时钟在系统掉电或重新启动时每次会被清除.   

CPU 时钟: 即 CPU 的频率, 当然这里的时钟频率指的是工作频率, 即外频, 还有什么主频=外频×倍频, 这个网上资料一大堆, 就不介绍了. 




系统定时器, 不分体系结构, 都会有的, 依赖于驱动内核的时钟滴答, 时间片、进程执行被打断执行调度程序都依赖这个时钟滴答, HZ 、jffes 都是这个时钟的概念, 这个时钟对硬件的要求就是可编程, 让它按照固定的 HZ 发时钟中断就行了, 默认是占用 IRQ0 中断线

rtc 实时时钟, 体系结构相关的, 一般提供开机时墙上时钟, 断电不丢失, 也可以当作一个普通定时器用, 硬要用 rtc 来实现上面那个系统定时器需要的时钟中断也行





RTC 主要提供日历时间(墙上时间)

PIT 是可编程控制的硬件, 使其按照编程指定的 HZ 发出中断

在 IRQ0 上的中断被 OS 当作系统时钟中断, 内核定时器依赖这个系统时钟, 所以精度最高只能是 1/HZ 

一般 RTC 也能够定时产生时钟中断, 实现 pit 的功能, PC 上即是如此. rtc 通过 8254 时钟芯片分频后当作系统时钟. 

一般用户编程, sleep usleep 等都没有直接操作硬件, 还是靠软件的内核定时器实现的



RTC 时间是单独的一个模块, 有备用电池, 关机后, 它照样运行

系统在系统的时候, 会从 RTC 读出时间, 从而作为系统时间. 

关机的同时会去重写 RTC 时间

系统定时器使用的是系统时间. 

一般都不会去使用 RTC 时间, 而只是从系统获得时间来定时




# 参考

https://www.cnblogs.com/jingzhishen/p/4225765.htm

https://bbs.csdn.net/topics/330114794

http://blog.sina.com.cn/s/blog_68f909c30100pli7.html

http://hi.baidu.com/jackfrued/item/e245b029bf7e4a0b42634aa0

