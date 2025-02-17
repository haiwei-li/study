
进行 `VM-entry` 操作时处理器会执行严格的检查, 可以分为以下 3 个阶段.

* 第 1 阶段: 对 **VMLAUNCH** 或 **VMRESUME** **指令**的执行进行**基本检查**

* 第 2 阶段: 对当前 VMCS 内的 `VM-execution`, `VM-exit` 以及 `VM-entry` 控制区域和 `host-state` 区域进行检查.

* 第 3 阶段: 对当前 VMCS 内的 `guest-state` 区域进行检查, 并加载 MSR.

所有检查通过后, 处理器从 **guest-state 区域**里加载**处理器状态和执行环境信息**. 如果设置需要加载**MSR**, 则接着从 **VM-entry MSR-load MSR 列表区域里加载 MSR**.

**VM-entry 操作**附加动作会**清由执行 MONITOR 指令而产生的地址监控(！！！**), 这个措施可**防止 guest 软件检测到自己处于虚拟机(！！！**)内.

在**成功完成 VM-entry** 后, 如果**注入了一个向量事件**, 则通过 **guest\-IDT** 立即 **deliver 这个向量事件执行**. 如果存在 pending debug exception 事件, 则在**注入事件完成后 deliver 一个 #DB 异常执行**.

注意: 在整个 VM\-entry 操作流程中, 如果 VM\-entry 失败可能产生下面三种结果:

(1) VMLAUNCH 和 VMRESUME 指令产生异常, 从而执行相应的异常服务例程.

(2) VMLAUCH 和 VMRESUME 指令产生 VMfailValid 或 VMfailValid 类型失败, 处理器接着执行下一条指令.

(3) VMLAUNCH 和 VMRESUME 指令的执行由于检查 guest-state 区域不通过, 或在加载 MSR 阶段失败而产生 VM-exit, 从而转入 host-RIP 的入口点执行.

在前面所述的第 1 阶段检查里, 可能会产生第 1 种或第 2 中结果. 在第 2 阶段检查, 可能会产生第 2 种结果. 在第 3 阶段检查可能会产生第 3 种结果.


