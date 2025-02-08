
作者: 罗冰 https://blog.csdn.net/luobing4365

# 大致规划

这次的 ACPI 探索的博客, 估计会有不少篇章. 准备从三个角度来了解ACPI的知识, 包括 UEFI 的角度、操作系统的角度和 ACPI 规范的角度. 

内容的编排不会那么规范, 想到哪里就写到哪里, 大致的计划如下: 

1) UEFI配置表中的ACPI; 
2) ACPI规范简介; 
3) 使用UEFI Protocol分析AML Code; 
4) ShellPkg中的acpiview
5) EDK2中对ACPI的实现
6) 独立于操作系统的ACPICA
7) Windows/Linux下使用ACPI分析工具
8) 其他ACPI相关课题

ACPI作为独立于操作系统的一套底层规范, 在现代操作系统中发挥了巨大的作用. 目前其规范已经移交给UEFI官网维护, 可以在UEFI.org上下载各版本的规范文档. 

本篇先借用好友lab-z博客中的方法, 通过UEFI配置表, 找到ACPI相关的各种表格, 博客地址如下: http://www.lab-z.com/studsdt/