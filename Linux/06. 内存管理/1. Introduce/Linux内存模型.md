

# 前言

在 linux 内核中支持**3 中内存模型**, 分别是**flat memory model**, **Discontiguous memory model**和**sparse memory model**. 所谓 memory model, 其实就是从 cpu 的角度看, 其物理内存的分布情况, 在 linux kernel 中, 使用什么的方式来管理这些物理内存. 另外, 需要说明的是: 本文主要 focus 在 share memory 的系统, 也就是说所有的 CPUs 共享一片物理地址空间的.

本文的内容安排如下: 为了能够清楚的解析内存模型, 我们对一些基本的术语进行了描述, 这在第二章. 第三章则对三种内存模型的工作原理进行阐述, 最后一章是代码解析, 代码来自 4.4.6 内核, 对于体系结构相关的代码, 我们采用 ARM64 进行分析.

# 和内存模型相关的术语

## 什么是 page frame?

操作系统最重要的作用之一就是管理计算机系统中的各种资源, 做为最重要的资源: 内存, 我们必须管理起来. 在 linux 操作系统中, 物理内存是按照 page size 来管理的, 具体 page size 是多少是和硬件以及 linux 系统配置相关的, 4k 是最经典的设定. 因此, 对于物理内存, 我们将其分成一个个按 page size 排列的 page, 每一个**物理内存中**的**page size 的内存区域**我们称之**page frame**. 我们针对每一个物理的 page frame 建立一个**struct page**的数据结构来跟踪**每一个物理页面的使用情况**: 是用于内核的正文段?还是用于进程的页表?是用于各种 file cache 还是处于 free 状态......

**每一个 page frame**有一个**一一对应的 page 数据结构**, 系统中定义了**page_to_pfn**和**pfn_to_page**的宏用来在**page frame number**和**page 数据结构**之间进行**转换**, 具体**如何转换**是和**memory modle 相关**, 我们会在第三章详细描述 linux kernel 中的 3 种内存模型.

## 什么是 PFN?

对于一个计算机系统, 其整个**物理地址空间**应该是**从 0 开始**, 到**实际**系统能支持的**最大物理空间**为止的一段地址空间. 在 ARM 系统中, 假设物理地址是 32 个 bit, 那么其物理地址空间就是 4G, 在 ARM64 系统中, 如果支持的**物理地址 bit 数目**是 48 个, 那么其物理地址空间就是 256T. 当然, 实际上这么大的**物理地址空间**并不是都用于**内存**, 有些也属于**I/O 空间**(当然, 有些 cpu arch 有自己独立的 io address space). 因此, **内存所占据的物理地址空间**应该是一个**有限的区间**, **不可能覆盖整个物理地址空间**. 不过, 现在由于内存越来越大, 对于 32 位系统, 4G 的物理地址空间已经无法满足内存的需求, 因此会有 high memory 这个概念, 后续会详细描述.

PFN 是 page frame number 的缩写, 所谓 page frame, 就是针对**物理内存**(**不是物理地址空间！！！**)而言的, 把**物理内存**分成一个个的**page size**的区域, 并且给**每一个 page 编号**, 这个号码就是 PFN. **假设**物理内存从 0 地址开始, 那么 PFN 等于 0 的那个页帧就是 0 地址(物理地址)开始的那个 page. 假设物理内存从 x 地址开始, 那么第一个页帧号码就是(**x>>PAGE_SHIFT**).

## 什么是 NUMA?

在为 multiprocessors 系统设计内存架构的时候有两种选择: 一种就是 UMA(Uniform memory access), 系统中的所有的 processor 共享一个统一的, 一致的物理内存空间, 无论从哪一个 processor 发起访问, 对内存地址的访问时间都是一样的. NUMA(Non-uniform memory access)和 UMA 不同, 对某个内存地址的访问是和该 memory 与 processor 之间的相对位置有关的. 例如, 对于某个节点(node)上的 processor 而言, 访问 local memory 要比访问那些 remote memory 的速度要快.

# Linux 内核中的三种 memory model

## 什么是 FLAT memory model

如果从系统中**任意一个 processor**的角度来看, 当它**访问物理内存**的时候, **物理地址空间**是一个**连续的, 没有空洞的地址空间**, 那么这种计算机系统的内存模型就是**Flat memory**. 这种内存模型下, 物理内存的管理比较简单, **每一个物理页帧**都会有一个**page 数据结构**来抽象, 因此系统中存在一个**struct page 的数组**(**mem_map**), 每一个数组条目指向一个实际的物理页帧(page frame). 在 flat memory 的情况下, **PFN**(page frame number)和**mem_map 数组 index**的关系是**线性的**(有一个固定偏移, 如果内存对应的物理地址等于 0, 那么 PFN 就是数组 index). 因此从 PFN 到对应的 page 数据结构是非常容易的, 反之亦然, 具体可以参考 page_to_pfn 和 pfn_to_page 的定义.

此外, 对于 flat memory model, 节点(**struct pglist_data**)只有一个(为了和 Discontiguous Memory Model 采用同样的机制). 下面的图片描述了 flat memory 的情况:

![config](images/19.gif)

需要强调的是**struct page**所占用的内存位于直接映射(directly mapped)区间, 因此操作系统**不需要**再为其建立**page table**.

## 什么是 Discontiguous Memory Model?

如果 cpu 在访问物理内存的时候, 其地址空间有一些空洞, 是**不连续的**, 那么这种计算机系统的内存模型就是 Discontiguous memory. 一般而言, **NUMA 架构**的计算机系统的 memory model 都是**选择 Discontiguous Memory**, 不过, 这两个概念其实是不同的. **NUMA 强调的是 memory 和 processor 的位置关系**, 和**内存模型**其实是**没有关系**的, 只不过, 由于**同一 node**上的**memory 和 processor**有更紧密的**耦合**关系(访问更快), 因此需要**多个 node**来管理.

Discontiguous memory**本质**上是**flat memory 内存模型的扩展**, 整个物理内存的 address space 大部分是成片的大块内存, 中间会有一些空洞, **每一个成片**的**memory address space 属于一个 node**(如果局限在一个 node 内部, 其内存模型是 flat memory). 下面的图片描述了 Discontiguous memory 的情况:

![config](images/20.gif)

因此, 这种内存模型下, 节点数据(**struct pglist_data**)有多个, 宏定义 NODE_DATA 可以得到指定节点的 struct pglist_data. 而, **每个节点**管理的**物理内存**保存在**struct pglist_data** 数据结构的**node_mem_map**成员中(概念**类似 flat memory 中的 mem_map**). 这时候, 从**PFN 转换到具体的 struct page**会稍微复杂一点, 我们**首先**要从 PFN 得到**node ID**, 然后根据这个 ID 找到对于的**pglist_data** 数据结构, 也就找到了**对应的 page 数组**, 之后的方法就类似 flat memory 了.

## 什么是 Sparse Memory Model?

Memory model 也是一个演进过程, 刚开始的时候, 使用 flat memory 去抽象一个连续的内存地址空间(mem_maps[]), 出现 NUMA 之后, 整个不连续的内存空间被分成若干个 node, 每个 node 上是连续的内存地址空间, 也就是说, 原来的单一的一个 mem_maps[]变成了若干个 mem_maps[]了. 一切看起来已经完美了, 但是**memory hotplug**的出现让原来完美的设计变得不完美了, 因为即便是**一个 node 中的 mem_maps[]也有可能是不连续**了. 其实, 在出现了 sparse memory 之后, Discontiguous memory 内存模型已经不是那么重要了, 按理说 sparse memory 最终可以替代 Discontiguous memory 的, 这个替代过程正在进行中, **4.4 的内核**仍然是有**3 内存模型**可以选择. (Processor type and features  ---> Memory model, 但是 4.18 已经不可选, 只有 sparse memory)

为什么说 sparse memory 最终可以替代 Discontiguous memory 呢?实际上在 sparse memory 内存模型下, **连续的地址空间**按照**SECTION**(例如 1G)被分成了一段一段的, 其中**每一 section 都是 hotplug 的**, 因此 sparse memory 下, 内存地址空间可以**被切分的更细**, 支持**更离散**的 Discontiguous memory. 此外, 在 sparse memory 出现之前, NUMA 和 Discontiguous memory 总是剪不断, 理还乱的关系: **NUMA 并没有规定其内存的连续性**, 而 Discontiguous memory 系统也**并非一定是 NUMA 系统**, 但是这两种配置都是 multi node 的. 有了 sparse memory 之后, 我们终于可以把**内存的连续性**和**NUMA 的概念**剥离开来: 一个 NUMA 系统可以是 flat memory, 也可以是 sparse memory, 而一个 sparse memory 系统可以是 NUMA, 也可以是 UMA 的.

下面的图片说明了 sparse memory 是如何管理 page frame 的(配置了 SPARSEMEM_EXTREME):

![config](images/21.gif)

(注意: 上图中的**一个 mem_section**指针应该指向**一个 page**, 而**一个 page**中有**若干个 struct mem_section**数据单元)

整个连续的物理地址空间是按照一个 section 一个 section 来切断的, 每一个**section 内部**, 其**memory 是连续的**(即**符合 flat memory 的特点**), 因此, mem_map 的**page 数组**依附于 section 结构(**struct mem_section**)而**不是 node 结构**了(struct pglist_data). 当然, 无论哪一种 memory model, 都需要处理 PFN 和 page 之间的对应关系, 只不过 sparse memory 多了一个 section 的概念, 让转换变成了**PFN<--->Section<--->page**.

我们首先看看如何**从 PFN 到 page 结构的转换**: kernel 中**静态定义**了一个**mem_section 的指针数组**, **一个 section**中往往包括**多个 page**, 因此需要通过**右移**将**PFN**转换成**section number**, 用**section number**做为 index 在**mem_section 指针数组**可以找到**该 PFN 对应的 section 数据结构**. 找到 section 之后, 沿着其**section_mem_map**就可以找到对应的 page 数据结构. 顺便一提的是, 在**开始的时候**, sparse memory 使用了**一维的 memory_section 数组**(**不是指针数组**), 这样的实现对于特别稀疏(**CONFIG_SPARSEMEM_EXTREME**)的系统非常浪费内存. 此外, **保存指针对 hotplug 的支持是比较方便**的, 指针等于 NULL 就意味着该 section 不存在. 上面的图片描述的是一维 mem_section 指针数组的情况(配置了 SPARSEMEM_EXTREME), 对于非 SPARSEMEM_EXTREME 配置, 概念是类似的, 具体操作大家可以自行阅读代码.

从**page 到 PFN**稍微有一点麻烦, 实际上**PFN 分成两个部分**: 一部分是**section index**, 另外一个部分是**page 在该 section 的偏移**. 我们需要**首先**从 page 得到**section index**, 也就得到对应的**memory_section**(**PFN 第一部分 get**), 知道了 memory_section 也就知道该 page 在**section_mem_map**, 也就知道了 page 在该 section 的偏移(**PFN 第二部分 get**), 最后可以合成 PFN.

对于 page 到 section index 的转换, sparse memory 有**2 种方案**, 我们先看看经典的方案, 也就是**保存在 page->flags**中(配置了**SECTION_IN_PAGE_FLAGS**). 这种方法的最大的问题是 page->flags 中的**bit 数目不一定够用**, 因为这个 flag 中承载了太多的信息, 各种 page flag, node id, zone id 现在又增加一个 section id, 在不同的 architecture 中无法实现一致性的算法, 有没有一种通用的算法呢?这就是**CONFIG_SPARSEMEM_VMEMMAP(可配置项**). 具体的算法可以参考下图:

![config](images/22.gif)

(上面的图片有一点问题, vmemmap 只有在**PHYS_OFFSET 等于 0**的情况下才指向第一个 struct page 数组, 一般而言, 应该有一个 offset 的)

对于**经典的 sparse memory 模型**, **一个 section 的 struct page 数组**所占用的**内存**来自**directly mapped 区域**, **页表在初始化的时候就建立**好了, **分配了 page frame 也就是分配了虚拟地址**. 但是, 对于**SPARSEMEM_VMEMMAP**而言, **虚拟地址一开始就分配好了**, 是**vmemmap 开始**的一段**连续的虚拟地址空间**, 每一个 page 都有一个对应的 struct page, 当然, **只有虚拟地址, 没有物理地址**. 因此, 当一个 section 被发现后, 可以立刻找到对应的 struct page 的虚拟地址, 当然, 还需要分配一个**物理的 page frame**, 然后建立页表什么的, 因此, 对于这种 sparse memory, 开销会稍微大一些(多了个建立映射的过程).

# 代码分析

我们的代码分析主要是通过 include/asm-generic/memory_model.h 展开的.

## flat memory

代码如下:

```cpp
#define __pfn_to_page(pfn)    (mem_map + ((pfn) - ARCH_PFN_OFFSET))
#define __page_to_pfn(page)    ((unsigned long)((page) - mem_map) + ARCH_PFN_OFFSET)
```

由代码可知, PFN 和 struct page 数组(mem_map)index 是线性关系, 有一个固定的偏移就是 ARCH_PFN_OFFSET, 这个偏移是和估计的 architecture 有关. 对于 ARM64, 定义在 arch/arm/include/asm/memory.h 文件中, 当然, 这个定义是和内存所占据的物理地址空间有关(即和 PHYS_OFFSET 的定义有关).

## Discontiguous Memory Model

```cpp
#define __pfn_to_page(pfn)            \
({    unsigned long __pfn = (pfn);        \
    unsigned long __nid = arch_pfn_to_nid(__pfn);  \
    NODE_DATA(__nid)->node_mem_map + arch_local_page_offset(__pfn, __nid);\
})

#define __page_to_pfn(pg)                        \
({    const struct page *__pg = (pg);                    \
    struct pglist_data *__pgdat = NODE_DATA(page_to_nid(__pg));    \
    (unsigned long)(__pg - __pgdat->node_mem_map) +            \
     __pgdat->node_start_pfn;                    \
})
```

Discontiguous Memory Model 需要获取 node id, 只要找到 node id, 一切都好办了, 比对 flat memory model 进行就 OK 了. 因此对于__pfn_to_page 的定义, 可以首先通过 arch_pfn_to_nid 将 PFN 转换成 node id, 通过 NODE_DATA 宏定义可以找到该 node 对应的 pglist_data 数据结构, 该数据结构的 node_start_pfn 记录了该 node 的第一个 page frame number, 因此, 也就可以得到其对应 struct page 在 node_mem_map 的偏移. __page_to_pfn 类似, 大家可以自己分析.

## Sparse Memory Model

经典算法的代码我们就不看了, 一起看看配置了**SPARSEMEM_VMEMMAP**的代码, 如下:

```cpp
#define __pfn_to_page(pfn)    (vmemmap + (pfn))
#define __page_to_pfn(page)    (unsigned long)((page) - vmemmap)
```

简单而清晰, PFN 就是 vmemmap 这个 struct page 数组的 index 啊. 对于 ARM64 而言, vmemmap 定义如下:

```cpp
#define vmemmap    ((struct page *)VMEMMAP_START - \
        SECTION_ALIGN_DOWN(memstart_addr >> PAGE_SHIFT))
```

毫无疑问, 我们需要在虚拟地址空间中分配一段地址来安放 struct page 数组(该数组包含了所有物理内存跨度空间 page), 也就是 VMEMMAP_START 的定义.

# 参考

http://www.wowotech.net/memory_management/memory_model.html