
在 ARM 架构中, Xen Hypervisor 的 Dom0(特权域)的 kernel 通常运行在 **EL1**, 而非 EL2.

# Xen Hypervisor 与 ARM 异常等级的关系

1. Xen Hypervisor 运行在 EL2

根据 ARMv8 的异常等级设计, EL2 是专为虚拟化设计的层级, 用于运行 Hypervisor. Xen 作为 Type-1 Hypervisor 直接运行在 EL2, 负责管理硬件资源(如 CPU, 调度器, 内存, 中断等)和虚拟机监控, 并控制 Stage 2 地址转换以隔离虚拟机.

2. Dom0 的角色与执行层级

Dom0 是 Xen 创建的第一个虚拟机, 具有管理特权 (如设备驱动, 虚拟机生命周期管理). 然而, Dom0 本质上仍是一个 **客户操作系统**, 其内核(如 Linux) 运行在 EL1. 这与普通虚拟机 (DomU) 的层级相同, 但 Dom0 拥有更高的硬件访问权限.

# ARM Xen 架构的隔离与效率考量

1. EL2 的专用性

EL2 是 Hypervisor 的专属层级, 用于处理虚拟化相关操作 (如陷入模拟, 中断路由), 而不直接驱动硬件. Xen 的 Dom0 需要直接与硬件交互(例如通过 Device Driver), 这要求其运行在 EL1, 以便通过 Hypervisor 的协调完成硬件访问

若 Dom0 运行在 EL2, 会导致 Hypervisor 与 Dom0 的权限边界模糊, 违反ARM架构对EL2的隔离设计, 增加安全风险. Xen 通过严格分离 EL2(Hypervisor) 和 EL1(Dom0/DomU)来确保隔离性.

2. 性能优化

Xen 在 ARM 上的设计目标是减少上下文切换. 通过将 Hypervisor 固定在 EL2, 而 Dom0 运行在 EL1, Xen 避免了频繁切换异常等级的开销. 例如, Dom0 通过 **HVC 指令** 向 Hypervisor 发起超级调用(hypercall), 而无需切换至 EL2 执行.

# ARM最新架构的扩展

根据 ARMv8.4 及后续版本, **安全状态（Secure World）** 下的 **EL2** 已被支持, 允许在**安全环境中运行 Hypervisor**. 然而, 这主要用于 TrustZone 等场景, **非安全状态（Normal World）** 下的 Xen Dom0 仍保持在 EL1

# 技术实现与例外情况

1. Dom0 的硬件访问

Dom0 虽然运行在 EL1, 但可通过 Hypervisor 授权的直通 (Passthrough) 或半虚拟化驱动直接访问硬件资源(如网卡, 存储控制器). 例如, Xen 将物理设备的 MMIO 区域重新映射给 Dom0, 使其无需依赖 EL2 即可管理设备.

2. 未来可能性与实验性方案

目前主流的 Xen 实现中, Dom0 仍运行在 EL1. 但理论上, 若修改 Xen 架构, 允许 Dom0 内核部分代码在 EL2 执行(例如实现更底层的资源管理), 需解决以下问题:

- 安全隔离: 需防止 Dom0 滥用 EL2 权限;

- 兼容性: 需调整 Hypervisor 与 Dom0 的交互机制;

目前未见公开资料支持此类方案.

# 对比 x86 架构的差异

在 x86 架构中, Xen 的 Dom0 通常运行在 **Ring 0**(最高特权级), 与 Hypervisor 共享部分权限. 而 ARM 通过异常等级实现了更严格的层级隔离, 因此 Dom0 在 ARM 上无法像 x86 那样 "贴近"Hypervisor 的特权级.

# 结论

在现有 ARM Xen 实现中, **Dom0 的 kernel 运行在 EL1**, 而 Xen Hypervisor 独占 EL2. 这种设计兼顾了安全性, 性能与架构规范性. 若需进一步验证, 可参考 Xen 官方文档或 ARMv8 虚拟化扩展的技术手册.
