
凡是对现代计算机系统有一定了解的人都知道, 在不同的物理核之间共享数据的开销是挺大的. 一般来说, 从 register 中读取一个字长数据的开销是 1 个 cycle, 在 L1 cache 中读取的开销是 3 个 cycle, 而如果这个数据在另外一个核甚至是另外一个 node 的 cache 上, 这个开销最高可能达到 100 个 cycle. 因此, 设计高性能程序不到万不得已时不应该在不同核之间共享数据. 造成这个现象的原因是现代的 cpu 需要利用 MESI 协议来保证不同核之间 cache 的一致性(不然程序员写程序时还不得时常在想我此时读到的数据对不对?是不是最新的值?), 要发消息到 target core 再等消息回来(会引发流水线 stall?), 不慢才怪.

以上是采用 Percpu variable 的一个原因, 为了保证每个 core 对共享数据的互斥访问, 还必须得加锁, 这又带来了额外的性能开销.

而 Percpu variable 的诞生则很好地解决了以上的问题, 避免了 cache line 的乒乓问题, 也没有了锁之间的 contention. 下面就来讲一讲 linux 中 percpu variable 的实现.

在 percpu-defs.h 中有如下宏定义:

```cpp
/*
 * Variant on the per-CPU variable declaration/definition theme used for
 * ordinary per-CPU variables.
 */
#define DECLARE_PER_CPU(type, name)                 \
        DECLARE_PER_CPU_SECTION(type, name, "")

#define DEFINE_PER_CPU(type, name)                  \
        DEFINE_PER_CPU_SECTION(type, name, "")
```

于是可以用 DECLARE_PER_CPU 来申明一个 Percpu variable, 用`DEFINE_PER_CPU`来定义一个 Percpu variable.

继续往下展开, DEFINE_PER_CPU(type, name)可以变为:

```cpp
#define DEFINE_PER_CPU_SECTION(type, name, sec)             \
        __PCPU_ATTRS(sec) PER_CPU_DEF_ATTRIBUTES            \
        __typeof__(type) name

#define __PCPU_ATTRS(sec)                       \
        __percpu __attribute__((section(PER_CPU_BASE_SECTION sec))) \
        PER_CPU_ATTRIBUTES

#ifndef PER_CPU_BASE_SECTION
#ifdef CONFIG_SMP
#define PER_CPU_BASE_SECTION ".data..percpu"
#else
#define PER_CPU_BASE_SECTION ".data"
#endif
#endif
```

可以看到其实就是利用 gcc 的__attribute__关键字将这个变量放到了一个叫.data..percpu 的特殊 section 中去了, 在编译好的 vmlinuz 文件中就可以发现这个 section.

```
21:33:22 mcore-tub2:/usr/src/linux-3.13.3 # objdump -h ./vmlinux|grep percpu
        15 .data..percpu 00013b00  0000000000000000  000000000169c000  00a00000  2**12
```

在 linux 中, 除了要用以上所述特殊方式定义一个 Percpu variable, 访问一个 Percpu variable 也要遵循特定的规则, 要使用 per_cpu 宏, 这个宏有两个参数, 第一个是变量名, 第二个是 cpu 的 id. 不奇怪, 这两个参数唯一确定了一个 Percpu variable, 避免了二义性.

```cpp
extern unsigned long __per_cpu_offset[NR_CPUS];
#define per_cpu_offset(x) (__per_cpu_offset[x])

#define RELOC_HIDE(ptr, off)                    \
        ({ unsigned long __ptr;                 \
        __asm__ ("" : "=r"(__ptr) : "0"(ptr));  \
        (typeof(ptr)) (__ptr + (off)); })

/* Weird cast keeps both GCC and sparse happy. */
#define SHIFT_PERCPU_PTR(__p, __offset) ({                                  \
        __verify_pcpu_ptr((__p));                                           \
        RELOC_HIDE((typeof(*(__p)) __kernel __force *)(__p), (__offset));   \
})

/*
 * A percpu variable may point to a discarded regions. The following are
 * established ways to produce a usable pointer from the percpu variable
 * offset.
 */
#define per_cpu(var, cpu) \
        (*SHIFT_PERCPU_PTR(&(var), per_cpu_offset(cpu)))
```

简单来说就是把 var 的地址加上了一个 percpu 的偏移, 接下来的问题就明朗了, 就是这个`__per_cpu_offset`是怎么来的.

```cpp
void __init setup_per_cpu_areas(void) {
    ......
    for_each_possible_cpu(cpu) {
        per_cpu_offset(cpu) = delta + pcpu_unit_offsets[cpu];
        per_cpu(this_cpu_off, cpu) = per_cpu_offset(cpu);
        per_cpu(cpu_number, cpu) = cpu;
        setup_percpu_segment(cpu);
        setup_stack_canary_segment(cpu);
    ......
    }
}
```

以上代码可以在`arch/x86/kernel/setup_percpu.c`中找到, 含义不言自明.

由于 C 语言的语法结构简单, 所以不能够做到透明利用 Percpu variable, 必须要借助宏来做到. 后文将介绍 sv6 中 Percpu variable 的实现, 绝对让你想不到.

# 参考

http://cwndmiao.github.io/2014/03/10/percpu/