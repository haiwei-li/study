
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 前景回顾](#1-前景回顾)
  - [1.1 CFS 调度算法](#11-cfs-调度算法)
  - [1.2 CFS 的 pick_next_fair 选择下一个进程](#12-cfs-的-pick_next_fair-选择下一个进程)
  - [1.3 今日看点--(CFS 如何处理周期性调度器)](#13-今日看点-cfs-如何处理周期性调度器)
- [2 CFS 的周期性调度](#2-cfs-的周期性调度)
  - [2.1 task_tick_fair 与周期性调度](#21-task_tick_fair-与周期性调度)
  - [2.2 entity_tick 函数](#22-entity_tick-函数)
  - [2.3 check_preempt_tick 函数](#23-check_preempt_tick-函数)
  - [2.4  resched_curr 设置重调度标识 TIF_NEED_RESCHED](#24--resched_curr-设置重调度标识-tif_need_resched)
- [3 总结](#3-总结)

<!-- /code_chunk_output -->

Linux CFS 调度器之 task_tick_fair 处理周期性调度器
=======


| 日期 | 内核版本 | 架构| 作者 | GitHub| CSDN |
| ------- |:-------:|:-------:|:-------:|:-------:|:-------:|
| 2016-07-4 | [Linux-4.6](http://lxr.free-electrons.com/source/?v=4.6) | X86 & arm | [gatieme](http://blog.csdn.net/gatieme) | [LinuxDeviceDrivers](https://github.com/gatieme/LDD-LinuxDeviceDrivers) | [Linux 进程管理与调度](http://blog.csdn.net/gatieme/article/details/51456569) |


CFS 负责处理普通非实时进程, 这类进程是我们 linux 中最普遍的进程


#1 前景回顾
-------


##1.1 CFS 调度算法
-------

**CFS 调度算法的思想**

理想状态下每个进程都能获得相同的时间片, 并且同时运行在 CPU 上, 但实际上一个 CPU 同一时刻运行的进程只能有一个. 也就是说, 当一个进程占用 CPU 时, 其他进程就必须等待. CFS 为了实现公平, 必须惩罚当前正在运行的进程, 以使那些正在等待的进程下次被调度.

##1.2 CFS 的 pick_next_fair 选择下一个进程
-------

前面的一节中我们讲解了 CFS 的 pick_next 操作**pick_next_task_fair 函数**, 他从当前运行队列上找出一个最优的进程来抢占处理器 ,一般来说这个最优进程总是**红黑树的最左进程 left 结点(其 vruntime 值最小)**, 当然如果挑选出的进程正好是队列是上需要**被调过调度的 skip**, 则可能需要进一步读取**红黑树的次左结点 second**, 而同样**curr 进程**可能 vruntime 与 cfs_rq 的 min_vruntime 小, 因此它可能更渴望得到处理器, 而**last 和 next 进程**由于刚被唤醒也应该尽可能的补偿.

**主调度器 schedule**在选择最优的进程抢占处理器的时候, 通过__schedule 调用**全局的 pick_next_task**函数, 在**全局的 pick_next_task**函数中, 按照 stop > dl > rt > cfs > idle 的顺序依次从**各个调度器类中 pick_next 函数**, 从而选择一个最优的进程.

##1.3 今日看点--(CFS 如何处理周期性调度器)
-------

周期性调度器的工作由 scheduler_tick 函数完成(定义在[kernel/sched/core.c, line 2910](http://lxr.free-electrons.com/source/kernel/sched/core.c?v=4.6#L2910)), 在 scheduler_tick 中周期性调度器通过调用 curr 进程所属调度器类 sched_class 的 task_tick 函数完成周期性调度的工作

周期调度的工作形式上 sched_class 调度器类的 task_tick 函数完成, CFS 则对应 task_tick_fair 函数, 但实际上工作交给 entity_tick 完成.


#2 CFS 的周期性调度
-------

##2.1 task_tick_fair 与周期性调度
-------

CFS 完全公平调度器类通过 task_tick_fair 函数完成周期性调度的工作, 该函数定义在[kernel/sched/fair.c?v=4.6#L8119](http://lxr.free-electrons.com/source/kernel/sched/fair.c?v=4.6#L8119)

```c
/*
 * scheduler tick hitting a task of our scheduling class:
 */
static void task_tick_fair(struct rq *rq, struct task_struct *curr, int queued)
{
    struct cfs_rq *cfs_rq;
    /*  获取到当前进程 curr 所在的调度实体  */
    struct sched_entity *se = &curr->se;

    /* for_each_sched_entity
     * 在不支持组调度条件下, 只循环一次
     * 在组调度的条件下, 调度实体存在层次关系,
     * 更新子调度实体的同时必须更新父调度实体  */
    for_each_sched_entity(se)
    {
        /*  获取当当前运行的进程所在的 CFS 就绪队列  */
        cfs_rq = cfs_rq_of(se);
        /*  完成周期性调度  */
        entity_tick(cfs_rq, se, queued);
    }

    if (static_branch_unlikely(&sched_numa_balancing))
        task_tick_numa(rq, curr);
}
```

我们可以看到, CFFS 周期性调度的功能实际上是委托给 entity_tick 函数来完成的


##2.2 entity_tick 函数
-------

在 task_tick_fair 中, 内核将 CFS 周期性调度的实际工作交给了 entity_tick 来完成, 该函数定义在[kernel/sched/fair.c, line 3470](http://lxr.free-electrons.com/source/kernel/sched/fair.c?v=4.6#L3470)中, 如下所示

```c
static void
entity_tick(struct cfs_rq *cfs_rq, struct sched_entity *curr, int queued)
{
    /*
     * Update run-time statistics of the 'current'.
     */
    update_curr(cfs_rq);

    /*
     * Ensure that runnable average is periodically updated.
     */
    update_load_avg(curr, 1);
    update_cfs_shares(cfs_rq);

#ifdef CONFIG_SCHED_HRTICK
    /*
     * queued ticks are scheduled to match the slice, so don't bother
     * validating it and just reschedule.
     */
    if (queued) {
        resched_curr(rq_of(cfs_rq));
        return;
    }
    /*
     * don't let the period tick interfere with the hrtick preemption
     */
    if (!sched_feat(DOUBLE_TICK) &&
            hrtimer_active(&rq_of(cfs_rq)->hrtick_timer))
        return;
#endif

    if (cfs_rq->nr_running > 1)
        check_preempt_tick(cfs_rq, curr);
}
```


首先, 一如既往的使用 update_curr 来更新统计量

接下来是 hrtimer 的更新, 这些由内核通过参数 CONFIG_SCHED_HRTICK 开启

然后如果 cfs 就绪队列中进程数目 nr_running 少于两个(< 2)则实际上无事可做. 因为如果某个进程应该被抢占, 那么至少需要有另一个进程能够抢占它(即 cfs_rq->nr_running > 1)

如果进程的数目不少于两个, 则由 check_preempt_tick 作出决策

```c
    if (cfs_rq->nr_running > 1)
        check_preempt_tick(cfs_rq, curr);
```

##2.3 check_preempt_tick 函数
-------

在 entity_tick 中, 如果 cfs 的就绪队列中进程数目不少于 2, 说明至少需要有另外一个进程能够抢占当前进程, 此时内核交给 check_preempt_tick 作出决策. check_preempt_tick 函数定义在[kernel/sched/fair.c, line 3308](http://lxr.free-electrons.com/source/kernel/sched/fair.c?v=4.6#L3308)


```c
/*
 * Preempt the current task with a newly woken task if needed:
 */
static void
check_preempt_tick(struct cfs_rq *cfs_rq, struct sched_entity *curr)
{
    unsigned long ideal_runtime, delta_exec;
    struct sched_entity *se;
    s64 delta;

    /*  计算 curr 的理论上应该运行的时间  */
    ideal_runtime = sched_slice(cfs_rq, curr);

    /*  计算 curr 的实际运行时间
     *  sum_exec_runtime: 进程执行的总时间
     *  prev_sum_exec_runtime:进程在切换进 CPU 时的 sum_exec_runtime 值  */
    delta_exec = curr->sum_exec_runtime - curr->prev_sum_exec_runtime;

    /*  如果实际运行时间比理论上应该运行的时间长
     *  说明 curr 进程已经运行了足够长的时间
     *  应该调度新的进程抢占 CPU 了  */
    if (delta_exec > ideal_runtime)
    {
        resched_curr(rq_of(cfs_rq));
        /*
         * The current task ran long enough, ensure it doesn't get
         * re-elected due to buddy favours.
         */
        clear_buddies(cfs_rq, curr);
        return;
    }

    /*
     * Ensure that a task that missed wakeup preemption by a
     * narrow margin doesn't have to wait for a full slice.
     * This also mitigates buddy induced latencies under load.
     */
    if (delta_exec < sysctl_sched_min_granularity)
        return;

    se = __pick_first_entity(cfs_rq);
    delta = curr->vruntime - se->vruntime;

    if (delta < 0)
        return;

    if (delta > ideal_runtime)
        resched_curr(rq_of(cfs_rq));
}
```


check_preempt_tick 函数的目的在于, 判断是否需要抢占当前进程. 确保没有哪个进程能够比延迟周期中确定的份额运行得更长. 该份额对应的实际时间长度在 sched_slice 中计算.

而上一节我们提到, 进程在 CPU 上已经运行的实际时间间隔由 sum_exec_runtime - prev_sum_runtime 给出.


>还记得上一节,  在 set_next_entity 函数的最后, 将选择出的调度实体 se 的 sum_exec_runtime 保存在了 prev_sum_exec_runtime 中, 因为该调度实体指向的进程, 马上将抢占处理器成为当前活动进程, 在 CPU 上花费的实际时间将记入 sum_exec_runtime, 因此内核会在 prev_sum_exec_runtime 保存此前的设置. 要注意进程中的 sum_exec_runtime 没有重置. 因此差值 sum_exec_runtime - prev_sum_runtime 确实标识了在 CPU 上执行花费的实际时间.
>
>在处理周期性调度时, 这个差值就显得格外重要


因此抢占决策很容易做出决定, 如果检查发现当前进程运行需要被抢占, 那么通过 resched_task 发出重调度请求. 这会在 task_struct 中设置 TIF_NEED_RESCHED 标志, 核心调度器会在下一个适当的时机发起重调度.


其实需要抢占的条件有下面两种可能性

* curr 进程的实际运行时间 delta_exec 比期望的时间间隔 ideal_runtime 长

 此时说明 curr 进程已经运行了足够长的时间

* curr 进程与红黑树中最左进程 left 虚拟运行时间的差值大于 curr 的期望运行时间 ideal_runtime

 此时说明红黑树中最左结点 left 与 curr 节点更渴望处理器, 已经接近于饥饿状态, 这个我们可以这样理解, 相对于 curr 进程来说, left 进程如果参与调度, 其期望运行时间应该域 curr 进程的期望时间 ideal_runtime 相差不大, 而此时如果 curr->vruntime - se->vruntime > curr.ideal_runtime, 我们可以初略的理解为 curr 进程已经优先于 left 进程多运行了一个周期, 而 left 又是红黑树总最饥渴的那个进程, 因此 curr 进程已经远远领先于队列中的其他进程, 此时应该补偿其他进程.


如果检查需要发生抢占, 则内核通过 resched_curr(rq_of(cfs_rq))设置重调度标识, 从而触发延迟调度




##2.4  resched_curr 设置重调度标识 TIF_NEED_RESCHED
-------


周期性调度器并不显式进行调度, 而是采用了延迟调度的策略, 如果发现需要抢占, 周期性调度器就设置进程的重调度标识 TIF_NEED_RESCHED, 然后由主调度器完成调度工作.

>TIF_NEED_RESCHED 标识, 表明进程需要被调度, TIF 前缀表明这是一个存储在进程 thread_info 中 flag 字段的一个标识信息
>
>在内核的一些关键位置, 会检查当前进程是否设置了重调度标志 TLF_NEDD_RESCHED, 如果该进程被其他进程设置了 TIF_NEED_RESCHED 标志, 则函数重新执行进行调度

前面我们在 check_preempt_tick 中如果发现 curr 进程已经运行了足够长的时间, 其他进程已经开始饥饿, 那么我们就需要通过 resched_curr 来设置重调度标识 TIF_NEED_RESCHED


resched_curr 函数定义在[kernel/sched/core.c, line 446](http://lxr.free-electrons.com/source/kernel/sched/core.c#L446)中, 并没有什么复杂的工作, 其实就是通过 set_tsk_need_resched(curr);函数设置重调度标识



#3 总结
-------


周期性调度器的工作由**scheduler_tick 函数**完成(定义在[kernel/sched/core.c, line 2910](http://lxr.free-electrons.com/source/kernel/sched/core.c?v=4.6#L2910)), 在 scheduler_tick 中周期性调度器通过调用 curr 进程所属调度器类 sched_class 的 task_tick 函数完成周期性调度的工作

周期调度的工作形式上 sched_class 调度器类的 task_tick 函数完成, CFS 则对应**task_tick_fair 函数**, 但实际上工作交给**entity_tick**完成.

而 entity_tick 中则通过**check_preempt_tick**函数检查是否需要抢占当前进程 curr, 如果发现 curr 进程已经运行了足够长的时间, 其他进程已经开始饥饿, 那么我们就需要通过**resched_curr**函数来设置重调度标识 TIF_NEED_RESCHED


其中 check_preempt_tick 检查可抢占的条件如下

* curr 进程的实际运行时间 delta_exec 比期望的时间间隔 ideal_runtime 长, 此时说明 curr 进程已经运行了足够长的时间

* curr 进程与红黑树中最左进程 left 虚拟运行时间的差值大于 curr 的期望运行时间 ideal_runtime, 此时我们可以理解为 curr 进程已经优先于 left 进程多运行了一个周期, 而 left 又是红黑树总最饥渴的那个进程, 因此 curr 进程已经远远领先于队列中的其他进程, 此时应该补偿其他进程