
specification: https://github.com/oasis-tcs/virtio-spec




Linux 虚拟化 KVM-Qemu 分析(九)之 virtio 设备: https://www.cnblogs.com/LoyenWang/p/14399642.html

qemu Virtio 设备创建流程: https://www.blogsebastian.cn/?p=58



逻辑清晰: https://blog.csdn.net/huang987246510/category_9626816.html


virtio 前端通知机制分析: http://lihanlu.cn/virtio-frontend-kick/

VIRTIO VRING 工作机制分析: https://oenhan.com/virtio-vring

virtIO 前后端 notify 机制详解: https://www.cnblogs.com/ck1020/p/6066007.html

VirtIO 实现原理——前端通知机制(core): https://blog.csdn.net/huang987246510/article/details/105496843


VirtIO 实现原理——virtio 设备初始化: https://blog.csdn.net/huang987246510/article/details/103650906

virtio-blk 初始化: https://blog.csdn.net/LPSTC123/article/details/44961579

VirtIO 实现原理——PCI 基础: https://blog.csdn.net/huang987246510/article/details/103379926

浅析 qemu iothread: https://blog.csdn.net/huang987246510/article/details/93912197


虚拟化 VirtIO 专栏: https://blog.csdn.net/huang987246510/category_9626816.html


---

https://blog.csdn.net/qq_20817327/article/details/106655211

qemu 有个参数配置 queues 的数目

```
-device virtio-blk-pci,num-queues=2
```

虚拟机内部查看如下:

```
root@ubuntu:/sys/block/vdb# ll mq/
total 0
drwxr-xr-x  4 root root 0 Jun 22 03:36 ./
drwxr-xr-x 10 root root 0 Jun 22 03:34 ../
drwxr-xr-x  6 root root 0 Jun 22 03:36 0/
drwxr-xr-x  6 root root 0 Jun 22 03:36 1/
```

多队列可以提高 IO 性能, 默认多队列个数与 vcpu 个数相同, 让每个 vcpu 可以处理一个队列, 当虚拟机 IO 压力大的时候, IO 数据可以平均到各个队列分别让每个 cpu 单独处理, 从而提高传输效率

---

