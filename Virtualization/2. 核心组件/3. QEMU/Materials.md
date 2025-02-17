
1. QOM 模型

启动 QEMU 增加参数:

```
-qmp unix:/tmp/qmp.socket,server,nowait
```

在 QEMU 源码中, 动态 dump qom 模型

```
# cd scripts/qmp/
# ./qom-tree -s /tmp/qmp.socket
```

2. VMX 硬件支持情况

这是 CPU 支持的情况, 里面每一项都涉及到体系结构信息, 每个都是一个技术点

```
# cd scripts/kvm/
# ./vmxcap
```

源码分析: https://blog.csdn.net/u011364612/article/category/6219019

address_space_init 源码分析(GPA 的生成): https://blog.csdn.net/sinat_38205774/article/details/104312303

Qemu 内存管理代码分析: https://blog.csdn.net/shirleylinyuer/article/details/83592758

qemu 各个模块: https://richardweiyang.gitbooks.io/understanding_qemu/address_space/08-commit_mr.html

qemu 2019: https://www.shangmayuan.com/a/b5d230757e6c49aa8868099d.html , https://juejin.cn/post/6844903844455907335 ,

重要: https://www.cnblogs.com/ck1020/category/905469.html

重要: https://luohao-brian.gitbooks.io/interrupt-virtualization/qemu-kvm-zhong-duan-xu-ni-hua-kuang-jia-fen-679028-4e0a29.html

重要: https://richardweiyang-2.gitbook.io/understanding_qemu/

qemu 源码: 《QEMU/KVM 源码解析与应用》, 李强, https://item.jd.com/12720957.html



qemu tcg vs apple rosetta2 漫谈编译器核心技术 - https://zhuanlan.zhihu.com/p/393803092


qemu-参数解析:

* https://blog.csdn.net/woai110120130/article/details/107169226

* https://www.cnblogs.com/tuilinengshou/p/12818895.html

使用 QEMU 监视器管理虚拟机: https://documentation.suse.com/zh-cn/sles/15-SP2/html/SLES-all/cha-qemu-monitor.html




qemu 系统分析之实例: https://david921518.blog.csdn.net/category_12640473_2.html

