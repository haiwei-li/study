禁止 Kernel 启动时 Logo 显示

```
make ARCH=x86_64 menuconfig
    -> Device Drivers
        -> Graphics support
            [*] Bootup logo
```

将 Bootup Logo 特性关闭设置为 N, 默认是 Y.