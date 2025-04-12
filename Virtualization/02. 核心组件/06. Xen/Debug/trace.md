
Xentrace 能够帮助你知道在Hypervisor中发生了什么, 作为一个统计工具, 可以记录所有的VMEnter/Exit、Schedule、Dom0ops等信息, 并能够指定统计哪个cpu、记录哪些事件的信息。在进行一些验证、测试或Resource counting的时候有比较大的作用。

```
# xentrace --help
Usage: xentrace [OPTION...] [output file]
Tool to capture Xen trace buffer data

  -c, --cpu-mask=c        Set cpu-mask, using either hex, CPU ranges, or
                          for all CPUs
  -e, --evt-mask=e        Set evt-mask
  -s, --poll-sleep=p      Set sleep time, p, in milliseconds between
                          polling the trace buffer for new data
                          (default 100).
  -S, --trace-buf-size=N  Set trace buffer size in pages (default 32).
                          N.B. that the trace buffer cannot be resized.
                          if it has already been set this boot cycle,
                          this argument will be ignored.
  -D  --discard-buffers   Discard all records currently in the trace
                          buffers before beginning.
  -x  --dont-disable-tracing
                          By default, xentrace will disable tracing when
                          it exits. Selecting this option will tell it to
                          keep tracing on.  Traces will be collected in
                          Xen's trace buffers until they become full.
  -X  --start-disabled    Setup trace buffers and listen, but don't enable
                          tracing. (Useful if tracing will be enabled by
                          else.)
  -T  --time-interval=s   Run xentrace for s seconds and quit.
  -?, --help              Show this message
  -V, --version           Print program version
  -M, --memory-buffer=b   Copy trace records to a circular memory buffer.
                          Dump to file on exit.
  -r  --reserve-disk-space=n Before writing trace records to disk, check to see
                          that after the write there will be at least n space
                          left on the disk.

This tool is used to capture trace buffer data from Xen. The
data is output in a binary format, in the following order:

  CPU(uint) TSC(uint64_t) EVENT(uint32_t) D1 D2 D3 D4 D5 (all uint32_t)

The output should be parsed using the tool xenalyze,
which can produce human-readable output in ASCII format.
```

使用Xentrace非常简单, 在安装Xen tools的时候就已经安装好了xentrace, 直接调用即可:

```bash
xentrace -D -e all -T 10 trace.raw
```

-D 删掉之前的buffer, -e 是设置trace的事件类型:

```cpp
// xen/include/public/trace.h
/* Trace classes */
#define TRC_CLS_SHIFT 16
#define TRC_GEN      0x0001f000    /* General trace            */
#define TRC_SCHED    0x0002f000    /* Xen Scheduler trace      */
#define TRC_DOM0OP   0x0004f000    /* Xen DOM0 operation trace */
#define TRC_HVM      0x0008f000    /* Xen HVM trace            */
#define TRC_MEM      0x0010f000    /* Xen memory trace         */
#define TRC_PV       0x0020f000    /* Xen PV traces            */
#define TRC_SHADOW   0x0040f000    /* Xen shadow tracing       */
#define TRC_HW       0x0080f000    /* Xen hardware-related traces */
#define TRC_GUEST    0x0800f000    /* Guest-generated traces   */
```

-T 是设置trace的时间

生成的内容是二进制, 我们没有办法直接读取, 这时就要借助 xenalyze: `$XENDIR/tools/xentrace/xenalyze`

```
cat trace.raw | xenalyze ~/$XENDIR/tools/xentrace/formats > trace.txt
```

在xentrace/formats 可以看到所有的事件类型和对应的输出格式, 根据需要我们可以自行修改。

在Xen中, 如果我们想要自己记录一些信息, 除了在需要的地方加printk, 还可以借助trace:

```cpp
// xen/include/xen/trace.h
#define TRACE_0D(_e)                            \
    do {                                        \
        trace_var(_e, 1, 0, NULL);              \
    } while ( 0 )

#define TRACE_1D(_e,d1)                                         \
    do {                                                        \
        if ( unlikely(tb_init_done) )                           \
        {                                                       \
            u32 _d[1];                                          \
            _d[0] = d1;                                         \
            __trace_var(_e, 1, sizeof(_d), _d);                 \
        }                                                       \
    } while ( 0 )
```

文件中的0D-5D就是记录的数据的多少, 如果我们要记录3个数据, 就选用3D即可。

如果想要增加自定义的事件类型, 在 `xen/include/public/trace.h` 中添加自己的事件类型:

```cpp
// xen/include/public/trace.h
#define TRC_HVM_TRAP_DEBUG       (TRC_HVM_HANDLER + 0x24)
#define TRC_HVM_VLAPIC           (TRC_HVM_HANDLER + 0x25)
/* Add customized event */
#define TRC_HVM_ALICE           (TRC_HVM_HANDLER + 0x26)

/* Record our own event somewhere */
TRACE_0D(TRC_HVM_ALICE);
```

之后在trace.raw中就会出现我们自己定义的Trace.




# reference

https://silentming.net/blog/2016/09/21/xen-log-6-xentrace/
