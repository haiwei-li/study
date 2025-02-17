
AMD虚拟化(AMD-V?)构架安全虚拟机(Secure Virtual Machine, SVM)为企业级服务器虚拟软件技术设计, SVM在处理器上提供了硬件资源, 允许单个机器更有效地运行多个操作系统, 并维护安全和资源相互隔离. 

**虚拟机监视器**(Virtual Machine Monitor, VMM)也称为系统管理程序(Hypervisor), 由控制程序软件组成, 用于控制在单个物理机器上运行的多个客户操作系统. VMM给 每个客户操作系统提供了完全的计算机系统控制, 包括内存、CPU和其他周边设备. 

**VMM**在客户操作系统上以安全的方式**拦截**(**intercepting**)和**模拟**(**emulating**)硬件敏感的操作(如: 页表切换). 

AMD的SVM提供了硬件支持, 以改进虚拟化操作的性能. 

`host` 代指VMM的执行上下文.

`World switch`代指host和guest的切换.
