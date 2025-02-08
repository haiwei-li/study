
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 前景回顾](#1-前景回顾)
  - [1.1 进程调度](#11-进程调度)
  - [1.2 进程的分类](#12-进程的分类)
  - [1.3 linux 调度器的演变](#13-linux-调度器的演变)
  - [1.4 Linux 的调度器组成](#14-linux-的调度器组成)
- [2 cfs 完全公平调度器](#2-cfs-完全公平调度器)
  - [2.1 CFS 调度器类 fair_sched_class](#21-cfs-调度器类-fair_sched_class)
  - [2.2 cfs 的就绪队列](#22-cfs-的就绪队列)
- [3 参考](#3-参考)

<!-- /code_chunk_output -->

Linux 进程调度 CFS 调度器

| 日期 | 内核版本 | 架构| 作者 | GitHub| CSDN |
| ------- |:-------:|:-------:|:-------:|:-------:|:-------:|
| 2016-06-14 | [Linux-4.6](http://lxr.free-electrons.com/source/?v=4.6) | X86 & arm | [gatieme](http://blog.csdn.net/gatieme) | [LinuxDeviceDrivers](https://github.com/gatieme/LDD-LinuxDeviceDrivers) | [Linux 进程管理与调度](http://blog.csdn.net/gatieme/article/category/6225543) |


# 1 前景回顾
-------


##1.1 进程调度
-------


内存中保存了对每个进程的唯一描述, 并通过若干结构与其他进程连接起来.


**调度器**面对的情形就是这样, 其任务是在程序之间共享 CPU 时间, 创造并行执行的错觉, 该任务分为两个不同的部分, 其中一个涉及**调度策略**, 另外一个涉及**上下文切换**.




##1.2 进程的分类
-------

linux 把进程区分为**实时进程**和**非实时进程**, 其中非实时进程进一步划分为交互式进程和批处理进程

根据进程的不同分类 Linux 采用不同的调度策略.

对于实时进程, 采用 FIFO, Round Robin 或者 Earliest Deadline First (EDF)最早截止期限优先调度算法|的调度策略.



##1.3 linux 调度器的演变
-------


| 字段 | 版本 |
| ------------- |:-------------:|
| O(n)的始调度算法 | linux-0.11~2.4 |
| O(1)调度器 | linux-2.5 |
| CFS 调度器 | linux-2.6~至今 |


##1.4 Linux 的调度器组成
-------


**2 个调度器**

可以用两种方法来激活调度

* 一种是直接的, 比如进程打算睡眠或出于其他原因放弃 CPU

* 另一种是通过周期性的机制, 以固定的频率运行, 不时的检测是否有必要

因此当前 linux 的调度程序由两个调度器组成: **主调度器**, **周期性调度器**(两者又统称为**通用调度器(generic scheduler)**或**核心调度器(core scheduler)**)

并且每个调度器包括两个内容: **调度框架**(其实质就是两个函数框架)及**调度器类**



**6 种调度策略**

linux 内核目前实现了 6 中调度策略(即调度算法), 用于对不同类型的进程进行调度, 或者支持某些特殊的功能

* SCHED_NORMAL 和 SCHED_BATCH 调度普通的非实时进程

* SCHED_FIFO 和 SCHED_RR 和 SCHED_DEADLINE 则采用不同的调度策略调度实时进程

* SCHED_IDLE 则在系统空闲时调用 idle 进程.



**5 个调度器类**

而依据其调度策略的不同实现了 5 个调度器类, 一个调度器类可以用一种种或者多种调度策略调度某一类进程, 也可以用于特殊情况或者调度特殊功能的进程.


其所属进程的优先级顺序为

```c
stop_sched_class -> dl_sched_class -> rt_sched_class -> fair_sched_class -> idle_sched_class
```

**3 个调度实体**

调度器不限于调度进程, 还可以调度更大的实体, 比如实现组调度.

这种一般性要求调度器不直接操作进程, 而是处理可调度实体, 因此需要一个通用的数据结构描述这个调度实体,即 seched_entity 结构, 其实际上就代表了一个调度对象, 可以为一个进程, 也可以为一个进程组.

linux 中针对当前可调度的实时和非实时进程, 定义了类型为 seched_entity 的 3 个调度实体

* sched_dl_entity 采用 EDF 算法调度的实时调度实体

* sched_rt_entity 采用 Roound-Robin 或者 FIFO 算法调度的实时调度实体 rt_sched_class

* sched_entity 采用 CFS 算法调度的普通非实时进程的调度实体




#2 cfs 完全公平调度器
-------

##2.1 CFS 调度器类 fair_sched_class
-------

CFS 完全公平调度器的调度器类叫 fair_sched_class, 其定义在[kernel/sched/fair.c, line 8521](http://lxr.free-electrons.com/source/kernel/sched/fair.c#L8521), 它是我们熟知的是 struct  sched_class 调度器类类型, 将我们的 CFS 调度器与一些特定的函数关联起来

```c
/*
 * All the scheduling class methods:
 */
const struct sched_class fair_sched_class = {
        /* 下个优先级的调度类, 所有的调度类通过 next 链接在一个链表中 */
        .next                   = &idle_sched_class,
        .enqueue_task           = enqueue_task_fair,
        .dequeue_task           = dequeue_task_fair,
        .yield_task             = yield_task_fair,
        .yield_to_task          = yield_to_task_fair,

        .check_preempt_curr     = check_preempt_wakeup,

        .pick_next_task         = pick_next_task_fair,
        .put_prev_task          = put_prev_task_fair,

#ifdef CONFIG_SMP
        .select_task_rq         = select_task_rq_fair,
        .migrate_task_rq        = migrate_task_rq_fair,

        .rq_online              = rq_online_fair,
        .rq_offline             = rq_offline_fair,

        .task_waking            = task_waking_fair,
        .task_dead              = task_dead_fair,
        .set_cpus_allowed       = set_cpus_allowed_common,
#endif

        .set_curr_task          = set_curr_task_fair,
        .task_tick              = task_tick_fair,
        .task_fork              = task_fork_fair,

        .prio_changed           = prio_changed_fair,
        .switched_from          = switched_from_fair,
        .switched_to            = switched_to_fair,

        .get_rr_interval        = get_rr_interval_fair,

        .update_curr            = update_curr_fair,

#ifdef CONFIG_FAIR_GROUP_SCHED
        .task_move_group        = task_move_group_fair,
#endif
};
```

| 成员 | 描述 |
| ------------- |:-------------:|
| enqueue\_task | 向**就绪队列**中**添加一个进程**,某个任务**进入可运行状态时**, 该函数将得到**调用**. 它将调度实体(进程)**放入红黑树**中, 并对**nr\_running**变量加 1 |
| dequeue\_task | 将一个进程从**就就绪队列**中**删除**,当某个任务**退出可运行状态**时调用该函数, 它将**从红黑树中去掉对应的调度实体**, 并从 **nr\_running** 变量中减 1 |
| yield\_task | 在进程想要资源**放弃对处理器的控制权**的时, 可使用在**sched\_yield 系统调用**, 会调用内核 API yield\_task 完成此工作. **compat\_yield sysctl 关闭**的情况下, 该函数实际上执行**先出队后入队**; 在这种情况下, 它将调度实体放在**红黑树的最右端** |
| check\_preempt\_curr | 该函数将**检查当前运行的任务是否被抢占**. 在**实际抢占正在运行的任务之前**, CFS 调度程序模块将**执行公平性测试**. 这**将驱动唤醒式(wakeup)抢占** |
| pick\_next\_task | 该函数**选择**接下来要运行的最合适的进程 |
| put\_prev\_task | 用另一个进程**代替当前运行的进程** |
| set\_curr\_task | 当任务**修改其调度类或修改其任务组**时, 将调用这个函数 |
| task\_tick | 在**每次激活周期调度器**时, 由**周期性调度器调用**, 该函数通常调用自 time tick 函数; 它**可能引起进程切换**. 这将驱动运行时(running)抢占 |
| task\_new | 内核调度程序为调度模块提供了管理新任务启动的机会,用于建立 fork 系统调用和调度器之间的关联, 每次**新进程建立**后,则用**new\_task 通知调度器**,CFS 调度模块使用它进行组调度, 而用于**实时任务的调度模块则不会使用**这个函数 |


##2.2 cfs 的就绪队列

**就绪队列**是**全局调度器**许多**操作的起点**, 但是**进程并不是由就绪队列直接管理**的, **调度管理**是**各个调度器**的职责, 因此在**各个就绪队列**中嵌入了**特定调度类的子就绪队列**(cfs 的顶级调度就队列 struct cfs\_rq, 实时调度类的就绪队列 struct rt\_rq 和 deadline 调度类的就绪队列 struct dl\_rq

```c
/* CFS-related fields in a runqueue */
/* CFS 调度的运行队列, 每个 CPU 的 rq 会包含一个 cfs_rq, 而每个组调度的 sched_entity 也会有自己的一个 cfs_rq 队列 */
struct cfs_rq {
 /* CFS 运行队列中所有进程的总负载 */
    struct load_weight load;
 /*
     *  nr_running: cfs_rq 中调度实体数量
     *  h_nr_running: 只对进程组有效, 其下所有进程组中 cfs_rq 的 nr_running 之和
 */
    unsigned int nr_running, h_nr_running;

    u64 exec_clock;

 /*
     * 当前 CFS 队列上最小运行时间, 单调递增
     * 两种情况下更新该值:
     * 1、更新当前运行任务的累计运行时间时
     * 2、当任务从队列删除去, 如任务睡眠或退出, 这时候会查看剩下的任务的 vruntime 是否大于 min_vruntime, 如果是则更新该值.
     */

    u64 min_vruntime;
#ifndef CONFIG_64BIT
    u64 min_vruntime_copy;
#endif
 /* 该红黑树的 root */
    struct rb_root tasks_timeline;
     /* 下一个调度结点(红黑树最左边结点, 最左边结点就是下个调度实体) */
    struct rb_node *rb_leftmost;

    /*
     * 'curr' points to currently running entity on this cfs_rq.
     * It is set to NULL otherwise (i.e when none are currently running).
  * curr: 当前正在运行的 sched_entity(对于组虽然它不会在 cpu 上运行, 但是当它的下层有一个 task 在 cpu 上运行, 那么它所在的 cfs_rq 就把它当做是该 cfs_rq 上当前正在运行的 sched_entity)
     * next: 表示有些进程急需运行, 即使不遵从 CFS 调度也必须运行它, 调度时会检查是否 next 需要调度, 有就调度 next
     *
     * skip: 略过进程(不会选择 skip 指定的进程调度)
     */
    struct sched_entity *curr, *next, *last, *skip;

#ifdef  CONFIG_SCHED_DEBUG
    unsigned int nr_spread_over;
#endif

#ifdef CONFIG_SMP
    /*
     * CFS load tracking
     */
    struct sched_avg avg;
    u64 runnable_load_sum;
    unsigned long runnable_load_avg;
#ifdef CONFIG_FAIR_GROUP_SCHED
    unsigned long tg_load_avg_contrib;
#endif
    atomic_long_t removed_load_avg, removed_util_avg;
#ifndef CONFIG_64BIT
    u64 load_last_update_time_copy;
#endif

#ifdef CONFIG_FAIR_GROUP_SCHED
    /*
     *   h_load = weight * f(tg)
     *
     * Where f(tg) is the recursive weight fraction assigned to
     * this group.
     */
    unsigned long h_load;
    u64 last_h_load_update;
    struct sched_entity *h_load_next;
#endif /* CONFIG_FAIR_GROUP_SCHED */
#endif /* CONFIG_SMP */

#ifdef CONFIG_FAIR_GROUP_SCHED
    /* 所属于的 CPU rq */
    struct rq *rq;  /* cpu runqueue to which this cfs_rq is attached */

    /*
     * leaf cfs_rqs are those that hold tasks (lowest schedulable entity in
     * a hierarchy). Non-leaf lrqs hold other higher schedulable entities
     * (like users, containers etc.)
     *
     * leaf_cfs_rq_list ties together list of leaf cfs_rq's in a cpu. This
     * list is used during load balance.
     */
    int on_list;
    struct list_head leaf_cfs_rq_list;
    /* 拥有该 CFS 运行队列的进程组 */
    struct task_group *tg;  /* group that "owns" this runqueue */

#ifdef CONFIG_CFS_BANDWIDTH
    int runtime_enabled;
    u64 runtime_expires;
    s64 runtime_remaining;

    u64 throttled_clock, throttled_clock_task;
    u64 throttled_clock_task_time;
    int throttled, throttle_count;
    struct list_head throttled_list;
#endif /* CONFIG_CFS_BANDWIDTH */
#endif /* CONFIG_FAIR_GROUP_SCHED */
};
```

| 成员 | 描述 |
| ------------- |:-------------:|
| nr\_running | 队列上**可运行进程的数目**
| load | **就绪队列**上可运行进程的**累计负荷权重** |
| min\_vruntime | 跟踪记录队列上所有进程的**最小虚拟运行时间**. 这个值是实现与就绪队列相关的虚拟时钟的基础 |
| tasks\_timeline | 用于在**按时间排序**的**红黑树**中管理所有进程 |
| rb\_leftmost | 总是设置为指向红黑树最左边的节点, 即需要被调度的进程. 该值其实可以可以通过病例红黑树获得, 但是将这个值存储下来可以减少搜索红黑树花费的平均时间 |
| curr | 当前正在运行的 sched\_entity(对于组虽然它不会在 cpu 上运行, 但是当它的下层有一个 task 在 cpu 上运行, 那么它所在的 cfs\_rq 就把它当做是该 cfs\_rq 上当前正在运行的 sched\_entity |
| next | 表示有些进程急需运行, 即使不遵从 CFS 调度也必须运行它, 调度时会检查是否 next 需要调度, 有就调度 next |
| skip | 略过进程(不会选择 skip 指定的进程调度) |


#3 参考
-------

[Linux 进程组调度机制分析](http://www.oenhan.com/task-group-sched)

[ Linux 内核学习笔记(一)CFS 完全公平调度类 ](http://blog.chinaunix.net/uid-24757773-id-3266304.html)

[CFS 调度器学习笔记](http://blog.csdn.net/melong100/article/details/6329201)


[linux 调度器(五)——进程管理与 CFS](http://blog.csdn.net/wudongxu/article/details/8574737)

[CFS 进程调度](http://blog.csdn.net/arriod/article/details/7033895)


[理解 CFS 组调度](http://www.360doc.com/content/15/1006/18/18252487_503643269.shtml)

[从几个问题开始理解 CFS 调度器](http://linuxperf.com/?p=42)


[Linux 任务调度策略](http://blog.csdn.net/mtofum/article/details/44108043)

[Linux 内核学习 6: 内存管理(2)-进程地址空间](http://blog.csdn.net/gzbaishabi/article/details/39371523)