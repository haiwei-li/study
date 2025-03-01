https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=858a43aae23672d46fe802a41f4748f322965182


检查下 flushmask 是否为 NULL

为 NULL 表示, 表明没有 running 的 vCPUs, 都是 preempted vCPUs

不用调用 `native_flush_tlb_others`


ebizzy -M