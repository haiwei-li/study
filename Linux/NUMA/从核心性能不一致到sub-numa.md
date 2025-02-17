
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [参考](#参考)

<!-- /code_chunk_output -->

"那种期待一个应用就把一台主机塞满的时代是回不来了！"不同于服务传统的称之为"科学计算"的模式, 云计算的业务场景要求 CPU 的隔离性更优于性能, 尽可能的各个 core 之间是搭积木似的即可随意打通(单虚机多 CPU)又要互不干扰的. Xeon 为代表的服务器 CPU 给出的主流解决方式是单 socket, 更多核心.

PS:如果对 NUMA 概念比较模糊的话, 建议阅读本站几篇 NUMA 的帖子:

- [Linux 的 NUMA 机制](http://www.litrin.net/2014/06/18/linux%e7%9a%84numa%e6%9c%ba%e5%88%b6/)
- [深挖 NUMA](http://www.litrin.net/2017/10/31/%e6%b7%b1%e6%8c%96numa/)
- [UMA\-NUMA 之性能差异](http://www.litrin.net/2017/12/18/uma-numa%e4%b9%8b%e6%80%a7%e8%83%bd%e5%b7%ae%e5%bc%82/)

更多的核心带来更大面积的 CPU 芯片, 而更远的传输距离势必将会带一个工程上的问题: **核心之间的通讯 (C2C**)以及**内存访问(C2M**)的**时延**问题. 且不说在 CPU 时钟周期以纳秒为单位的时代, 接近光速的信号电流传输速度事实上已经成为了一面看得见摸得着且随时可以撞上的墙(c=30cm/ns). 更**要命**的是, 同样是**远近的不一致性**, 导致了**同一块 CPU！！！**上**局部核心之间**存在由于时延不同带来的性能差异, 即位置决定性能.

- C2C: 各个 CPU core 之间需要通过 L3 同步数据以及保持 L2 缓存以下的一致性问题.
- C2M: core 没有自己的内存控制器, 所有的 core 共享的是 socket 上少数几个内存控制器.





# 参考

http://www.litrin.net/2019/03/13/%E4%BB%8E%E6%A0%B8%E5%BF%83%E6%80%A7%E8%83%BD%E4%B8%8D%E4%B8%80%E8%87%B4%E5%88%B0sub-numa/