
以下全部来自 Intel 手册, 章节号已经标出

# 1. [30.1]PERFORMANCE MONITORING OVERVIEW

从 Pentium 奔腾处理器开始 Intel 引入了**一组计数寄存器**用于做**系统性能监视**(System Performance monitoring). 针对**不同型号的 CPU 处理器**它们各自拥有的**性能计数寄存器是不同**的因此相对 ISA 标准的普通寄存器而言这些寄存器被称之为属于 PMU 中的 MSR 寄存器.

- PMU: Performance Monitoring Unit 性能监视单元
- MSR: Model\-Specific Register

性能计数器允许用户对选定的处理器参数进行监视和统计根据这些统计值进行系统调优. 从 Intel P6 开始性能监视机制得到了进一步的改进和增强允许用户选择更广泛的事件进行监控. 在奔腾 4 以及至强处理器又引入了新的性能监视机制和一组新的性能监视事件.

从 Intel Core Solo and Intel Core Duo 处理器开始性能监视事件被分为两类:

1. non\-architectural performance events(后文简称为特定架构事件、特定架构监视事件)

model\-specific 即不同型号的处理器各自所拥有的不同事件.

2. architectural performance events(后文简称为架构兼容事件、架构兼容监视事件)

compatible among processor families 即在不同型号的处理器之间是兼容的事件. 因为要提供各个型号处理器之间的兼容因此这一类事件比较少.

# 2. [30.2]ARCHITECTURAL PERFORMANCE MONITORING

如果**性能监视事件**在不同微架构上的**性能保存一致**那么它就是架构兼容事件. 架构兼容事件可以在处理器发展过程中逐步增强也就是可以认为架构兼容事件具有版本更新的概念即在新型号的处理器上提供的架构兼容事件可能要比旧型号的处理器要多同一个架构兼容事件的功能可能也要更强大. 通过**CPUID\.0AH**可以获取到**当前处理器**支持的**架构兼容事件版本 ID**.

## 2.1 [30.2.1]Architectural Performance Monitoring Version 1

通过**两组寄存器**来实现对**架构兼容事件的使用**一组为**事件选择寄存器(IA32\_PERFEVTSELx**)一组为**计数寄存器(IA32\_PMCx**)这两组寄存器是一一对应的另外它们的个数也非常有限.

为了保证这两组寄存器在各个架构之间兼容它们有如下一些约定:

1. 在各个微架构之间 IA32\_PERFEVTSELx 的 bit 位布局是一致的.
2. 在各个微架构之间 IA32\_PERFEVTSELx 的地址是不变的.
3. 在各个微架构之间 IA32\_PMCx 的地址是不变的.
4. **每一个逻辑处理器**拥有**它自己的 IA32\_PERFEVTSELx 和 IA32\_PMCx(！！！**). 也就是说如果**某一个处理器 core**上有**两个逻辑处理器, 即两个 thread**那么这两个逻辑处理器拥有它各自的 IA32\_PERFEVTSELx 和 IA32\_PMCx.

### 2.1.1 [30.2.1.1]Architectural Performance Monitoring Version 1 Facilities

**每一个逻辑处理器(logic processor！！！**)拥有的**MSR 寄存器 IA32\_PERFEVTSELx 和 IA32\_PMCx 对数**可以通过**CPUID\.0AH\:EAX\[15\:8**\]获取. 这些 MSR 寄存器有如下一些特点:

1. **IA32\_PMCx 寄存器**的**起始地址为 0C1H**并且占据**一块连续的 MSR 地址空间**.

对应到 linux-3.10 内核代码为宏:
```
#define MSR_ARCH_PERFMON_PERFCTR0                 0xc1
```

2. IA32_PERFEVTSELx 寄存器的起始地址为 186H 并且占据一块连续的 MSR 地址空间. 从该地址开始的每一个 IA32_PERFEVTSELx 寄存器与从 0C1H 开始的 IA32_PMCx 寄存器一一对应.

对应到 linux-3.10 内核代码为宏:
```
#define MSR_ARCH_PERFMON_EVENTSEL0               0x186
```

3. 通过 CPUID.0AH:EAX[23:16]可获取 IA32_PMCx 寄存器的 bit 位宽.

4. 在各个微架构之间 IA32_PERFEVTSELx 的 bit 位布局是一致的.

IA32_PERFEVTSELx 寄存器的 bit 位布局如下:

- 0-7: Event select field 事件选择字段
- 8-15: Unit mask (UMASK) field 事件检测掩码字段
- 16: USR (user mode) flag 设置仅对用户模式(privilege levels 1, 2 or 3)进行计数可以和 OS flag 一起使用.
- 17: OS (operating system mode) flag 设置仅对内核模式(privilege levels 0)进行计数可以和 USR flag 一起使用.
- 18: E (edge detect) flag
- 19: PC (pin control) flag 如果设置为 1 那么当性能监视事件发生时逻辑处理器就会增加一个计数并且"toggles the PMi pins"; 如果清零那么当性能计数溢出时处理器就会"toggles the PMi pins". "toggles the PMi pins"不好翻译其具体定义为: "The toggling of a pin is defined as assertion of the pin for a single bus clock followed by deassertion."对于此处我的理解也就是把 PMi 针脚激活一下从而触发一个 PMI 中断.
- 20: INT (APIC interrupt enable) flag 如果设置为 1 当性能计数溢出时就会通过 local APIC 来触发逻辑处理器产生一个异常.
- 21: 保留
- 22: EN (Enable Counters) Flag 如果设置为 1 性能计数器生效否则被禁用.
- 23: INV (invert) flag 控制是否对 Counter mask 结果进行反转.
- 24-31: Counter mask (CMASK) field 如果该字段不为 0 那么只有在单个时钟周期内发生的事件数大于等于该值时对应的计数器才自增 1. 这就可以用于统计每个时钟周期内发生多次的事件. 如果该字段为 0 那么计数器就以每时钟周期按具体发生的事件数进行增长.
- 32-63: 保留

对应到 linux-3.10 内核代码为宏:
```
#define ARCH_PERFMON_EVENTSEL_EVENT         0x000000FFULL
#define ARCH_PERFMON_EVENTSEL_UMASK         0x0000FF00ULL
#define ARCH_PERFMON_EVENTSEL_USR           (1ULL << 16)
#define ARCH_PERFMON_EVENTSEL_OS            (1ULL << 17)
#define ARCH_PERFMON_EVENTSEL_EDGE          (1ULL << 18)
#define ARCH_PERFMON_EVENTSEL_PIN_CONTROL       (1ULL << 19)
#define ARCH_PERFMON_EVENTSEL_INT           (1ULL << 20)
#define ARCH_PERFMON_EVENTSEL_ANY           (1ULL << 21)
#define ARCH_PERFMON_EVENTSEL_ENABLE            (1ULL << 22)
#define ARCH_PERFMON_EVENTSEL_INV           (1ULL << 23)
#define ARCH_PERFMON_EVENTSEL_CMASK         0xFF000000ULL
```

## 2.2 Additional Architectural Performance Monitoring Extensions

第二个版本的架构兼容监视机制包含如下增强特性:

1. 提供有三个固定功能的性能计数器 IA32_FIXED_CTR0、IA32_FIXED_CTR1 和 IA32_FIXED_CTR2 每一个固定功能性能计数器一次只能统计一个事件. 通过写位于地址 38DH 的 IA32_FIXED_CTR_CTRL 寄存器 bit 位来配置这些固定功能性能计数器而不再是像通用 IA32_PMCx 性能计数器那样通过对应 IA32_PERFEVTSELx 寄存器来配置.

对应到 linux-3.10 内核代码的相关宏为:
```
/*

* All 3 fixed-mode PMCs are configured via this single MSR:

*/
#define MSR_ARCH_PERFMON_FIXED_CTR_CTRL 0x38d

/*

* The counts are available in three separate MSRs:

*/

/* Instr_Retired.Any: */
#define MSR_ARCH_PERFMON_FIXED_CTR0 0x309
#define INTEL_PMC_IDX_FIXED_INSTRUCTIONS    (INTEL_PMC_IDX_FIXED + 0)

/* CPU_CLK_Unhalted.Core: */
#define MSR_ARCH_PERFMON_FIXED_CTR1 0x30a
#define INTEL_PMC_IDX_FIXED_CPU_CYCLES  (INTEL_PMC_IDX_FIXED + 1)

/* CPU_CLK_Unhalted.Ref: */
#define MSR_ARCH_PERFMON_FIXED_CTR2 0x30b
#define INTEL_PMC_IDX_FIXED_REF_CYCLES  (INTEL_PMC_IDX_FIXED + 2)
#define INTEL_PMC_MSK_FIXED_REF_CYCLES  (1ULL << INTEL_PMC_IDX_FIXED_REF_CYCLES)

/*

* We model BTS tracing as another fixed-mode PMC.

*

* We choose a value in the middle of the fixed event range, since lower

* values are used by actual fixed events and higher values are used

* to indicate other overflow conditions in the PERF_GLOBAL_STATUS msr.

*/
#define INTEL_PMC_IDX_FIXED_BTS             (INTEL_PMC_IDX_FIXED + 16)

```

2. 简化的事件编程一般的编程操作也就是启用事件计数、禁用事件计数、检测计数溢出因此提供有三个专门的架构兼容 MSR 寄存器:
- IA32_PERF_GLOBAL_CTRL: 允许软件通过一条 WRMSR 指令实现对所有或任何组合的 IA32_FIXED_CTRx 或任意 IA32_PMCx 进行启用或禁用事件计数的操作.
- IA32_PERF_GLOBAL_STATUS: 允许软件通过一条 RDMSR 指令实现对任何组合的 IA32_FIXED_CTRx 或任意 IA32_PMCx 的溢出状态的查询操作.
- IA32_PERF_GLOBAL_OVF_CTRL: 允许软件通过一条 WRMSR 指令实现对任何组合的 IA32_FIXED_CTRx 或任意 IA32_PMCx 的溢出状态的清除操作.

对应到 linux-3.10 内核代码的相关宏为:
```
/* Intel Core-based CPU performance counters */
#define MSR_CORE_PERF_FIXED_CTR0    0x00000309
#define MSR_CORE_PERF_FIXED_CTR1    0x0000030a
#define MSR_CORE_PERF_FIXED_CTR2    0x0000030b
#define MSR_CORE_PERF_FIXED_CTR_CTRL    0x0000038d
#define MSR_CORE_PERF_GLOBAL_STATUS 0x0000038e
#define MSR_CORE_PERF_GLOBAL_CTRL   0x0000038f
#define MSR_CORE_PERF_GLOBAL_OVF_CTRL   0x00000390
```