第 4 章
- 4.1 80x86 系统寄存器和系统指令
    - 4.1.1 标志寄存器
    - 4.1.2 内存管理寄存器
    - 4.1.3 控制寄存器
    - 4.1.4 系统指令
- 4.2 保护模式内存管理
    - 4.2.1 内存寻址
    - 4.2.2 地址变换
    - 4.2.3 保护
- 4.3 分段机制
    - 4.3.1 段的定义
    - 4.3.2 段描述符表
    - 4.3.3 段选择符
    - 4.3.4 段描述符
    - 4.3.5 代码和数据段描述符类型
    - 4.3.6 系统描述符类型
- 4.4 分页机制
    - 4.4.1 页表结构
    - 4.4.2 页表项格式
    - 4.4.3 虚拟存储
- 4.5 保护
    - 4.5.1 段级保护
    - 4.5.2 访问数据段时的特权级检查
    - 4.5.3 代码段之间转移控制时的特权级
    - 4.5.3 代码段之间转移控制时的特权级
    - 4.5.4 页级保护
    - 4.5.5 组合页级和段级保护
- 4.6 中断和异常处理
    - 4.6.1 异常和中断向量
    - 4.6.2 中断源和异常源
    - 4.6.3 异常分类
    - 4.6.4 程序或任务的重新执行
    - 4.6.5 开启和禁止中断
    - 4.6.6 异常和中断的优先级
    - 4.6.7 中断描述符表
    - 4.6.8 IDT 描述符
    - 4.6.9 异常与中断处理
    - 4.6.10 中断处理任务
    - 4.6.11 错误码
- 4.7 任务管理
    - 4.7.1 任务的结构和状态
    - 4.7.2 任务的执行
    - 4.7.3 任务管理数据结构
    - 4.7.4 任务切换
    - 4.7.5 任务链
    - 4.7.6 任务地址空间
- 4.8 保护模式编程初始化
    - 4.8.1 进入保护模式时的初始化操作
    - 4.8.2 模式切换
- 4.9 一个简单的多任务内核实例
    - 4.9.1 多任务程序结构和工作原理
    - 4.9.2 引导启动程序 boot.s
    - 4.9.3 多任务内核程序 head.s