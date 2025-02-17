
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 OVS中的bridge](#1-ovs中的bridge)
* [OVS常用操作](#ovs常用操作)
* [使用OVS实现单网卡多网络平面](#使用ovs实现单网卡多网络平面)

<!-- /code_chunk_output -->

http://www.voidcn.com/article/p-ndfxasid-gr.html

https://blog.csdn.net/Moolight_shadow/article/details/52909986

https://blog.csdn.net/jiashanshan521/article/details/52266156

http://sdnhub.cn/index.php/openv-switch-full-guide/

https://blog.csdn.net/zengxiaosen/article/details/79083205

在 OVS 中, 有几个非常重要的概念: 

- Bridge: Bridge 代表一个**以太网交换机(Switch**), 一个主机中可以创建一个或者多个 Bridge 设备. 
- Port: 端口与物理交换机的端口概念类似, **每个 Port** 都隶属于**一个 Bridge**. 
- Interface: 连接到 Port 的网络接口设备. 在通常情况下, Port 和 Interface 是一对一的关系, 只有在配置 Port 为 bond 模式后, Port 和 Interface 是一对多的关系. 

注意: 网桥名字最好不要带"-"

# 1 OVS中的bridge

一个桥就是一个交换机. 在OVS中, 

```
ovs-vsctl add-br brname(br-int) 
```

当我们创建了一个**交换机(网桥**)以后, 此时**网络功能不受影响**, 但是会产生一个**虚拟网卡**, 名字就是**brname**, 之所以会产生一个虚拟网卡, 是为了实现接下来的**网桥(交换机)功能**. 有了这个交换机以后, 我还需要为**这个交换机增加端口(port**), **一个端口**, 就是一个**物理网卡**, 当网卡加入到这个交换机之后, 其工作方式就和普通交换机的一个端口的工作方式类似了. 

```
ovs-vsctl add-port brname port
```

这里要特别注意, 网卡加入网桥以后, 要按照网桥的工作标准工作, 那么加入的一个端口就必须是以混杂模式工作, 工作在**链路层**, 处理2层的帧, 所以这个port就**不需要配置IP**了. (你没见过哪个交换的端口有IP的吧)

那么接下来你可能会问, 通常的交换机不都是有一个管理接口, 可以telnet到交换机上进行配置吧, 那么在OVS中创建的虚拟交换机有木有这种呢, 有的！上面既然创建交换机brname的时候产生了一个虚拟网口brname,那么, 你给这个虚拟网卡配置了IP以后, 就相当于给交换机的管理接口配置了IP, 此时一个正常的虚拟交换机就搞定了. 

```
ip address add 192.168.1.1/24 dev brname
```

最后查看一个br的具体信息

```
[root@compute1 ~]# ovs-vsctl show
b97e9aa2-620f-40ba-b2cd-2a5b6f46d824
    Bridge "br1"
        Port "patch-to-br1-brex"
            Interface "patch-to-br1-brex"
                type: patch
                options: {peer="patch-to-br1"}
        Port "br1"
            Interface "br1"
                type: internal
```

首先, 这里显示一个名为br1的桥(交换机), 这个交换机有两个接口, 一个是patch\-to\-br1\-brex, 一个是"br1". 上面说到, 创建桥的时候会创建一个和桥名字一样的接口, 并自动作为该桥的一个端口, 那么这个虚拟接口的作用, 一方面是可以作为交换机的管理端口, 另一方面也是基于这个虚拟接口, 实现了桥的功能. 

# OVS常用操作

以下操作都需要root权限运行, 在所有命令中br0表示网桥名称, eth0为网卡名称. 

添加网桥: 

```
#ovs-vsctl add-br br0
```

列出open vswitch中的所有网桥: 

```
#ovs-vsctl list-br
```

判断网桥是否存在

```
#ovs-vsctl br-exists br0
```

将物理网卡挂接到网桥: 

```
#ovs-vsctl add-port br0 eth0
```

列出网桥中的所有端口: 

```
#ovs-vsctl list-ports br0
```

列出所有挂接到网卡的网桥: 

```
#ovs-vsctl port-to-br eth0
```

查看open vswitch的网络状态: 

```
#ovs-vsctl show
```

删除网桥上已经挂接的网口: 

```
#vs-vsctl del-port br0 eth0
```

删除网桥: 

```
#ovs-vsctl del-br br0
```

# 使用OVS实现单网卡多网络平面

首先, 安装openvswitch

```
yum install openvswitch
```

配置这个网卡的网桥使用, 记得备份哈

```
[root@controller124 ~]# cat /etc/sysconfig/network-scripts/ifcfg-br-ex
DEVICE=br-ex
DEVICETYPE=ovs
TYPE=OVSBridge
BOOTPROTO=static
IPADDR=10.121.2.124
NETMASK=255.255.255.0
GATEWAY=10.121.2.1
DNS1=114.114.114.114
ONBOOT=yes
[root@controller124 ~]# cat /etc/sysconfig/network-scripts/ifcfg-enp10s0f0
TYPE=OVSPort
DEVICETYPE=ovs
DEVICE=enp10s0f0
ONBOOT=yes
OVS_BRIDGE=br-ex
```
重启网络服务

```
systemctl restart network
```

然后使用分别创建网桥以及port连接

```
[root@controller124 ~]# ovs-vsctl add-br br1
[root@controller124 ~]# ovs-vsctl add-br br2
[root@controller124 ~]# ovs-vsctl add-br br3
[root@controller124 ~]# ovs-vsctl add-br br4
[root@controller124 ~]# ovs-vsctl list-br
br-ex
br1
br2
br3
br4
[root@controller124 ~]# ovs-vsctl add-port br-ex patch-to-br1
[root@controller124 ~]# ovs-vsctl set interface patch-to-br1 type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br1 options:peer=patch-to-br1-brex
[root@controller124 ~]# ovs-vsctl add-port br1 patch-to-br1-brex
[root@controller124 ~]# ovs-vsctl set interface patch-to-br1-brex type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br1-brex options:peer=patch-to-br1
[root@controller124 ~]#
[root@controller124 ~]#
[root@controller124 ~]# ovs-vsctl add-port br-ex patch-to-br2
[root@controller124 ~]# ovs-vsctl set interface  patch-to-br2 type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br2 options:peer=patch-to-br2-brex
[root@controller124 ~]# ovs-vsctl add-port br2 patch-to-br2-brex
[root@controller124 ~]# ovs-vsctl set interface patch-to-br2-brex type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br2-brex options:peer=patch-to-br2
[root@controller124 ~]#
[root@controller124 ~]#
[root@controller124 ~]# ovs-vsctl add-port br-ex patch-to-br3
[root@controller124 ~]# ovs-vsctl set interface patch-to-br3 type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br3 options:peer=patch-to-br3-brex
[root@controller124 ~]# ovs-vsctl add-port br3 patch-to-br3-brex
[root@controller124 ~]# ovs-vsctl set interface patch-to-br3-brex type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br3-brex options:peer=patch-to-br3
[root@controller124 ~]#
[root@controller124 ~]#
[root@controller124 ~]# ovs-vsctl add-port br-ex patch-to-br4
[root@controller124 ~]# ovs-vsctl set interface patch-to-br4 type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br4 options:peer=patch-to-br4-brex
[root@controller124 ~]# ovs-vsctl add-port br4 patch-to-br4-brex
[root@controller124 ~]# ovs-vsctl set interface patch-to-br4-brex type=patch
[root@controller124 ~]# ovs-vsctl set interface patch-to-br4-brex options:peer=patch-to-br4
[root@controller ~]# ovs-vsctl show
baea5b51-90c4-4cc2-b764-34719a29e7ac
    Bridge br-ex
        Port "patch-to-br3"
            Interface "patch-to-br3"
                type: patch
                options: {peer="patch-to-br3-brex"}
        Port "patch-to-br2"
            Interface "patch-to-br2"
                type: patch
                options: {peer="patch-to-br2-brex"}
        Port "patch-to-br4"
            Interface "patch-to-br4"
                type: patch
                options: {peer="patch-to-br4-brex"}
        Port "patch-to-br1"
            Interface "patch-to-br1"
                type: patch
                options: {peer="patch-to-br1-brex"}
        Port br-ex
            Interface br-ex
                type: internal
    Bridge "br1"
        Port "br1"
            Interface "br1"
                type: internal
        Port "patch-to-br1-brex"
            Interface "patch-to-br1-brex"
                type: patch
                options: {peer="patch-to-br1"}
    Bridge "br4"
        Port "br4"
            Interface "br4"
                type: internal
        Port "patch-to-br4-brex"
            Interface "patch-to-br4-brex"
                type: patch
                options: {peer="patch-to-br4"}
    Bridge "br2"
        Port "patch-to-br2-brex"
            Interface "patch-to-br2-brex"
                type: patch
                options: {peer="patch-to-br2"}
        Port "br2"
            Interface "br2"
                type: internal
    Bridge "br3"
        Port "br3"
            Interface "br3"
                type: internal
        Port "patch-to-br3-brex"
            Interface "patch-to-br3-brex"
                type: patch
                options: {peer="patch-to-br3"}
    ovs_version: "2.0.0"

[root@controller124 ~]# ip address add  10.121.2.134/24 dev br1
[root@controller124 ~]# ip address add  10.121.2.135/24 dev br2
[root@controller124 ~]# ip address add  10.121.2.136/24 dev br3
[root@controller124 ~]# ip address add  10.121.2.137/24 dev br4
```

ovs-vsctl add-port br-ex patch-to-br1
ovs-vsctl set interface patch-to-br1 type=patch
ovs-vsctl set interface patch-to-br1 options:peer=patch-to-br1-brex
ovs-vsctl add-port br1 patch-to-br1-brex
ovs-vsctl set interface patch-to-br1-brex type=patch
ovs-vsctl set interface patch-to-br1-brex options:peer=patch-to-br1


ovs-vsctl add-port br-ex patch-to-br2
ovs-vsctl set interface  patch-to-br2 type=patch
ovs-vsctl set interface patch-to-br2 options:peer=patch-to-br2-brex
ovs-vsctl add-port br2 patch-to-br2-brex
ovs-vsctl set interface patch-to-br2-brex type=patch
ovs-vsctl set interface patch-to-br2-brex options:peer=patch-to-br2

ovs-vsctl add-port br-ex patch-to-br3
ovs-vsctl set interface patch-to-br3 type=patch
ovs-vsctl set interface patch-to-br3 options:peer=patch-to-br3-brex
ovs-vsctl add-port br3 patch-to-br3-brex
ovs-vsctl set interface patch-to-br3-brex type=patch
ovs-vsctl set interface patch-to-br3-brex options:peer=patch-to-br3

ovs-vsctl add-port br-ex patch-to-br4
ovs-vsctl set interface patch-to-br4 type=patch
ovs-vsctl set interface patch-to-br4 options:peer=patch-to-br4-brex
ovs-vsctl add-port br4 patch-to-br4-brex
ovs-vsctl set interface patch-to-br4-brex type=patch
ovs-vsctl set interface patch-to-br4-brex options:peer=patch-to-br4

ip address add  10.121.2.154/24 dev br1
ip address add  10.121.2.155/24 dev br2
ip address add  10.121.2.156/24 dev br3
ip address add  10.121.2.157/24 dev br4