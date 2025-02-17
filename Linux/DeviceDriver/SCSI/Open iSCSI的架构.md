前言
    最近在搞基于 SCSI 的技术项目, 所以要学习一下 linux 对于 scsi 的实现, 以及一些 iSCSI 的知识. 以前对一些技术的学习总是没有留下学习资料, 没有传承. 这次学习 scsi 子系统, 还是要留下一些东西. 对系统有了进一步的理解, 并且能挤出时间的话, 我就会来更新这个连载.
    本次研究的主要对象是 Open iSCSI(2.0.873)/ Linux(3.11.4)/  Linux SCSI target(1.0.38)
实现架构
     如下图, 是 Linux 系统中, 一种通用的 iSCSI 的实现架构, initiator 端主要由 Open iSCSI 实现, target 端由 Linux SCSI target framework 实现. Open iSCSI 又分为用户态程序和内核模块两个部分. 而 tgt 是在纯用户态实现的 iSCSI target 程序. 以后的分析主要是 initiator 端, 也就是 Open iSCSI 的部分. 如果有需要, tgt 部分也会稍微提一下.

 iscsiadmin

    iscsiadmin 是提供给用户使用的命令行程序, 主要功能就是设置 iSCSI 的一些相关功能属性, 比如发现 iqn; 设置认证模式、用户名、密码; 连接 SCSI 设备等等. 但是 iscsiadm 又不做具体的工作, 它只是把这些信息通过 IPC 调用传递给 iscsid 这个服务程序, 由 iscsid 来执行真正的操作. 而这里的 IPC 实际上就是一个本地的 socket, iscsid 监听这个本地 socket, iscsiadm 通过这个 socket 和 iscsid 交互.
iscsid

    iscsid 可以看做是用户和内核的一个桥梁, 它通过 mgmt_ipc(本地 socket)这个东西和 iscsiadm 交互, 响应用户的请求; 利用 control_fd(netlink)和内核交互, 把用户的指令发送给内核.
scsi_transport_iscsi

    这是 iscsi 传输层, 一个内核模块. Linux 在设计的时候, 非常好的利用了面向对象的设计思想, 这个模块就可以看做是一个对 scsi 传输层的抽象, 它仅实现一些传输层通用的流程, 具体的实现由它的子类们完成.
iscsi_tcp

    基于 tcp 协议的 iSCSI 传输模块, 是上面讲到的 scsi_transport_iscsi 的具体实现. 传输层需要的基于 tcp 的数据收发就是这个模块实现的.
    这里要注意一个问题, 上图实际上少画了一条线, iscsid 到 tgtd 之间应该有一个 socket 路径. 在创建连接、session 和进行认证的时候, 实际上是 iscsid 创建了一个 socket, 和 tgtd 进行交互. 以上操作都正确完成了之后, iscsid 会将这个 socket 的句柄传递到内核, iscsi_tcp 正是使用的这个 socket.
后续计划
    后面主要会研究一下这三个方面:
iscsi 的登陆认证流程, 基于 chap 的认证流程.
iscsi 磁盘的扫描流程, 一个 target 的设备如何映射到主机上成为一个 sd 设备.
iscsi 磁盘的 IO 流程, 从读写函数开始, 一个 IO 请求是如何变成 scsi 命令, 然后发送到 target 端的.
