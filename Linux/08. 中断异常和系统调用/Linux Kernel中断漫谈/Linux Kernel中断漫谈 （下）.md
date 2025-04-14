
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [3 x86 下 Linux 的中断向量表](#3-x86-下-linux-的中断向量表)
  - [3.1 异常中断向量(0 - 15, 0x0h - 0xfh)](#31-异常中断向量0---15-0x0h---0xfh)
  - [3.2 不可屏蔽中断向量(16 - 31,  0x10h - 0x1fh)](#32-不可屏蔽中断向量16---31--0x10h---0x1fh)
  - [3.3 可屏蔽中断向量(32 - 47,  0x20h - 0x2fh)](#33-可屏蔽中断向量32---47--0x20h---0x2fh)
  - [3.4 软中断向量(48 - 255,  0x30h - 0xffh)](#34-软中断向量48---255--0x30h---0xffh)
- [4 protect mode 中断模式切换](#4-protect-mode-中断模式切换)
  - [4.1 Call gates & Task Gate](#41-call-gates--task-gate)
  - [4.2 Trap gates & Interrupt gates](#42-trap-gates--interrupt-gates)
  - [4.3 Fast System Call](#43-fast-system-call)
  - [4.4 Interrupt Context](#44-interrupt-context)
- [5 Linux Top and Bottom Half](#5-linux-top-and-bottom-half)
  - [5.1 Softirq & Tasklet](#51-softirq--tasklet)
  - [5.2 WOrking Queue](#52-working-queue)
- [6 热插拔(Hot\-Plug)](#6-热插拔hot-plug)
- [7 时钟中断](#7-时钟中断)
- [8 网络中断](#8-网络中断)
- [9 TX and RX](#9-tx-and-rx)

<!-- /code_chunk_output -->

# 3 x86 下 Linux 的中断向量表

电源点亮以后, BIOS 的指令会被默认加载并开始执行. **BIOS**会负责**初始化**所需要的**中断芯片(设置芯片的各个可写寄存器**), 并且在可以使用的内存中(real mode 现在还是)初始化中断向量表, 并且初始化中断处理函数.

>One important code areas created by BIOS is Interrupts Vectors which provide abilities that operating systems and application programs use to invoke the facilities of the Basic Input/Output System, such as read one disk, flush screen or do printing. It also handle basic device interrupts : IRQ0-IRQ15(Interrupt Request).
>
>For X86, BIOS then build up The memory mapping area(address) normally is between 0x0000 to 0x3FFF, totally 1KB, 256 slots and 4B for each slot.

**4B**是因为**每个 slot**对应一个**32 位的地址**(16bit segment selector, 16bit line address).**256 个中断向量**, 其中:

- 0-15 **异常**, **intel 内部保留**, 不可屏蔽
- 16-31 **非屏蔽中断**, intel 内部保留, **不可屏蔽**
- 32-47 **可屏蔽中断**, 可屏蔽
- 47-255 **软中断**, linux 系统本身**使用 128(0x80**)来作为**系统调用软中断**, 可屏蔽

指令 INT xx 可以用来触发中断向量 xx, 所需要的**参数放置在寄存器 AH 中**.

另外, 中断向量表示可以修改的(基地址都可以改掉), 当操作系统从 BIOS 那里接手过系统的控制权时候, 可以修改中断向量表来指向自定义的中断处理函数. **linux**就是这么干的, 一方面把**向量表换了个基位置**为了开启保护模式, 另外一部分**overwrite 部分向量表的实现**.

## 3.1 异常中断向量(0 - 15, 0x0h - 0xfh)

```
INT_NUM    Short Description PM
0x00    Division by zero
0x01    Debugger
0x02    NMI
0x03    Breakpoint
0x04    Overflow
0x05    Bounds
0x06    Invalid Opcode
0x07    Coprocessor not available
0x08    Double fault
0x09    Coprocessor Segment Overrun (386 or earlier only)
0x0A    Invalid Task State Segment
0x0B    Segment not present
0x0C    Stack Fault
0x0D    General protection fault
0x0E    Page fault
0x0F    reserved
0x10    Math Fault
0x11    Alignment Check
0x12    Machine Check
0x13    SIMD Floating-Point Exception
0x14    Virtualization Exception
0x15    Control Protection Exception
```

## 3.2 不可屏蔽中断向量(16 - 31,  0x10h - 0x1fh)

中断向量 16 开始就是**CPU 外部的中断**. 而中断向量 16 - 31 中断还提供很多神奇的功能.

这部分中断向量也可以叫做**BIOS interrupt(！！！**). BIOS 会调用它们来把**向屏幕显示文字**或者把**控制权转个操作系统**(著名的**INT 19H, 触发 bootloader(！！！**)).

部分不可屏蔽中断向量描述(**大多需要配合 AH**):

```
INT_NUM    Short Description PM
0x10    Video Services
0x13    Low Level Disk Services
0x14    Serial Port Services
0x15    Miscellaneous System Services
0x16    Keyboard Services
0x17    Printer Services
0x19    OS Booting Load or Restart OS
0x1A    PIC Services
```

DOS 很大程度上直接继承并使用这些中断向量, 而 windows 和 linux 会在 BIOS 触发 INT 0x19h 之后最终接管整个中断系统.

## 3.3 可屏蔽中断向量(32 - 47,  0x20h - 0x2fh)

**芯片 8259A**的**IRQ0 \- IRQ15**被映射到**中断向量 32-47 范围**, 也就是可以屏蔽的范围(**APIC 以后不一定一一对应！！！**). 是否被屏蔽依赖于:

- **EFLAGS 中的 IF**位, **全局**的觉得是否屏蔽
- **芯片的 MASK**, 决定**单个 IRQ 的屏蔽**

**多个设备**可以**共享一个中断(！！！**), 当**中断触发**时, **所有注册的 handler**都会**被触发(！！！**), **每个 handler**需要自己去判断**是不是自己的中断**.

## 3.4 软中断向量(48 - 255,  0x30h - 0xffh)

48 开始, 大部分空间都是操作系统可用的中断向量. 有一部分提供专门用处, 其中最特殊的是**0x80h**, 负责**系统调用**, 具体如下:

- 128(0x80): 系统调用, 由程序主动触发, 也可以称为软陷入.
- 239(0xef): **APIC 本地时钟中断**
- 240 (0xf0) : Local APIC thermal interrupt (introduced in the Pentium 4 models)
- 241\-250(0xf1\-0xfa) : Linux 保留作将来使用(注意是 Linux 内核保留, 而非 Intel 保留 )
- 251(0xfb): CALL\_FUNCTION\_VECTOR :发往所有的 CPU(不包括发送者), 强制这些 CPU 运行发送者传递过来的函数.
- 252(0xfc): RESCHEDULE\_VECTOR : 当一个 CPU 接收这种类型的中断时, 限定自己来应答中断. 当从中断返回时, 所有的重新调度都自动进行.
- 253(0xfd): INVALIDATE\_TLB\_VECTOR : 发往所有 CPU(不包括发送者), 强制他们的转换后援缓冲器(TLB)变为无效,
- 254(0xfe): ERROR\_APIC\_VECTOR : 错误的 APIC 向量, 应该从不发生.
- 255 (0xff): SPURIOUS\_APIC\_VECTOR: 假的 APIC 向量, 应该从不发生.

# 4 protect mode 中断模式切换

在系统从**real mode**往**protect mode**切换时候, linux 会把**原有的中断向量表废止**, 新建自己的 IDT 用来处理中断. 当然, 因为 real mode 下的表废止了, 而新表稍微建立, **中断必须被屏蔽**. real mode 的中断向量长度是 4bytes, 在 32bit protect 下是 8bytes, 64bit protect 下面是 16bytes.

类似于中断向量表, IDT 中保存了更多的控制信息. **BIOS**在调用**INT 0x19h**把**控制权**交给**bootloader(！！！**), 后者负责:

- **关闭中断**
- **清理内存布局**: 删除原有中断向量表, 构建 GDT
- 打开**A20**切换到 protect 模式
- 通过**GDT**把**控制权交给 linux**

**随后 linux 接管(head.S**)

- 清理内存: **copy 代码(包括 kernel**), 创建**新的 GDT**, 初始化**IDT**, 初始化**分页机制(创建页表**等等)
- protect 模式初始化: 清理并设置寄存器等等

随后把控制权交给 kernel.

real mode 下的中断向量是**没有权限控制**的, protect mode 需要同时 take care 权限的问题. 为此, x86 引入了 gate 的概念, 一共有四种类型的 gate:

- Call gates : 不存在 IDT 中
- Trap gates : Only in IDT
- Interrupt gates : Only in IDT
- Task gates: IDT, LDT
g
ate 一方面指向了对应的 ISR(中断服务程序, Interrupt Service Routines), 另一方面用于判断调用是否有权限.

>Code modules in lower privilege segments can only access modules operating at higher privilege segments by means of a tightly controlled and protected interface called a gate. Attempts to access higher privilege segments without going through a protection gate and without having sufficient access rights causes a general-protection exception (#GP) to be generated."

## 4.1 Call gates & Task Gate

Call Gate 是在 protect mode 下提供 FAR CALL 功能而引入的. FAR CALL 有很多种 type, Call Gate 只是其中一种.

>When the processor is operating in protected mode, the CALL instruction can be used to perform the following three types of far calls: o Far call to the same privilege level o Far call to a different privilege level (inter-privilege level call) o Task switch (far call to another task) In protected mode, the processor always uses the segment selector part of the far address to access the corresponding descriptor in the GDT or LDT. The descriptor type (code segment, call gate, task gate, or TSS) and access rights determine the type of call operation to be performed.

Task Gate 也是为了 Far Call, 不过他会产生一个新的 Task 来执行中断处理程式, 而新的 Task 在执行期间会屏蔽中断.

>When an exception or interrupt handler is accessed through a task gate in the IDT, a task switch results. Handling an exception or interrupt with a separate task offers several advantages.

Call Gate 同时可以作为 privilege 切换的方式, 也可以作为 16bit 和 32bit 指令直接切换的方式. 所以 Call Gate 可以作为系统调用实现的一种方式.

**但 Call Gate 没有流行起来**, 主要原因**INT 0x80h 的引入**, 另外移植性和灵活性也一般. 随后新的指令: **sysenter/sysexit and syscall/sysret(AMD)引入**并被广泛使用.

换句话说, 现在有三种模式去调用一个**system call(系统调用！！！**):

- 通过**Call Gate**
- 通过**Trap Gate 0x80h**
- 通过**sysenter/sysexit and syscall/sysret(AMD**)

## 4.2 Trap gates & Interrupt gates

Trap gates 和 Interrupt gates 类似于 real mode 中的中断向量, 指向对应的中断处理程式. 两者都有 DPL(Descriptor Privilege Level)来表明调用者所需要权限, 地址等信息. 不同之处在于**Interrupt gates**会**屏蔽所有可屏蔽中断(IF flags = 0**), 再**interrupt handler 返回后恢复**; Trap gates 则会保持中断屏蔽**原来的状态**.

在 Intel 的文档中没有说 interrupt handler 执行时候会屏蔽触发中断, 因此理论上中断处理程式可能是需要 re\-enter 的. 但是 linux 会屏蔽当前触发的中断, 因此, **linux 的 ISR(中断处理程式**)是可以**写成非重入**的, 但是 ISR 本身不做全部中断屏蔽(除非手工屏蔽), 还是可能会被其他中断所 interrupt.

linux 使用 0x80h 这个**Trap Gate 来实现系统调用**, 所以 linux 的系统调用执行的过程中是可能**被其他中断所打断的**.

## 4.3 Fast System Call

通过**Call Gate**或者**INT 0x80h 系统调用**时候都需要**上下文切换额外的开销**. 而**Fast System Call 则重用当前的执行栈(！！！**), 因此可以省去这部分开销, 对应的指令包括**SYSENTER/SYSEXIT**(by Intel)和**SYSCALL/SYSRET**(by AMD).

**Fast System Call**执行时候会**屏蔽中断(！！！**), 并在**返回时恢复**.

```
if(CR0.PE == 0) Exception(GP(0));
if(SYSENTER_CS_MSR == 0) Exception(GP(0));
EFLAGS.VM = 0; //Insures protected mode execution
EFLAGS.IF = 0; //Mask interrupts
...
```

## 4.4 Interrupt Context

和**Interrupt Context**对应的是**User Context**和**Process Context**. User Context 就是**默认用户执行程序的 context**, **用户空间**.

当一个**user space thread**做**系统调用**进入系统或者一个 kernel thread 在运行的时候, that is Process Context mode, 这意味这个线程可以被 block(sleep). 而 Interrupt Context 不能 block(sleep), 因此 semaphore 等依赖于 block 的方法也不能被使用.

值得注意的是, **不能 block(sleep**)和**不能被 preempt**是两个概念, 前者依赖于**时钟中断去唤醒**, 后者一般**被其他中断所抢占**. 不能 block(sleep)的原因不是因为逻辑上的错误, 而更多是为了性能, 概念上的完整性和实现的复杂上的考虑的结果.

# 5 Linux Top and Bottom Half

我们无法保证在**单次函数处理**时候情况下, 中断处理既能**及时**又要能**handle 大批量的工作**. 因此**Linux**选择把**中断处理**分成**两个部分**: **快速响应**并返回的**Top Half**和**处理繁重工作的 Bottom Half**.

- **Top Half**负责处理**critical**的工作, **响应, copy 需要的值, 返回**.
- Bottom Half 一般会**被队列起来**, 在**空闲的时候依次处理**.

例如对于**网卡中断**, **Top Half**负责**响应中断**, 然后把**数据**从**网卡**内部存储**copy**到**内存**空间, 然后**返回**. 留下剩下的**协议栈解包**等工作给**Bottom Half**执行.

Top Half 也就是所谓的 ISR 部分, 而 ISR 的部分由 Bottom Half 负责. 不过**如何切分 Top 和 Bottom**依赖于 device driver 的**开发者**, 并没有明确和清晰的边界, 只有一些 suggestion 或者 principle:

- If the work is time sensitive, perform it in the interrupt handler.
- If the work is related to the hardware, perform it in the interrupt handler.
- If the work needs to ensure that another interrupt (particularly the same interrupt) does not interrupt it, perform it in the interrupt handler.
- For everything else, consider performing the work in the bottom half.

另外要注意的是, **Bottom Half 执行**时候**context**是**不屏蔽中断(！！！**)的.

历史上遗留下来了多种**Bottom Half 的实现方式**:

- **Orignial Bottom Half(BH**): based on globally synchronized; tossed to the curb in version 2.5
- **Task Queue** : replaced by Work Queue in version 2.5
- **Softirqs** : compile time registered, multi running instance for one type in SMP, introduced in version 2.3
- **Tasklets** : dynamic registered, one running instance for one type even in SMP, introduced in version 2.3
- **Work Queue** : replace Task Queue

## 5.1 Softirq & Tasklet

Linux 内置了**9 个 Softirqs Types**, 一般开发者也不会对此进行增加, 而更加依赖于使用 Tasklets 来完成工作, 除非需要非常高的性能要求:

Table Softirq Types

TaskletPrioritySoftirq DescriptionHI\_SOFTIRQ0High-priority taskletsTIMER_SOFTIRQ1TimersNET_TX_SOFTIRQ2Send network packetsNET_RX_SOFTIRQ3Receive network packetsBLOCK_SOFTIRQ4Block devicesTASKLET_SOFTIRQ5Normal priority taskletsSCHED_SOFTIRQ6SchedulerHRTIMER_SOFTIRQ7High-resolution timersRCU_SOFTIRQ8RCU(Read-copy update) locking

**Network 和 Block**是最常用的**I/O 设备相关的 Softirq**, 剩下负责时钟和内存同步. 有意思的事, Tasklets 其实是通过 Softirq 实现的. Softirq 通过函数 raise\_softirq 触发, 例如网络就是调用 raise\_softirq(NET\_TX\_SOFTIRQ); 在每个 core 上面都有一个 ksoftirqd 的 thread, 负责执行 Softirq 的 request.

Tasklets 提供两个 queue: 普通和 high priority 的, 不能在执行期间 sleep, 因此也不能使用 semphore 等同步方式. 同时 Tasklets 保证执行时候是 unique instance. 这些限制是为了简化 Tasklets 的设计. 但是 Tasklets 不屏蔽中断.

Linux 为了防止 user\-space 进程饿死问题, 会 timely check 是否有足够多的 Softirq 触发了, 随后才执行.

最后, Softirq 和 Tasklet 在 Interrupt Context 运行.

## 5.2 WOrking Queue

Working Queue 类似于 Tasklets, 不同之处在于**Working Queue**在**Process Context**下运行, 所以**可以 block(sleep**), 也可以**schedule**. 你甚至可以 Working Queue 就是一个 kernel thread(**pool**), 不停的处理中断有关的 bottom half work.

# 6 热插拔(Hot\-Plug)

Linxu 依赖于**udev(！！！**)去**热插拔某个硬件(包括/dev 挂载点的创建**). 当**某个设备**被插入系统系统时候, 一个**uevent 被触发时**, udev 尝试:

1. 按照**系统中/etc/udev/rules.d/定义的 rules**去捕捉 event
2. **create/remove device files**,
3. **load/unload** 对应的**module(driver**)
4. 通知**用户空间**

而**中断分配等工作**就是在**module(driver)被 load/unload**时候发生.

一台 PnP 兼容的电脑必须满足下列三个要素:

- 操作系统必须兼容 PnP
- BIOS 必须支持 PnP
- 要安装的设备本身必须是 PnP 设备

**PnP 设备**会和**BIOS(PIC)申请 IRQ 号**, 随后**向 OS 注册**, 随后当**Drvier 被引入**时候, 就可以**通过调用函数询问设备的 IRQ 号**而不必要自己探测.

# 7 时钟中断

Linux 中的**sleep 操作**依赖于**时钟中断去实现**. 当**一个时钟中断触发**时候, Linux 会检查**sleep 队列**中是否有需要**唤醒的 task**, 随后唤醒如果需要.

在计算机系统中存在着许多**硬件计时器**, 例如**Real Timer Clock(RTC**)、**Time Stamp Counter(TSC**)和**Programmable Interval Timer(PIT**)等等.

- Real Timer Clock ( RTC ):
    - **独立**于整个计算机系统(例如:  CPU 和其他 chip )
    - 内核利用其获取**系统当前时间和日期**
- Time Stamp Counter ( TSC ):
    - 从 Pentium 起, 提供一个**寄存器 TSC**, 用来**累计每一次外部振荡器产生的时钟信号**
    - 通过**指令 rdtsc**访问这个寄存器
    - 比起**PIT, TSC**可以提供**更精确的时间测量**
- Programmable Interval Timer ( PIT ):
    - 时间测量设备
    - **内核**使用的**产生时钟中断的设备**, 产生的时钟中断依赖于硬件的体系结构, 慢的为**10 ms**一次, 快的为**1 ms**一次
- High Precision Event Timer ( HPET ):
    - **PIT** 和 **RTC** 的替代者, 和之前的计时器相比, HPET 提供了**更高的时钟频率**(至少 10 MHz )以及**更宽的计数器宽度(64 位**)
    - 一个 HPET 包括了一个**固定频率的数值增加的计数器**以及**3 到 32 个独立的计时器**, 这**每一个计时器**有包含了一个**比较器**和一个**寄存器**(保存一个数值, 表示**触发中断的时机**). 每一个比较器都比较计数器中的数值和寄存器中的数值, 当这**两个数值相等**时, 将**产生一个中断**

其中 PIT 和 HPET 会触发时钟中断, 而且 HPET 是可编程的.

# 8 网络中断

当**一个 packet**到达**某个网卡(NIC**), 如下的流程会被触发:

1. **数据**会通过**DMA 的模式 copy 到 RAM 中的一个 ring buffer 上面**
2. NIC 触发一个**IRQ 通知 CPU**, 数据来了
3. **IRQ 的 handler 被运行**, raise 一个**Softirq**
4. IRQ 返回, **清理 NIC 的 Interrupt Flag(！！！**)
5. **Softirq 运行触发 NAPI**
6. NAPI 继续运行, 做一系列可能数据合并等优化, 数据在**整理后发送给 Protocol Stacks**

在此过程中可能会包括和其他 Core**直接的 IPI(inter\-processor interrupt)通讯**.

# 9 TX and RX

cat /proc/interrupts 你会发现一些的网络相关的中断上面会有 eth0\-tx\-0, eth0\-rx\-0 或者 eth0\-TxRx\-0 的中断. 其中**Tx 和 Rx**分别表示**Transmit**和**Receive**. **一个网卡**会有**多个 tx 和 rx**, 另外还有个**单独的网卡的中断**:

```
PCI-MSI-edge      eth0
PCI-MSI-edge      eth0-TxRx-0
PCI-MSI-edge      eth0-TxRx-1
PCI-MSI-edge      eth0-TxRx-2
PCI-MSI-edge      eth0-TxRx-3
PCI-MSI-edge      eth0-TxRx-4
PCI-MSI-edge      eth0-TxRx-5
PCI-MSI-edge      eth0-TxRx-6
PCI-MSI-edge      eth0-TxRx-7
```

如上, 可以看到会有 8 个发送接受合并中断. 所以, 理论上而言, 开**同时开 8 个链接可以最大化的提升网络性能**?While, it is another story.

**每个 rx 和 tx**也可以**单独的分配一个中断**:

```
CPU0 CPU1 CPU2 CPU3 CPU4 CPU5
105: 141606 0 0 0 0 0 IR-PCI-MSI-edge eth2-rx-0
106: 0 141091 0 0 0 0 IR-PCI-MSI-edge eth2-rx-1
107: 2 0 163785 0 0 0 IR-PCI-MSI-edge eth2-rx-2
108: 3 0 0 194370 0 0 IR-PCI-MSI-edge eth2-rx-3
109: 0 0 0 0 0 0 IR-PCI-MSI-edge eth2-tx
```

不过具体**每个中断名的意思依赖于 driver 和硬件**, 可能某个 NIC 的 rx 和 tx 就共享一个中断.

另外**MSI**是**PCI socket 专门的一种中断触发机制**, 不走**传统的 INT 引脚**, 通过**PCI 总线**向**专门的存储结构写信息来触发中断(！！！**).