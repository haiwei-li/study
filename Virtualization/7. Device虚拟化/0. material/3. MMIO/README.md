
http://chinaunix.net/uid-28541347-id-5789579.html

https://kernelgo.org/mmio.html

https://cloud.tencent.com/developer/article/1087477


intel 有个 mmio 加速: https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=68c3b4d1676d870f0453c31d5a52e7e65c7448ae

amd 是否可做???

暂停 amd kvm 上 fast mmio bus 的实现, intel kvm 上利用 ept misconfig 来节省遍历页表和解码指令, intel 上 ept misconfig 的时候硬件会解码出指令的长度, 虽然 SDM 没有规定. amd 上没有 ept misconfig, 只有 npf_intercept, 这个 amd 硬件不会解码出指令的长度, 也就是说, 快速模拟 mmio 操作后, 无法 skip 当前指令, 因为不知道长度是多大, 只能走慢速路径, 软件解码指令的长度, 这样 fast mmio bus 操作就失去了意义.

