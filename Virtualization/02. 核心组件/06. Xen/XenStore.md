
XenStore 是由 [Xenstored](https://wiki.xenproject.org/wiki/Xenstored) 维护的**域之间共享的信息存储空间**. 它主要用于配置和状态信息, 而**不是**用于**大数据传输**. 每个域在存储空间中都有自己的路径, 这在某种程度上类似于 procfs. 当存储空间中的值发生变化时, 相应的驱动程序会收到通知. 有关更多信息以及如何使用 XenStore 进行开发的指南, 请参阅 [XenBus](https://wiki.xenproject.org/wiki/XenBus).

你可以在 [XenStoreReference](https://wiki.xenproject.org/wiki/XenStoreReference) 中找到更多关于 XenStore 中存储的数据的信息.

你可以使用 `xenstore-ls` 工具转储 XenStore 的内容.

```
# xenstore-ls
local = ""domain =""
 0 = ""name ="Domain-0"device-model =""
   0 = ""state ="running"memory =""
   target = "524288"
   static-max = "524288"
   freemem-slack = "1254331"
  libxl = ""disable_udev ="1"vm =""
libxl = ""
```

或者使用 `-f` 选项生成扁平化输出

```
# xenstore-ls -f
/local = ""/local/domain =""
/local/domain/0 = ""/local/domain/0/name ="Domain-0"/local/domain/0/device-model =""
/local/domain/0/device-model/0 = ""/local/domain/0/device-model/0/state ="running"/local/domain/0/memory =""
/local/domain/0/memory/target = "524288"
/local/domain/0/memory/static-max = "524288"
/local/domain/0/memory/freemem-slack = "1254331"
/local/domain/0/libxl = ""/local/domain/0/libxl/disable_udev ="1"/vm =""
/libxl = ""
```
