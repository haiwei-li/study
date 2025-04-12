Linux 初始化 init 系统

从 sysvinit 到 systemd

近年来, Linux 系统的 init 进程经历了两次重大的演进, 传统的 sysvinit 已经淡出历史舞台, 新的 init 系统 UpStart 和 systemd 各有特点, 而越来越多的 Linux 发行版采纳了 systemd. 本文简要介绍了这三种 init 系统的使用和原理, 每个 Linux 系统管理员和系统软件开发者都应该了解它们, 以便更好地管理系统和开发应用. 本文是系列的第一部分, 主要讲述 sysvinit 的特点和使用.

```
参考:
https://www.ibm.com/developerworks/cn/views/linux/libraryview.jsp?sort_by=&show_abstract=true&show_all=&search_flag=&contentarea_by=Linux&search_by=%E6%B5%85%E6%9E%90+Linux+%E5%88%9D%E5%A7%8B%E5%8C%96+init+%E7%B3%BB%E7%BB%9F&topic_by=-1&type_by=%E6%89%80%E6%9C%89%E7%B1%BB%E5%88%AB&ibm-search=%E6%90%9C%E7%B4%A2
```