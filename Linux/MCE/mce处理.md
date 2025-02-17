
# machine check 是什么?

machine check 是一种用来报告内部错误的一种硬件的方式. 它包括 `machine check exceptions` 和 `silent machine check`.

其中, machine check exceptions(MCEs) 是在**硬件不能纠正内部错误的时候发生**, 在这种情况下, 通常会**中断** CPU 当前正在运行的程序, 并且调用一个特殊的**异常处理程序**. 这种情况通常需要软件来进行处理, 即 machine check exception handler.

当**硬件能够纠正内部错误**的时候, 这种情况通常称作 silent machine check. 当这种错误发生的时候, 硬件会把相应的错误信息登记到特殊的寄存器中. 之后, 操作系统或者是固件(BIOS)就可以从这写寄存器中读取信息, 登记和分析这些错误信息有助于提前预测机器硬件的故障.

# machine check 很重要

随着每一代芯片中晶体管数量的增加, 以及芯片大小的减小, 硬件发生错误的概率也在提高, 因此能够处理这种错误变得越来越重要.

另外, 现在将许多计算机集成在一起进行高性能的科学计算也越来越流行. 这些集群的计算机中, 发生硬件错误的概率将比普通的计算机发生错误的概率要高, 因此, 为了保证可靠性, 处理这些硬件错误也是很重要的.

产生 machine checks 的原因很多, 这些来源包括 CPU,  缓存,  内部总线,  内存等等, 当然也有可能是驱动中的软件错误.

# x86 machine check architecture 概述

intel 和 amd 的芯片都属于 x86 架构的. 之前在 IBM 的机器中引入了记忆体(parity memory), 当内存发生错误的时候, 会出发一个 NMI. 随后的机器丢弃了记忆体, 但仍然报告一些硬件的错误. 之后, 在 intel pentium 中又将基本的 machine check 加入到 CPU 中, 并引入了 MCA(machine check architecture). MCA 包括一个标准的异常(18 号中断), 以及一些标准的寄存器 MSR(在有的地方全称是 model specific register, 另外一些称为 machine specific register). 这些寄存器允许软件来检查, 是否发生了一个 machine check , 允许或者禁止他们, 检测这些错误是否被恢复, 是否污染了 CPU 的状态.

另外, bank 中包括了更多的寄存器, bank 是具体的子系统产生的错误的分组, 这些子系统包括 CPU, 总线单元, 缓存和北桥等. bank 的数量和意义是依赖于具体的 CPU 的. 每一个 bank 都有一定数量的子错误, 这些子错误可以被禁止或者是允许. 通常, 一个通用的 machine check 处理函数允许所有的错误和 bank. 另外, bank 中还保存了与错误有关的地址. 这个通用架构的优点就是一个单独的 machine check 处理函数可以在许多不同的 CPU 上工作. 当一个 machine check 被检测到以后, 内核就会读取所有的 machine check 寄存器, 以及报告错误的那个 bank 的寄存器.

对于不同错误的解码和解释是依赖于具体的 CPU 和 用户的. 一些通用的处理就可以完成, 例如, 当 bank 寄存器中含有一个合法的错误地址时, 我们就假设在这个地址的内存处发生了错误. 当然, 处理函数根据错误是否被纠正以及错误是否污染了 CPU 的上下文来作出相应的动作.

# 为什么写一个 machine check 处理函数是困难的

因为当前的内核服务都不能被使用. 我们知道内核代码可以运行在进程上下文和中断上下文, 在中断上下文可以做的事情比进程上下文可以做的事情要少. 在中断上下文调用的函数必须合适的保护了它的数据结构, 防止来自多个中断的并发访问. 这些函数被称为是"中断安全的".

但是, 我们知道 machine check exception 在任何时候都可能会发生, 甚至在所有中断都被禁止的临界区中也有可能会发生. 因此在这种情况下, 如果在 machine check exception 处理函数中调用了这些中断安全的函数, 就可能会死锁在自旋锁上.

由于为了让代码更加的简单,  silent machine check 处理函数和 machine check exception 处理函数共享了同一条代码路径, 因此上面所讨论的问题对于 silent machine check 处理函数同样适用.

同样, 能够尽快的处理 machine check 也是非常重要的, 因为在发生了一个硬件错误之后, 机器的状态可能变得已经不太稳定了. 当处理函数在等待机器进入一个更加容易被处理的状态的时候, 这个事件可能会变得不能被处理. 例如, 在等待的时间内, 在同一个 bank 上, 又发生了另一个错误, 这个错误就会覆盖之前的错误, 并且变得不可处理.

对于一些复杂的 RAM 错误, 处理函数除了等待就没有别的办法了, 因为这要求和内核锁进行同步. 不像其他的异常, machine check 是异步的. 这就是说, CPU 报告的错误并不在发生错误的那条指令处, 这可能已经过了几百个时钟周期, 这就导致了处理的不可靠性.

# 登记 machine check 

传统的, 登记 machine check 是由固件来进行的(即 BIOS), 当操作系统没有 machine check 处理函数时, 那些 MC 寄存器将不会被清零. 在下一次热启动之后, BIOS 将从最后一次 machine check 中找到信息, 并登记到日志文件中. 这种方式显然存在很多缺点, 例如, 必须在每次机器重新启动时才能够登记日志文件, 不能够记录在同一个 bank 上发生的多个错误, 在网络中收集信息和将日志写到磁盘是很困难的.

因此, 最好的方法是将登记日志的任务交给操作系统, 就可以解决这些问题. 但是, 当前大多数的 linux 用户使用的都是 X 界面, 因此控制口是不可见的. 当操作系统登记一个致命的 machine check 后, X 界面看起来就像是冻住了一样, 不会响应用户. 为了解决这个问题, 这种致命的 machine check 都在机器重启时再登记. 这也能够将日文件写道磁盘里, 使后来的支持人员分析称为可能.

将 machine check 日志文件和 软件错误日志文件分开是有必要的, 因为用户可能分不清出这两种错误. 经验表明, 最好将这两种日志文件完全分开.

# 重写的 x86-64 处理函数

由于最初的 linux2.4 内核中的 x86-64 machine check 处理函数是从 i386 的版本继承而来的. 但是后来发现这里面存在一些 bug , 及一些设计上的错误. 因此在 linux 2.5 内核又对 x86-64 上的 machine check 处理函数进行了重写. 这次重写紧跟 Intel 和 AMD 对 machine check 处理函数的标准. 在这次重写的代码中没有与具体的 CPU 相关的代码, 这些代码都是完全按照通用的 x86 machine check 架构编写的. 另外, 这次重写的代码在区分不可纠正错误和污染 CPU 状态的错误之间做了区分, 在第一种情况下时, 会在安全的时候将进程杀死, 而不用系统 panic. 而在之前的处理函数中, 这两种情况系统都会 panic . 但是, 当进程处于内核态的时候, 并且持有锁, 杀死这个进程就会造成系统死锁. 而死锁比 panic 更难以处理, 因此当处于内核态的进程发生了 machine check 的时候, 内核选择 panic.

在新编写的处理函数中, 创建了一个无锁的二进制日志文件系统, 它完全和 printk 日志文件分开. 它将 machine check 记录到一个缓冲区中, 当缓冲区满了之后, 后来的信息就会被丢弃, 并且可以在用户空间通过字符设备 /dev/mcelog 来进行访问. 在用户空间中使用应用程序 mcelog 有规律的对这个字符设备进行读取和解码.

当遇到一个致命的 machine check 的时候, 会在系统重新热启动之后, 由 BIOS 或者内核读取这个错误. 而其他的 slient machine check 可以通过 mcelog 按照一定的规律进行存取, 并将他们写道特殊的日志文件中.

mce 结构如下:


# 参考

https://blog.csdn.net/xiaocainiaoshangxiao/article/details/38046239 (未完)

http://linuxperf.com/?p=105 (未)

https://www.kernel.org/doc/html/latest/firmware-guide/acpi/apei/einj.html

https://mp.weixin.qq.com/s/N5x7gG-YGusJgVMmKDTjwQ

