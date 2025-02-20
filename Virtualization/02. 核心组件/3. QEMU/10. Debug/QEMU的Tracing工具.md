
Qemu 有自己的 Trace 框架并支持多个 debug/trace 后端包括: nop, dtrace, ftrace, log, simple, ust, 可以帮助我们分析 Qemu 中的问题. 关于这些 backend 的介绍, 可以看这个链接:  https://repo.or.cz/w/qemu/stefanha.git/blob_plain/refs/heads/tracing:/docs/tracing.txt , 如果现有的 trace point 不能满足你的需求, 里面还有介绍如何添加新的 trace point.

# simple

Simple trace, 不需要安装任何其他软件就可以使用.

1) 编译 qemu 时要 enable trace backend

```
$ ./configure --enable-trace-backends=simple --enable-debug --enable-kvm --target-list=x86_64-softmmu
$ make
$ make install
```

2) 添加你想要 trace 的 event

最好使用 qemu 自己的 event, 每个代码的目录下都有 `trace-events` 文件

```
$ cat ./hw/block/trace-events
```

3) 启动虚拟机, 并启用想要的 event

```
$ qemu-system-x86_64 /root/CentOS---6.6-64bit---2015-03-06-a.qcow2 -smp 4 -m 4096 --enable-kvm -nographic -net nic -net tap,ifname=tap0,script=no,downscript=no -trace enable=vtd_inv_desc,events=/tmp/events,file=trace.bin
```

加入 `"-trace enable=vtd_inv_desc,events=/data/code/qemu/hw/block/trace-events,file=/tmp/trace.bin"`, 其中

* `enable=vtd_inv_desc`, 想要启用的 event, 如果想要启用所有那就用 `*`, 所有 event 默认是 disable 的
* `events=/data/code/qemu/hw/block/trace-events` 就是要跟踪的 event;
* `file=/tmp/trace.bin` 就是 trace 产生的文件, 不能直接读, 而要通过工具来读.

4) 获取 trace 结果

```
$ ./scripts/simpletrace.py /data/code/qemu/hw/block/trace-events /tmp/trace.bin
```

5)有些模块也实现了自己的 pretty-print 工具, 可以更方便的查看结果. 比如你 trace 了 9p 的模块, 可以通过以下工具查看.

```
$ ./scripts/analyse-9p-simpletrace.py trace-events trace.bin
```

正常运行 QEMU, 为了调试可以在运行 QEMU 的时候加入 monitor 功能, 即在运行的命令中加入 -monitor stdio, 这样就启动了 monitor 并且和用户在 console 中进行交互

(qemu)info trace-events 参考那些 event 已经被 trace, 其中 state 为 1 的是已经 enable 的;  运行(qemu)info trace 查看缓存的 trace

当然除了 trace-events 定义的一些默认函数外, 依据例子也可以自己定义一些 trace, 定义的规则符合 c 语言函数的命名规则, 在使用的文件中加入 #include "trace.h" , 需要 trace 的地方在 name 前加入 trace_即可, 具体参考 qemu/trace-event 和 qemu/docs/tracing.txt 文档.

# log 方式

https://blog.csdn.net/daxiatou/article/details/103450929

qemu 编译选项

```
./configure --enable-trace-backends=log --enable-debug --enable-kvm --target-list=x86_64-softmmu
```

启动命令行

```
sudo /usr/local/bin/qemu-system-x86_64 -name ubuntu-hirsute -accel kvm -cpu host -smp 4,sockets=1,cores=2,threads=2 -m 3G -device piix3-usb-uhci,id=usb,bus=pci.0,addr=0x1.0x2 -drive file=/data/images/ubuntu_hirsute.qcow2,if=none,id=drive-virtio-disk0,format=qcow2,cache=none -device virtio-blk-pci,scsi=off,bus=pci.0,addr=0x3,drive=drive-virtio-disk0,id=virtio-disk0,bootindex=1 -drive file=/data/images/data.qcow2,format=qcow2,if=none,id=drive-virtio-disk1,cache=none -object iothread,id=iothread1 -device virtio-blk-pci,iothread=iothread1,scsi=off,bus=pci.0,addr=0x4,drive=drive-virtio-disk1,id=virtio-disk1 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic -full-screen -chardev socket,id=montest,server=on,wait=off,path=/tmp/mon_test -mon chardev=montest,mode=readline -D /data/images/qemu.log
```

/home/test/workspace/qemu.log

设置 event

```
# nc -U /tmp/mon_test
QEMU 7.0.50 monitor - type 'help' for more information
(qemu) trace-event virtio_blk_req_complete on
trace-event virtio_blk_req_complete on
(qemu) trace-event virtio_blk_rw_complete on
trace-event virtio_blk_rw_complete on
(qemu) trace-event virtio_blk_handle_write on
trace-event virtio_blk_handle_write on
(qemu) trace-event virtio_blk_handle_read on
trace-event virtio_blk_handle_read on
```

`(qemu)info trace-events` 那些 event 已经被 trace, 其中 state 为 1 的是已经 enable 的;

运行 `(qemu)info trace` 查看缓存的 trace

查看 event log

查看 /data/images/qemu.log 可得



# 参考

https://blog.csdn.net/scaleqiao/article/details/50787340

https://blog.csdn.net/wenmang1977/article/details/8562678