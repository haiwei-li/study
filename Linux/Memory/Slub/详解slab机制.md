https://blog.csdn.net/cosmoslhf/article/details/42743101


# slab 分配器概述

有了伙伴系统 buddy, 我们可以以页为单位获取连续的物理内存了, 即 4K 为单位的获取, 但如果需要频繁的获取/释放并不大的连续物理内存怎么办, 如几十字节几百字节的获取/释放, 这样的话用 buddy 就不太合适了, 这就引出了 slab.

比如我需要一个 100 字节的连续物理内存, 那么内核 slab 分配器会给我提供一个相应大小的连续物理内存单元, 为 128 字节大小(不会是整好 100 字节, 而是这个档的一个对齐值, 如 100 字节对应 128 字节, 30 字节对应 32 字节, 60 字节对应 64 字节), 这个物理内存实际上还是从伙伴系统获取的物理页; 当我不再需要这个内存时应该**释放它**, 释放它并非把它归还给伙伴系统, 而是**归还给 slab 分配器**, 这样等再需要获取时无需再从伙伴系统申请, 这也就是为什么 slab 分配器往往会把**最近释放的内存**(即所谓"**热")分配给申请者**, 这样效率是比较高的.

# 创建一个 slab

## 什么叫创建 slab

上面举了申请 100 字节连续物理内存的例子, 还提到了实际分配的是 128 字节内存, 也就是实际上内核中 slab 分配器对不同长度内存是分档的, 其实这就是 slab 分配器的一个基本原则, 按**申请的内存的大小**分配**相应长度的内存**.

同时也说明一个事实, 内核中一定应该有这样的按**不同长度 slab 内存单元**, 也就是说已经**创建过这样的内存块**, 否则申请时怎能根据大小识别应该分配给怎样大小的内存, 这可以先参加 kmalloc 的实现, `kmalloc` -> `__do_kmalloc`, `__do_kmalloc` 函数中的如下:

```cpp
static __always_inline void *__do_kmalloc(size_t size, gfp_t flags,  void *caller)
{
    struct kmem_cache *cachep;
    void *ret;

    /*找一个合适大小的高速缓存*/
    cachep = __find_general_cachep(size, flags);
    if (unlikely(ZERO_OR_NULL_PTR(cachep)))
           return cachep;

    ret = __cache_alloc(cachep, flags, caller);
    trace_kmalloc((unsigned long) caller, ret,
                 size, cachep->buffer_size, flags);
    return ret;
}
```

kmalloc 申请的**物理内存长度为参数 size**, 它需要先**根据这个长度**找到**相应的长度的缓存**, 这个缓存的概念是什么马上就要引出先别着急, 先看函数 `__find_general_cachep`:

```cpp
static inline struct kmem_cache *__find_general_cachep(size_t size,  gfp_t gfpflags)
{
    struct cache_sizes *csizep = malloc_sizes;
#if DEBUG
    /* This happens if someone tries to call
    * kmem_cache_create(), or __kmalloc(), before
    * the generic caches are initialized.
    */
    BUG_ON(malloc_sizes[INDEX_AC].cs_cachep == NULL);
#endif
    if (!size)
        return ZERO_SIZE_PTR;

    /*这是本函数唯一有用的地方: 寻找合适大小的 cache_sizes*/
    while (size > csizep->cs_size)
        csizep++;
    /*
    * Really subtle: The last entry with cs->cs_size==ULONG_MAX
    * has cs_{dma,}cachep==NULL. Thus no special case
    * for large kmalloc calls required.
    */
#ifdef CONFIG_ZONE_DMA
    if (unlikely(gfpflags & GFP_DMA))
        return csizep->cs_dmacachep;
#endif
    return csizep->cs_cachep;
}
```

这个函数唯一有用的部分就是这里, csizep 初始化成全局变量 `malloc_sizes`, 根据全局变量 `malloc_sizes` 的 `cs_size` 成员和 size 的大小比较, 不断后移 `malloc_sizes`, 现在就要看看 `malloc_sizes` 是怎么回事:

```cpp
struct cache_sizes malloc_sizes[] = {
#define CACHE(x) { .cs_size = (x) },
#include <linux/kmalloc_sizes.h>
         CACHE(ULONG_MAX)
#undef CACHE
};
```

观察文件 `linux/kmalloc_sizes.h` 的情况, 篇幅太大这个文件内容就不列了, 里面都是一堆的 CACHE(X)的宏声明, 根据里边的定制宏情况(`L1_CACHE_BYTES` 值为 32, `KMALLOC_MAX_SIZE` 值为 4194304), 一共声明了 CACHE(32)、CACHE(64)、CACHE(96)、CACHE(128)、CACHE(192)、CACHE(256)、CACHE(512)、CACHE(1024)、CACHE(2048)、CACHE(4096)、CACHE(8192)、CACHE(16384)、CACHE(32768)、CACHE(65536)、CACHE(131072)、CACHE(262144)、CACHE(524288)、CACHE(1048576)、CACHE(2097152)、CACHE(4194304)和最后的 CACHE(0xffffffff)共计 21 个 CACHE(X)的宏声明, 结合结构类型 struct cache_sizes, 对于 arm 它实际上有两个成员:

```cpp
struct cache_sizes {
    size_t cs_size;
    struct kmem_cache *cs_cachep;
#ifdef CONFIG_ZONE_DMA
    struct kmem_cache *cs_dmacachep;
#endif
};
```

**除 X86 以外**基本都**没有 DMA 必须在物理内存前 16MB 的限制**, 所以包括 arm 的很多体系结构都没有 `CONFIG_ZONE_DMA`, 所以本结构实际上是两个成员 `cs_size` 和 `cs_cachep`, 那么这里就比较清晰了, 全局变量 `malloc_sizes` 共有 21 个成员, 每个成员都定义了 `cs_size` 值, 从 32 到 4194304 加上 0xffffffff, `cs_cachep` 都为 NULL; 其实这些值就是 slab 分配器的一个个按长度的分档;

回到函数 `__find_general_cachep`, 已经很清晰了, 全局变量 `malloc_sizes` 的第 0 个成员开始, 当申请的内存长度比该成员的档次值 `cs_size` 大, 就换下一个成员, 直到比它小为止, 仍然如申请 100 字节的例子, 在 96 字节的分档时还比申请长度小, 在 128 字节的分档时就可以满足了, 这就是为什么说申请 100 字节实际获取到的是 128 字节的内存单元的原因.

回到函数 `__do_kmalloc`, 接下来调用的是__cache_alloc, 将按照前面确定的内存分档值给申请者分配一个相应值的内存, 这说明, 内核有能力给分配这样的内存单元;

内核为什么有能力创建这样的内存单元?slab 分配器并非一开始就能智能的根据内存分档值分配相应长度的内存的, 它需要先创建一个这样的"规则"式的东西, 之后才可以根据这个"规则"分配相应长度的内存, 看看前面的结构 `struct cache_sizes` 的定义, 里边的成员 `cs_cachep`, 它的结构类型是 `struct kmem_cache*`, 这个结构也是同样是刚才提到的缓存的概念, 每种长度的 slab 分配都得通过它对应的 cache 分配, 换句话说就是每种 cache 对应一种长度的 slab 分配, 这里顺便能看看 slab 分配接口, 一个是函数 kmalloc 一个是函数 `kmem_cache_alloc`, kmalloc 的参数比较轻松, 直接输入自己想要的内存长度即可, 由 slab 分配器去找应该是属于哪个长度分档的, 然后由那个分档的 `kmem_cache` 结构指针去分配相应长度内存, 而 `kmem_cache_alloc` 就显得比较"专业", 它不是输入我要多少长度内存, 而是直接以 `kmem_cache` 结构指针作为参数, 直接指定我要这样长度分档的内存, 稍微看看这两个函数的调用情况就可以发现它们很快都是调用函数 `__cache_alloc`, 只是前面的这些不同而已.

比如现在有一个内核模块想要申请一种它自创的结构, 这个结构是 111 字节, 并且它不想获取 128 字节内存就想获取 111 字节长度内存, 那么它需要在 slab 分配器中创建一个这样的"规则", 这个规则规定 slab 分配器当按这种"规则"分配时要给我 111 字节的内存, 这个"规则"的创建方法就是调用函数 `kmem_cache_create`;

同样, 内核 slab 分配器之所以能够默认的提供 32-4194304 共 20 种内存长度分档, 肯定也是需要创建这样 20 个"规则"的, 这是在初始化时创建的, 由函数 `kmem_cache_init`, 先不要纠结 `kmem_cache_init`, 它里边有一些道理需要在理解 slab 分配器原理后才能更好的理解, 先看 `kmem_cache_create`

## 2.2 创建 slab 的过程

直接看函数源码:

```cpp
struct kmem_cache *kmem_cache_create (const char *name, size_t size, size_t align,
         unsigned long flags, void (*ctor)(void *))
{
    size_t left_over, slab_size, ralign;
         struct kmem_cache *cachep = NULL, *pc;
         gfp_t gfp;
         /*
          * Sanity checks... these are all serious usage bugs.
          */
/*参数检查: 名字不能为 NULL、不许在中断中调用本函数(本函数可能睡眠)、
  获取长度不得小于 4 字节(CPU 字长)、获取长度不得大于最大值(1<<22 = 4MB)*/
         if (!name || in_interrupt() || (size < BYTES_PER_WORD) ||
             size > KMALLOC_MAX_SIZE) {
                   printk(KERN_ERR "%s: Early error in slab %s\n", __func__, name);
                   BUG();
         }
         /*
          * We use cache_chain_mutex to ensure a consistent view of
          * cpu_online_mask as well.  Please see cpuup_callback
          */
         if (slab_is_available()) {
                   get_online_cpus();
                   mutex_lock(&cache_chain_mutex);
         }
    /*一些检查机制, 无需关注*/
         list_for_each_entry(pc, &cache_chain, next) {
                   char tmp;
                   int res;
                   /*
                    * This happens when the module gets unloaded and doesn't
                    * destroy its slab cache and no-one else reuses the vmalloc
                    * area of the module.  Print a warning.
                    */
                   res = probe_kernel_address(pc->name, tmp);
                   if (res) {
                           printk(KERN_ERR
                                   "SLAB: cache with size %d has lost its name\n",
                                   pc->buffer_size);
                            continue;
                   }
                   if (!strcmp(pc->name, name)) {
                            printk(KERN_ERR
                                   "kmem_cache_create: duplicate cache %s\n", name);
                            dump_stack();
                            goto oops;
                   }
         }

#if DEBUG
         WARN_ON(strchr(name, ' '));  /* It confuses parsers */
#if FORCED_DEBUG
         /*
          * Enable redzoning and last user accounting, except for caches with
          * large objects, if the increased size would increase the object size
          * above the next power of two: caches with object sizes just above a
          * power of two have a significant amount of internal fragmentation.
          */
         if (size < 4096 || fls(size - 1) == fls(size-1 + REDZONE_ALIGN +
                                                        2 * sizeof(unsigned long long)))
                   flags |= SLAB_RED_ZONE | SLAB_STORE_USER;
         if (!(flags & SLAB_DESTROY_BY_RCU))
                   flags |= SLAB_POISON;
#endif
         if (flags & SLAB_DESTROY_BY_RCU)
                   BUG_ON(flags & SLAB_POISON);
#endif
         /*
          * Always checks flags, a caller might be expecting debug support which
          * isn't available.
          */
         BUG_ON(flags & ~CREATE_MASK);
         /*
          * Check that size is in terms of words.  This is needed to avoid
          * unaligned accesses for some archs when redzoning is used, and makes
          * sure any on-slab bufctl's are also correctly aligned.
          */
/*下面是一堆关于对齐的内容*/
         if (size & (BYTES_PER_WORD - 1)) {
                   size += (BYTES_PER_WORD - 1);
                   size &= ~(BYTES_PER_WORD - 1);
         }
         /* calculate the final buffer alignment: */
         /* 1) arch recommendation: can be overridden for debug */
         if (flags & SLAB_HWCACHE_ALIGN) {
                   /*
                    * Default alignment: as specified by the arch code.  Except if
                    * an object is really small, then squeeze multiple objects into
                    * one cacheline.
                    */
                   ralign = cache_line_size();
                   while (size <= ralign / 2)
                            ralign /= 2;
         } else {
                   ralign = BYTES_PER_WORD;
         }
         /*
          * Redzoning and user store require word alignment or possibly larger.
          * Note this will be overridden by architecture or caller mandated
          * alignment if either is greater than BYTES_PER_WORD.
          */
         if (flags & SLAB_STORE_USER)
                   ralign = BYTES_PER_WORD;
         if (flags & SLAB_RED_ZONE) {
                   ralign = REDZONE_ALIGN;
                   /* If redzoning, ensure that the second redzone is suitably
                    * aligned, by adjusting the object size accordingly. */
                   size += REDZONE_ALIGN - 1;
                   size &= ~(REDZONE_ALIGN - 1);
         }
         /* 2) arch mandated alignment */
         if (ralign < ARCH_SLAB_MINALIGN) {
                   ralign = ARCH_SLAB_MINALIGN;
         }
         /* 3) caller mandated alignment */
         if (ralign < align) {
                   ralign = align;
         }
         /* disable debug if necessary */
         if (ralign > __alignof__(unsigned long long))
                   flags &= ~(SLAB_RED_ZONE | SLAB_STORE_USER);
         /*
          * 4) Store it.
          */
         align = ralign;
         if (slab_is_available())
                   gfp = GFP_KERNEL;
         else
                   gfp = GFP_NOWAIT;
         /* Get cache's description obj. */
/*从 cache_cache 缓存中分配一个 kmem_cache 新实例*/
         cachep = kmem_cache_zalloc(&cache_cache, gfp);
         if (!cachep)
                   goto oops;
#if DEBUG
         cachep->obj_size = size;
         /*
          * Both debugging options require word-alignment which is calculated
          * into align above.
          */
         if (flags & SLAB_RED_ZONE) {
                  /* add space for red zone words */
                   cachep->obj_offset += sizeof(unsigned long long);
                   size += 2 * sizeof(unsigned long long);
         }
         if (flags & SLAB_STORE_USER) {
                   /* user store requires one word storage behind the end of
                    * the real object. But if the second red zone needs to be
                    * aligned to 64 bits, we must allow that much space.
                    */
                   if (flags & SLAB_RED_ZONE)
                            size += REDZONE_ALIGN;
                   else
                            size += BYTES_PER_WORD;
         }
#if FORCED_DEBUG && defined(CONFIG_DEBUG_PAGEALLOC)
         if (size >= malloc_sizes[INDEX_L3 + 1].cs_size
             && cachep->obj_size > cache_line_size() && size < PAGE_SIZE) {
                   cachep->obj_offset += PAGE_SIZE - size;
                   size = PAGE_SIZE;
         }
#endif
#endif
         /*
          * Determine if the slab management is 'on' or 'off' slab.
          * (bootstrapping cannot cope with offslab caches so don't do
          * it too early on.)
          */
         /*确定 slab 管理对象的存储方式: 内置还是外置. 通常, 当对象大于等于 512 时, 使用外置方式. 初始化阶段采用内置式(kmem_cache_init 中创建两个普通高速缓存之后就把变量 slab_early_init 置 0 了)*/
         if ((size >= (PAGE_SIZE >> 3)) && !slab_early_init)
                   /*
                    * Size is large, assume best to place the slab management obj
                    * off-slab (should allow better packing of objs).
                    */
                   flags |= CFLGS_OFF_SLAB;
         size = ALIGN(size, align);
    /*计算碎片大小, 计算 slab 由几个页面组成, 同时计算每个 slab 中有多少对象*/
         left_over = calculate_slab_order(cachep, size, align, flags);
         if (!cachep->num) {
                   printk(KERN_ERR
                          "kmem_cache_create: couldn't create cache %s.\n", name);
                   kmem_cache_free(&cache_cache, cachep);
                   cachep = NULL;
                   goto oops;
         }
    /*计算 slab 管理对象的大小, 包括 struct slab 对象和 kmem_bufctl_t 数组  */
         slab_size = ALIGN(cachep->num * sizeof(kmem_bufctl_t)
                              + sizeof(struct slab), align);
         /*
          * If the slab has been placed off-slab, and we have enough space then
          * move it on-slab. This is at the expense of any extra colouring.
          */
         /*如果这是一个外置式 slab, 并且碎片大小大于 slab 管理对象的大小, 则可将 slab 管理对象移到 slab 中, 改造成一个内置式 slab*/
         if (flags & CFLGS_OFF_SLAB && left_over >= slab_size) {
        /*去除外置标志*/
                   flags &= ~CFLGS_OFF_SLAB;
        /*碎片可以减小了!*/
                   left_over -= slab_size;
         }
    /*对于实际的外置 slab, 无需对齐管理对象, 恢复其对齐前长度*/
         if (flags & CFLGS_OFF_SLAB) {
                   /* really off slab. No need for manual alignment */
                   slab_size =
                       cachep->num * sizeof(kmem_bufctl_t) + sizeof(struct slab);
#ifdef CONFIG_PAGE_POISONING
                   /* If we're going to use the generic kernel_map_pages()
                    * poisoning, then it's going to smash the contents of
                    * the redzone and userword anyhow, so switch them off.
                    */
                   if (size % PAGE_SIZE == 0 && flags & SLAB_POISON)
                            flags &= ~(SLAB_RED_ZONE | SLAB_STORE_USER);
#endif
         }
    /*着色块单位, 为 32 字节*/
         cachep->colour_off = cache_line_size();
         /* Offset must be a multiple of the alignment. */
    /*着色块单位必须是对齐单位的整数倍*/
         if (cachep->colour_off < align)
                   cachep->colour_off = align;
    /*得出碎片区域需要多少个着色块*/
         cachep->colour = left_over / cachep->colour_off;
    /*管理对象大小*/
         cachep->slab_size = slab_size;
    cachep->flags = flags;
         cachep->gfpflags = 0;
    /*对于 arm 无需关注下面的 if, 因为不需考虑 DMA*/
         if (CONFIG_ZONE_DMA_FLAG && (flags & SLAB_CACHE_DMA))
                   cachep->gfpflags |= GFP_DMA;
    /*slab 对象的大小*/
         cachep->buffer_size = size;
    /*slab 对象的大小的倒数, 计算对象在 slab 中索引时用, 参见 obj_to_index 函数 */
         cachep->reciprocal_buffer_size = reciprocal_value(size);
    /*外置 slab, 这里分配一个 slab 管理对象, 保存在 slabp_cache 中, 如果是内置式的 slab, 此指针为空*/
         if (flags & CFLGS_OFF_SLAB) {
                   cachep->slabp_cache = kmem_find_general_cachep(slab_size, 0u);
                   /*
                    * This is a possibility for one of the malloc_sizes caches.
                    * But since we go off slab only for object size greater than
                    * PAGE_SIZE/8, and malloc_sizes gets created in ascending order,
                    * this should not happen at all.
                    * But leave a BUG_ON for some lucky dude.
                    */
                   BUG_ON(ZERO_OR_NULL_PTR(cachep->slabp_cache));
         }
    /*cache 的构造函数和名字*/
         cachep->ctor = ctor;
         cachep->name = name;
    /*设置每个 cpu 上的 local cache, 配置 local cache 和 slab 三链*/
         if (setup_cpu_cache(cachep, gfp)) {
                   __kmem_cache_destroy(cachep);
                   cachep = NULL;
                   goto oops;
         }
         /* cache setup completed, link it into the list */
         list_add(&cachep->next, &cache_chain);
oops:
         if (!cachep && (flags & SLAB_PANIC))
                   panic("kmem_cache_create(): failed to create slab `%s'\n",
                         name);
         if (slab_is_available()) {
                   mutex_unlock(&cache_chain_mutex);
                   put_online_cpus();
         }
         return cachep;
}
```

直到函数中的"if (slab_is_available()) gfp = GFP_KERNEL;"这里, 前面的都可以不用关注, 分别是运行环境和参数的检查(需要注意本函数会可能睡眠, 所以绝不能在中断中调用本函数)、一堆对齐机制的东西, 看看这一段:

```
if (slab_is_available())

         gfp = GFP_KERNEL;

else

         gfp = GFP_NOWAIT;
```

到这里首先根据当前 slab 是否初始化完成确定变量 gfp 的值, gfp 并不陌生, 它规定了从伙伴系统寻找内存的地点和方式, 这里的在 slab 初始化完成时 gfp 值为 GFP_KERNEL 说明了为什么可能会睡眠, 而 slab 初始化完成之前 gfp 值为 GFP_NOWAIT 说明不会睡眠;