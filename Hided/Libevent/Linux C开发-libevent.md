
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 介绍](#1-介绍)
* [2 event\_base](#2-event_base)
	* [2.1 创建event\_base](#21-创建event_base)
	* [2.2 查看IO模型](#22-查看io模型)
	* [2.3 销毁event\_base](#23-销毁event_base)
	* [2.4 事件循环 event loop](#24-事件循环-event-loop)
	* [2.5 event\_base的例子](#25-event_base的例子)
* [3 event事件](#3-event事件)
	* [3.1 创建一个事件event](#31-创建一个事件event)
	* [3.2 释放event\_free](#32-释放event_free)
	* [3.3 注册event](#33-注册event)
	* [3.4 event\_assign](#34-event_assign)
	* [3.5 信号事件](#35-信号事件)
	* [3.6 event细节](#36-event细节)
* [4 Socket实例](#4-socket实例)
* [5 Bufferevent](#5-bufferevent)
	* [5.1 创建Bufferevent API](#51-创建bufferevent-api)
* [参考](#参考)

<!-- /code_chunk_output -->

# 1 介绍

libevent是一个**事件触发**的**网络库**, 适用于windows、linux、bsd等多种平台, 内部使用**select**、**epoll**、**kqueue**等**系统调用**管理事件机制. 著名分布式缓存软件memcached也是libevent based, 而且libevent在使用上可以做到跨平台, 而且根据libevent官方网站上公布的数据统计, 似乎也有着非凡的性能. 

- [官网文档](http://libevent.org/)
- [英文文档](http://www.wangafu.net/~nickm/libevent-book/)
- [中文文档](http://www.cppblog.com/mysileng/category/20374.html)

Libevent是基于事件的网络库. 说的通俗点, 例如**客户端**连接到**服务端**属于一个连接的事件, 当这个事件触发的时候就会去处理. 

# 2 event\_base

## 2.1 创建event\_base

event\_base是**event**的一个**集合**. event\_base中存放你是监听是否就绪的event. 一般情况下一个线程一个event_base, 多个线程的情况下需要开多个event\_base. 

event\_base主要是用来管理和实现事件的监听循环. 

一般情况下直接new一个event_base就可以满足大部分需求了, 如果需要配置参数的, 可以参见libevent官网. 

创建方法:

```c
struct event_base *event_base_new(void);
```

销毁方法:

```c
void event_base_free(struct event_base *base);
```

重新初始化:

```c
int event_reinit(struct event_base *base);
```

## 2.2 查看IO模型

IO多路复用模型中([IO模型文章](http://blog.csdn.net/initphp/article/details/42011845)), 有多种方法可以供我们选择, 但是这些模型是在不同的平台下面的:  select  poll  epoll  kqueue  devpoll  evport  win32

当我们创建一个event\_base的时候, libevent会**自动**为我们选择**最快的IO多路复用模型**, Linux下一般会用epoll模型. 

下面这个方法主要是用来获取IO模型的名称. 

```c
const char *event_base_get_method(const struct event_base *base);
```

## 2.3 销毁event\_base

```c
void event_base_free(struct event_base *base);
```

## 2.4 事件循环 event loop

上面说到 event\_base是一组event的集合, 我们也可以将event事件注册到这个集合中. 当需要事件监听的时候, 我们就需要对这个event\_base进行循环. 

下面这个函数非常重要, 会在**内部不断的循环监听注册上来的事件**. 

```c
int event_base_dispatch(struct event_base *base);
```

返回值: 0 表示成功退出  \-1 表示存在错误信息. 

还可以用这个方法: 

```c
#define EVLOOP_ONCE             0x01
#define EVLOOP_NONBLOCK         0x02
#define EVLOOP_NO_EXIT_ON_EMPTY 0x04
 
int event_base_loop(struct event_base *base, int flags);
```

event\_base\_loop这个方法会比event\_base\_dispatch这个方法更加灵活一些. 

- EVLOOP\_ONCE: 阻塞直到有一个活跃的event, 然后执行完活跃事件的回调就退出. 

- EVLOOP\_NONBLOCK: 不阻塞, 检查哪个事件准备好, 调用优先级最高的那一个, 然后退出. 

0: 如果参数填了0, 则**只有事件进来的时候**才会**调用一次事件的回调函数**, 比较常用

事件循环停止的情况: 

1. event\_base中没有事件event

2. 调用event\_base\_loopbreak(), 那么事件循环将停止

3. 调用event\_base\_loopexit(), 那么事件循环将停止

4. 程序错误, 异常退出

两个退出的方法: 

```c
// 这两个函数成功返回 0 失败返回 -1
// 指定在 tv 时间后停止事件循环
// 如果 tv == NULL 那么将无延时的停止事件循环
int event_base_loopexit(struct event_base *base,const struct timeval *tv);
// 立即停止事件循环(而不是无延时的停止)
int event_base_loopbreak(struct event_base *base);
```

两个方法区别: 

1. event_base_loopexit(base, NULL) 如果当前正在为多个活跃事件调用回调函数, 那么不会立即退出, 而是等到所有的活跃事件的回调函数都执行完成后才退出事件循环

2. event_base_loopbreak(base) 如果当前正在为多个活跃事件调用回调函数, 那么当前正在调用的回调函数会被执行, 然后马上退出事件循环, 而并不处理其他的活跃事件了

## 2.5 event\_base的例子

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>    
#include <sys/socket.h>    
#include <netinet/in.h>    
#include <arpa/inet.h>   
#include <string.h>
#include <fcntl.h> 
 
#include <event2/event.h>
#include <event2/bufferevent.h>
 
int main() {
	puts("init a event_base!");
	struct event_base *base; //定义一个event_base
	base = event_base_new(); //初始化一个event_base
	const char *x =  event_base_get_method(base); //查看用了哪个IO多路复用模型, linux一下用epoll
	printf("METHOD:%s\n", x);
	int y = event_base_dispatch(base); //事件循环. 因为我们这边没有注册事件, 所以会直接退出
	event_base_free(base);  //销毁libevent
	return 1;
}
```

# 3 event事件

event_base是事件的集合, 负责事件的循环, 以及集合的销毁. 而event就是event_base中的基本单元: 事件. 

我们举一个简单的例子来理解事件. 例如我们的socket来进行网络开发的时候, 都会使用accept这个方法来阻塞监听是否有客户端socket连接上来, 如果客户端连接上来, 则会创建一个线程用于服务端与客户端进行数据的交互操作, 而服务端会继续阻塞等待下一个客户端socket连接上来. 客户端连接到服务端实际就是一种事件. 

## 3.1 创建一个事件event

```c
struct event *event_new(struct event_base *base, evutil_socket_t fd,short what, event_callback_fn cb,void *arg);
```

参数: 

1. base: 即event_base

2. fd: 文件描述符. 

3. what: event关心的各种条件. 

4. cb: 回调函数. 

5. arg: 用户自定义的数据, 可以传递到回调函数中去. 

libevent是基于事件的, 也就是说只有在事件到来的这种条件下才会触发当前的事件. 例如: 

1. fd文件描述符已准备好可写或者可读

2. fd马上就准备好可写和可读. 

3. 超时的情况 timeout

4. 信号中断

5. 用户触发的事件

what参数 event各种条件: 

```c
// 超时
#define EV_TIMEOUT 0x01
// event 相关的文件描述符可以读了
#define EV_READ 0x02
// event 相关的文件描述符可以写了
#define EV_WRITE 0x04
// 被用于信号检测(详见下文)
#define EV_SIGNAL 0x08
// 用于指定 event 为 persistent 持久类型. 当事件执行完毕后, 不会被删除, 继续保持pending等待状态;
// 如果是非持久类型, 则回调函数执行完毕后, 事件就会被删除, 想要重新使用这个事件, 就必须将这个事件继续添加event_add 
#define EV_PERSIST 0x10
// 用于指定 event 会被边缘触发
#define EV_ET 0x20
```

## 3.2 释放event\_free

真正的释放event的内存. 

```c
void event_free(struct event *event);
```

event_del 清理event的内存. 这个方法并不是真正意义上的释放内存. 

当函数会将事件转为 非pending和非activing的状态. 

```c
int event_del(struct event *event);
```

## 3.3 注册event

该方法将用于**向event_base注册事件**. 

参数: ev 为事件指针; tv 为时间指针. 当tv = NULL的时候则无超时时间. 

函数返回: 0表示成功 -1 表示失败. 

```c
int event_add(struct event *ev, const struct timeval *tv);
```

tv时间结构例子: 

```c
struct timeval five_seconds = {5, 0};
event_add(ev1, &five_seconds);
```

## 3.4 event\_assign

**event\_new**每次都会**在堆上分配内存**. 有些场景下并不是每次都需要在堆上分配内存的, 这个时候我们就可以用到event\_assign方法. 

已经初始化或者处于 pending 的 event, 首先需要调用 event\_del() 后再调用 event_assign(). 这个时候就可以重用这个event了. 

```cpp
// 此函数用于初始化 event(包括可以初始化栈上和静态存储区中的 event)
// event_assign() 和 event_new() 除了 event 参数之外, 使用了一样的参数
// event 参数用于指定一个未初始化的且需要初始化的 event
// 函数成功返回 0 失败返回 -1
int event_assign(struct event *event, struct event_base *base,evutil_socket_t fd, short what,void (*callback)(evutil_socket_t, short, void *), void *arg);
     
// 类似上面的函数, 此函数被信号 event 使用
event_assign(event, base, signum, EV_SIGNAL|EV_PERSIST, callback, arg)
```

## 3.5 信号事件

信号事件也可以对信号进行事件的处理. 用法和event_new类似. 只不过处理的是信号而已. 

```c
// base --- event_base
// signum --- 信号, 例如 SIGHUP
// callback --- 信号出现时调用的回调函数
// arg --- 用户自定义数据
evsignal_new(base, signum, cb, arg)
     
//将信号 event 注册到 event_base
evsignal_add(ev, tv) 
     
// 清理信号 event
evsignal_del(ev) 
```

## 3.6 event细节

1. 每一个事件event都需要通过event_new初始化生成. event_new生成的事件是在堆上分配的内存. 

2. 当一个事件通过event_add被注册到event_base上的时候, 这个事件处于pending(等待状态), 当只有有事件进来的时候, event才会被激活active状态, 相关的回调函数就会被调用. 

3. persistent 如果event_new中的what参数选择了EV_PERSIST, 则是持久的类型. 持久的类型调用玩回调函数后, 会继续转为pending状态, 就会继续等待事件进来. 大部分情况下会选择持久类型的事件. 

3. 而非持久的类型的事件, 调用完一次之后, 就会变成初始化的状态. 这个时候需要调用event_add 继续将事件注册到event_base上之后才能使用. 

# 4 Socket实例

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>    
#include <sys/socket.h>    
#include <netinet/in.h>    
#include <arpa/inet.h>   
#include <string.h>
#include <fcntl.h> 
 
#include <event2/event.h>
#include <event2/bufferevent.h>
 
//读取客户端
void do_read(evutil_socket_t fd, short event, void *arg) {
    //继续等待接收数据  
    char buf[1024];  //数据传送的缓冲区    
    int len;  
    if ((len = recv(fd, buf, 1024, 0)) > 0)  {  
        buf[len] = '\0';    
        printf("%s\n", buf);    
        if (send(fd, buf, len, 0) < 0) {    //将接受到的数据写回客户端
            perror("write");    
        }
    } 
}
 
 
//回调函数, 用于监听连接进来的客户端socket
void do_accept(evutil_socket_t fd, short event, void *arg) {
    int client_socketfd;//客户端套接字    
    struct sockaddr_in client_addr; //客户端网络地址结构体   
    int in_size = sizeof(struct sockaddr_in);  
    //客户端socket  
    client_socketfd = accept(fd, (struct sockaddr *) &client_addr, &in_size); //等待接受请求, 这边是阻塞式的  
    if (client_socketfd < 0) {  
        puts("accpet error");  
        exit(1);
    }  
 
    //类型转换
    struct event_base *base_ev = (struct event_base *) arg;
 
    //socket发送欢迎信息  
    char * msg = "Welcome to My socket";  
    int size = send(client_socketfd, msg, strlen(msg), 0);  
 
    //创建一个事件, 这个事件主要用于监听和读取客户端传递过来的数据
    //持久类型, 并且将base_ev传递到do_read回调函数中去
    struct event *ev;
    ev = event_new(base_ev, client_socketfd, EV_TIMEOUT|EV_READ|EV_PERSIST, do_read, base_ev);
    event_add(ev, NULL);
}
 
 
//入口主函数
int main() {
 
    int server_socketfd; //服务端socket  
    struct sockaddr_in server_addr;   //服务器网络地址结构体    
    memset(&server_addr,0,sizeof(server_addr)); //数据初始化--清零    
    server_addr.sin_family = AF_INET; //设置为IP通信    
    server_addr.sin_addr.s_addr = INADDR_ANY;//服务器IP地址--允许连接到所有本地地址上    
    server_addr.sin_port = htons(8001); //服务器端口号    
  
    //创建服务端套接字  
    server_socketfd = socket(PF_INET,SOCK_STREAM,0);  
    if (server_socketfd < 0) {  
        puts("socket error");  
        return 0;  
    }  
 
    evutil_make_listen_socket_reuseable(server_socketfd); //设置端口重用
    evutil_make_socket_nonblocking(server_socketfd); //设置无阻赛
  
    //绑定IP  
    if (bind(server_socketfd, (struct sockaddr *)&server_addr, sizeof(struct sockaddr))<0) {  
        puts("bind error");  
        return 0;  
    }  
 
    //监听,监听队列长度 5  
    listen(server_socketfd, 10);  
    
    //创建event_base 事件的集合, 多线程的话 每个线程都要初始化一个event_base
    struct event_base *base_ev;
    base_ev = event_base_new(); 
    const char *x =  event_base_get_method(base_ev); //获取IO多路复用的模型, linux一般为epoll
    printf("METHOD:%s\n", x);
 
    //创建一个事件, 类型为持久性EV_PERSIST, 回调函数为do_accept(主要用于监听连接进来的客户端)
    //将base_ev传递到do_accept中的arg参数
    struct event *ev;
    ev = event_new(base_ev, server_socketfd, EV_TIMEOUT|EV_READ|EV_PERSIST, do_accept, base_ev);
 
    //注册事件, 使事件处于 pending的等待状态
    event_add(ev, NULL);
 
    //事件循环
    event_base_dispatch(base_ev);
 
    //销毁event_base
	event_base_free(base_ev);  
	return 1;
}
```

说明: 
1. 必须设置socket为非阻塞模式, 否则就会阻塞在那边, 影响整个程序运行

```cpp
evutil_make_listen_socket_reuseable(server_socketfd); //设置端口重用
evutil_make_socket_nonblocking(server_socketfd); //设置无阻赛
```

2. 我们首先建立的事件主要用于**监听客户端的连入**. 当客户端有socket连接到服务器端的时候, 回调函数do_accept就会去执行; 当空闲的时候, 这个事件就会是一个pending等待状态, 等待有新的连接进来, 新的连接进来了之后又会继续执行. 

```cpp
struct event *ev;
ev = event_new(base_ev, server_socketfd, EV_TIMEOUT|EV_READ|EV_PERSIST, do_accept, base_ev);
```

3. 在do_accept事件中我们创建了一个新的事件, 这个事件的回调函数是do\_read. 主要用来**循环监听客户端上传的数据**. do\_read这个方法会一直循环执行, 接收到客户端数据就会进行处理. 

```cpp
//创建一个事件, 这个事件主要用于监听和读取客户端传递过来的数据
//持久类型, 并且将base_ev传递到do_read回调函数中去
struct event *ev;
ev = event_new(base_ev, client_socketfd, EV_TIMEOUT|EV_READ|EV_PERSIST, do_read, base_ev);
event_add(ev, NULL);
```

# 5 Bufferevent

上面的socket例子估计经过测试估计大家就会有很多疑问: 

1. do_read方法作为一个事件会一直被循环

2. 当客户端连接断开的时候, do_read方法还是在循环, 根本不知道客户端已经断开socket的连接. 

3. 需要解决各种粘包和拆包(相关粘包拆包文章)问题

如果要解决这个问题, 我们可能要做大量的工作来维护这些socket的连接状态, 读取状态. 而Libevent的Bufferevent帮我们解决了这些问题. 

Bufferevent主要是用来管理和调度IO事件; 而Evbuffer(下面一节会讲到)主要用来缓冲网络IO数据. 

Bufferevent目前支持TCP协议, 而不知道UDP协议. 我们这边也只讲TCP协议下的Bufferevent的使用. 

我们先看下下面的接口(然后结合下面改进socket的例子, 自己动手去实验一下): 

## 5.1 创建Bufferevent API

```cpp
//创建一个Bufferevent
struct bufferevent *bufferevent_socket_new(struct event_base *base, evutil_socket_t fd, enum bufferevent_options options);
```

参数: 

base: 即event_base

fd: 文件描述符. 如果是socket的方法, 则socket需要设置为非阻塞的模式. 

options: 行为选项, 下面是行为选项内容

1. BEV_OPT_CLOSE_ON_FREE : 当 bufferevent 被释放同时关闭底层(socket 被关闭等) 一般用这个选项

2. BEV_OPT_THREADSAFE : 为 bufferevent 自动分配锁, 这样能够在多线程环境中安全使用

3. BEV_OPT_DEFER_CALLBACKS :  当设置了此标志, bufferevent 会延迟它的所有回调(参考前面说的延时回调)

4. BEV_OPT_UNLOCK_CALLBACKS :  如果 bufferevent 被设置为线程安全的, 用户提供的回调被调用时 bufferevent 的锁会被持有. 如果设置了此选项, Libevent 将在调用你的回调时释放 bufferevent 的锁




# 参考
https://blog.csdn.net/initphp/article/details/41946061

