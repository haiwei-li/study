
https://blog.51cto.com/11811268/1896308

有时候,一台服务器需要设置多个 ip,但又不想添加多块网卡,那就需要设置虚拟网卡.这里介绍几种方式在 Linux 服务器上添加虚拟网卡.

# 1

# 2

# 3 创建 tap

安装 rpm 包

```
yum install tunctl-1.5-12.el7.nux.x86_64
```

添加虚拟网桥

```
brctl addbr br0
```

激活虚拟网桥并查看网桥信息

```
ip link set br0 up
brctl show
```

添加虚拟网卡 tap

```
# tunctl -b
tap0 -------> 执行上面使命就会生成一个 tap,后缀从 0, 1, 2 依次递增
```

激活创建的 tap

```
ip link set tap0 up
```

将 tap0 虚拟网卡添加到指定网桥上.

```
brctl addif br0 tap0
```

给网桥配制 ip 地址

```
ifconfig br0 169.254.251.4 up
```

给 br0 网桥添加网卡 eth6

```
brctl addif br0 eth6
```

给 tap0 配置网络

```
ifconfig tap0 192.168.92.126 netmask 255.255.255.240 up
```

将 virbr1 网桥上绑定的网卡 eth5 解除

```
brctl delif virb1 eth5
```
