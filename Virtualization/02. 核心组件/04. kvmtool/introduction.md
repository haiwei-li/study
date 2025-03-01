http://www.biscuitos.cn/blog/kvmtool-on-BiscuitOS/

https://zhuanlan.zhihu.com/p/545241171

从 kvmtools 学习虚拟化一 基础介绍: https://zhuanlan.zhihu.com/p/583201080

KVM-api学习--基于kvmtool: https://zhuanlan.zhihu.com/p/545241171



lkvm run --name BiscuitOS-kvm --cpus 2 --mem 128 --disk BiscuitOS.img --kernel bzImage --params "loglevel=3"

lkvm run --kernel ./vmlinuz-5.10.75-sunxi64 --disk ./ramdisk --name rzl-vm --cpus 1 --mem 512



