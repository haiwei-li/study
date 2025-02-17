https://lore.kernel.org/patchwork/cover/176034/

v2: https://linux.kernel.narkive.com/6koakwgA/patch-v2-00-12-kvm-add-asynchronous-page-fault-for-pv-guest#post2

v7: https://lkml.org/lkml/2010/10/14/118

https://www.kernelnote.com/entry/kvmguestswap

https://terenceli.github.io/%E6%8A%80%E6%9C%AF/2019/03/24/kvm-async-page-fault

2010 kvm forum: https://www.linux-kvm.org/images/a/ac/2010-forum-Async-page-faults.pdf

v6: https://linux.kernel.narkive.com/7AbMVEwr/patch-v6-11-12-let-host-know-whether-the-guest-can-handle-async-pf-in-non-userspace-context#post1

启动参数:

no-kvmapf: `[X86,KVM] Disable paravirtualized asynchronous page fault handling.`

dmesg | grep async

[    1.822108] KVM setup async PF for cpu 81
[    1.825874] KVM setup async PF for cpu 82
[    1.829800] KVM setup async PF for cpu 83
[    1.833828] KVM setup async PF for cpu 84
[    1.838012] KVM setup async PF for cpu 85
[    1.844895] KVM setup async PF for cpu 86
[    1.849222] KVM setup async PF for cpu 87