《深入浅出 SSD》

第 5 章 PCIe 介绍

```
1. 从速度说起
 ├─ Lane
 ├─ Link
 ├─ 工作模式
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
2. PCIe 拓扑结构
 ├─ 计算机拓扑
 ├─ PCI 总线型拓扑
 └─ PCIe 树形拓扑
    ├─ RC
    │  └─ 内部构成
    ├─ Endpoint
    ├─ Switch
    │  └─ 内部构成
    └─ 小结
```

```
3. PCIe 分层结构
 ├─ PCIe 的三层结构
 ├─ 各层细节
 ├─ 发送方打包 TLP 过程
 ├─ 接收方解包 TLP 过程
 ├─ 对 PCIe 层次的实现
 └─ RC 与 EP 通信
```

```
4. TLP 类型
 ├─ Packet
 ├─ Request(请求) TLP
 │  ├─ Non-Posted 和 Posted Request
 │  └─ Native PCIe Request
 ├─ Completion(响应) TLP
 ├─ TLP 类型总结
 └─ TLP 例子
    ├─ Memory Read
    └─ Memory Write
```

```
5. TLP 结构
 ├─ TLP 格式
 └─ TLP Header
    ├─ 通用部分
    │  └─ Fmt 和 Type
    └─ 特有部分
       ├─ Memory TLP
       ├─ Configuration TLP
       ├─ Message TLP
       └─ Completion TLP
```

```
6. 配置和地址空间
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```

```
1. PCIe 拓扑结构
 ├─ Lane 和 Link
 │  ├─ 全双工模式
 │  └─ 半双工模式
 ├─ 带宽
 │  ├─ 带宽的计算
 │  │  ├─ PCIe1.0
 │  │  ├─ PCIe2.0
 │  │  └─ PCIe3.0
 │  ├─ 速度和成本
 │  └─ IOPS
 └─ 并口和串口
```