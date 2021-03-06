
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 内核线程](#1-内核线程)
	* [1.1 为什么需要内核线程](#11-为什么需要内核线程)
	* [1.2 内核线程概述](#12-内核线程概述)
	* [1.3 内核线程的进程描述符task\_struct](#13-内核线程的进程描述符task_struct)
* [2 内核线程的创建](#2-内核线程的创建)
	* [2.1 创建内核线程接口的演变](#21-创建内核线程接口的演变)
	* [2.2 2号进程kthreadd的诞生](#22-2号进程kthreadd的诞生)
		* [2.2.1 Workqueue机制](#221-workqueue机制)
		* [2.2.2 2号进程kthreadd](#222-2号进程kthreadd)
	* [2.3 kernel\_thread](#23-kernel_thread)
		* [2.3.1 早期实现](#231-早期实现)
	* [2.4 kthread\_create](#24-kthread_create)
	* [2.5 kthread\_run](#25-kthread_run)
* [3 内核线程的退出](#3-内核线程的退出)

<!-- /code_chunk_output -->

# 1 内核线程

## 1.1 为什么需要内核线程

Linux内核可以看作**一个服务进程**(管理软硬件资源，响应用户进程的种种合理以及不合理的请求)。

内核需要**多个执行流并行**，为了防止可能的阻塞，支持多线程是必要的。

**内核线程**就是**内核的分身**，一个分身可以处理一件特定事情。**内核线程的调度由内核负责**，一个内核线程处于阻塞状态时不影响其他的内核线程，因为其是调度的基本单位。

这与用户线程是不一样的。因为**内核线程只运行在内核态**

因此，它**只能使用大于PAGE\_OFFSET**（**传统的x86\_32上是3G**）的**地址空间**。

## 1.2 内核线程概述

**内核线程**是直接由**内核本身启动的进程**。**内核线程**实际上是将**内核函数**委托给**独立的进程**，它与内核中的其他进程"并行"执行。内核线程经常被称之为**内核守护进程**。

他们执行下列**任务**

- **周期性**地将**修改的内存页与页来源块设备同步**

- 如果**内存页很少使用**，则**写入交换区**

- 管理**延时动作**,　如**２号进程接手内核进程的创建**

- 实现**文件系统的事务日志**

**内核线程**主要有**两种类型**

1. 线程启动后一直**等待**，直至**内核请求线程执行某一特定操作**。

2. 线程启动后按**周期性间隔运行**，检测特定资源的使用，在用量超出或低于预置的限制时采取行动。

**内核线程**由**内核自身生成**，其**特点**在于

1. 它们在**CPU的管态执行**，而**不是用户态**。

2. 它们只可以访问**虚拟地址空间的内核部分**（**高于TASK\_SIZE的所有地址**），但**不能访问用户空间**

## 1.3 内核线程的进程描述符task\_struct

task\_struct进程描述符中包含**两个和进程地址空间**相关的字段mm,active\_mm

```c
struct task_struct

{
	// ...
	struct mm_struct *mm;
	struct mm_struct *avtive_mm;
	//...
};
```

大多数计算机上系统的**全部虚拟地址空间**分为**两个部分**:供**用户态程序访问的虚拟地址空间**和**供内核访问的内核空间**。每当内核**执行上下文切换**时,**虚拟地址空间**的**用户层部分都会切换**,以便当前运行的进程匹配,而**内核空间不会发生切换(！！！内核空间都是一样的**)。

对于**普通用户进程**来说，**mm**指向**虚拟地址空间(！！！)的用户空间部分**，而对于**内核线程**，**mm**为**NULL**。

这为优化提供了一些余地, 可遵循所谓的**惰性TLB处理(lazy TLB handing**)。**active\_mm**主要**用于优化**，由于**内核线程不与任何特定的用户层进程相关(！！！**)，内核并**不需要倒换虚拟地址空间的用户层部分**，保留旧设置即可。由于**内核线程之前**可能是**任何用户层进程在执行**，故**用户空间部分**的内容本质上是**随机**的，**内核线程**决**不能修改其内容**，故**将mm设置为NULL**，同时如果**切换出去**的是**用户进程**，内核将**原来进程的mm**存放在**新内核线程**的**active\_mm**中，因为**某些时候**内核必须知道**用户空间**当前包含了什么。

>为什么**没有mm指针**的**进程**称为**惰性TLB进程**?
>
>假如**内核线程之后运行的进程**与**之前**是**同一个**,在这种情况下,内核并**不需要修改用户空间地址表(！！！**)。地址转换后备缓冲器(即**TLB**)中的信息**仍然有效**。**只有**在**内核线程之后**,执行的**进程**是**与此前不同的用户层进程**时,**才需要切换**(并对应清除TLB数据)。

**内核线程**和**普通的进程**间的区别在于**内核线程没有独立的地址空间**，**mm指针被设置为NULL**；它**只在内核空间运行**，从来**不切换到用户空间**去；并且和普通进程一样，可以**被调度**，也可以**被抢占**。

# 2 内核线程的创建

## 2.1 创建内核线程接口的演变

内核线程可以通过两种方式实现：

- **古老的接口kernel\_create和daemonize**

将**一个函数**传递给**kernel\_thread**创建并初始化一个task，**该函数**接下来负责帮助内核**调用daemonize**已转换为**内核守护进程**，daemonize随后完成一些列操作,如该函数**释放其父进程的所有资源**，不然这些资源会一直锁定直到线程结束。阻塞信号的接收, 将**init用作守护进程的父进程**

- **更加现在的方法kthead\_create和kthread\_run**

创建内核更常用的方法是辅助函数kthread\_create，该函数创建一个新的内核线程。**最初线程是停止的**，需要使用**wake\_up\_process**启动它。

使用**kthread\_run**，与kthread\_create不同的是，其创建新线程后**立即唤醒它**，其本质就是先用**kthread\_create**创建一个内核线程，然后通过wake\_up\_process唤醒它

## 2.2 2号进程kthreadd的诞生

**早期的kernel\_create和daemonize接口**

在**早期的内核**中,提供了kernel\_create和daemonize接口,但是这种机制**操作复杂**而且**将所有的任务交给内核去完成**。

但是这种机制低效而且繁琐,将所有的操作塞给内核,我们创建内核线程的初衷不本来就是为了内核分担工作, 减少内核的开销的么

### 2.2.1 Workqueue机制

因此在linux-2.6以后,提供了更加方便的接口**kthead\_create**和**kthread\_run**,同时**将内核线程的创建操作延后**,交给一个**工作队列workqueue**,参见[http://lxr.linux.no/linux+v2.6.13/kernel/kthread.c#L21](http://lxr.linux.no/linux+v2.6.13/kernel/kthread.c#L21)，

Linux中的**workqueue机制**就是为了**简化内核线程的创建**。通过**kthread\_create**并不真正创建内核线程, 而是**将创建工作create work**插入到**工作队列**[**helper\_wq**](http://lxr.linux.no/linux+v2.6.11/kernel/kthread.c#L17)中,随后**调用workqueue的接口**就能**创建内核线程**。并且可以**根据当前系统CPU的个数(！！！)创建线程的数量**，使得**线程处理的事务**能够**并行化**。workqueue是内核中实现简单而有效的机制，他显然简化了内核daemon的创建，方便了用户的编程.

>**工作队列（workqueue**）是另外一种**将工作推后执行的形式**.工作队列可以把工作推后，交由一个**内核线程去执行**，也就是说，这个下半部分可以在进程上下文中执行。最重要的就是工作队列允许被重新调度甚至是睡眠。

>具体的信息, 请参见
>
>[Linux workqueue工作原理 ](http://blog.chinaunix.net/uid-21977330-id-3754719.html)

### 2.2.2 2号进程kthreadd

但是这种方法依然看起来不够优美,我们何不把这种**创建内核线程的工作**交给一个**特殊的内核线程**来做呢？

于是linux-2.6.22引入了**kthreadd进程**,并随后**演变为2号进程**,它在系统初始化时同1号进程一起被创建(当然肯定是通过**kernel\_thread**), 参见rest\_init函数,并随后演变为**创建内核线程的真正建造师**, 参见kthreadd和kthreadd函数, 它会**循环的是查询工作链表**static LIST\_HEAD(kthread\_create\_list)中是否有需要被创建的内核线程,而我们的通过**kthread\_create**执行的操作, 只是在内核线程任务队列kthread\_create\_list中增加了一个create任务, 然后会唤醒kthreadd进程来执行真正的创建操作

**内核线程**会出现在**系统进程列表中**,但是在**ps的输出**中**进程名command由方括号包围**, 以便**与普通进程区分**。

如下图所示, 我们可以看到系统中,**所有内核线程都用[]标识**,而且这些进程**父进程id均是2**, 而**2号进程kthreadd**的**父进程是0号进程**

>使用ps -eo pid,ppid,command

![ps查看内核线程](./images/ps-eo.jpg)

## 2.3 kernel\_thread

kernel\_thread是最基础的创建内核线程的接口, 它通过将**一个函数**直接传递给内核来创建一个进程, 创建的进程**运行在内核空间**, 并且与其他进程线程**共享内核虚拟地址空间**

kernel\_thread的实现**经历过很多变革**

**早期**的kernel\_thread执行**更底层的操作**, 直接创建了**task\_struct**并进行初始化,

引入了kthread\_create和kthreadd 2号进程后, **kernel\_thread**的实现也由**统一的\_do\_fork**(或者早期的do\_fork)托管实现

### 2.3.1 早期实现

早期的内核中, kernel\_thread并**不是使用统一的do\_fork或者\_do\_fork**这一封装好的接口实现的, 而是使用**更底层的细节**

>参见
>
>http://lxr.free-electrons.com/source/kernel/fork.c?v=2.4.37#L613

我们可以看到它**内部调用了更加底层的arch\_kernel\_thread创建了一个线程**

>arch\_kernel\_thread
>
>其具体实现请参见
>
>http://lxr.free-electrons.com/ident?v=2.4.37;i=arch_kernel_thread

但是这种方式创建的线程并**不适合运行**，因此内核提供了**daemonize函数**, 其**声明在include/linux/sched.h**中

```c
//http://lxr.free-electrons.com/source/include/linux/sched.h?v=2.4.37#L800
extern void daemonize(void);
```

**定义在kernel/sched.c**

>http://lxr.free-electrons.com/source/kernel/sched.c?v=2.4.37#L1326

主要执行如下操作

1. 该函数**释放其父进程的所有资源**，不然这些资源会**一直锁定直到线程结束**。

2. **阻塞信号的接收**

3. 将**init用作守护进程的父进程**

我们可以看到早期内核的很多地方使用了这个接口, 比如

>可以参见
>
>http://lxr.free-electrons.com/ident?v=2.4.37;i=daemonize

我们将了这么多**kernel\_thread**,但是我们并**不提倡我们使用它**,因为这个是**底层的创建内核线程的操作接口**,使用kernel\_thread在内核中**执行大量的操作**,虽然创建的代价已经很小了,但是对于追求性能的linux内核来说还不能忍受

因此我们只能说<font color=0x00ffff>kernel\_thread是一个古老的接口,内核中的有些地方仍然在使用该方法,将一个函数直接传递给内核来创建内核线程</font>

于是linux-3.x下之后, 有了更好的实现, 那就是

**延后内核的创建工作**, 将内核线程的创建工作交给一个内核线程来做, 即kthreadd 2号进程

但是**在kthreadd还没创建之前**,我们**只能通过kernel\_thread这种方式去创建**

同时kernel\_thread的实现也改为由\_do\_fork(早期内核中是do_fork)来实现, 参见[kernel/fork.c](http://lxr.free-electrons.com/source/kernel/fork.c?v=4.5#L1779)

```c
pid_t kernel_thread(int (*fn)(void *), void *arg, unsigned long flags)
{
    return _do_fork(flags|CLONE_VM|CLONE_UNTRACED, (unsigned long)fn,
            (unsigned long)arg, NULL, NULL, 0);
}
```

## 2.4 kthread\_create

```c
struct task_struct *kthread_create_on_node(int (*threadfn)(void *data),
                                           void *data,
                                          int node,
                                          const char namefmt[], ...);
#define kthread_create(threadfn, data, namefmt, arg...) \
       kthread_create_on_node(threadfn, data, NUMA_NO_NODE, namefmt, ##arg)
```

创建内核线程**更常用**的方法是辅助函数**kthread\_create**，该函数创建一个新的内核线程。**最初线程是停止的**，需要使用**wake\_up\_process启动**它。

## 2.5 kthread\_run

```c
/**
 * kthread_run - create and wake a thread.
 * @threadfn: the function to run until signal_pending(current).
 * @data: data ptr for @threadfn.
 * @namefmt: printf-style name for the thread.
 *
 * Description: Convenient wrapper for kthread_create() followed by
 * wake_up_process().  Returns the kthread or ERR_PTR(-ENOMEM).
 */
#define kthread_run(threadfn, data, namefmt, ...)                     \
({                                                                  \
    struct task_struct *__k                                            \
            = kthread_create(threadfn, data, namefmt, ## __VA_ARGS__); \
    if (!IS_ERR(__k))                                                  \
            wake_up_process(__k);                                      \
    __k;                                                               \
})
```
使用**kthread\_run**，与kthread\_create不同的是，其**创建新线程后立即唤醒它**，其**本质**就是先用**kthread\_create创建**一个内核线程，然后通过**wake\_up\_process唤醒**它

# 3 内核线程的退出

**线程一旦启动起来**后，会**一直运行**，除非**该线程主动调用do\_exit函数**，或者**其他的进程**调用**kthread\_stop**函数，结束线程的运行。

```c
    int kthread_stop(struct task_struct *thread);
```

kthread\_stop()通过**发送信号给线程**。

如果**线程函数**正在处理一个非常重要的任务，它**不会被中断**的。当然如果**线程函数永远不返回并且不检查信号**，它将**永远都不会停止**。

在**执行kthread\_stop的时候**，目标线程**必须没有退出**，否则**会Oops**。原因很容易理解，当**目标线程退出**的时候，其对应的**task结构也变得无效**，kthread\_stop**引用该无效task结构就会出错**。

为了避免这种情况，**需要确保线程没有退出**，其方法如代码中所示：

```c
thread_func()
{
    // do your work here
    // wait to exit
    while(!thread_could_stop())
    {
           wait();
    }
}

exit_code()
{
     kthread_stop(_task);   //发信号给task，通知其可以退出了
}
```
这种退出机制很温和，一切尽在thread\_func()的掌控之中，**线程在退出**时可以从容地**释放资源**，而不是莫名其妙地被人“暗杀”。