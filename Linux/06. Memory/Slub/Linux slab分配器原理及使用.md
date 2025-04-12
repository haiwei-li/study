
参考:

https://www.ibm.com/developerworks/cn/linux/l-cn-slub/

Linux slab 分配器剖析: https://www.ibm.com/developerworks/cn/linux/l-linux-slab-allocator/index.html

# slab 缓存

Linux 所使用的 slab 分配器的基础是 Jeff Bonwick 为 SunOS 操作系统首次引入的一种算法. Jeff 的分配器是围绕对象缓存进行的. 在内核中, 会为有限的对象集(例如文件描述符和其他常见结构)分配大量内存. Jeff 发现对内核中普通对象进行初始化所需的时间超过了对其进行分配和释放所需的时间. 因此他的结论是不应该将内存释放回一个全局的内存池, 而是将内存保持为针对特定目而初始化的状态. 例如, 如果内存被分配给了一个互斥锁, 那么只需在为互斥锁首次分配内存时执行一次互斥锁初始化函数(`mutex_init`)即可. 后续的内存分配不需要执行这个初始化函数, 因为从上次释放和调用析构之后, 它已经处于所需的状态中了.

Linux slab 分配器使用了这种思想和其他一些思想来构建一个在空间和时间上都具有高效性的内存分配器.

图 1 给出了 slab 结构的高层组织结构. 在最高层是 `cache_chain`, 这是一个 slab 缓存的链接列表. 这对于 best-fit 算法非常有用, 可以用来查找最适合所需要的分配大小的缓存(遍历列表). `cache_chain` 的每个元素都是一个 `kmem_cache` 结构的引用(称为一个 cache). 它定义了一个要管理的给定大小的对象池.

slab 分配器的主要结构:

![config](images/1.gif)

每个缓存都包含了一个**slabs 列表**, 这是一段**连续的内存块**(通常都是页面). 存在 3 种 slab:

- `slabs_full`: 完全分配的 slab
- `slabs_partial`: 部分分配的 slab
- `slabs_empty`: 空 slab, 或者没有对象被分配

注意 **slabs_empty** 列表中的 slab 是**进行回收(reaping)的主要备选对象**. 正是通过此过程, slab 所使用的内存被返回给操作系统供其他用户使用.

**slab 列表**中的**每个 slab**都是一个连续的内存块(一个或多个连续页), 它们被划分成一个个对象. 这些对象是从特定缓存中进行分配和释放的基本元素. 注意**slab 是 slab 分配器进行操作的最小分配单位**, 因此如果需要**对 slab 进行扩展**, 这也就是所**扩展的最小值**. 通常来说, **每个 slab 被分配为多个对象**.

由于**对象是从 slab 中进行分配和释放**的, 因此单个 slab 可以在 slab 列表之间进行移动. 例如, 当一个 slab 中的**所有对象**都被使用完时, 就从 slabs_partial 列表中移动到 slabs_full 列表中. 当一个 slab 完全被分配并且有对象被释放后, 就从 slabs_full 列表中移动到 slabs_partial 列表中. 当所有对象都被释放之后, 就从 slabs_partial 列表移动到 `slabs_empty` 列表中.

# 2 slab 背后的动机

与传统的内存管理模式相比,  slab 缓存分配器提供了很多优点. 首先, 内核通常依赖于对小对象的分配, 它们会在系统生命周期内进行无数次分配. slab 缓存分配器通过对类似大小的对象进行缓存而提供这种功能, 从而避免了常见的碎片问题. slab 分配器还支持通用对象的初始化, 从而避免了为同一目而对一个对象重复进行初始化. 最后, slab 分配器还可以支持硬件缓存对齐和着色, 这允许不同缓存中的对象占用相同的缓存行, 从而提高缓存的利用率并获得更好的性能.

# 3 API 函数

现在来看一下能够创建新 slab 缓存、向缓存中增加内存、销毁缓存的应用程序接口(API)以及 slab 中对对象进行分配和释放操作的函数.

第一个步骤是**创建 slab 缓存结构**, 您可以将其静态创建为:

```cpp
struct struct kmem_cache *my_cachep;
```

然后其他 slab 缓存函数将使用该引用进行创建、删除、分配等操作. kmem_cache 结构包含了每个中央处理器单元(CPU)的数据、一组可调整的(可以通过 proc 文件系统访问)参数、统计信息和管理 slab 缓存所必须的元素.

## 3.1 kmem_cache_create

内核函数 kmem_cache_create 用来创建一个新缓存. 这通常是在内核初始化时执行的, 或者在首次加载内核模块时执行. 其原型定义如下:

```
struct kmem_cache *
kmem_cache_create( const char *name, size_t size, size_t align,
                   unsigned long flags;
                   void (*ctor)(void*, struct kmem_cache *, unsigned long),
                   void (*dtor)(void*, struct kmem_cache *, unsigned long));
```

- name 参数定义了缓存名称, proc 文件系统(在 /proc/slabinfo 中)使用它标识这个缓存.

- size 参数指定了为这个缓存创建的对象的大小

- align 参数定义了每个对象必需的对齐.

- flags 参数指定了为**缓存启用的选项**. 这些标志如表 1 所示.

表 1. kmem_cache_create 的部分选项(在 flags 参数中指定)

选项 | 说明
---|---
SLAB_RED_ZONE | 在对象头、尾插入标志, 用来支持对缓冲区溢出的检查.
SLAB_POISON | 使用一种己知模式填充 slab, 允许对缓存中的对象进行监视(对象属对象所有, 不过可以在外部进行修改).
SLAB_HWCACHE_ALIGN | 指定缓存对象必须与硬件缓存行对齐.

ctor 和 dtor 参数定义了一个可选的对象构造器和析构器. 构造器和析构器是用户提供的回调函数. 当从缓存中分配新对象时, 可以通过构造器进行初始化.

在创建缓存之后,  kmem_cache_create 函数会返回对它的引用. 注意这个函数**并没有向缓存分配任何内存**. 相反, 在试图从缓存(**最初为空**)**分配对象**时, **refill 操作将内存分配给它**. 当**所有对象都被使用掉**时, 也可以通过相同的操作向缓存添加内存.

## 3.2 kmem_cache_destroy

内核函数 kmem_cache_destroy 用来销毁缓存. 这个调用是由**内核模块在被卸载时执行**的. 在调用这个函数时, **缓存必须为空**.

```
void kmem_cache_destroy( struct kmem_cache *cachep );
```

## 3.3 kmem_cache_alloc

要从一个命名的缓存中**分配一个对象**, 可以使用 kmem_cache_alloc 函数. 调用者提供了从中分配对象的缓存以及一组标志:

```
void kmem_cache_alloc( struct kmem_cache *cachep, gfp_t flags );
```

这个函数从缓存中返回一个对象. 注意如果**缓存目前为空**, 那么这个函数就会调用**cache_alloc_refill**向**缓存中增加内存**. kmem_cache_alloc 的 flags 选项与 kmalloc 的 flags 选项相同. 表 2 给出了标志选项的部分列表.

表 2. kmem_cache_alloc 和 kmalloc 内核函数的标志选项

标志 | 说明
---|---
GFP_USER | 为用户分配内存(这个调用可能会睡眠).
GFP_KERNEL | 从内核 RAM 中分配内存(这个调用可能会睡眠).
GFP_ATOMIC | 使该调用强制处于非睡眠状态(对中断处理程序非常有用).
GFP_HIGHUSER | 从高端内存中分配内存.

## 3.4 kmem_cache_zalloc

内核函数 kmem_cache_zalloc 与 kmem_cache_alloc 类似, 只不过它对对象执行 memset 操作, 用来在将对象返回调用者之前对其进行清除操作.

## 3.5 kmem_cache_free

要将一个对象释放回 slab, 可以使用 kmem_cache_free. 调用者提供了缓存引用和要释放的对象.

```
void kmem_cache_free( struct kmem_cache *cachep, void *objp );
```

## 3.6 kmalloc 和 kfree

内核中最常用的内存管理函数是 kmalloc 和 kfree 函数. 这两个函数的原型如下:

```
void *kmalloc( size_t size, int flags );
void kfree( const void *objp );
```

注意在 kmalloc 中, 惟一两个参数是要分配的对象的大小和一组标志(请参看 表 2 中的部分列表). 但是 kmalloc 和 kfree 使用了类似于前面定义的函数的 slab 缓存. **kmalloc 没有**为要从中分配对象的**某个 slab 缓存命名**, 而是**循环遍历可用缓存来查找可以满足大小限制的缓存**. 找到之后, 就(使用__kmem_cache_alloc)分配**一个对象**.

要使用 kfree 释放对象, 从中**分配对象的缓存**可以通过调用**virt_to_cache**确定. 这个函数会返回一个**缓存引用**, 然后在__cache_free 调用中使用该引用释放对象.

# 4 其他函数

slab 缓存 API 还提供了其他一些非常有用的函数. **kmem_cache_size**函数会返回这个**缓存所管理的对象的大小**. 您也可以通过调用**kmem_cache_name**来检索给定**缓存的名称**(在创建缓存时定义). 缓存可以通过**释放其中的空闲 slab 进行收缩**. 这可以通过调用 kmem_cache_shrink 实现. 注意这个操作(称为**回收**)是由**内核定期自动执行**的(通过**kswapd**).

```
unsigned int kmem_cache_size( struct kmem_cache *cachep );
const char *kmem_cache_name( struct kmem_cache *cachep );
int kmem_cache_shrink( struct kmem_cache *cachep );
```

# 5 slab 缓存的示例用法

下面的代码片断展示了创建新 slab 缓存、从缓存中分配和释放对象然后销毁缓存的过程.

首先, 必须要**定义一个 kmem_cache 对象**, 然后对其进行**初始化**(请参看清单 1). 这个特定的缓存包含 32 字节的对象, 并且是**硬件缓存对齐**的(由标志参数 SLAB_HWCACHE_ALIGN 定义).

清单 1. **创建新 slab 缓存**

```
static struct kmem_cache *my_cachep;

static void init_my_cache( void )
{

   my_cachep = kmem_cache_create(
                  "my_cache",            /* Name */
                  32,                    /* Object Size */
                  0,                     /* Alignment */
                  SLAB_HWCACHE_ALIGN,    /* Flags */
                  NULL, NULL );          /* Constructor/Deconstructor */

   return;
}
```

使用所分配的 slab 缓存, 您现在可以从中分配一个对象了. 清单 2 给出了一个从缓存中分配和释放对象的例子. 它还展示了两个其他函数的用法.

清单 2. **分配和释放对象**

```
int slab_test( void )
{
  void *object;

  printk( "Cache name is %s\n", kmem_cache_name( my_cachep ) );
  printk( "Cache object size is %d\n", kmem_cache_size( my_cachep ) );

  object = kmem_cache_alloc( my_cachep, GFP_KERNEL );

  if (object) {

    kmem_cache_free( my_cachep, object );

  }

  return 0;
}
```

最后, 清单 3 演示了 slab 缓存的销毁. 调用者必须确保在执行销毁操作过程中, 不要从缓存中分配对象.

清单 3. **销毁 slab 缓存**

```
static void remove_my_cache( void )
{

  if (my_cachep) kmem_cache_destroy( my_cachep );

  return;
}
```

# 6 slab 的 proc 接口

proc 文件系统提供了一种简单的方法来监视系统中所有活动的 slab 缓存. 这个文件称为 /proc/slabinfo, 它除了提供一些可以从用户空间访问的可调整参数之外, 还提供了有关所有 slab 缓存的详细信息. 当前版本的 slabinfo 提供了一个标题, 这样输出结果就更具可读性. 对于系统中的每个 slab 缓存来说, 这个文件提供了对象数量、活动对象数量以及对象大小的信息(除了每个 slab 的对象和页面之外). 另外还提供了一组可调整的参数和 slab 数据.

要调优特定的 slab 缓存, 可以简单地向 /proc/slabinfo 文件中以字符串的形式回转 slab 缓存名称和 3 个可调整的参数. 下面的例子展示了如何增加 limit 和 batchcount 的值, 而保留 shared factor 不变(格式为 "cache name limit batchcount shared factor"):

```
# echo "my_cache 128 64 8" > /proc/slabinfo
```

limit 字段表示每个 CPU 可以缓存的对象的最大数量.  batchcount 字段是当缓存为空时转换到每个 CPU 缓存中全局缓存对象的最大数量.  shared 参数说明了对称多处理器(Symmetric MultiProcessing, SMP)系统的共享行为.

注意您必须具有超级用户的特权才能在 proc 文件系统中为 slab 缓存调优参数.

# 7 SLOB 分配器

对于小型的嵌入式系统来说, 存在一个 slab 模拟层, 名为 SLOB. 这个 slab 的替代品在小型嵌入式 Linux 系统中具有优势, 但是即使它保存了 512KB 内存, 依然存在碎片和难于扩展的问题. 在禁用 CONFIG_SLAB 时, 内核会回到这个 SLOB 分配器中. 更多信息请参看 [参考资料] 一节.

# 8 链接

- "[The Slab Allocator: An Object-Caching Kernel Memory Allocator (1994)](http://citeseer.ist.psu.edu/bonwick94slab.html)" 是 Jeff Bonwick 最初的论文, 其中介绍了在 SunOS 5.4 内核内存分配器中出现的第一个 slab 分配器.
- "[The Linux Slab Allocator (200)](http://citeseer.ist.psu.edu/fitzgibbons00linux.html)" 介绍了 Linux 版本的 slab 分配器. 这篇文章介绍了 2.4 内核版本, 此后进行过更新.
- [SLOB 分配器](http://lwn.net/Articles/157944/) 是内存受限系统中的一个 SLAB 缓存实现. 可以通过内核配置启用该分配器.
- 在线书籍 [Understanding the Linux Virtual Memory Manager](http://www.phptr.com/content/images/0131453483/downloads/gorman_book.pdf)(PDF 格式)由 Mel Gorman 撰写, 详细介绍了 Linux 中的内存管理. 您可以从 Prentice Hall 下载.