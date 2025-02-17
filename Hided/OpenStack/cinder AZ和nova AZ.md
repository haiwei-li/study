
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 Boot from volume](#1-boot-from-volume)
	* [1.1 问题](#11-问题)
	* [1.2 解决](#12-解决)
* [参考](#参考)

<!-- /code_chunk_output -->

# 1 Boot from volume

## 1.1 问题

今天处理了一个 Boot from volume 失败的问题, 错误日志给出了明确的原因: The instance and volume are not in the same AZ. 

```
BuildAbortException: Build of instance aa701728-f40b-47e7-b8ed-2302f1bff226 aborted: Invalid volume: Instance 2216 and volume bbbd66b4-761f-4096-b8f7-4feeb04c4b44 are not in the same availability_zone. Instance is in ovs. Volume is in nova
```

## 1.2 解决

AZ 的含义是为了划分不同的故障域, 开始只是 Nova 的概念, 但由于 Instance 与 Volume 的紧密联系, AZ 的概念自然被延伸至 Cinder. 在 nova.conf 的 [cinder] Section 中可以找到 `Option cross_az_attach = False|True`, 当其为 True 时表示允许跨 AZ 挂载卷, 反之则不能. 在生产环境中一般建议设置为 False, 由此导致了上述的问题. 因为我们希望创建一个处于 AZ:ovs 的 Instance, 但指定的 Cinder backend 默认却处于 AZ:nova. e.g.

```
# cinder.conf
[DEFAULT]
...
storage_availability_zone = nova
default_availability_zone = nova
```

解决这个问题的办法自然就是将预期的 Cinder backend 也划分至 AZ:ovs 中: 

```
# cinder.conf
[DEFAULT]
...
storage_availability_zone = ovs
default_availability_zone = ovs
```

此后创建该 Backend 的 Volumes 也需要显式的指定 AZ 参数: 

```
openstack volume create --type ovs_backend --availability-zone ovs ...
```

如此这般, 保证了 Nova 和 Cinder 处于同一个 AZ, 卷挂载自然就没有问题了. 


# 参考

- https://blog.csdn.net/jmilk/article/details/89917583
- https://segmentfault.com/a/1190000011033324
- cinder可用域问题分析: https://wenku.baidu.com/view/b221e07eb5daa58da0116c175f0e7cd184251802.html
- https://www.mirantis.com/blog/the-first-and-final-word-on-openstack-availability-zones/