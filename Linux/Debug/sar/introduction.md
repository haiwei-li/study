
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->



<!-- /code_chunk_output -->

sar(System Activity Reporter 系统活动情况报告)是目前 Linux 上最为全面的系统性能分析工具之一, 可以从多方面对系统的活动进行报告, 包括: 文件的读写情况、系统调用的使用情况、磁盘 I/O、CPU 效率、内存使用状况、进程活动及 IPC 有关的活动等.


- %user: 显示了用户进程消耗的 CPU 时间百分比
- %nice: 显示了运行正常进程所消耗的 CPU 时间百分比
- %system: 显示了系统进程消耗的 CPU 时间百分比
- %iowait: 显示了 IO 等待所占用的 CPU 时间百分比
- %steal: 显示了在内存相对紧张情况下 page in 强制对不同的页面进行的 steal 操作
- %idle: 显示了 CPU 处于空闲状态的时间百分比


- await 表示平均每次设备 I/O 操作的等待时间(以毫秒为单位).
- svctm 表示平均每次设备 I/O 操作的服务时间(以毫秒为单位).
- %util 表示一秒中有百分之几的时间用于 I/O 操作.

参考

http://lovesoo.org/linux-sar-command-detailed.html?sidulm=sygmz2