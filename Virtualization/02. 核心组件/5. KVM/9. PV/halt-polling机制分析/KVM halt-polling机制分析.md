
简介

在实际业务中, guest 执行**HLT 指令**是导致虚拟化 overhead 的一个重要原因. 如[1].

KVM halt polling 特性就是为了解决这一个问题被引入的, 它在 Linux 4.3-rc1 被合入主干内核, 其基本原理是当 guest idle 发生 vm-exit 时, host 继续 polling 一段时间, 用于减少 guest 的业务时延. 进一步讲, 在 vcpu 进入 idle 之后, guest 内核默认处理是执行 HLT 指令, 就会发生 vm-exit, host kernel 并不马上让出物理核给调度器, 而是 poll 一段时间, 若 guest 在这段时间内被唤醒, 便可以马上调度回该 vcpu 线程继续运行.

polling 机制带来时延上的降低, 至少是一个线程调度周期, 通常是几微妙, 但最终的性能提升是跟 guest 内业务模型相关的. 如果在 host kernel polling 期间, 没有唤醒事件发生或是运行队列里面其他任务变成 runnable 状态, 那么调度器就会被唤醒去干其他任务的事. 因此, halt polling 机制对于那些在很短时间间隔就会被唤醒一次的业务特别有效.

代码流程
guest 执行 HLT 指令发生 vm-exit 后, kvm 处理该异常, 在 kvm_emulate_halt 处理最后调用 kvm_vcpu_halt(vcpu).

int kvm_vcpu_halt(struct kvm_vcpu *vcpu){