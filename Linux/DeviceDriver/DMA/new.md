
DMA 映射主要为在设备与主存之间建立 DMA 数据传输通道时, 在主存中为该 DMA 通道分配内存空间的行为, 该内存空间也称为 DMA 缓冲区. 这个任务原本可以很简单, 但是由于现代处理器 cache 的存在, 使得事情变得复杂.



PCI 设备 支持 DMA, 那么在传输数据的时候, 我们需要一块 DMA buffer 用于 接收或者发送数据, 这块 DMA buffer 存在于 RAM 内存区域 中.

但我们之前说了, PCI 设备在 MMIO 区域 有规定的 总线地址, 那么在 RAM 内存区域 也是一样, PCI 设备 无法通过方位 RAM 内存区域中的虚拟地址 来 获取或存放数据. 但与 MMIO 不同的是, MMIO 通过 PCI 桥 将 虚拟地址 映射为 总线地址, RAM 内存 则是通过 IOMMU 将 虚拟地址 映射为 总线地址.

那么 PCI 设备、DMA 和 CPU 是如何在 同一块内存 中进行交互的呢?
回答这个问题, 我们需要清楚以下几点:

* PCI 设备 使用 DMA 传输 的是数据时需要使用的是 总线地址, 即 DMA 是使用 总线地址 作为 源地址 或者 目的地址
* DMA 传输数据时, *IOMMU 可以将 总线地址 转换 物理地址 .
* DMA 传输完成后, CPU 使用 虚拟地址 访问该内存块.

其步骤如下:

1. 内存块 由 CPU 创建, 此时 CPU 获取到的是 内存块的虚拟地址 X.
2. 调用接口, 将该内存块的 虚拟地址 X 对应的 物理地址 Y 映射为 总线地址 Z 并返回给 CPU.
3. CPU 拿到的地址有 内存块 的 虚拟地址 和 总线地址, 其 物理地址 对于 CPU 来说没有意义.
4. 将 总线地址 写入 DMA 对应的寄存器, 接着就可以执行相关的 DMA 操作 了.


数据如何在 CPU 和 IO device 之间的传递和处理?

(1)**CPU** 通过**MMU**建立起数据的**物理地址 PA**到数据的**虚拟地址**之间的映射, CPU 通过访问 **VA** 从而访问到数据(比如 CPU 填充数据到内存中);

(2)**IO 设备驱动**得到数据的**PA**, 并通过**DMA MAP**将数据的物理地址**PA**和**IOVA**建立**映射**, 然后 IO 设备驱动将 IOVA 传递给 IOMMU 设备;

(3)IOMMU 将 IOVA 转换为 PA, 从而对 PA 处的数据的处理;

(4)完成数据处理后, 通过 DMA UNMAP 取消 IOVA 到 PA 的映射;

都会将物理区域与连续的 IOVA 建立起映射:

* dma_alloc_coherent(dev, size, dma_handle, gfp), 一致性 DMA, 在分配物理区域的同时, 建立物理区域与 IOVA 的映射, 同时返回 VA.

> 之前介绍过 COHERENT 特性, 对于一致性 DMA, 可以保证 CPU 和 IO 设备看到的物理地址是一致, 因为 CPU 侧存在 CACHE, 一致性 DMA 可通过关 CACHE 或硬件来保证 CPU 和 IO 设备看到的物理地址是一致. 函数 dma_alloc_coherent()为一致性 DMA. 一致性 DMA 通常为静态的, 建立起一致性映射后, 一般在系统结束时取消映射.

* dma_map_sg/page/single(), 流式 DMA, 将之前分配好的物理区域与连续的 IOVA 建立起映射

> 流式 DMA 为动态的, 每次都会建立映射, 然后取消映射. 由于 CPU 侧存在 CACHE, 需要软件或硬件来维护一致性

iommu_dma_ops




1. kmalloc() 等申请 DMA 缓冲区, 使用 GFP_DMA 标志.


dma_mem_alloc()



DMA 映射包括两个方面的工作: 分配一片 DMA 缓冲区; 为这片缓冲区产生设备可访问的地址.

dma_alloc_coherent() 申请一片 DMA 缓冲区, 以进行地址映射并保证该缓冲区的 Cache 一致性







DMA 的原理就是 CPU 将需要迁移的数据的位置告诉给 DMA, 包括源地址, 目的地址以及需要迁移的长度, 然后启动 DMA 设备, DMA 设备收到命令之后, 就去完成相应的操作, 最后通过中断反馈给老板 CPU, 结束.


在实现 DMA 传输时, 是 DMA 控制器掌控着总线, 也就是说, 这里会有一个控制权转让的问题, 我们当然知道, 计算机中最大的 BOSS 就是 CPU, 这个 DMA 暂时掌管的总线控制权当前也是 CPU 赋予的, 在 DMA 完成传输之后, 会通过中断通知 CPU 收回总线控制权.

一个完整的 DMA 传输过程必须经过 DMA 请求、DMA 响应、DMA 传输、DMA 结束这四个阶段.

DMA 请求: CPU 对 DMA 控制器初始化, 并向 I/O 接口发出操作命令, I/O 接口提出 DMA 请求

DMA 响应: DMA 控制器对 DMA 请求判别优先级以及屏蔽位, 向总线裁决逻辑提出总线请求, 当 CPU 执行完成当前的总线周期之后即可释放总线控制权. 此时, 总线裁决逻辑输出总线应答, 表示 DMA 已经就绪, 通过 DMA 控制器通知 I/O 接口开始 DMA 传输.

DMA 传输: 在 DMA 控制器的引导下, 在存储器和外设之间进行数据传送, 在传送过程中不需要 CPU 的参与.

DMA 结束: 当完成既定操作之后, DMA 控制器释放总线控制权, 并向 I/O 接口发出结束信号, 当 I/O 接口收到结束信号之后, 一方面停止 I/O 设备的工作, 另一方面向 CPU 提出中断请求, 使 CPU 从不介入状态解脱, 并执行一段检查本次 DMA 传输操作正确性的代码. 最后带着本次操作的结果以及状态继续执行原来的程序.


```cpp
    /* 申请 dma 通道, 在此之前请确保设备树中的 dma 相关属性编写正确, 否则会引发 oops */
    test_device->dma_chan = dma_request_chan(&pdev->dev, "sdram");
    if(NULL == test_device->dma_chan)
    {
        printk(KERN_INFO"request dma channel error\n");
        goto DEVICE_FAILE;
    }

    /* 开辟缓冲区并填充 */
    int buf_size = 128;
    void* dma_src = NULL;
    void* dma_dst = NULL;
    dma_addr_t dma_bus_src;
    dma_addr_t dma_bus_dst;
#if 0
    /* 一致性映射 */
    dma_src = dma_alloc_coherent(&pdev->dev, buf_size, &dma_bus_src, GFP_KERNEL|GFP_DMA);
    if(NULL == dma_src)
    {
        printk(KERN_INFO"alloc src buffer error\n");
        goto DMA_SRC_FAILED;
    }
    printk(KERN_INFO"dma_src = %p, dma_bus_src = %#x\n", dma_src, dma_bus_src);

    dma_dst = dma_alloc_coherent(&pdev->dev, buf_size, &dma_bus_dst, GFP_KERNEL|GFP_DMA);
    if(NULL == dma_src)
    {
        printk(KERN_INFO"alloc src buffer error\n");
        goto DMA_DST_FAILED;
    }
    printk(KERN_INFO"dma_dst = %p, dma_bus_dst = %#x\n", dma_dst, dma_bus_dst);

    for(int i = 0; i < buf_size; i++)
    {
        ((char*)dma_src)[i] = i;
        printk(KERN_INFO"dma_src[%d] = %d, dma_dst[%d] = %d\n", i, ((char*)dma_src)[i], i, ((char*)dma_dst)[i]);
    }
#else
    dma_src = devm_kzalloc(&pdev->dev, buf_size, GFP_KERNEL);
    if(NULL == dma_src)
    {
        printk(KERN_INFO"alloc src buffer error\n");
        goto DEVICE_FAILE;
    }
    dma_dst = devm_kzalloc(&pdev->dev, buf_size, GFP_KERNEL);
    if(NULL == dma_src)
    {
        printk(KERN_INFO"alloc src buffer error\n");
        goto DEVICE_FAILE;
    }
#if 0
    /*
        错误的流式映射
        在进行映射后不能对缓冲区进行操作, 不然 DMA 拿到的数据与真正的数据不一致
    */
    dma_bus_src = dma_map_single(&pdev->dev, dma_src, buf_size, DMA_BIDIRECTIONAL);
    dma_bus_dst = dma_map_single(&pdev->dev, dma_dst, buf_size, DMA_BIDIRECTIONAL);
    printk(KERN_INFO"dma_src = %p, dma_bus_src = %#x\n", dma_src, dma_bus_src);
    printk(KERN_INFO"dma_dst = %p, dma_bus_dst = %#x\n", dma_dst, dma_bus_dst);
    for(int i = 0; i < buf_size; i++)
    {
        ((char*)dma_src)[i] = i;
        printk(KERN_INFO"dma_src[%d] = %d, dma_dst[%d] = %d\n", i, ((char*)dma_src)[i], i, ((char*)dma_dst)[i]);
    }
#else
    /*
        正确的流式映射
        将数据放入缓冲区后在进行映射, 确保 DMA 拿到正确的数据
    */
    for(int i = 0; i < buf_size; i++)
    {
        ((char*)dma_src)[i] = i;
        printk(KERN_INFO"dma_src[%d] = %d, dma_dst[%d] = %d\n", i, ((char*)dma_src)[i], i, ((char*)dma_dst)[i]);
    }

    dma_bus_src = dma_map_single(&pdev->dev, dma_src, buf_size, DMA_BIDIRECTIONAL);
    dma_bus_dst = dma_map_single(&pdev->dev, dma_dst, buf_size, DMA_BIDIRECTIONAL);
    printk(KERN_INFO"dma_src = %p, dma_bus_src = %#x\n", dma_src, dma_bus_src);
    printk(KERN_INFO"dma_dst = %p, dma_bus_dst = %#x\n", dma_dst, dma_bus_dst);
#endif
#endif

    /* 获取传输描述符 */
    struct  dma_async_tx_descriptor* dma_tx = NULL;
    dma_tx = dmaengine_prep_dma_memcpy(test_device->dma_chan, dma_bus_dst, dma_bus_src, buf_size, DMA_PREP_INTERRUPT);
    if(NULL == dma_tx)
    {
        printk(KERN_INFO"prepare dma error\n");
        goto DEVICE_FAILE;
    }

    /* 获取 dma cookie */
    dma_cookie_t dma_cookie;
    dma_cookie = dmaengine_submit(dma_tx);
    if (dma_submit_error(dma_cookie))
    {
        printk(KERN_INFO"submit dma error\n");
        goto DEVICE_FAILE;
    }

    /* 开始传输 */
    dma_async_issue_pending(test_device->dma_chan);

    /* 等待传输完成 */
    enum dma_status dma_status = DMA_ERROR;
    struct dma_tx_state tx_state = {0};
    while(DMA_COMPLETE!= dma_status)
    {
        dma_status = test_device->dma_chan->device->device_tx_status(test_device->dma_chan, dma_cookie, &tx_state);
        schedule();
    }
    printk(KERN_INFO"dma_status = %d\n", dma_status);

    for(int i = 0; i < buf_size; i++)
    {
        printk(KERN_INFO"dma_src[%d] = %d, dma_dst[%d] = %d\n", i, ((char*)dma_src)[i], i, ((char*)dma_dst)[i]);
    }
    printk(KERN_INFO"dma finished\n");

#if 1
    /* 如果是流式映射, 在使用完以后需要去映射 */
    dma_unmap_single(&pdev->dev, dma_bus_src, buf_size, DMA_BIDIRECTIONAL);
    dma_unmap_single(&pdev->dev, dma_bus_dst, buf_size, DMA_BIDIRECTIONAL);
#endif
```