Memcached是一个自由开源的, 高性能, 分布式**内存对象缓存系统**.

Memcached是一种基于内存的key\-value存储, 用来存储**小块的任意数据(字符串、对象**). 这些数据可以是数据库调用、API调用或者是页面渲染的结果.

memcached 作为高速运行的分布式缓存服务器, 具有以下的特点.

- 协议简单
- 基于libevent的事件处理
- 内置内存存储方式
- memcached不互相通信的分布式

支持的语言
许多语言都实现了连接memcached的客户端, 其中以Perl、PHP为主. 仅仅memcached网站上列出的有:

- Perl
- PHP
- Python
- Ruby
- C#
- C/C++
- Lua
- 等等

教程: http://www.runoob.com/memcached/memcached-tutorial.html

http://calixwu.com/2014/11/memcached-yuanmafenxi-from-set.html

memcached 1.4源码注释: <https://github.com/y123456yz/Reading-and-comprehense-memcached-1.4.22>