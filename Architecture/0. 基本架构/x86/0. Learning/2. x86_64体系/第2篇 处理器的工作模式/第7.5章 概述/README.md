在这一篇里, 我们将围绕处理器的几个主要工作模式进行探讨, 包括:

- 第 8 章 实地址模式
- 第 9 章 SMM 系统管理模式探索
- 第 10 章 x86/x64 保护模式体系(上)
- 第 11 章 x86/x64 保护模式体系(下)
- 第 12 章 long\-mode

本篇有 5 章, 共有 25 个实验例子.

其中, 保护模式尤为重要, 篇幅也较长, 分为上下两个部分. 第 10 章探讨保护模式下的 segmentation 管理(段式管理)下的种种行为. 例如: CS 段的加载, 以及 Stack 的管理.

第 11 章探讨保护模式下的 paging 管理(页式管理)机制, 包括 x86/x64 体系的三种分页模式: 32-bit paging, PAE paging, 以及 IA-32e paging 模式, 还对 TLB 以及 Paging\-Structure Cache 进行了介绍.

第 12 章在保护模式的基础上, 对 long\-mode 进行了总结与归纳介绍.