
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 社区概述](#1-社区概述)
- [2. Communicating(交流)](#2-communicating交流)
  - [2.1. SIGs](#21-sigs)
  - [2.2. 社交媒体](#22-社交媒体)
  - [2.3. Slack](#23-slack)
  - [2.4. Mailing lists](#24-mailing-lists)
  - [2.5. Issues](#25-issues)
  - [2.6. 访问社区文档](#26-访问社区文档)
  - [2.7. Office Hours](#27-office-hours)
  - [2.8. Weekly Meeting](#28-weekly-meeting)
  - [2.9. 会议](#29-会议)
- [3. Governance(管理/治理)](#3-governance管理治理)
- [4. Build(开发构建)](#4-build开发构建)
- [5. Contribute(贡献)](#5-contribute贡献)
- [6. 会员](#6-会员)
- [7. 相关链接](#7-相关链接)
- [8. SIGs](#8-sigs)
- [9. Kubernetes Developer Guide](#9-kubernetes-developer-guide)
  - [9.1. 开发以及贡献代码到Kuberentes project的流程](#91-开发以及贡献代码到kuberentes-project的流程)
  - [9.2. 建立你的开发环境, coding以及debugging](#92-建立你的开发环境-coding以及debugging)

<!-- /code_chunk_output -->

# 1. 社区概述

社区Github: https://github.com/kubernetes/community

主要包含下面几部分内容

# 2. Communicating(交流)

列出了沟通渠道: chat(聊天), issues, mail list(邮件列表), conference(会议)等.

对于特定的topic, SIG.

主页: https://github.com/kubernetes/community/blob/master/communication

## 2.1. SIGs

Kubernetes包含许多项目, 组织成SIG. 一些交流已经被移入到了特定于SIG的channel, 详细信息查看SIG子目录

不过, 下面会列出专门讨论Kubernetes的general channel、groups和meetings. 

## 2.2. 社交媒体

* [Twitter](https://twitter.com/kubernetesio)
* [Blog](https://kubernetes.io/blog/)
* [Stack Overflow](https://stackoverflow.com/questions/tagged/kubernetes)

## 2.3. Slack

http://slack.k8s.io/

## 2.4. Mailing lists

Kubernetes邮件列表通过谷歌组托管. 要接收这些列表的电子邮件, 加入相关的组即可.

* [kubernets-announce](https://groups.google.com/forum/#!forum/kubernetes-announce): 广播主要的项目公告, 如release和安全问题
* [kubernetes-dev](https://groups.google.com/forum/#!forum/kubernetes-dev): 围绕开发kubernetes进行讨论
* [Discuss Kubernetes](https://discuss.kubernetes.io/): Kubernetes用户交流讨论的地方
* 存在额外的谷歌组, 并且可以加入到与每个团体和工作组相关的讨论中. 这些链接来自SIG列表. 

## 2.5. Issues

使用K8s有任何问题, 查看 [故障排查指南](https://kubernetes.io/docs/tasks/debug-application-cluster/troubleshooting/)

如果上面的没有解决, 或发现一个bug, [提交一个issue](https://github.com/kubernetes/kubernetes/issues/new)

## 2.6. 访问社区文档

Google Docs中有很多工作文档和笔记, 有必要的话会放到这个repo中

获取这些文档, 必须订阅上面的_Kubernetes-dev 邮件列表_

## 2.7. Office Hours

Office Hours每月举行一次. 参照 [这个](https://github.com/kubernetes/community/blob/master/events/office-hours.md) 获取更多信息.

是个定期安排的直播, 在 [YouTube频道](https://www.youtube.com/c/KubernetesCommunity/) 回答用户的实时问题, 获得有关如何使用Kubernetes的反馈.

每个月的第三个星期三

直播地址: https://www.youtube.com/c/KubernetesCommunity/live

您可以在Slack 上的 [\#office-hours频道](https://kubernetes.slack.com/messages/office-hours) 上发布问题, 或者可以将问题提交给Stack Overflow. 

所有会议的档案都保存在这里: 

* [播放列表](https://www.youtube.com/playlist?list=PL69nYSiGNLP3azFUvYJjGn45YbF6C-uIg)
* [会议记录](http://bit.ly/k8s-office-hours-notes)

## 2.8. Weekly Meeting

每周四美国太平洋时间上午10点举行公开会议, 并且会记录. 即北京时间周三凌晨1:00

查看所有K8s的会议安排: https://calendar.google.com/calendar/embed?src=cgnt364vd8s86hr2phapfjc6uk@group.calendar.google.com&ctz=America/Los_Angeles&pli=1

在[calendar.google.com](https://calendar.google.com/calendar/embed?src=cgnt364vd8s86hr2phapfjc6uk%40group.calendar.google.com&ctz=America/Los_Angeles)网站上查看, 或将[此iCal网址](https://calendar.google.com/calendar/ical/cgnt364vd8s86hr2phapfjc6uk%40group.calendar.google.com/public/basic.ics)粘贴到任何iCal客户端. 

要添加到日历项目, 请加入Google [网上论坛kubernetes-community-video-chat](https://groups.google.com/forum/#!forum/kubernetes-community-video-chat)以获取进一步说明. 

如果您有想要讨论或想要讨论的主题, 请在[Kubernetes社区会议议程](https://docs.google.com/document/d/1VQDIAB0OqiSjIHI8AWMvSdceWhnz56jNpZrLs6o7NJY/edit#)上提出具体日期. 

## 2.9. 会议

Kubernetes是KubeCon + CloudNativeCon的主要焦点, 每年春季在欧洲, 夏季在中国, 冬季在北美举行. 

有关这些和其他社区活动的信息可在[CNCF 活动页面](https://www.cncf.io/events/)上找到. 

# 3. Governance(管理/治理)

关于项目结构和组织

官方支持的的groups:

* Committees(委员会), 允许私聊. 安全/行为准则等

* Special Interest Groups (SIGs, 特殊兴趣小组), 持久的开放小组, 专注项目的一部分, 必须有公开透明的程序. 任何人可以参与, SIG目的是建立一组子项目(subprojects)

    * Subprojects(子项目): 每个SIG可以有一组subprojects. 这些是可以独立工作的小组. 一些子项目(subproject)将成为Kubernetes主要可交付成果的一部分, 另外的一些更可推测并且在kubernetes\-sigs github中

* Working Group(工作组): 临时组, 为了处理跨SIG边界问题而建立. 工作组没有任何代码和长期构件. 工作组可通过相关的SIGs来报告并采取行动.
* User Group(用户组): 用于促进与topic相关的信息的交流和发现, 这些topic与k8s的大型用户组有长期相关性. 不具有代码权.

主页: https://github.com/kubernetes/community/blob/master/governance.md

SIG可以有自己贡献策略, 在这个repo(https://github.com/kubernetes/community)的SIG文件夹下的README或CONTRIBUTING文件中描述(比如 [sig-cli/CONTRIBUTING.md](https://github.com/kubernetes/community/blob/master/sig-cli/CONTRIBUTING.md) ), 以及SIG自己的邮件列表, slack channel等

# 4. Build(开发构建)

技术主题: [contributors/devel/README.md](https://github.com/kubernetes/community/blob/master/contributors/devel/README.md)

# 5. Contribute(贡献)

第一步是从[Kubernetes SIGs列表](https://github.com/kubernetes/community/blob/master/sig-list.md)中选择. 参加SIG会议, 加入Slack频道并且订阅邮件列表. SIGs经常会有一系列"help wanted"的问题来帮助新的贡献者参与进去

[贡献者指南](https://github.com/kubernetes/community/blob/master/contributors/guide/README.md)提供了关于如何让你的想法和bug修复被看到并接受的详细说明, 包含

1. 如何[提交问题](https://github.com/kubernetes/community/blob/master/contributors/guide/README.md#file-an-issue)
2. 如何[找到一些能做的事情](https://github.com/kubernetes/community/blob/master/contributors/guide/README.md#find-something-to-work-on)
3. 如何[open一个pull request](https://github.com/kubernetes/community/blob/master/contributors/guide/README.md#open-a-pull-request)

# 6. 会员

我们鼓励所有贡献者成为会员. 我们的目标是发展一个由贡献者、评审人员和代码所有者组成的活跃、健康的社区. 

在我们的[社区会员](https://github.com/kubernetes/community/blob/master/community-membership.md)页面了解更多关于会员的要求和职责. 

# 7. 相关链接

slack channel: http://slack.k8s.io/ 

google group: https://groups.google.com/forum/#!forum/kubernetes-dev

weekly community meeting: https://groups.google.com/forum/#!forum/kubernetes-community-video-chat 

官方的Meetup: 

https://www.meetup.com/topics/kubernetes/ 

https://www.meetup.com/Kubernetes-Cloud-Native-Online-Meetup/ 

Kubernetes API: https://kubernetes.io/docs/reference/ 

kuberntes.io　－－教程 

kubeweekly －－－案例分享 

design-proposal 设计方案说明(https://github.com/kubernetes/community/blob/master/contributors/design-proposals/), 同样可以用来学习插件的开发.  

kubernets项目更好的参与 https://github.com/kubernetes/community/tree/master/contributors/devel

list of SIGs(罗列了主要的SIG以及Meetings时间) 
https://github.com/kubernetes/community/blob/master/sig-list.md

# 8. SIGs

name | URL
-----|----
API Machinery | https://github.com/kubernetes/community/blob/master/sig-api-machinery/README.md
AWS | https://github.com/kubernetes/community/blob/master/sig-aws/README.md
Apps | https://github.com/kubernetes/community/blob/master/sig-apps/README.md
Architecture | https://github.com/kubernetes/community/blob/master/sig-architecture/README.md
Auth | https://github.com/kubernetes/community/blob/master/sig-auth/README.md
Autoscaling | https://github.com/kubernetes/community/blob/master/sig-autoscaling/README.md
Azure | https://github.com/kubernetes/community/blob/master/sig-azure/README.md
Big Data | https://github.com/kubernetes/community/blob/master/sig-big-data/README.md
CLI | https://github.com/kubernetes/community/blob/master/sig-cli/README.md
Cluster Lifecycle | https://github.com/kubernetes/community/blob/master/sig-cluster-lifecycle/README.md
Cluster Ops | https://github.com/kubernetes/community/blob/master/sig-cluster-ops/README.md
Contributor Experience | https://github.com/kubernetes/community/blob/master/sig-contributor-experience/README.md
Docs | https://github.com/kubernetes/community/blob/master/sig-docs/README.md
Federation | https://github.com/kubernetes/community/blob/master/sig-federation/README.md
Instrumentation | https://github.com/kubernetes/community/blob/master/sig-instrumentation/README.md
Network | https://github.com/kubernetes/community/blob/master/sig-network/README.md
Node | https://github.com/kubernetes/community/blob/master/sig-node/README.md
On Premise | https://github.com/kubernetes/community/blob/master/sig-on-premise/README.md
OpenStack | https://github.com/kubernetes/community/blob/master/sig-openstack/README.md
Product Management | https://github.com/kubernetes/community/blob/master/sig-product-management/README.md
Scalability | https://github.com/kubernetes/community/blob/master/sig-scalability/README.md
Scheduling | https://github.com/kubernetes/community/blob/master/sig-scheduling/README.md
Service Catalog | https://github.com/kubernetes/community/blob/master/sig-service-catalog/README.md
Storage | https://github.com/kubernetes/community/blob/master/sig-storage/README.md
Testing | https://github.com/kubernetes/community/blob/master/sig-testing/README.md
UI | https://github.com/kubernetes/community/blob/master/sig-ui/README.md
Windows | https://github.com/kubernetes/community/blob/master/sig-windows/README.md
Container Identity | https://github.com/kubernetes/community/blob/master/wg-container-identity/README.md
Resource Management | https://github.com/kubernetes/community/blob/master/wg-resource-management/README.md

# 9. Kubernetes Developer Guide

https://github.com/kubernetes/community/blob/master/contributors/devel/README.md 

https://github.com/kubernetes/community/blob/master/contributors/guide/github-workflow.md 

有几篇强相关的文档可以read一下,包含的内容

## 9.1. 开发以及贡献代码到Kuberentes project的流程

* pr的信息以及代码reviw
* github上提交Issues
* pr处理过程
* 怎么加速Pr的review
* ci最新编译的ｉ去那个看
* 自动化的工具

## 9.2. 建立你的开发环境, coding以及debugging

* 建立开发环境
* 测试(unit, integration and e2e test)

```
unit测试
运行unit测试, 下面是一些常用的例子
cd kubernetes
make test #Run all unit tests
make test WHAT=./pkg/api  #Run tests for pkg/api        
make test WHAT="./pkg/api  ./pkg/kubelet"  # run tests for pkg/api and pkg/kubelet
指定需要运行的test方法

# Runs TestValidatePod in pkg/api/validation with the verbose flag set

make test WHAT=./pkg/api/validation GOFLAGS="-v" KUBE_TEST_ARGS='-run ^TestValidatePod$'

# Runs tests that match the regex ValidatePod|ValidateConfigMap in pkg/api/validation

make test WHAT=./pkg/api/validation GOFLAGS="-v" KUBE_TEST_ARGS="-run ValidatePod|ValidateConfigMap$"

压力测试
make test PARALLEL=2 ITERATION=5

生成覆盖率
make test PARALLEL=2 ITERATION=5

make test WHAT=./pkg/kubectl KUBE_COVER=y　　＃only one package-k8s-images

Benchmark unit tests

go test ./pkg/apiserver -benchmem -run=XXX -bench=BenchmarkWatch

集成测试Integration tests
End-to-End tests 
https://github.com/kubernetes/community/blob/master/contributors/devel/e2e-tests.md
```

flake free tests

glog日志打印级别 
glog.Errorf() 
glog.Warningf() 
glog.Infof　info级别的日志又分成五个级别, 范围依次变高 
glog.V(0) ＜glog.V(1)＜glog.V(２)＜glog.V(３) ＜glog.V(４) 
可以通过－ｖ＝X来设置X is the descired maximum level to log.
profiling kubernetes
add a new metrics to kubernetes code.
代码规范
文档规范
运行a fast and lightweight local cluster deployment for development
Kuberntes API的开发
REST API文档
Annotations: 用于将任意的非识别元数据附加到对象.  自动化Kubernetes对象的程序可能会使用注释来存储少量的状态. 
API conventions(约定)
插件开发
Authentication　认证插件　
Authorization Plugins　授权插件
Admission Control Plugins 准入插件
发布流程
具体流程

