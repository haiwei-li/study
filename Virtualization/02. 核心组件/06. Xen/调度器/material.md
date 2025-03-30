
https://wiki.xenproject.org/wiki/Category:Scheduler

Xen Project Schedulers: https://wiki.xenproject.org/wiki/Xen_Project_Schedulers

Xen的调度分析 (五) ——关于RTDS调度算法简介: https://www.cnblogs.com/linanwx/p/5383269.html

Xen的调度分析 (一) ——概览: https://www.cnblogs.com/linanwx/p/5355107.html

Xen调度分析-RT: https://blog.csdn.net/ytfy339784578/article/details/103946311

```shell
$ ls xen/common/sched
arinc653.c  boot-cpupool.c  compat.c  core.c  cpupool.c  credit2.c  credit.c  Kconfig  Makefile  null.c  private.h  rt.c

# grep -rni "scheduler sched_"
xen/common/sched/credit.c:2274:static const struct scheduler sched_credit_def = {
xen/common/sched/rt.c:1556:static const struct scheduler sched_rtds_def = {
xen/common/sched/null.c:1042:static const struct scheduler sched_null_def = {
xen/common/sched/credit2.c:4218:static const struct scheduler sched_credit2_def = {
xen/common/sched/arinc653.c:697:static const struct scheduler sched_arinc653_def = {
```

