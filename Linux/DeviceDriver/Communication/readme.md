
首先先来介绍以下同步和异步通信, 同步是指, 发送方发出数据后, 等接收方发回响应以后才发下一个数据包的通讯方式; 异步是指, 发送方发出数据后, 不等接收方发回响应, 接着发送下个数据包的通讯方式. 换句话说, 同步通信是阻塞方式, 异步通信是非阻塞方式. 在常见通信总线协议中, I2C, SPI属于同步通信而UART属于异步通信. 同步通信的通信双方必须先建立同步, 即双方的时钟要调整到同一个频率, 收发双方不停地发送和接收连续的同步比特流. 异步通信在发送字符时, 发送端可以在任意时刻开始发送字符, 所以, 在UART通信中, 数据起始位和停止位是必不可少的. 

串口进行通信的方式有两种: 同步通信方式和异步通信方式

* SPI(Serial Peripheral Interface: 串行外设接口);

* I2C(INTER IC BUS: 意为IC之间总线), 一(host)对多, 以字节为单位发送. 

* UART(Universal Asynchronous Receiver Transmitter: 通用异步收发器),  一对一, 以位为单位发送. 


https://github.com/haiwei-li/siflower.github.io

