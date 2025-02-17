[TOC]

http://mp.weixin.qq.com/s?__biz=MzI3MTUxOTYyMA==&mid=2247484002&idx=1&sn=19393c4abd317aea0ab8d535559603b2&chksm=eac1d889ddb6519f2190f4f24d7679f34f443db342700332b4749e360c8011cb0d901d15023f&mpshare=1&scene=1&srcid=01274rIaA8vFPzDBWpMKvytq#rd

# 0 概述

![config](./images/2.png)

**Meltdown breaks the most fundamental isolation between user applications and the operating system**. This attack allows a program to access the memory, and thus also the secrets, of other programs and the operating system.

官网: https://meltdownattack.com/

![config](./images/3.png)

**Spectre breaks the isolation between different applications**. It allows an attacker to trick error-free programs, which follow best practices, into leaking their secrets. In fact, the safety checks of said best practices actually increase the attack surface and may make applications more susceptible to Spectre.

官网同上

一个形象的场景形容 meltdown 如下:

1. 三个人 A, B 和 C 去餐厅点餐, 排队, C 排在 B 后面, B 在 A 后面
2. A 点了面条, 后厨听到开始做面条, 还没做完
3. B 向点餐服务员喊说点饺子(指令顺序进入), 服务员说, **前面还有一位, 稍等下**. 但**后厨听到后开始做饺子**, 很快做好了, 这就是**指令预取**
4. A 拿到面条走了, **轮到 B 点餐**了, 此时突然有事情, 没有吃饺子, 但是已经做好了, 然后被餐厅请出去了, 这就是**异常处理**
5. C 排在 B 后面, 说: 饺子, 面条, 包子各来一份, 饿死了, 哪个快先给我哪个
6. C 拿到了"饺子"
7. C 知道了 B 点了饺子

5, 6, 7 就是 cache 攻击

# 1 CPU 体系结构

## 1.1 指令执行过程

经典处理器架构使用五级流水线: 取指(IF)、译码(ID)、执行(EX)、数据内存访问(MEM)和写回(WB).

现代处理器在设计上都采用了超标量体系结构(Superscalar Architecture)和乱序执行(Out\-of\-Order)技术, 极大地提高了处理器计算能力. 超标量技术能够在一个时钟周期内执行多个指令, 实现指令级的并行, 有效提高了 ILP(InstructionLevel Parallelism)指令级的并行效率, 同时也增加了整个 cache 和 memory 层次结构的实现难度.

![config](./images/1.jpeg)

![config](./images/4.png)

在一个支持超标量和乱序执行技术的处理器中, 一条指令的执行过程被分解为若干步骤. 指令首先进入流水线(pipeline)的前端(Front\-End), 包括预取(fetch)和译码(decode), 经过分发(dispatch)和调度(scheduler)后进入执行单元, 最后提交执行结果. 所有的指令采用顺序方式(In-Order)通过前端, 并采用乱序的方式进行发射, 然后乱序执行, 最后用顺序方式提交结果. 若是一条存储读写指令最终结果更新到 LSQ(Load-StoreQueue)部件. LSQ 部件是指令流水线的一个执行部件, 可以理解为存储子系统的最高层, 其上接收来自 CPU 的存储器指令, 其下连接着存储器子系统. 其主要功能是将来自 CPU 的存储器请求发送到存储器子系统, 并处理其下存储器子系统的应答数据和消息.

如图所示, 在 x86 微处理器经典架构中, **存储指令**从**L1 指令 cache(L1 指令缓存！！！)中读取指令**, **L1 指令 cache(！！！也是 CPU 的一部分！！！**)会做**指令加载、指令预取、指令预解码, 以及分支预测**. 然后进入**Fetch&Decode**单元, 会把指令**解码成 macro\-ops 微操作指令**, 然后由 **Dispatch 部件**分发到 **Integer Unit** 或者 **FloatPoint Unit**.

**Integer Unit** 由 **Integer Scheduler** 和 **Execution Unit** 组成, **Execution Unit**包含**算术逻辑单元**(arithmetic\-logic unit, **ALU**)和**地址生成单元**(address generation unit, **AGU**), 在**ALU 计算完成**之后进入 AGU, 计算**有效地址**完毕后, 给**ROB(reorder buffer**)组件, **排队 commit**, 然后将**结果发送到 LSQ 部件**.

**LSQ 部件**首先根据处理器系统要求的**内存一致性！！！**(memory consistency)模型确定**访问时序**, 另外 LSQ 还需要处理存储器指令间的依赖关系, 最后 LSQ 需要**准备 L1 cache 使用的地址**, 包括**有效地址**的计算和**虚实地址转换**, 将地址发送到 L1 Data Cache(**L1 数据缓存, 不是指令缓存**)中.

**强烈关注这几个 cache 的位置！！！**, L3 cache 位置不对, 应该在 CPU 里面, 可参照下面图

**顺序预取, 乱序执行, 顺序提交**

## 1.2 乱序执行(out\-of\-order execution)

Tomasulo 算法, 1967 年:

- 寄存器重命名
- 读后写相关(Write\-after\-Read, WAR)
- 写后写相关(Write\-after\-Write, WAW)
- 保留站(reservation station): 暂存数据
- ROB(reorder buffer): 排队 commit

现代的处理器为了提高性能, 实现了乱序执行(Out\-of\-Order, OOO)技术. 在古老的处理器设计中, 指令在处理器内部执行是严格按照指令编程顺序的, 这种处理器叫做顺序执行的处理器. 在顺序执行的处理器中, 当一条指令需要访问内存的时候, 如果所需要的内存数据不在 Cache 中, 那么需要去访问主存储器, 访问主存储器的速度是很慢的, 那么这时候顺序执行的处理器会停止流水线执行, 在数据被读取进来之后, 然后流水线才继续工作. 这种工作方式大家都知道一定会很慢, 因为后面的指令可能不需要等这个内存数据, 也不依赖当前指令的结果, 在等待的过程中可以先把它们放到流水线上去执行. 所以这个有点像在火车站排队买票, 正在买票的人发现钱包不见了, 正在着急找钱, 可是后面的人也必须停下来等, 因为不能插队.

**1967**年**Tomasulo**提出了**一系列的算法**来实现**指令的动态调整**从而实现乱序执行, 这个就是著名的**Tomasulo 算法**. 这个算法的**核心**是实现一个叫做**寄存器重命名(Register Rename**)来**消除寄存器数据流之间依赖关系**, 从而**实现指令的并行执行**. 它在**乱序执行的流水线**中有**两个作用**, 一是**消除指令之间**的寄存器**读后写相关(Write\-after\-Read, WAR**)和**写后写相关(Write\-after\-Write, WAW**); 二是当**指令执行发生例外**或者**转移指令猜测错误而取消后面的指令**时, 可用来**保证现场的精确**. 其思路为**当一条指令写一个结果寄存器**时**不直接写到这个结果寄存器**, 而是**先写到一个中间寄存器过渡**, 当**这条指令提交时再写到结果寄存器**中.

通常处理器实现了一个统一的保留站(reservationstation), 它允许处理器把已经执行的指令的结果保存到这里, 然后在最后指令提交的时候会去做寄存器重命名来保证指令顺序的正确性.

如图所示, 经典的 X86 处理器中的"整数重命名"和"浮点重命名"部件(英文叫做 reorder buffer, 简称 ROB), 它会负责寄存器的分配、寄存器重命名以及指令丢弃(retiring)等作用.

x86 的指令从 L1 指令 cache 中预取之后, 进入前端处理部分(Front\-end), 这里会做指令的分支预测和指令编码等工作, 这里是顺序执行的(in\-order). 指令译码的时候会**把 x86 指令变成众多的微指令(uOPs**), 这些微指令会**按照顺序**发送到**执行引擎(Execution Engine**). 执行引擎这边开始乱序执行了. 这些指令首先会**进入到重命名缓存(ROB**)里, 然后**ROB 部件会把这些指令**经由**调度器单元发生到各个执行单元(Execution Unit, 简称 EU**)里. 假设有一条指令需要访问内存, 这个 EU 单元就停止等待了, 但是后面的指令不需要停顿下来等这条指令, 因为 ROB 会把后面的指令发送给空闲的 EU 单元, 这样就实现了乱序执行.

如果用高速公路要做比喻的话, 多发射的处理器就像多车道一样, 汽车不需要按照发车的顺序在高速公路上按顺序执行, 它们可以随意超车. 一个形象的比喻是, 如果一个汽车抛锚了, 后面的汽车不需要排队等候这辆汽车, 可以超车.

在高速公里的终点设置了一个很大的停车场, 所有的指令都必须在停车场里等候, 然后停车场里有设置了一个出口, 所有指令从这个出口出去的时候必须按照指令原本的顺序, 并且**指令在出口**的时候**必须进行写寄存器操作**. 这样从出口的角度看, 指令就是按照原来的逻辑顺序一条一条出去并且写寄存器.

这样从处理器角度看, 指令是顺序发车, 乱序超车, 顺序归队. 那么这个停车场就是 ROB, 这个缓存机制可以称为保留站(reservation station), 这种乱序执行的机制就是人们常说的乱序执行.

## 1.3 异常处理

- CPU 指令在执行过程中可能会产生异常, 但是处理器支持乱序执行, 异常指令后面的指令都已经执行, 怎么办?
- ROB 会起作用
    - 异常指令和其后面的指令会被丢弃掉, 不提交
    - 但是有可能预取的数据已经在 cache 里

## 1.4 cache 存储结构

现代处理器执行指令的瓶颈已经不在 CPU 端, 而是在内存访问端. 因为 CPU 的处理速度要远远大于物理内存的访问速度, 所以为了减轻 CPU 等待数据的时间, 在现代处理器设计中都设置了多级的 cache 单元.

![config](./images/5.png)

如图所示(**图中的 cluster 应该是 package, 表示物理 CPU**), 一个拥有**2 个 CPU**的系统, **每个 CPU**有**两个 Core**, **每个 Core**有**两个线程(图中没有显示)的 Cache 架构**. **每一个 Core(以 core 为单位！！！**)有**单独的 L1 cache(！！！**), 它由**其中的线程所共享**, **每一个 CPU(物理 CPU**)中的**所有 Core**共享**同一个 L2 Cache**, **同一个 cluster 的所有的 CPU**共享**同一个 L3 Cache**.

**L1 cache**最靠近处理器核心, 因此它的访问**速度也是最快**的, 当然它的容量也是最小的. CPU 访问各级的 Cache 速度和延迟是不一样的, **L1 Cache 的延迟最小**, **L2 Cache 其次**, **L3 Cache 最慢**.

- 处理器**首次访问主存上的某地址**时, 会将此地址所在**cache line 单位大小的内容**依次载入 L3, L2, L1 Cache
- 短时间内, 处理器再次访问这个地址时, 将直接从 L1 Cache 读取

### 1.4.1 Cache 访问速度对比

下面是 Xeon 5500 Series 的各级 cache 的访问延迟: (根据 CPU 主频不同, 一个时钟周期的时间也不同, 在 1GHz 主频的 CPU 下, 一个时钟周期大概 1 纳秒, 在 2.1GHz 主频的 CPU 下, 访问 L1 cache 也就 2 纳秒)

访问类型 | 延迟
---|---
L1 cache 命中 | 约 4 个时钟周期
L2 cache 命中 | 约 100 纳秒
L3 cache 命中 | 约 100 纳秒
访问本地 DDR | 约 100 纳秒
访问远端内存节点 DDR | 约 100 纳秒

如表所示, 我们可以看到**各级内存访问的延迟**有**很大的差异**.

**CPU**访问一块**新的内存**时, 它会首先把包含**这块内存的 Cache Line 大小的内容(！！！**)获取到**L3 Cache**, 然后是载入到**L2 Cache**, 最后载入到了**L1 Cache**. 这个过程需要**访问主存储器**, 因此**延迟会很大**, 大约需要**几十纳秒**. 当**下次再读取相同一块数据**的时候**直接从 L1 Cache 里取数据**的话, 这个延迟**大约只有 4 个时钟周期**. 当**L1 Cache 满**了并且有**新的数据**要进来, 那么根据**Cache 的置换算法**会选择**一个 Cache line**置换到**L2 Cache**里, **L3 Cache**也是同样的道理.

### 1.4.2 cache 攻击

我们已经知道**同一个 CPU 上的 Core 共享 L2 cache 和 L3 Cache**, 如果**内存已经被缓存到 CPU cache**里, 那么**同一个 CPU 的 Core**就会用**较短的时间取到内存里的内容**, 否则取内存的时间就会较长. 两者的**时间差异**非常明显(大约有**300 个 CPU 时钟周期**), 因此攻击者可以**利用这个时间差异来进行攻击**.

- cache side\-channel attacks
- 根据这个**读取物理内存的延迟(约 60 纳秒**)和以及**读取已经缓存到 cache 中的数据(约 1\~2 纳秒**)之间的**时间差**

### 1.4.3 cache 攻击示例

```
clflush for user_probe_addr[]; // 将 user_probe_addr 对应的 cache 全部都 flush 掉
u8 index = *(u8 *)attacked_mem_adr; // attacked_mem_addr 存放被攻击的地址
data = user_probe_addr[index * 4096]; // user_probe_addr 存放攻击者可以访问的基地址
```

user\_probe\_addr\[\]是一个攻击者可以访问的, **255 \* 4096 大小的数组**.

第 1 行, 把**user\_probe\_addr 数组对应的 cache 全部清除掉**.

第 2 行, 我们设法访问到**attacked\_mem\_addr 中的内容(内核空间的一个地址**). 由于 CPU 权限的保护, 我们不能直接取得里面的内容, 但是可以利用它来造成我们可以观察到影响.

第 3 行, 我们用**访问到的值做偏移**, 以**4096 为单位**, 去**访问攻击者有权限访问的数组**,这样**对应偏移处的内存**就可以**缓存到 CPU cache**里.

这样, 虽然我们在**第 2 行处拿到的数据不能直接看到**, 但是它的值对**CPU cache 已经造成了影响**.

接下来可以**利用 CPU cache 来间接拿到这个值**. 我们**以 4096 为单位**依次访问**user\_probe\_addr 对应内存**单位的**前几个字节**, 并且**测量这该次内存访问的时间**, 就可以**观察到时间差异**, 如果**访问时间短**, 那么可以**推测访内存已经被 cache**, 可以**反推出示例代码中的 index**的值.

在这个例子里, 之所以用**4096 字节做为访问单位**是为了**避免内存预读带来的影响**, 因为 CPU 在每次从主存访问内存的时候, 根据局部性原理, 有可能将**临近的内存也读进来**. **Intel**的**开发手册**上指明**CPU 的内存预取不会跨页面**, 而**每个页面的大小是 4096**.

数据对比

![config](./images/7.png)

根据 256 个页面的访问时间可以得到第 84 个页面的内容是已经被缓存到 cache 中, 所以反推出 index 的值就是 84

如果 attached\_mem\_addr 属于内核空间地址, 我们就可以**利用它来读取内核空间的内容**.

如果 CPU 顺序执行, 在第 2 行就会发现它访问了一个没有权限地址, 产生 page fault (缺页异常), 进而被内核捕获, 第 3 行就没有机会运行. 不幸的是, CPU 会乱序执行, 在某些条件满足的情况下, 它取得了 attacked\_mem\_addr 里的值, 并在 CPU 将该指令标记为异常之前将它传递给了下一条指令, 并且随后的指令利用它来触发了内存访问. 在指令提交的阶段 CPU 发现了异常,再将已经乱序执行指令的结果丢弃掉. 这样虽然没有对指令的正确性造成影响, 但是乱序执行产生的 CPU cache 影响依然还是在那里, 并能被利用.

该场景有个前置条件, **attached\_mem\_addr**必须要已经被**缓存到了 CPU L1**, 因为这样才会有可能在**CPU 将指令标记为异常之前指数据传给后续的指令**.

那么如何来将要**被攻击的内存缓存到 L1**里呢? 有两种方法:

1) 利用**系统调用进入内核**. 如果该系统调用的路径访问到了该内存, 那么很有可能会将该内存缓存到 L1 (在 footprint 不大于 L1 大小的情况下).

2) 其次是**利用 prefetch 指令**.  有研究显示, **Intel 的 prefetch 指令**会完全忽略权限检查, **将数据读到 cache**.

## 1.5 进程地址空间

现代的处理器为了实现**CPU 的进程虚拟化**, 都采用了**分页机制**, 分页机制保证了**每个进程的地址空间的隔离性**. 分页机制也实现了**虚拟地址到物理地址的转换**, 这个过程需要查询页表, 页表可以是多级页表. 那么这个页表除了实现虚拟地址到物理地址的转换之外还定义了访问属性, 比如这个虚拟页面是只读的还是可写的还是可执行的还是只有特权用户才能访问等等权限.

**每个进程的虚拟地址空间都是一样**的, 但是它**映射的物理地址是不一样**的, 所以**每一个进程**都有**自己的页表**, 在操作系统做**进程切换**的时候, 会把**下一个进程的页表的基地址**填入到**寄存器**, 从而实现**进程地址空间的切换**. 以外, 因为**TLB**里**还缓存着上一个进程的地址映射关系**, 所以在**切换进程**的时候需要把**TLB 对应的部份也清除掉**.

当进程在运行的时候不可避免地需要**和内核交互**, 例如**系统调用**, **硬件中断**. 当**陷入到内核**后, 就需要去**访问内核空间**, 为了**避免这种切换**带来的**性能损失以及 TLB 刷新**, 现代 OS 的设计都把**用户空间和内核空间的映射**放到了**同一张页表**里. 这两个空间有一个明显的分界线, 在 Linux Kernel 的源码中对应**PAGE\_OFFSET**.

![config](./images/8.png)

如图所示, 虽然两者是在**同一张页表**里, 但是他们**对应的权限不一样**, **内核空间部份**标记为仅在**特权层可以访问**, 而**用户空间部份**在**特权层与非特权层都可以访问**. 这样就完美地把用户空间和内核空间隔离开来: 当**进程**跑在**用户空间时**只能**访问用户空间的地址映射**, 而**陷入到内核**后就**既可以访问内核空间**也可以**访问用户空间**.

对应地, **页表**中的**用户空间映射部份**只包含**本进程**可以访问的**物理内存映射**, 而**任意的物理内存**都有可能会**被映射到内核空间部分**.

- 分页机制, 保障进程之间地址空间的隔离性
- 每个进程都有一套页表
- 进程切换需要切换页表
    - 切换页表
    - 刷新 TLB: 写 CR3 寄存器隐含了 TLB 的 flush

解决办法:

- ARM: ASID(Address Space ID)
- x86: PCID(Process Context identifier), 该技术是 Intel 的 IA\-32e paging 模式特有功能, 为 TLB 和 paging\-structure cache 而产生, 详细看体系结构知识

## 1.6 TLB

**CPU 指令**在执行的过程过有可能会产生**异常**, 但是我们的处理器是支持**乱序执行**的, 那么有可能**异常指令后面的指令**都已经**执行**了, 那怎么办?

我们从处理器内部来考察这个异常的发生. **操作系统**为了处理异常, 有一个要求就是, 当**异常发生**的时候, 异常发生**之前的指令**都已经**执行完成**, 异常指令**后面的所有指令**都**没有执行**. 但是我们的处理器是支持乱序执行的, 那么有可能异常指令后面的指令都已经执行了, 那怎么办?

那么这时候**ROB**就要起到清道夫的作用了. 从之前的介绍我们知道**乱序执行**的时候, 要**修改什么东西**都通过**中间的寄存器暂时记录**着, 等到在**ROB 排队出去的时候才真正提交修改**, 从而**维护指令之间的顺序关系**. 那么当一条指令发生异常的时候, 它就会带着异常"宝剑"来到 ROB 中排队. **ROB**按**顺序**把**之前的正常的指令**都**提交发送出去**, 当看到这个带着**异常**"宝剑"的指令的时候, 那么就启动应急预案, 把出口封锁了, 也就是**异常指令和其后面的指令会被丢弃掉**, 不提交.

但是, 为了保证程序执行的正确性, 虽然异常指令后面的指令不会提交, 可是由于**乱序执行**机制, **后面的一些访存指令**已经把**物理内存数据预取到 cache 中(！！！**)了, 这就给 Meltdown 漏洞留下来后面, 虽然这些数据会最终被丢弃掉.

- TLB: Translation Lookasid Buffer
- 加快虚拟地址到物理地址的转换的 cache, cache entry 存储的虚实地址转换的 entry
- 进程切换需要 flush TLB, 导致新进程运行时性能低下

优化:

- ARM: ASID
- x86: PCID

# 2 Meltdown 分析

```
clflush for user_probe_addr[]; // 将 user_probe_addr 对应的 cache 全部都 flush 掉
u8 index = *(u8 *)attacked_mem_adr; // attacked_mem_addr 存放被攻击的地址
data = user_probe_addr[index * 4096]; // user_probe_addr 存放攻击者可以访问的基地址
```

第二行, 产生 page fault(缺页异常), 进而被内核捕获. 这是一个异常指令

第三行: 由于 CPU 的乱序执行, 这条指令已经被预取到 cache 中, 但是 ROB 不会 commit 这条指令

# 3 Meltdown 漏洞修复

Linux 内核修复办法: 内核页表隔离 KPTI(Kernel page table isolation)

- 每个进程一张页表变成两张: 运行在内核态和运行在用户态时分别使用各自分离的页表
- Kernel 页表包含了进程用户空间地址的映射和 kernel 使用的内存映射
- 用户页表仅仅包含了用户空间的内存映射以及内核跳板的内存映射
- 当进程运行在用户空间时, 使用的是用户页表
- 当发生中断或异常时, 需要陷入内核, 进入内核空间后, 有一小段内核跳板将页表切换到内核页表

![config](./images/9.png)

# 4 ARM64 上的 KPTI 补丁

ARM64 上只有 Cortex\-A75 中招 Meltdown 漏洞

- 官方白皮书: www.arm.com/security-update
- Variant3: using speculative reads of inaccessible data
- 变种: Sub\-variant 3a \- using speculative reads of inaccessible data

ARM64 上 KPTI 的优化:

- A75 上虽然有**两个页表寄存器**, 但是 TLB 上依然没法做到完全隔离, 用户进程在 meltdown 情况下仍然可能访问内核空间映射的 TLB entry
- **每个进程**的**ASID 设置两份**, 一个给当进程跑在内核态的使用, 另外一个给进程跑在用户态时使用. 这样**原本内核空间属于 global TLB**, 就变成**Process\-Special 类型的 TLB**



# 相关论文

- Meltdown, https://meltdownattack.com/
- Spectre Attacks: Exploiting Speculative Execution, https://meltdownattack.com/
- Google Zero Projecthttps://googleprojectzero.blogspot.com/
- MeltdownPrime and SpectrePrime: Automatically-Synthesized Attacks Exploiting Invalidation-Based Coherence ProtocolsKPTI, Submitted on 11 Feb 2018
- Negative Result:Reading Kernel Memory From User Mode https://cyber.wtf/2017/07/28/negative-result-reading-kernel-memory-from-usermode/