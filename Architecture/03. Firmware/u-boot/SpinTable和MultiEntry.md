
在 U-Boot 中, `CONFIG_ARMV8_MULTIENTRY` 和 `CONFIG_ARMV8_SPIN_TABLE` 是用于管理 ARMv8 多核启动的关键配置选项, 二者的核心区别体现在 **从处理器** (Secondary CPU) 的**启动机制**和适用场景上:

# 功能与机制对比

## Spin-Table

`CONFIG_ARMV8_SPIN_TABLE`

### 核心机制

主处理器 (Primary CPU) 启动后, 从处理器会进入 自旋等待状态 (WFE), 并在内存中维护一个共享的启动地址表(spin-table). 当主处理器完成系统初始化后, 将内核入口地址写入该表, 随后通过唤醒指令(如 `SEV`) 通知从处理器跳转到指定地址执行.

### 依赖条件

需要主处理器主动管理从处理器的启动地址.

需要 U-Boot 在设备树 (Device Tree) 中声明 `spin-table` 内存区域的地址, 供内核使用.

代码实现

```assembly
/* 从处理器自旋等待流程(arch/arm/cpu/armv8/start.S) */
spin_table_secondary_jump:
    wfe                         // 进入低功耗等待状态
    ldr x0, spin_table_addr     // 加载共享地址
    cbz x0, spin_table_secondary_jump // 检查地址是否有效
    br x0                       // 跳转到内核入口
```

## Multi-Entry

`CONFIG_ARMV8_MULTIENTRY`

### 核心机制

从处理器在启动时直接进入轮询等待状态, 持续检查固定的内存地址(如 `cpu_release_addr`) 是否被主处理器写入有效的入口地址. 一旦发现有效地址, 立即跳转执行.

### 依赖条件

不依赖复杂的电源管理协议(如 PSCI).

通常用于无安全监控环境(Non-Secure World) 或 简单的多核启动场景.

代码实现

```assembly
/* 从处理器轮询流程(arch/arm/cpu/armv8/start.S) */
slave_cpu:
    wfe                         // 等待事件信号
    ldr x1, =cpu_release_addr   // 加载固定地址
    ldr x0, [x1]                // 读取入口地址
    cbz x0, slave_cpu           // 地址无效则继续等待
    br x0                       // 跳转执行
```

# 应用场景对比

| 配置项 | 适用场景 | 优势 | 局限性 |
|-------|---------|-----|-------|
| `CONFIG_ARMV8_SPIN_TABLE` | 需要与 安全监控(如 ATF/TrustZone) 或 虚拟化(如 Hypervisor) 配合的场景 | 标准化, 兼容性强, 支持安全状态切换 | 依赖设备树配置, 需主处理器主动管理地址表 |
| `CONFIG_ARMV8_MULTIENTRY` | 简单多核系统 (无安全监控需求) 或 快速启动场景 | 实现简单, 无需外部依赖, 资源占用低 | 不适用于需要安全隔离或复杂电源管理的场景 |

# 典型工作流程示例

## Spin-Table 启动流程

1) **主处理器初始化**: 主处理器完成硬件初始化和内存设置.

2) **从处理器等待**: 从处理器执行 `wfe` 进入低功耗状态, 等待主处理器信号.

3) **地址写入**: 主处理器将内核入口地址写入 `spin-table` 内存区域.

4) **唤醒从处理器**: 主处理器发送 `SEV` 信号唤醒从处理器, 从处理器跳转到指定地址执行.

## Multi-Entry 启动流程

1) **主处理器初始化**: 主处理器完成基础初始化, 设置 `cpu_release_addr`.

2) **从处理器轮询**: 从处理器持续检查 `cpu_release_addr` 的值.

3) **地址生效**: 主处理器写入有效地址后, 从处理器立即跳转执行.

# 配置与兼容性

## Spin-Table

需在设备树中声明 `cpu-release-addr` 属性, 例如:

```dts
cpu@1 {
    enable-method = "spin-table";
    cpu-release-addr = <0x0 0x8000fff8>;
};
```

## Multi-Entry

无需额外设备树配置, 但需确保 `cpu_release_addr` 的地址在内核中已定义.

# 总结

* `CONFIG_ARMV8_SPIN_TABLE` 是 标准化, 安全兼容性更强的启动方案, 适合与安全固件 (如 ATF) 或虚拟化扩展配合使用.

* `CONFIG_ARMV8_MULTIENTRY` 是 轻量级, 实现简单的方案, 适用于无需安全隔离的快速启动场景.

开发者需根据系统需求 (安全性, 启动速度, 资源占用) 选择合适的配置.
