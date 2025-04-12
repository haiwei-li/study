Linux 进程退出详解
=======


| 日期 | 内核版本 | 架构| 作者 | GitHub| CSDN |
| ------- |:-------:|:-------:|:-------:|:-------:|:-------:|
| 2016-06-14 | [Linux-4.6](http://lxr.free-electrons.com/source/?v=4.6) | X86 & arm | [gatieme](http://blog.csdn.net/gatieme) | [LinuxDeviceDrivers](https://github.com/gatieme/LDD-LinuxDeviceDrivers) | [Linux 进程管理与调度](http://blog.csdn.net/gatieme/article/category/6225543) |

1. 调度器概述 introduction
2. 调度器演变 develop
3. 调度器的设计 design
4. 周期性调度器 periodic_scheduler
5. 主调度器 main_schedulrt
6. 优先级 priority
7. 抢占-内核抢占和用户抢占以及抢占的时机 preempt
8. 进程切换 context_switch
9. 完全公平调度器 cfs-设计
10. cfs-负荷权重
11. cfs-虚拟时钟
12. cfs-延迟跟踪
13. cfs-操作 pick_next_task
14. rt 实时调度器
15. dl 时调度器
16. stop 调度
17. idle 调度器
18. SMP 调度
19. 调度域和控制组

http://blog.csdn.net/b02042236/article/details/6076473
http://www.tuicool.com/articles/MjyANr
http://iamzhongyong.iteye.com/blog/1895728
http://blog.csdn.net/xiaofei0859/article/details/8113211



BFS
https://en.wikipedia.org/wiki/Brain_Fuck_Scheduler

http://blog.csdn.net/u201017971/article/details/50511511


http://baike.baidu.com/link?url=qO-044OZarVCuMDuioyhbYLswbB7MkyVwW3vPbWzHGE6j2-2X3IKIiXCUecABqkg9KCXSPCQ3Kc6IP26uCT0JK

Con Kolivas

http://www.ibm.com/developerworks/cn/linux/l-cn-bfs/


rifs 进程调度比起 bfs cfs 好在哪差在哪

交互性极佳, 特别是在大负载, 那种交互性差距很明显
吞吐量比 bfs 和 cfs 低一半, 但还是比 windows 高 1/3

要测试交互性的差距请用 mplayer 测,
要体验交互性大可以开 make -j512 然后看网页, 听音乐, 移动窗口.


