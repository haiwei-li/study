

iommu 分析之---iommu 的内核参数解析: https://www.cnblogs.com/10087622blog/p/15459332.html

热插拔: https://www.cxyzjd.com/article/weixin_39645457/85237058

PCI 设备模拟的学习: 以 edu 为例.

设备虚拟化

主要有:

- PIO/MMIO

- DMA

- Interrupt

参考:

PIO:

- http://oenhan.com/kvm-src-5-io-pio

- http://mp.weixin.qq.com/s?__biz=MzI5NzYxMTEyNw==&mid=2247483818&idx=1&sn=d25664c763700cd09b5327e1b95cd6cd&chksm=ecb33bb2dbc4b2a4343c56d49782c15221d46a218a6e8c9af7d6ae4863e2d8389879958aacb8&mpshare=1&scene=1&srcid=0104znfaEvdMfcqZnSp866L3#rd
-

MMIO:

- http://mp.weixin.qq.com/s?__biz=MzI5NzYxMTEyNw==&mid=2247483849&idx=1&sn=3c2fde425b052ca56f3d98310bce5e3d&chksm=ecb33bd1dbc4b2c7cdd3231b6f5e588cdfc119e5ae1a615034571203d2977d0f163101eae2ac&mpshare=1&scene=1&srcid=0104paOLQQ0gLNtL4rzs7e7R#rd


IO 处理流程: http://liujunming.top/2017/06/26/QEMU-KVM-I-O-%E5%A4%84%E7%90%86%E8%BF%87%E7%A8%8B/


PCI 设备的创建与初始化: https://github.com/GiantVM/doc/blob/master/pci.md