
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. k8s](#1-k8s)
- [2. 物料准备](#2-物料准备)
- [3. go环境安装](#3-go环境安装)
- [4. 开发环境安装](#4-开发环境安装)
- [5. k8s源码下载](#5-k8s源码下载)
- [6. k8s源码整理](#6-k8s源码整理)
- [7. IDE打开](#7-ide打开)
- [8. 开始分析](#8-开始分析)
  - [8.1. cmd](#81-cmd)
  - [8.2. pkg](#82-pkg)

<!-- /code_chunk_output -->

# 1. k8s

k8s是用go语言写的, 看k8s的源码首先要安装go的环境, 然后下载源码, 使用开发工具打开, 最后进行分析. 

# 2. 物料准备

- go
- Kubernetes源码
- GoLand

# 3. go环境安装

进入golang官网下载页面https://golang.org/dl/ , 选择合适的go版本下载. 

具体安装见GoLang下内容

安装后需要设置环境变量

* GOROOT: 指向golang的安装路径
* GOPATH: 指向golang的工作空间
* PATH: 系统变量

# 4. 开发环境安装

目前常用的有如下几个:

* LiteIDE
* vscode(go插件)
* Intellij IDEA for golang

注: 刚开始Intellij idea支持go开发是使用的一个go插件, 后来推出了专门的GoLand, 这个有个优点: 每一个打开的工程都可以设置自己的GOPATH. 

# 5. k8s源码下载

到k8s github主页上下载k8s的代码. 

# 6. k8s源码整理

k8s的源码下载后是无法直接编译和查看啊, k8s也依赖很多golang的开源代码, 而且如果用ide打开后有很多依赖是无法找到的, 所以要现整理一下. 

在上面我们设置的**GOPATH目录**下, 新建文件夹: \$**GOPATH/src/k8s.io/kubernetes**; 

```
# mkdir -p $GOPATH/src/k8s.io/kubernetes

# cd $GOPATH/src/k8s.io/kubernetes

# git clone https://github.com/kubernetes/kubernetes.git
```

将下载的zip包解压后, 将kubernetes目录下的如下5个文件夹拷贝到$GOPATH/src/k8s.io/kubernetes:

* cmd
* pkg
* plugin
* vender
* third\_party

为了验证k8s的代码能否找到相应的依赖, 我们可以通过如下方式验证: 

* 命令行进入$GOPATH/src/k8s.io/kubernetes/cmd/kube\-proxy目录

* 执行go build命令; 

* 命令执行过程中没有报错, 且执行完成后文件中多了一个可执行文件, 说明编译成功了

```
# echo $GOPATH
/root/go

# pwd
/root/go/src/k8s.io/kubernetes/cmd/kube-proxy

# ls
app  BUILD  proxy.go

# go build .

# ls
app  BUILD  kube-proxy  proxy.go
```

注: 关于go的依赖机制vendor可以参考: https://studygolang.com/articles/4607

# 7. IDE打开

打开刚才安装好的GoLand, 选择Open Project, 选择$**GOPATH目录**

注意project路径

```
# echo $GOPATH
/Volumes/Main/Codes/go
```



代码入口在`k8s.io/kubernetes/cmd`目录下

# 8. 开始分析

几个主要目录

目录名 | 用途
----|---
cmd | 每个组件代码入口(main函数)
pkg | 各个组件的具体功能实现
staging | 已经分库的项目
vendor | 依赖

## 8.1. cmd

包括kubernetes所有**后台进程的代码**包括apiserver、controller manager、proxy、kuberlet等进程

每个组件代码入口(main函数)

## 8.2. pkg

各个组件的具体功能实现

各个子包的功能

包名 | 用途
---|---
api | kubernetesapi主要包括最新版本的Rest API接口的类, 并提供数据格式验证转换工具类, 对应版本号文件夹下的文件描述了特定的版本如何序列化存储和网络
client | Kubernetes 中公用的客户端部分, 实现对对象的具体操作增删该查操作
cloudprovider | kubernetes 提供对aws、azure、gce、cloudstack、mesos等云供应商提供了接口支持, 目前包括负载均衡、实例、zone信息、路由信息等
controller | kubernetes controller主要包括各个controller的实现逻辑, 为各类资源如replication、endpoint、node等的增删改等逻辑提供派发和执行
credentialprovider | kubernetes credentialprovider 为docker 镜像仓库贡献者提供权限认证
generated | kubernetes generated包是所有生成的文件的目标文件, 一般这里面的文件日常是不进行改动的
kubectl | kuernetes kubectl模块是kubernetes的命令行工具, 提供apiserver的各个接口的命令行操作, 包括各类资源的增删改查、扩容等一系列命令工具
kubelet | kuernetes kubelet模块是kubernetes的核心模块, 该模块负责node层的pod管理, 完成pod及容器的创建, 执行pod的删除同步等操作等等
master | kubernetes master负责集群中master节点的运行管理、api安装、各个组件的运行端口分配、NodeRegistry、PodRegistry等的创建工作
runtime | kubernetes runtime实现不同版本api之间的适配, 实现不同api版本之间数据结构的转换

