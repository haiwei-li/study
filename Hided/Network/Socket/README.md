socket是对TCP/IP的抽象,  网络编程肯定绕不过socket, 绝大部分语言都提供了socket相关的API. 

工作中直接对socket编程的机会不多, 大多都是封装好的,  但是要理解socket在客户端和服务器端的区别, 服务器端是如何维护连接的,  这就会引出一个重要的技术: I/O多路复用(select/poll/epoll) , 也是ngnix,redis等著名软件的基础. 

I/O多路复用是I/O模型之一, 其他还有同步阻塞, 同步非阻塞, 信号驱动和异步. 

这方面最经典的书应该是《Unix网络编程了》. 

码农翻身文章: 

《[张大胖的socket](http://mp.weixin.qq.com/s?__biz=MzAxOTc0NzExNg==&mid=2665513387&idx=1&sn=99665948d0b968cf15c5e7a01ffe166c&chksm=80d679e8b7a1f0febad077b57e8ad73bfb4b08de74814c45e1b1bd61ab4017b5041942403afb&scene=21#wechat_redirect)》

《[HTTP Server : 一个差生的逆袭](http://mp.weixin.qq.com/s?__biz=MzAxOTc0NzExNg==&mid=2665513467&idx=1&sn=178459f4bb9891c9cf471a28e7c340be&chksm=80d679b8b7a1f0aea8f6e3f09acb6969993825753170dc3db63f8ef35c95cce98aa40a0c7097&scene=21#wechat_redirect)》