
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 前言](#1-前言)
* [2 调度器](#2-调度器)
* [参考](#参考)

<!-- /code_chunk_output -->

# 1 前言

本篇记录了 Openstack 在创建 Instances 时, nova-scheduler 作为调度器的工作原理和代码实现.  

Openstack 中会由多个的 Instance 共享同一个 Host, 而不是独占. 所以就需要使用调度器这种管理规则来协调和管理 Instance 之间的资源分配. 

# 2 调度器

调度器: 调度 Instance 在哪一个 Host 上运行的方式.  

目前 Nova 中实现的调度器方式由下列几种: 

- ChanceScheduler(随机调度器): 从所有正常运行 nova-compute 服务的 Host Node 中随机选取来创建 Instance

- FilterScheduler(过滤调度器): 根据指定的过滤条件以及权重来挑选最佳创建 Instance 的 Host Node . 

- Caching(缓存调度器): 是 FilterScheduler 中的一种, 在其基础上将 Host 资源信息缓存到本地的内存中, 然后通过后台的定时任务从数据库中获取最新的 Host 资源信息. 

为了便于扩展, Nova 将一个调度器必须要实现的接口提取出来成为 nova.scheduler.driver.Scheduler, 只要继承了该类并实现其中的接口, 我们就可以自定义调度器. 

注意: 不同的调度器并不能共存, 需要在 /etc/nova/nova.conf 中的选项指定使用哪一个调度器. 默认为 FilterScheduler . 

vim /etc/nova/nova.conf

```
scheduler_driver = nova.scheduler.filter_scheduler.FilterScheduler
```



# 参考

https://blog.csdn.net/Jmilk/article/details/52213999