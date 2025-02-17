
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [CPU ID](#cpu-id)
  - [Type(类型)](#type类型)
  - [Family(系列)](#family系列)
  - [Mode(型号)](#mode型号)
  - [Stepping(步进编号)](#stepping步进编号)
  - [Brand ID(品种标识)](#brand-id品种标识)

<!-- /code_chunk_output -->

![config](./images/26.png)

/proc/cpuinfo 文件的内容包括有:

```
vendor_id : GenuineIntel
cpu family: 6
model     : 23
model name: Intel(R) Core(TM)2 Quad CPU    Q9400  @ 2.66GHz
stepping  : 10
```

这里面

**vendor\_id**: **CPU 制造商**

**cpu family**: CPU 产品**系列代号**. 此分类标识英特尔**微处理器的品牌**以及**属于第几代产品**. 例如, 当今的 P6 系列(第六代)英特尔微处理器包括英特尔 Celeron、Pentium II、Pentium II Xeon、Pendum IⅡ和 Pentium III Xeon 处理器.

- "1"表示为 8086 和 80186 级芯片;
- "2"表示为 286 级芯片;
- "3"表示为 386 级芯片;
- "4"表示为 486 级芯片(SX、DX、: DX2、DX4);
- "5"表示为 P5 级芯片(经典奔腾和多能奔腾);
- "6"表示为 P6 级芯片(包括 Celeron、PentiumII、PenfiumIII 系列);
- "F"代表奔腾Ⅳ.

**model**: CPU 属于**其系列**中的**哪一代的代号**. "型号"编号可以让英特尔识别微处理器的制造技术以及属于**第几代设计**(例如型号 4). **型号与系列**通常是**相互配合使用**的, 用以确定您的计算机中所安装的处理器是属于处理器系列中的哪一种特定类型. 在与英特尔联系时, 此信息通常用以识别特定的处理器.

- "1"为 Pentium Pro(高能奔腾);
- "2"为 Pentium Pro(高能奔腾);
- "3"为 Klamath(Pentium II);
- "4"为 Deschutes(Pentium II);
- "5"为 Covington(Celeron);
- "6"为 Mendocino(Celeron A);
- "7"为 Katmai(Penfium III);
- "8"为 Coppermine(Penfium III)

**model name**: CPU 属于的**名字**及其**编号**、标称**主频**

**stepping**: CPU 属于**制作更新版本**. Stepping ID(步进)也叫分级鉴别产品数据转换规范,  "步进"编号标识生产英特尔微处理器的**设计或制造版本数据**(例如步进 4). 步进用于标识一次"**修订**", 通过使用唯一的步进, 可以有效地控制和跟踪所做的更改. 步进还可以让最终用户**更具体地识别其系统所安装的处理器版本**. 在尝试确定微处理器的内部设计或制造特性时, 英特尔可能会需要使用此分类数据.

- Katmai Stepping 含义: "2"为 kB0 步进; "3"为 kC0 步进.
- Coppermine Stepping 含义: "l"为 cA2 步进; "3"为 cB0 步进; "6"为 cC0 步进.

# CPU ID

CPU ID 是 CPU 生产厂家为识别不同类型的 CPU, 而为 CPU 制订的不同的单一的代码; 不同厂家的 CPU, 其 CPU ID 定义也是不同的; 如"0F24"(Inter 处理器)、"681H"(AMD 处理器), 根据这些数字代码即可判断 CPU 属于哪种类型, 这就是一般意义上的 CPU ID.

由于计算机使用的是十六进制, 因此 CPUID 也是以十六进制表示的. Inter 处理器的 CPU ID 一共包含四个数字, 如"0F24", 从左至右分别表示 Type(类型)、Family(系列)、Mode(型号)和 Stepping(步进编号). 从 CPUID 为"068X"的处理器开始, Inter 另外增 加了 Brand ID(品种标识)用来辅助应用程序识别 CPU 的类型, 因此根据"068X"CPUID 还不能正确判别 Pentium 和 Celerom 处理 器. 必须配合 Brand ID 来进行细分. AMD 处理器一般分为三位, 如"681", 从左至右分别表示为 Family(系列)、Mode(型号)和 Stepping(步进编号).

## Type(类型)

类型标识用来区别 INTEL 微处理器是用于由最终用户安装, 还是由专业个人计算机系 统集成商、服务公司或制作商安装; 数字"1"标识所测试的微处理器是用于由用户安装的; 数字"0"标识所测试的微处理器是用于由专业个人计算机系统集成 商、服务公司或制作商安装的. 我们通常使用的 INTEL 处理器类型标识都是"0", "0F24"CPUID 就属于这种类型.

## Family(系列)

系列标识可用来确定处理器属于那一代产品. 如 6 系列的 INTEL 处理器包括 Pentium Pro、Pentium II、Pentium II Xeon、Pentium III 和 Pentium III Xeon 处理器. 5 系列(第五代)包括 Pentium 处理器和采用 MMX 技术的 Pentium 处理器. AMD 的 6 系列实际指有 K7 系列 CPU, 有 DURON 和 ATHION 两大类. 最新一代的 INTEL Pentium 4 系列处理器(包括相同核心的 Celerom 处理器)的系列值为"F"

## Mode(型号)

型号标识可用来 确定处理器的制作技术以及属于该系列的第几代设计(或核心), 型号与系列通常是相互配合使用的, 用于确定计算机所安装的处理器是属于某系列处理器的哪种特 定类型. 如可确定 Celerom 处理器是 Coppermine 还是 Tualutin 核心; Athlon XP 处理器是 Paiomino 还是 Thorouhgbred 核心.

## Stepping(步进编号)

步进编号用来标识处理器的设计或制作版本, 有助于控制和跟踪处理器的更改, 步进还可以让最终用户更具体地识别其系统安装的处理器版本, 确定微处理器的内部设计或制作特性. 步进编号就好比处理器的小版本号, 如 CPUID 为"686"和"686A"就好比 WINZIP8.0 和 8.1 的关系. 步进编号和核心步进是密切联系的. 如 CPUID 为"686"的 Pentium III 处理器是 cCO 核心, 而"686A"表示的是更新版本 cD0 核心.

## Brand ID(品种标识)

INTEL 从 Coppermine 核心的处理器开始引入 Brand ID 作为 CPU 的辅助识别手段. 如我们通过 Brand ID 可以识别出处理器究竟是 Celerom 还是 Pentium 4.


如上的计算机的 CPUID 为 7A 06 01 00 FF FB EB BF.

而它对应的 DisplayFamily\_DisplayModel 为, 06\_17H, 因为十六进制的 17 为 23, 详细内容参见: Intel(R) 64 and IA-32 Architectures Software Developer's Manual Volume 3 (3A, 3B & 3C): System Programming Guide 中 CHAPTER 35 MODEL-SPECIFIC REGISTERS (MSRS) Table 35-1. CPUID Signature Values of DisplayFamily\_DisplayModel