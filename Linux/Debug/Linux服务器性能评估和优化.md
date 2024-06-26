
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 影响 Linux 服务器性能的因素](#1-影响-linux-服务器性能的因素)
- [2. 系统性能评估标准](#2-系统性能评估标准)
- [3. 系统性能分析工具](#3-系统性能分析工具)
  - [3.1. 常用系统命令](#31-常用系统命令)
    - [3.1.1. 常用组合方式](#311-常用组合方式)
- [4. Linux 性能评估与优化](#4-linux-性能评估与优化)
  - [4.1. 系统整体性能评估(uptime 命令)](#41-系统整体性能评估uptime-命令)
  - [4.2. CPU 性能评估](#42-cpu-性能评估)
    - [4.2.1. 利用 vmstat 命令监控系统 CPU](#421-利用-vmstat-命令监控系统-cpu)
    - [4.2.2. 利用 sar 命令监控系统 CPU](#422-利用-sar-命令监控系统-cpu)
  - [4.3. 内存性能评估](#43-内存性能评估)
    - [4.3.1. 利用 free 指令监控内存](#431-利用-free-指令监控内存)
    - [4.3.2. 利用 vmstat 命令监控内存](#432-利用-vmstat-命令监控内存)
  - [4.4. 磁盘 I/O 性能评估](#44-磁盘-io-性能评估)
    - [4.4.1. 磁盘存储基础](#441-磁盘存储基础)
    - [4.4.2. 利用 iostat 评估磁盘性能](#442-利用-iostat-评估磁盘性能)
    - [4.4.3. 利用 sar 评估磁盘性能](#443-利用-sar-评估磁盘性能)
  - [4.5. 网络性能评估](#45-网络性能评估)

<!-- /code_chunk_output -->

# 1. 影响 Linux 服务器性能的因素

1. 操作系统级

- CPU
- 内存
- 磁盘 I/O 带宽
- 网络 I/O 带宽

2. 程序应用级

# 2. 系统性能评估标准

影响性能因素

<espace>
<table>
  <tr>
    <th rowspan="2">影响性能因素</th>
    <th colspan="3">评判标准</th>
  </tr>
  <tr>
    <th>好</th>
    <th>坏</th>
    <th>糟糕</th>
  </tr>
  <tr>
    <td>CPU</td>
    <td>user% + sys% < 70%</td>
    <td>user% + sys% = 85%</td>
    <td>user% + sys% >= 90%</td>
  </tr>
  <tr>
    <td>内存</td>
    <td>swap in(si) = 0<br/>swap out(so) = 0</td>
    <td>Per CPU with 10 page/s</td>
    <td>More Swap In & Swap Out</td>
  </tr>
  <tr>
    <td>磁盘</td>
    <td>iowait% < 20%</td>
    <td>iowait% = 35%</td>
    <td>iowait% > 50%</td>
  </tr>
</table>
</espace>

其中:
- %user: 表示 CPU 处在用户模式下的时间百分比
- %sys: 表示 CPU 处在系统模式下的时间百分比
- %iowait: 表示 CPU 等待输入输出完成时间的百分比
- swap in: 即 si, 表示虚拟内存的页导入, 从磁盘交换到内存
- swap out: 即 so, 表示虚拟内存的页导出, 从内存交换到磁盘

# 3. 系统性能分析工具

## 3.1. 常用系统命令

vmstat, sar, iostat, netstat, free, ps, top 等

### 3.1.1. 常用组合方式

- 用 vmstat, sar, iostat 检测是否是 CPU 瓶颈
- 用 free, vmstat 检测是否是内存瓶颈
- 用 iostat 检测是否是磁盘 I/O 瓶颈
- 用 netstat 检测是否是网络带宽瓶颈

# 4. Linux 性能评估与优化

## 4.1. 系统整体性能评估(uptime 命令)

```
[root@gerry ~]# uptime
 19:53:37 up 15:41,  4 users,  load average: 0.14, 0.06, 0.06
```

注意: load average 这个输出值, 这三个值的大小一般不能大于系统 CPU 的个数. 例如, 本输出中系统有 8 个 CPU,如果 load average 的三个值长期大于 8 时, 说明 CPU 很繁忙, 负载很高, 可能会影响系统性能, 但是偶尔大于 8 时, 倒不用担心, 一般不会影响系统性能. 相反, 如果 load average 的输出值小于 CPU 的个数, 则表示 CPU 还有空闲的时间片, 比如本例中的输出, CPU 是非常空闲的.

## 4.2. CPU 性能评估

### 4.2.1. 利用 vmstat 命令监控系统 CPU

该命令可显示关于系统各种资源之间相关性能的简要信息, 这里主要看 CPU 负载情况

```
[root@gerry ~]# vmstat 2 3
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0 174508 142104     20 891216    0    1   229   216  119  122 12  5 83  0  0
 0  0 174508 142364     20 891312    0    0     0     0  697  953  1  1 99  0  0
 0  0 174508 142364     20 891312    0    0     0     0  130  262  0  0 100  0  0
```

procs:

- r: 表示运行和等待 CPU 时间片的进程数, 这个值如果**长期大于系统 CPU 的个数**, 说明 CPU 不足, 需要增加 CPU.

- b: 表示等待资源的进程数, 比如正在等待 I/O, 或者内存交换等

CPU

- us: 显示用户进程消耗的 CPU 时间百分比. us 比较高时, 说明用户进程消耗的 CPU 时间多, 但**长期大于 50%**, 就需要考虑**优化程序**或**算法**

- sy: 显示内核进程消耗的 CPU 时间百分比. sy 较高时, 说明内核消耗的 CPU 资源很多. 根据经验, us\+sy 的参考值为 80%, 如果**us\+sy 大于 80%**说明可能存在**CPU 资源不足**

### 4.2.2. 利用 sar 命令监控系统 CPU

sar 功能很强, 可以对系统的每个方面都可以单独的统计, 但使用 sar 命令会增加系统开销, 不过这些开销是可评估的, 对系统的统计结果不会有很大影响

sar 命令统计 CPU 信息

```
[root@gerry ~]# sar -u 3 5
Linux 3.10.0-957.27.2.el7.x86_64 (gerry) 	2019 年 08 月 19 日 	_x86_64_	(4 CPU)

20 时 11 分 33 秒     CPU     %user     %nice   %system   %iowait    %steal     %idle
20 时 11 分 36 秒     all      0.08      0.00      0.08      0.00      0.00     99.83
20 时 11 分 39 秒     all      0.00      0.00      0.08      0.00      0.00     99.92
20 时 11 分 42 秒     all      0.50      0.00      0.42      0.00      0.00     99.08
20 时 11 分 45 秒     all      0.08      0.00      0.08      0.00      0.00     99.83
20 时 11 分 48 秒     all      0.00      0.00      0.08      0.00      0.00     99.92
平均时间:     all      0.13      0.00      0.15      0.00      0.00     99.72
```

输出的解释:

- %user: 显示了用户进程消耗的 CPU 时间百分比
- %nice: 显示了运行正常进程所消耗的 CPU 时间百分比
- %system: 显示了系统进程消耗的 CPU 时间百分比
- %iowait: 显示了 IO 等待所占用的 CPU 时间百分比
- %steal: 显示了在内存相对紧张情况下 page in 强制对不同的页面进行的 steal 操作
- %idle: 显示了 CPU 处于空闲状态的时间百分比

问题 1: 是否遇到过系统 CPU 整体利用率不高, 而应用缓慢的现象?

在一个**多 CPU**的系统中, 如果**程序**使用了**单线程**, 会出现这么一个现象, CPU 的**整体使用率不高**, 但是系统应用却响应缓慢, 这可能是由于程序使用单线程的原因, 单线程只使用一个 CPU, 导致这个 CPU 占用率为 100%, 无法处理其它请求, 而其它的 CPU 却闲置, 这就导致了整体 CPU 使用率不高, 而应用缓慢现象的发生.

## 4.3. 内存性能评估

### 4.3.1. 利用 free 指令监控内存

```
[root@gerry ~]# free -m
              total        used        free      shared  buff/cache   available
Mem:           1818         809         136          51         873         666
Swap:          2047         170        1877
```

一般而言,

- 应用程序可用内存/系统物理内存 > 70%, 表示系统内存资源非常充足, 不影响系统性能
- 应用程序可用内存/系统物理内存 < 20%, 表示系统内存资源紧缺, 需要增加系统内存
- 20% < 应用程序可用内存/系统物理内存 < 70%, 表示系统内存资源基本能满足应用需求, 暂时不影响系统性能

### 4.3.2. 利用 vmstat 命令监控内存

```
[root@gerry ~]# vmstat 2 3
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0 174508 142104     20 891216    0    1   229   216  119  122 12  5 83  0  0
 0  0 174508 142364     20 891312    0    0     0     0  697  953  1  1 99  0  0
 0  0 174508 142364     20 891312    0    0     0     0  130  262  0  0 100  0  0
```

memory:

- swpd 列表示切换到内存交换区的内存数量(以 k 为单位). 如果 swpd 的值不为 0, 或者比较大, 只要 si、so 的值长期为 0, 这种情况下一般不用担心, 不会影响系统性能.
- free 列表示当前空闲的物理内存数量(以 k 为单位)
- buff 列表示 buffers cache 的内存数量, 一般对块设备的读写才需要缓冲.
- cache 列表示 page cached 的内存数量, 一般作为文件系统 cached, 频繁访问的文件都会被 cached, 如果 cache 值较大, 说明 cached 的文件数较多, 如果此时 IO 中 bi 比较小, 说明文件系统效率比较好.

swap:

- si 列表示由磁盘调入内存, 也就是内存进入内存交换区的数量.
- so 列表示由内存调入磁盘, 也就是内存交换区进入内存的数量. 一般情况下, si、so 的值都为 0, 如果 si、so 的值长期不为 0, 则表示系统内存不足. 需要增加系统内存.

## 4.4. 磁盘 I/O 性能评估

### 4.4.1. 磁盘存储基础

- 熟悉 RAID 存储方式, 可以根据应用的不同, 选择不同的 RAID 方式
- 尽可能用内存的读写代替直接磁盘 IO, 使频繁访问的文件或数据放入内存中进行操作处理, 因为内存读写操作比直接磁盘读写的效率要高千倍
- 将经常进行读写的文件与长期不变的文件独立出来, 分别放置到不同的磁盘设备上
- 对于写操作频繁的数据, 可以考虑使用裸设备代替文件系统

使用裸设备的优点有:

- 数据可以直接读写, 不需要经过操作系统级的缓存, 节省了内存资源, 避免了内存资源争用.
- 避免了文件系统级的维护开销, 比如文件系统需要维护超级块、I-node 等.
- 避免了操作系统的 cache 预读功能, 减少了 I/O 请求.

使用裸设备的缺点是:

- 数据管理、空间管理不灵活,  需要很专业的人来操作

### 4.4.2. 利用 iostat 评估磁盘性能



### 4.4.3. 利用 sar 评估磁盘性能

通过"sar \–d"组合, 可以对系统的磁盘 IO 做一个基本的统计, 请看下面的一个输出:

```
[root@gerry ~]# sar -d 2 3
Linux 3.10.0-957.27.2.el7.x86_64 (gerry) 	2019 年 08 月 19 日 	_x86_64_	(4 CPU)

21 时 05 分 19 秒       DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
21 时 05 分 21 秒    dev8-0      1.00      0.00     10.50     10.50      0.00      0.00      0.00      0.00
21 时 05 分 21 秒  dev253-0      1.00      0.00     10.50     10.50      0.00      0.00      0.00      0.00
21 时 05 分 21 秒  dev253-1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

21 时 05 分 21 秒       DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
21 时 05 分 23 秒    dev8-0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
21 时 05 分 23 秒  dev253-0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
21 时 05 分 23 秒  dev253-1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

21 时 05 分 23 秒       DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
21 时 05 分 25 秒    dev8-0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
21 时 05 分 25 秒  dev253-0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
21 时 05 分 25 秒  dev253-1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

平均时间:       DEV       tps  rd_sec/s  wr_sec/s  avgrq-sz  avgqu-sz     await     svctm     %util
平均时间:    dev8-0      0.33      0.00      3.49     10.50      0.00      0.00      0.00      0.00
平均时间:  dev253-0      0.33      0.00      3.49     10.50      0.00      0.00      0.00      0.00
平均时间:  dev253-1      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
```

需要关注的几个参数含义:

- await 表示平均每次设备 I/O 操作的等待时间(以毫秒为单位).
- svctm 表示平均每次设备 I/O 操作的服务时间(以毫秒为单位).
- %util 表示一秒中有百分之几的时间用于 I/O 操作.

对以磁盘 IO 性能, 一般有如下评判标准:

正常情况下 svctm 应该是小于 await 值的, 而 svctm 的大小和磁盘性能有关, CPU、内存的负荷也会对 svctm 值造成影响, 过多的请求也会间接的导致 svctm 值的增加.

await 值的大小一般取决与 svctm 的值和 I/O 队列长度以及 I/O 请求模式, 如果 svctm 的值与 await 很接近, 表示几乎没有 I/O 等待, 磁盘 性能很好, 如果 await 的值远高于 svctm 的值, 则表示 I/O 队列等待太长, 系统上运行的应用程序将变慢, 此时可以通过更换更快的硬盘来解决问题.

%util 项的值也是衡量磁盘 I/O 的一个重要指标, 如果%util 接近 100%, 表示磁盘产生的 I/O 请求太多, I/O 系统已经满负荷的在工作, 该磁盘可能存在瓶颈. 长期下去, 势必影响系统的性能, 可以通过优化程序或者通过更换更高、更快的磁盘来解决此问题.

## 4.5. 网络性能评估

(1)通过 ping 命令检测网络的连通性

(2)通过 netstat \–i 组合检测网络接口状况

(3)通过 netstat \–r 组合检测系统的路由表信息

(4)通过 sar \–n 组合显示系统的网络运行状态