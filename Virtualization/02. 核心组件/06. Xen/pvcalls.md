- [1. 术语表(Glossary)](#1-术语表glossary)
- [2. 基本原理(Rationale)](#2-基本原理rationale)
- [3. 设计](#3-设计)
  - [3.1. 为什么选择 Xen?](#31-为什么选择-xen)
  - [3.2. XenStore](#32-xenstore)
    - [3.2.1. 前端 XenBus 节点](#321-前端-xenbus-节点)
    - [3.2.2. 后端 XenBus 节点](#322-后端-xenbus-节点)
    - [3.2.3. 状态机](#323-状态机)
  - [3.3. 命令环(Commands Ring)](#33-命令环commands-ring)
    - [3.3.1. 套接字Socket](#331-套接字socket)
    - [3.3.2. 连接(connect)](#332-连接connect)
    - [3.3.3. 释放(Release)](#333-释放release)
    - [3.3.4. 绑定(bind)](#334-绑定bind)
    - [3.3.5. 监听(listen)](#335-监听listen)
    - [3.3.6. 接受(accept)](#336-接受accept)
    - [3.3.7. 轮询(poll)](#337-轮询poll)
    - [3.3.8. 扩展协议](#338-扩展协议)
    - [3.3.9. 错误码](#339-错误码)
    - [3.3.10. 套接字族和地址格式](#3310-套接字族和地址格式)
  - [3.4. 索引页和数据环](#34-索引页和数据环)
    - [3.4.1. 索引页结构](#341-索引页结构)
    - [3.4.2. 数据环结构](#342-数据环结构)
    - [3.4.3. 为什么不需要 ring.h](#343-为什么不需要-ringh)
    - [3.4.4. 工作流程](#344-工作流程)
- [4. reference](#4-reference)

PV 调用协议版本 1

# 1. 术语表(Glossary)

以下是在 Xen 社区中使用的术语和定义列表. 如果您是 Xen 贡献者, 可以跳过这一部分.

- **PV**

  半虚拟化的简称.

- **Dom0**

  首先启动的虚拟机. 在大多数配置中, Dom0 是特权的, 并控制硬件设备, 如网卡, 显卡等.

- **DomU**

  普通的非特权 Xen 虚拟机.

- **域**

  Xen 虚拟机. Dom0 和所有 DomU 都是独立的 Xen 域.

- **虚拟机**

  与域相同: Xen 虚拟机.

- **前端**

  每个 DomU 都有一个或多个半虚拟化前端驱动程序, 用于访问磁盘, 网络, 控制台, 图形等. PV 设备的存在通过 XenStore 宣告, 这是一个跨域的键值数据库. 前端的意图类似于 Linux 中的 virtio 驱动程序.

- **后端**

  Xen 半虚拟化后端通常运行在 Dom0 中, 用于向 DomU 导出磁盘, 网络, 控制台, 图形等. 后端可以位于内核空间和用户空间. 例如, xen-blkback 位于 Linux 内核的 drivers/block 下, 而 xen_disk 位于 QEMU 的 hw/block 下. 半虚拟化后端的意图类似于 virtio 设备模拟器.

- **VMX 和 SVM**

  在 Intel 处理器上, VMX 是 VT-x 的 CPU 标志, 表示硬件虚拟化支持. 它对应于 AMD 处理器上的 SVM.

# 2. 基本原理(Rationale)

PV 调用是一种半虚拟化协议, 允许在不同的域中实现一组 POSIX 函数. PV 调用前端发送 POSIX 函数调用到后端, 后端实现这些函数并返回值给前端并执行函数调用.

本文档的这一版本涵盖了网络函数调用, 如 connect, accept, bind, release, listen, poll, recvmsg 和 sendmsg; 但该协议旨在轻松扩展以覆盖不同的调用集. 未实现的命令返回 ENOTSUP.

PV 调用提供以下好处:

- 在后端域上完全可见虚拟机行为, 允许以低成本过滤和操作任何虚拟机调用

- 优异的性能

具体来说, PV 调用在网络方面提供这些优势:

- 虚拟机网络在主机上的 VPN, 无线网络和任何其他复杂配置中都能即装即用

- 虚拟机服务监听直接绑定到后端域 IP 地址的端口

- 本地主机成为一个安全的主机范围网络, 用于 VM 间通信

# 3. 设计

## 3.1. 为什么选择 Xen?

PV 调用是为容器创建安全运行时环境 (特别是 Open Containers Initiative 镜像) 的一部分. PV 调用基于 Xen, 尽管将其移植到其他 hypervisor 是可能的. 选择 Xen 是因为其安全性和隔离特性, 以及它支持 PV 虚拟机, 这是一种不需要硬件虚拟化扩展 (Intel 处理器上的 VMX 和 AMD 处理器上的 SVM) 的虚拟机. 这很重要, 因为 PV 调用是为容器设计的, 而容器通常运行在不支持嵌套 VMX(或 SVM)的公共云实例上(截至 2017 年初). Xen PV 虚拟机轻量级, 最小化, 并且不需要机器模拟: 这些特性使它们非常适合本项目.

## 3.2. XenStore

前端和后端通过 [**XenStore**](https://xenbits.xen.org/docs/unstable/misc/xenstore.txt) 交换信息. 工具栈创建前端和后端节点, 状态为 [XenbusStateInitialising](https://xenbits.xen.org/docs/unstable/hypercall/x86_64/include,public,io,xenbus.h.html). 协议节点名称为 **pvcalls**. 每个域只能有**一个 PV 调用前端**.

### 3.2.1. 前端 XenBus 节点

- **version** 值:

  协议版本, 从前端支持的版本中选择(参见 [后端 XenBus 节点] 中的 **versions**). 目前, 值必须为 "1".

- **port** 值:

  用于通知命令环活动的 Xen 事件通道的标识符.

- **ring-ref** 值:

  授予后端映射单页大小命令环的唯一页面的 Xen 授权引用.

### 3.2.2. 后端 XenBus 节点

- **versions** 值:

  后端支持的协议版本列表, 以逗号分隔. 例如 "1, 2, 3". 目前, 值仅为 "1", 因为只有一个版本.

- **max-page-order** 值:

  支持的最大内存分配大小, 以机器页面的 log2n 为单位, 例如 1 = 2 页, 2 = 4 页等. 它必须为 1 或更大.

- **function-calls** 值:

  值 "0" 表示不支持任何调用.
  值 "1" 表示支持 socket,connect,release,bind,listen,accept 和 poll.

### 3.2.3. 状态机

**初始化**(Initialization):

```
*前端*                                *后端*
XenbusStateInitialising               XenbusStateInitialising
- 查询虚拟设备属性.                     - 查询后端设备标识数据.
- 设置操作系统设备实例.                  - 发布后端功能和传输参数
- 分配并初始化请求环.                            |
- 发布将在本次连接期间生效的传输参数.              |
             |                                V
             |                          XenbusStateInitWait
             |
             |
             V
    XenbusStateInitialised

                                        - 查询前端传输参数.
                                        - 连接到请求环和
                                          事件通道.
                                                     |
                                                     |
                                                     V
                                             XenbusStateConnected

- 查询后端设备属性.
- 完成操作系统虚拟设备
  实例.
             |
             |
             V
    XenbusStateConnected
```

一旦前端和后端连接, 它们将**共享一个页面**, 用于**通过环交换消息**, 以及**一个事件通道**, 用于**发送通知**.

**关闭**(Shutdown):

```
* 前端 *                            * 后端 *
XenbusStateConnected               XenbusStateConnected
            |
            |
            V
   XenbusStateClosing

                                   - 取消映射授权
                                   - 解绑事件通道
                                             |
                                             |
                                             V
                                     XenbusStateClosing

- 解绑事件通道
- 释放环
- 释放数据结构
           |
           |
           V
   XenbusStateClosed

                                   - 释放剩余数据结构
                                             |
                                             |
                                             V
                                     XenbusStateClosed
```

## 3.3. 命令环(Commands Ring)

共享环用于前端将 POSIX 函数调用转发到后端. 我们将这个环称为 **命令环**, 以区别于协议生命周期中可能创建的其他环(参见索引页和数据环). 该环的授权引用通过 XenStore 共享(参见前端 XenBus 节点). 环格式使用熟悉的 `DEFINE_RING_TYPES` 宏定义(`xen/include/public/io/ring.h`). 前端请求使用 `RING_GET_REQUEST` 宏分配在环上. 以下是按调用顺序列出的命令列表.

格式定义如下:

```c
#define PVCALLS_SOCKET         0
#define PVCALLS_CONNECT        1
#define PVCALLS_RELEASE        2
#define PVCALLS_BIND           3
#define PVCALLS_LISTEN         4
#define PVCALLS_ACCEPT         5
#define PVCALLS_POLL           6

struct xen_pvcalls_request {
    uint32_t req_id; /* 虚拟机私有, 响应中回显 */
    uint32_t cmd;    /* 要执行的命令 */
    union {
        struct xen_pvcalls_socket {
            uint64_t id;
            uint32_t domain;
            uint32_t type;
            uint32_t protocol;
            uint8_t pad[4];
        } socket;
        struct xen_pvcalls_connect {
            uint64_t id;
            uint8_t addr[28];
            uint32_t len;
            uint32_t flags;
            grant_ref_t ref;
            uint32_t evtchn;
            uint8_t pad[4];
        } connect;
        struct xen_pvcalls_release {
            uint64_t id;
            uint8_t reuse;
            uint8_t pad[7];
        } release;
        struct xen_pvcalls_bind {
            uint64_t id;
            uint8_t addr[28];
            uint32_t len;
        } bind;
        struct xen_pvcalls_listen {
            uint64_t id;
            uint32_t backlog;
            uint8_t pad[4];
        } listen;
        struct xen_pvcalls_accept {
            uint64_t id;
            uint64_t id_new;
            grant_ref_t ref;
            uint32_t evtchn;
        } accept;
        struct xen_pvcalls_poll {
            uint64_t id;
        } poll;
        /* 使 struct xen_pvcalls_request 在不同架构上的大小一致的虚拟成员 */
        struct xen_pvcalls_dummy {
            uint8_t dummy[56];
        } dummy;
    } u;
};
```

前两个字段是每个命令共有的. 它们的二进制布局为:

```
0       4       8
+-------+-------+
|req_id |  cmd  |
+-------+-------+
```

- **req_id** 由前端生成, 用于标识特定的请求/响应对. 不要与用于标识多个命令中套接字的 **id** 混淆, 参见套接字.

- **cmd** 是前端请求的命令:

  - `PVCALLS_SOCKET`: 0
  - `PVCALLS_CONNECT`: 1
  - `PVCALLS_RELEASE`: 2
  - `PVCALLS_BIND`: 3
  - `PVCALLS_LISTEN`: 4
  - `PVCALLS_ACCEPT`: 5
  - `PVCALLS_POLL`: 6

这两个字段由后端回显. 有关 **addr** 字段的格式, 请参见套接字族和地址格式. 命令特定参数的最大大小为 56 字节. 任何需要更多空间的未来命令都需要提高协议的 **version**.

类似于其他基于 Xen 环的协议, 前端在将请求写入环后调用 `RING_PUSH_REQUESTS_AND_CHECK_NOTIFY`, 并在需要时通过事件通道发送通知.

后端响应使用 `RING_GET_RESPONSE` 宏分配在环上. 格式如下:

```c
struct xen_pvcalls_response {
    uint32_t req_id;
    uint32_t cmd;
    int32_t ret;
    uint32_t pad;
    union {
        struct _xen_pvcalls_socket {
            uint64_t id;
        } socket;
        struct _xen_pvcalls_connect {
            uint64_t id;
        } connect;
        struct _xen_pvcalls_release {
            uint64_t id;
        } release;
        struct _xen_pvcalls_bind {
            uint64_t id;
        } bind;
        struct _xen_pvcalls_listen {
            uint64_t id;
        } listen;
        struct _xen_pvcalls_accept {
            uint64_t id;
        } accept;
        struct _xen_pvcalls_poll {
            uint64_t id;
        } poll;
        struct _xen_pvcalls_dummy {
            uint8_t dummy[8];
        } dummy;
    } u;
};
```

前四个字段是每个响应共有的. 它们的二进制布局为:

```
0       4       8       12      16
+-------+-------+-------+-------+
|req_id |  cmd  |  ret  |  pad  |
+-------+-------+-------+-------+
```

- **req_id**: 从请求中回显
- **cmd**: 从请求中回显
- **ret**: 返回值, 标识成功 (0) 或失败(参见后续部分的错误码). 如果后端不支持 **cmd**, 则 ret 为 ENOTSUP.
- **pad**: 填充

在调用 `RING_PUSH_RESPONSES_AND_CHECK_NOTIFY` 后, 后端检查是否需要通知前端, 并通过事件通道发送通知.

以下是对每个命令及其附加请求和响应字段的描述.

### 3.3.1. 套接字Socket

**套接字**(Socket) 操作对应于 POSIX 套接字函数. 它创建一个指定族, 类型和协议的新套接字. **id** 由前端自由选择, 并从此引用该特定套接字. 有关不同协议版本支持的套接字族和地址格式, 请参见套接字族和地址格式.

请求字段:

- **cmd** 值: 0
- 附加字段:
  - **id**: 由前端生成, 标识新套接字
  - **domain**: 通信域
  - **type**: 套接字类型
  - **protocol**: 与套接字一起使用的特定协议, 通常为 0

请求二进制布局:

```
8       12      16      20     24       28
+-------+-------+-------+-------+-------+
|       id      |domain | type  |protoco|
+-------+-------+-------+-------+-------+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16       20       24
+-------+--------+
|       id       |
+-------+--------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 套接字函数; 有关错误码, 请参见后续部分.

### 3.3.2. 连接(connect)

**连接**(connect) 操作对应于 POSIX 连接函数. 它将先前创建的套接字 (由 **id** 标识) 连接到指定地址.

连接操作创建一个新的共享环, 我们称之为 **数据环**. 数据环用于从套接字发送和接收数据. 连接操作传递两个附加参数: **evtchn** 和 **ref**.

* **evtchn** 是新事件通道的端口号, 将用于数据环活动的通知.

* **ref** 是 **索引页**(indexes page) 的授权引用: 一个包含指向数据环中写入和读取位置的共享索引的页面. **索引页** 还包含数据环的完整授权引用数组.

当前端发出 **连接** 命令时, 后端执行以下操作:

- 查找对应于 **id** 的内部套接字
- 将套接字连接到 **addr**
- 映射授权引用 **ref**, 即索引页, 参见 struct pvcalls_data_intf
- 映射 `struct pvcalls_data_intf` 中列出的所有授权引用, 并将其用作数据环的共享内存
- 绑定 **evtchn**
- 向前端回复

索引页和数据环格式将在下一节中描述. 当对活动套接字 (由 **id** 标识) 发出 **释放** 命令时, 数据环和索引页将被取消映射和释放. 前端状态更改也可能导致数据环被取消映射.

请求字段:

- **cmd** 值: 0
- 附加字段:
  - **id**: 标识套接字
  - **addr**: 要连接的地址, 参见套接字族和地址格式
  - **len**: 地址长度, 最多 28 个八位字节
  - **flags**: 连接的标志, 保留供将来使用
  - **ref**: 索引页的授权引用
  - **evtchn**: 用于通知数据环活动的 evtchn 的端口号

请求二进制布局:

```
8       12      16      20      24      28      32      36      40      44
+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|       id      |                            addr                       |
+-------+-------+-------+-------+-------+-------+-------+-------+-------+
| len   | flags |  ref  |evtchn |
+-------+-------+-------+-------+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16      20      24
+-------+-------+
|       id      |
+-------+-------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 连接函数; 有关错误码, 请参见后续部分.

### 3.3.3. 释放(Release)

**释放** 操作关闭一个现有的活动或被动套接字.

当对被动套接字发出释放命令时, 后端释放它并释放其内部映射. 当对活动套接字发出释放命令时, 数据环和索引页也将被取消映射和释放:

- 前端对活动套接字发出释放命令
- 后端释放套接字
- 后端取消映射数据环
- 后端取消映射索引页
- 后端解绑事件通道
- 后端向前端回复一个 **ret** 值
- 前端释放数据环, 索引页并解绑事件通道

请求字段:

- **cmd** 值: 1
- 附加字段:
  - **id**: 标识套接字
  - **reuse**: 供后端使用的优化提示. 该字段对被动套接字无效. 当设置为 1 时, 前端通知后端在创建下一个活动套接字时将重用完全相同的授权页面集 (索引页和数据环) 和事件通道. 后端可以利用这一点延迟取消映射授权和解绑事件通道. 后端可以自由忽略此提示. 重用的数据环通过 **ref** 查找, 即包含索引的页面的授权引用.

请求二进制布局:

```
8       12      16    17
+-------+-------+-----+
|       id      |reuse|
+-------+-------+-----+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16      20      24
+-------+-------+
|       id      |
+-------+-------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 关闭函数; 有关错误码, 请参见后续部分.

### 3.3.4. 绑定(bind)

**绑定**(bind) 操作对应于 POSIX 绑定函数. 它将作为参数传递的地址分配给先前创建的套接字, 由 **id** 标识.

**绑定**, **监听** 和 **接受** 是使被动套接字完全正常工作的三个操作, 应按此顺序发出.

请求字段:

- **cmd** 值: 2
- 附加字段:
  - **id**: 标识套接字
  - **addr**: 要连接的地址, 参见套接字族和地址格式
  - **len**: 地址长度, 最多 28 个八位字节

请求二进制布局:

```
8       12      16      20      24      28      32      36      40      44
+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|       id      |                            addr                       |
+-------+-------+-------+-------+-------+-------+-------+-------+-------+
|  len  |
+-------+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16      20      24
+-------+-------+
|       id      |
+-------+-------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 绑定函数; 有关错误码, 请参见后续部分.

### 3.3.5. 监听(listen)

**监听**(listen) 操作将套接字标记为被动套接字. 它对应于 POSIX 监听函数.

请求字段:

- **cmd** 值: 3
- 附加字段:
  - **id**: 标识套接字
  - **backlog**: 待处理连接队列的最大长度(以元素数表示)

请求二进制布局:

```
8       12      16      20
+-------+-------+-------+
|       id      |backlog|
+-------+-------+-------+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16      20      24
+-------+-------+
|       id      |
+-------+-------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 监听函数; 有关错误码, 请参见后续部分.

### 3.3.6. 接受(accept)

**接受**(accept) 操作从监听套接字 (由 **id** 标识) 的待处理连接队列中提取第一个连接请求, 并创建一个新的已连接套接字.
新套接字的 id 也由前端选择, 并作为接受请求结构的附加字段 (**id_new**) 传递. 有关参考, 请参见 POSIX 接受函数.

类似于 ** 连接 ** 操作,** 接受 ** 创建新的索引页和数据环. 数据环用于从套接字发送和接收数据. 接受操作传递两个附加参数:**evtchn** 和 **ref**.
**evtchn** 是新事件通道的端口号, 将用于数据环活动的通知.
**ref** 是索引页的授权引用: 一个包含指向数据环中写入和读取位置的共享索引的页面. 索引页还包含数据环的完整授权引用数组.

后端仅在成功接受新连接时回复请求, 即后端不会返回 EAGAIN 或 EWOULDBLOCK.

示例工作流程:

- 前端发出 ** 接受 ** 请求
- 后端等待套接字上有可用连接
- 新连接可用
- 后端接受新连接
- 后端创建从 **id_new** 到新套接字的内部映射
- 后端映射授权引用 **ref**, 即索引页, 参见 struct pvcalls_data_intf
- 后端映射 `struct pvcalls_data_intf` 中列出的所有授权引用, 并将其用作新数据环的共享内存
- 后端绑定到 **evtchn**
- 后端向前端回复一个 **ret** 值

请求字段:

- **cmd** 值: 4
- 附加字段:
  - **id**: 监听套接字的 id
  - **id_new**: 新套接字的 id
  - **ref**: 索引页的授权引用
  - **evtchn**: 用于通知数据环活动的 evtchn 的端口号

请求二进制布局:

```
8       12      16      20      24      28      32
+-------+-------+-------+-------+-------+-------+
|       id      |    id_new     |  ref  |evtchn |
+-------+-------+-------+-------+-------+-------+
```

响应附加字段:

- **id**: 监听套接字的 id, 从请求中回显

响应二进制布局:

```
16      20      24
+-------+-------+
|       id      |
+-------+-------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 接受函数; 有关错误码, 请参见后续部分.

### 3.3.7. 轮询(poll)

在此协议版本中, **轮询** 操作仅对被动套接字有效. 对于活动套接字, 前端应查看索引页上的索引. 当被动套接字的队列中有新连接可用时, 后端生成响应并通知前端.

请求字段:

- **cmd** 值: 5
- 附加字段:
  - **id**: 标识监听套接字

请求二进制布局:

```
8       12      16
+-------+-------+
|       id      |
+-------+-------+
```

响应附加字段:

- **id**: 从请求中回显

响应二进制布局:

```
16       20       24
+--------+--------+
|        id       |
+--------+--------+
```

返回值:

- 成功时为 0
- 有关错误名称, 请参见 POSIX 轮询函数; 有关错误码, 请参见后续部分.

### 3.3.8. 扩展协议

可以在不更改协议 ABI 的情况下引入新命令. 自然地, 后端 XenStore 节点中的一个功能标志应宣传新命令集的可用性.

如果新命令需要大于 56 字节的 struct xen_pvcalls_request 参数, 则需要提高协议版本. 一种方法是引入一个新命令, 例如 PVCALLS_CONNECT_EXTENDED, 并设置一个标志以指定请求使用两个请求槽, 总共 112 字节.

### 3.3.9. 错误码

对应于 POSIX 指定的错误名称的数字如下:

```
[EPERM]         -1
[ENOENT]        -2
[ESRCH]         -3
[EINTR]         -4
[EIO]           -5
[ENXIO]         -6
[E2BIG]         -7
[ENOEXEC]       -8
[EBADF]         -9
[ECHILD]        -10
[EAGAIN]        -11
[EWOULDBLOCK]   -11
[ENOMEM]        -12
[EACCES]        -13
[EFAULT]        -14
[EBUSY]         -16
[EEXIST]        -17
[EXDEV]         -18
[ENODEV]        -19
[EISDIR]        -21
[EINVAL]        -22
[ENFILE]        -23
[EMFILE]        -24
[ENOSPC]        -28
[EROFS]         -30
[EMLINK]        -31
[EDOM]          -33
[ERANGE]        -34
[EDEADLK]       -35
[EDEADLOCK]     -35
[ENAMETOOLONG]  -36
[ENOLCK]        -37
[ENOTEMPTY]     -39
[ENOSYS]        -38
[ENODATA]       -61
[ETIME]         -62
[EBADMSG]       -74
[EOVERFLOW]     -75
[EILSEQ]        -84
[ERESTART]      -85
[ENOTSOCK]       -88
[EOPNOTSUPP]    -95
[EAFNOSUPPORT]  -97
[EADDRINUSE]    -98
[EADDRNOTAVAIL] -99
[ENOBUFS]       -105
[EISCONN]       -106
[ENOTCONN]      -107
[ETIMEDOUT]     -110
[ENOTSUP]      -524
```

### 3.3.10. 套接字族和地址格式

> Socket families and address format

以下定义和显式大小, 连同 POSIX sys/socket.h 和 netinet/in.h, 定义了套接字族和地址格式. 请注意, 此规范版本仅支持 **domain** `AF_INET`,**type** `SOCK_STREAM` 和 **protocol** `0`, 其他返回 ENOTSUP.

```c
#define AF_UNSPEC   0
#define AF_UNIX     1   /* Unix 域套接字      */
#define AF_LOCAL    1   /* AF_UNIX 的 POSIX 名称   */
#define AF_INET     2   /* 互联网 IP 协议     */
#define AF_INET6    10  /* IP 第 6 版         */

#define SOCK_STREAM 1
#define SOCK_DGRAM  2
#define SOCK_RAW    3

/* 通用地址格式 */
struct sockaddr {
    uint16_t sa_family_t;
    char sa_data[26];
};

struct in_addr {
    uint32_t s_addr;
};

/* AF_INET 地址格式 */
struct sockaddr_in {
    uint16_t         sa_family_t;
    uint16_t         sin_port;
    struct in_addr   sin_addr;
    char             sin_zero[20];
};
```

## 3.4. 索引页和数据环

> Indexes Page and Data ring

数据环用于通过已连接套接字发送和接收数据. 它们在成功的 ** 接受 ** 或 ** 连接 ** 命令后创建.**sendmsg** 和 **recvmsg** 调用通过从数据环发送数据和接收数据以及更新索引页上的相应索引来实现.

首先,** 索引页 ** 通过 ** 连接 ** 或 ** 接受 ** 命令共享, 参见它们部分中的 **ref** 参数. 索引页的内容由 `struct pvcalls_ring_intf` 表示, 如下所示. 该结构包含构成数据环的 **in** 和 **out** 缓冲区的授权引用列表, 参见下面的 ref\[\]. 后端连续映射授权引用. 共享内存的第一半用于 **in** 数组, 第二半用于 **out** 数组. 它们用作循环缓冲区, 用于传输数据, 合在一起, 它们就是数据环.

```
    +---------------------------+                 索引页
    | 命令环:                 |                 +----------------------+
    | @0: xen_pvcalls_connect:  |                 |@0 pvcalls_data_intf: |
    | @44: ref  +-------------------------------->+@76: ring_order = 1   |
    |                           |                 |@80: ref[0]+          |
    +---------------------------+                 |@84: ref[1]+          |
                                                  |           |          |
                                                  |           |          |
                                                  +----------------------+
                                                              |
                                                              v (数据环)
                                                      +-------+-----------+
                                                      |  @0->4098: in     |
                                                      |  ref[0]           |
                                                      |-------------------|
                                                      |  @4099->8196: out |
                                                      |  ref[1]           |
                                                      +-------------------+
```

### 3.4.1. 索引页结构

```c
typedef uint32_t PVCALLS_RING_IDX;

struct pvcalls_data_intf {
    PVCALLS_RING_IDX in_cons, in_prod;
    int32_t in_error;

    uint8_t pad[52];

    PVCALLS_RING_IDX out_cons, out_prod;
    int32_t out_error;

    uint8_t pad[52];

    uint32_t ring_order;
    grant_ref_t ref[];
};

/* 实际上不合规的 C(ring_order 随套接字变化) */
struct pvcalls_data {
    char in[((1<<ring_order)<<PAGE_SHIFT)/2];
    char out[((1<<ring_order)<<PAGE_SHIFT)/2];
};
```

- **ring_order** 它表示数据环的顺序. 以下授权引用列表包含 `(1 << ring_order)` 个元素. 它不能大于后端在 XenBus 上指定的 **max-page-order**. 它至少为 1.
- **ref\[\]** 将包含实际数据的授权引用列表. 它们在虚拟内存中连续映射. 第一页是 **in** 数组, 第二页是 **out** 数组. 数组的大小必须是 2 的幂. 它们的总大小为 `(1 << ring_order) * PAGE_SIZE`.
- **in** 是一个用作循环缓冲区的数组, 包含从套接字读取的数据. 生产者是后端, 消费者是前端.
- **out** 是一个用作循环缓冲区的数组, 包含要写入套接字的数据. 生产者是前端, 消费者是后端.
- **in_cons** 和 **in_prod** 从套接字读取数据的消费者和生产者索引. 它们跟踪前端已经从 **in** 数组中消费了多少数据.**in_prod** 由后端在写入 **in** 后增加.**in_cons** 由前端在从 **in** 读取后增加.
- **out_cons**,**out_prod** 要写入套接字的数据的消费者和生产者索引. 它们跟踪前端已经写入 **out** 的数据量以及后端已经消费了多少数据.**out_prod** 由前端在写入 **out** 后增加.**out_cons** 由后端在从 **out** 读取后增加.
- **in_error** 和 **out_error** 它们在从套接字读取 (**in_error**) 或写入套接字 (**out_error**) 时发出错误信号. 0 表示没有错误. 当发生错误时, 不再对套接字执行进一步的读取或写入操作. 在有序关闭套接字的情况下(即读取返回 0),**in_error** 设置为 ENOTCONN.**in_error** 和 **out_error** 从不设置为 EAGAIN 或 EWOULDBLOCK(数据在可用时写入环).

`struct pvcalls_data_intf` 的二进制布局如下:

```
0         4         8         12           64        68        72        76
+---------+---------+---------+-----//-----+---------+---------+---------+
| in_cons | in_prod |in_error |  padding   |out_cons |out_prod |out_error|
+---------+---------+---------+-----//-----+---------+---------+---------+

76        80        84        88      4092      4096
+---------+---------+---------+----//---+---------+
|ring_orde|  ref[0] |  ref[1] |         |  ref[N] |
+---------+---------+---------+----//---+---------+
```

**注意** 对于一页, N 最大为 991 ((4096-132)/4), 但由于 N 需要是 2 的幂, 实际最大 N 为 512(ring_order = 9).

### 3.4.2. 数据环结构

数据环的二进制布局如下:

```
0         ((1<<ring_order)<<PAGE_SHIFT)/2       ((1<<ring_order)<<PAGE_SHIFT)
+------------//-------------+------------//-------------+
|            in             |           out             |
+------------//-------------+------------//-------------+
```

### 3.4.3. 为什么不需要 ring.h

许多 Xen PV 协议使用 ring.h 提供的宏来管理它们的共享环进行通信. PVCalls 不使用, 因为数据环结构实际上包含两个环:**in** 环和 **out** 环. 每个环都是单向的, 且没有静态请求大小: 生产者将不透明数据写入环. 在 ring.h 的另一端, 它们是组合的, 且请求大小是静态且已知的. 在 PVCalls 中:

in -> 仅后端到前端 out -> 仅前端到后端

在 **in** 环的情况下, 前端是消费者, 后端是生产者. 对于 **out** 环, 情况正好相反.

生产者 (**in** 环的后端,**out** 环的前端) 从不从环中读取. 事实上, 生产者不需要任何通知, 除非环已满. 此协议版本没有利用这一点, 为优化留出空间.

在另一端, 消费者始终需要通知, 除非它已经在积极从环中读取. 生产者可以通过比较函数开始和结束时的索引来确定这一点, 而无需在协议中添加任何额外字段. 这类似于 ring.h 的工作方式.

### 3.4.4. 工作流程

**in** 和 **out** 数组用作循环缓冲区:

```
0                               sizeof(array) == ((1<<ring_order)<<PAGE_SHIFT)/2
+-----------------------------------+
|to consume|    free    |to consume |
+-----------------------------------+
           ^            ^
           prod         cons

0                               sizeof(array)
+-----------------------------------+
|  free    | to consume |   free    |
+-----------------------------------+
           ^            ^
           cons         prod
```

提供以下函数来计算数组中当前未消费的字节数:

```c
#define _MASK_PVCALLS_IDX(idx, ring_size) ((idx) & (ring_size-1))

static inline PVCALLS_RING_IDX pvcalls_ring_unconsumed(PVCALLS_RING_IDX prod,
        PVCALLS_RING_IDX cons,
        PVCALLS_RING_IDX ring_size)
{
    PVCALLS_RING_IDX size;

    if (prod == cons)
        return 0;

    prod = _MASK_PVCALLS_IDX(prod, ring_size);
    cons = _MASK_PVCALLS_IDX(cons, ring_size);

    if (prod == cons)
        return ring_size;

    if (prod > cons)
        size = prod - cons;
    else {
        size = ring_size - cons;
        size += prod;
    }
    return size;
}
```

生产者 (**in** 环的后端,**out** 环的前端) 以以下方式写入数组:

- 从共享内存读取 `*[in|out]_cons, [in|out]_prod, [in|out]_error*`
- 一般内存屏障
- 在 `*[in|out]_error*` 时返回
- 将数据写入位置 `*[in|out]_prod*` up to `*[in|out]_cons*`, 必要时绕过循环缓冲区
- 写入内存屏障
- 增加 `*[in|out]_prod*`
- 通过 evtchn 通知另一端

消费者 (**out** 环的后端, **in** 环的前端) 以以下方式从数组中读取:

- 从共享内存读取 `*[in|out]_prod, [in|out]_cons, [in|out]_error*`
- 读取内存屏障
- 在 `*[in|out]_error*` 时返回
- 从位置 `*[in|out]_cons*` up to `*[in|out]_prod*` 读取, 必要时绕过循环缓冲区
- 一般内存屏障
- 增加 `*[in|out]_cons*`
- 通过 evtchn 通知另一端

生产者只写入缓冲区中 `*[in|out]_cons` 之前可用的字节数. 消费者只读取缓冲区中 `[in|out]_prod` 之前可用的字节数. 当写入或读取套接字时发生错误, `[in|out]_error*` 由后端设置.


# 4. reference

https://xenbits.xen.org/docs/unstable/misc/pvcalls.html
