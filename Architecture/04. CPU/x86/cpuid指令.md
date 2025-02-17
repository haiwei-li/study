
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 什么是 cpuid 指令](#1-什么是-cpuid-指令)
- [2 cpuid 指令的使用](#2-cpuid-指令的使用)
- [3 获得 CPU 的制造商信息(Vender ID String)](#3-获得-cpu-的制造商信息vender-id-string)
- [4 获得 CPU 商标信息(Brand String)](#4-获得-cpu-商标信息brand-string)
- [5. 检测 CPU 特性(CPU feature)](#5-检测-cpu-特性cpu-feature)

<!-- /code_chunk_output -->

https://baike.baidu.com/item/CPUID/5559847

CPU ID 指用户计算机当今的信息**处理器的信息**.  信息包括型号信息处理器家庭高速缓存尺寸钟速度和制造厂 codename 等. 通过查询可以知道一些信息: 晶体管数针脚类型尺寸等.

# 1 什么是 cpuid 指令

**CPUID 指令**是 intel IA32 架构下**获得 CPU 信息**的汇编指令可以得到 CPU 类型型号制造商信息商标信息序列号缓存等一系列 CPU 相关的东西.

# 2 cpuid 指令的使用

cpuid 使用**eax 作为输入参数****eaxebxecxedx 作为输出参数**举个例子:

```x86asm
__asm
{
mov eax, 1
cpuid
...
}
```

以上代码**以 1 为输入参数**执行**cpuid**后**所有寄存器的值都被返回值填充**. 针对不同的输入参数 eax 的值输出参数的意义都不相同.

# 3 获得 CPU 的制造商信息(Vender ID String)

把**eax = 0 作为输入参数**可以得到 CPU 的**制造商信息**.

cpuid 指令执行以后会返回一个**12 字符的制造商信息**前四个字符的 ASC 码按**低位到高位放在 ebx****中间四个放在 edx**最后四个字符放在**ecx**. 比如说对于 intel 的 cpu 会返回一个"GenuineIntel"的字符串返回值的存储格式为:

```
31 23 15 07 00
EBX| u (75)| n (6E)| e (65)| G (47)
EDX| I (49)| e (65)| n (6E)| i (69)
ECX| l (6C)| e (65)| t (74)| n (6E)
```

# 4 获得 CPU 商标信息(Brand String)

由于商标的字符串很长(48 个字符)所以不能在一次 cpuid 指令执行时全部得到所以 intel 把它分成了 3 个操作 eax 的输入参数分别是 0x80000002,0x80000003,0x80000004 每次返回的 16 个字符按照从低位到高位的顺序依次放在 eax, ebx, ecx, edx. 因此可以用循环的方式每次执行完以后保存结果然后执行下一次 cpuid.

# 5. 检测 CPU 特性(CPU feature)

CPU 的特性可以通过 cpuid 获得参数是 eax = 1 返回值放在 edx 和 ecx 通过验证 edx 或者 ecx 的某一个 bit 可以获得 CPU 的一个特性是否被支持. 比如说 edx 的 bit 32 代表是否支持 MMXedx 的 bit 28 代表是否支持 Hyper-Threadingecx 的 bit 7 代表是否支持 speed step.