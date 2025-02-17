
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 异步 IO](#1-异步-io)
- [2. libaio 中的结构体](#2-libaio-中的结构体)
- [3. libaio 提供的 API](#3-libaio-提供的-api)
  - [3.1. 建立 IO 任务](#31-建立-io-任务)
  - [3.2. 提交 IO 任务](#32-提交-io-任务)
  - [3.3. 获取完成的 IO](#33-获取完成的-io)
  - [3.4. 取消未完成的 IO](#34-取消未完成的-io)
  - [3.5. 销毁 IO 任务](#35-销毁-io-任务)
- [4. libaio 和 epoll 的结合](#4-libaio-和-epoll-的结合)
- [5. 完整实例](#5-完整实例)

<!-- /code_chunk_output -->

# 1. 异步 IO

在 Direct IO 模式下, 异步是非常有必要的(因为绕过了 pagecache, 直接和磁盘交互). linux Native AIO 正是基于这种场景设计的, 具体的介绍见: [KernelAsynchronousI/O (AIO)SupportforLinux](https://lse.sourceforge.net/io/aio.html).

下面我们就来分析一下 AIO 编程的相关知识.

阻塞模式下的 IO 过程如下:

```cpp
int fd = open(const char *pathname, int flags, mode_t mode);
ssize_t pread(int fd, void *buf, size_t count, off_t offset);
ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
int close(int fd);
```

因为整个过程会等待 read/write 的返回, 所以不需要任何额外的数据结构.

但异步 IO 的思想是: 应用程序不能阻塞在昂贵的系统调用上让 CPU 睡大觉, 而是将 IO 操作抽象成一个个的任务单元提交给内核, 内核完成 IO 任务后将结果放在应用程序可以取到的地方. 这样在底层做 I/O 的这段时间内, CPU 可以去干其他的计算任务. 但异步的 IO 任务批量的提交和完成, 必须有自身可描述的结构, 最重要的两个就是 iocb 和 `io_event`

# 2. libaio 中的结构体

```cpp
struct iocb {
    /* these are internal to the kernel/libc. */
    __u64   aio_data;       /* data to be returned in event's data */用来返回异步 IO 事件信息的空间, 类似于 epoll 中的 ptr.
    __u32   PADDED(aio_key, aio_reserved1); /* the kernel sets aio_key to the req # */
    /* common fields */
    __u16   aio_lio_opcode; /* see IOCB_CMD_ above */
    __s16   aio_reqprio;      // 请求的优先级
    __u32   aio_fildes;        //  文件描述符
    __u64   aio_buf;           // 用户态缓冲区
    __u64   aio_nbytes;      // 文件操作的字节数
    __s64   aio_offset;       // 文件操作的偏移量

    /* extra parameters */
    __u64   aio_reserved2;  /* TODO: use this for a (struct sigevent *) */
    __u64   aio_reserved3;
}; /* 64 bytes */


struct iocb {
    void     *data;  /* Return in the io completion event */
    unsigned key;   /*r use in identifying io requests */
    short           aio_lio_opcode;
    short           aio_reqprio;
    int             aio_fildes;
    union {
            struct io_iocb_common           c;
            struct io_iocb_vector           v;
            struct io_iocb_poll             poll;
            struct io_iocb_sockaddr saddr;
    } u;
};

struct io_iocb_common {
    void            *buf;
    unsigned long   nbytes;
    long long       offset;
    unsigned        flags;
    unsigned        resfd;
};
```

iocb 是提交 IO 任务时用到的, 可以完整地描述一个 IO 请求:

* data 是留给用来自定义的指针: 可以设置为 IO 完成后的 callback 函数;

* `aio_lio_opcode` 表示操作的类型: `IO_CMD_PWRITE | IO_CMD_PREAD`;

* `aio_fildes` 是要操作的文件: fd;

`io_iocb_common` 中的 buf, nbytes, offset 分别记录的 IO 请求的 mem buffer, 大小和偏移.

```cpp
struct io_event {
    __u64           data;          /* the data field from the iocb */ // 类似于 epoll_event 中的 ptr
    __u64           obj;            /* what iocb this event came from */ // 对应的用户态 iocb 结构体指针
    __s64           res;            /* result code for this event */ // 操作的结果, 类似于 read/write 的返回值
    __s64           res2;          /* secondary result */
};
```

io_event 是用来描述返回结果的:

obj 就是之前提交 IO 任务时的 iocb;

res 和 res2 来表示 IO 任务完成的状态.

# 3. libaio 提供的 API

## 3.1. 建立 IO 任务

```cpp
int io_setup(unsigned nr_events, aio_context_t *ctxp);
```

`io_setup` 初始化一个异步 IO 上下文. 参数 ctxp 用来描述异步 IO 请求上下文, 参数 nr_events 表示小可处理的异步 IO 事件的个数

注意: 传递给 `io_setup` 的 `aio_context` 参数必须初始化为 0, 在它的 man 手册里其实有说明, 但容易被忽视, man 说明如下:

> ctxp must not point to an  AIO context that already exists, and must be initialized to 0 prior to the call

## 3.2. 提交 IO 任务

```cpp
int io_submit(io_context_t ctx, long nr, struct iocb *iocbs[]);
```

`io_submit` 提交初始化好的异步 IO 事件. 其中 ctx 是上文的描述句柄, nr 表示提交的异步事件个数, iocb 是异步事件的结构体.

提交任务之前必须先填充 iocb 结构体, libaio 提供的包装函数说明了需要完成的工作:

```cpp
void io_prep_pread(struct iocb *iocb, int fd, void *buf, size_t count, long long offset)
{
    memset(iocb, 0, sizeof(*iocb));
    iocb->aio_fildes = fd;
    iocb->aio_lio_opcode = IO_CMD_PREAD;
    iocb->aio_reqprio = 0;
    iocb->u.c.buf = buf;
    iocb->u.c.nbytes = count;
    iocb->u.c.offset = offset;
}

void io_prep_pwrite(struct iocb *iocb, int fd, void *buf, size_t count, long long offset)
{
    memset(iocb, 0, sizeof(*iocb));
    iocb->aio_fildes = fd;
    iocb->aio_lio_opcode = IO_CMD_PWRITE;
    iocb->aio_reqprio = 0;
    iocb->u.c.buf = buf;
    iocb->u.c.nbytes = count;
    iocb->u.c.offset = offset;
}
```

这里注意读写的 buf 都必须是按扇区对齐的, 可以用 `posix_memalign` 来分配.

## 3.3. 获取完成的 IO

```cpp
int io_getevents(io_context_t ctx, long nr, struct io_event *events[], struct timespec *timeout);
```

`io_getevents` 获得已完成的异步 IO 事件. 其中参数 ctx 是上下文的句柄, nr 表示期望获得异步 IO 事件个数, events 用来存放已经完成的异步事件的数据, timeout 为超时事件.

这里最重要的就是提供一个 `io_event` 数组给内核来 copy 完成的 IO 请求到这里, 数组的大小是 `io_setup` 时指定的 `maxevents`.

timeout 是指等待 IO 完成的超时时间, 设置为 NULL 表示一直等待所有到 IO 的完成.

## 3.4. 取消未完成的 IO

```cpp
int io_cancel(aio_context_t ctx_id, struct iocb *iocb, struct io_event *result);
```

`io_cancel` 取消一个未完成的异步 IO 操作

## 3.5. 销毁 IO 任务

```cpp
int io_destroy(aio_context_t ctx);
```

`io_destroy` 用于销毁异步 IO 事件句柄.

# 4. libaio 和 epoll 的结合

在异步编程中, 任何一个环节的阻塞都会导致整个程序的阻塞, 所以一定要**避免**在 `io_getevents` 调用时**阻塞式的等待**.

还记得 `io_iocb_common` 中的 `flags` 和 `resfd` 吗? 看看 libaio 是如何提供 `io_getevents` 和事件循环的结合

```cpp
void io_set_eventfd(struct iocb *iocb, int eventfd)
{
    iocb->u.c.flags |= (1 << 0) /* IOCB_FLAG_RESFD */;
    iocb->u.c.resfd = eventfd;
}
```

这里的 resfd 是通过系统调用 eventfd 生成的.

```cpp
int eventfd(unsigned int initval, int flags);
```

eventfd 是 linux 2.6.22 内核之后加进来的 syscall, 作用是**内核**用来**通知应用程序**发生的事件的数量, 从而使应用程序不用频繁地去轮询内核是否有时间发生, 而是由**内核**将发生事件的**数量写入到该 fd**, 应用程序发现 fd 可读后, 从 fd 读取该数值, 并马上去内核读取.

有了 eventfd, 就可以很好地将 libaio 和 epoll 事件循环结合起来:

1. 创建一个 eventfd

```cpp
efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
```

2. 将 eventfd 设置到 iocb 中

```cpp
io_set_eventfd(iocb, efd);
```

3. 提交 AIO 请求

```cpp
io_submit(ctx, NUM_EVENTS, iocb);
```

4. 创建一个 epollfd, 并将 eventfd 加到 epoll 中

```cpp
epfd = epoll_create(1);
epoll_ctl(epfd, EPOLL_CTL_ADD, efd, &epevent);
epoll_wait(epfd, &epevent, 1, -1);
```

5. 当 eventfd 可读时, 从 eventfd 读出完成 IO 请求的数量, 并调用 `io_getevents` 获取这些 IO

```cpp
read(efd, &finished_aio, sizeof(finished_aio);
r = io_getevents(ctx, 1, NUM_EVENTS, events, &tms);
```

# 5. 完整实例

内核的异步 IO 通常和 epoll 等 IO 多路复用配合使用来完成一些异步事件, 那么就需要使用 epoll 来监听一个可以通知异步 IO 完成的描述符, 那么就需要使用 eventfd 函数来获得一个这样的描述符.

```cpp
#define TEST_FILE "aio_test_file"
#define TEST_FILE_SIZE (127 * 1024)
#define NUM_EVENTS 128
#define ALIGN_SIZE 512
#define RD_WR_SIZE 1024

struct custom_iocb
{
    struct iocb iocb;
    int nth_request;
};

//异步 IO 的回调函数
void aio_callback(io_context_t ctx, struct iocb *iocb, long res, long res2)
{
    struct custom_iocb *iocbp = (struct custom_iocb *)iocb;

    printf("nth_request: %d, request_type: %s, offset: %lld, length: %lu, res: %ld, res2: %ld\n", iocbp->nth_request, (iocb->aio_lio_opcode == IO_CMD_PREAD) ? "READ" : "WRITE",iocb->u.c.offset, iocb->u.c.nbytes, res, res2);
}

int main(int argc, char *argv[])
{
    int efd, fd, epfd;
    io_context_t ctx;
    struct timespec tms;
    struct io_event events[NUM_EVENTS];
    struct custom_iocb iocbs[NUM_EVENTS];
    struct iocb *iocbps[NUM_EVENTS];
    struct custom_iocb *iocbp;
    int i, j, r;
    void *buf;
    struct epoll_event epevent;

    //创建用于获取异步事件的通知描述符
    efd = eventfd(0, EFD_NONBLOCK | EFD_CLOEXEC);
    if (efd == -1) {
        perror("eventfd");
        return 2;
    }

    fd = open(TEST_FILE, O_RDWR | O_CREAT | O_DIRECT , 0644);
    if (fd == -1) {
        perror("open");
        return 3;
    }

    ftruncate(fd, TEST_FILE_SIZE);

    ctx = 0;
    //创建异步 IO 的句柄
    if (io_setup(8192, &ctx)) {
        perror("io_setup");
        return 4;
    }

    //申请空间
    if (posix_memalign(&buf, ALIGN_SIZE, RD_WR_SIZE)) {
        perror("posix_memalign");
        return 5;
    }

    printf("buf: %p\n", buf);
    for (i = 0, iocbp = iocbs; i < NUM_EVENTS; ++i, ++iocbp) {
        iocbps[i] = &iocbp->iocb;
        //设置异步 IO 读事件
        io_prep_pread(&iocbp->iocb, fd, buf, RD_WR_SIZE, i * RD_WR_SIZE);
        //关联通知描述符
        io_set_eventfd(&iocbp->iocb, efd);
        //设置回调函数
        io_set_callback(&iocbp->iocb, aio_callback);
        iocbp->nth_request = i + 1;
    }

    //提交异步 IO 事件
    if (io_submit(ctx, NUM_EVENTS, iocbps) != NUM_EVENTS) {
        perror("io_submit");
        return 6;
    }

    epfd = epoll_create(1);
    if (epfd == -1) {
        perror("epoll_create");
        return 7;
    }

    epevent.events = EPOLLIN | EPOLLET;
    epevent.data.ptr = NULL;

    if (epoll_ctl(epfd, EPOLL_CTL_ADD, efd, &epevent)) {
        perror("epoll_ctl");
        return 8;
    }

    i = 0;
    while (i < NUM_EVENTS) {
        uint64_t finished_aio;
        //监听通知描述符
        if (epoll_wait(epfd, &epevent, 1, -1) != 1) {
            perror("epoll_wait");
            return 9;
        }

        //读取完成的异步 IO 事件个数
        if (read(efd, &finished_aio, sizeof(finished_aio)) != sizeof(finished_aio)) {
            perror("read");
            return 10;
        }

        printf("finished io number: %"PRIu64"\n", finished_aio);

        while (finished_aio > 0) {
            tms.tv_sec = 0;
            tms.tv_nsec = 0;

            //获取完成的异步 IO 事件
            r = io_getevents(ctx, 1, NUM_EVENTS, events, &tms);
            if (r > 0) {
                for (j = 0; j < r; ++j) {
                    //调用回调函数
                    //events[j].data 的数据和设置的 iocb 结构体中的 data 数据是一致.
                    ((io_callback_t)(events[j].data))(ctx, events[j].obj, events[j].res, events[j].res2);
                }
                i += r;
                finished_aio -= r;
            }
        }
    }

    close(epfd);
    free(buf);
    io_destroy(ctx);
    close(fd);
    close(efd);
    remove(TEST_FILE);
    return 0;
}
```




完整示例如下:

```cpp
int main()
{
    io_context_t ctx;
    unsigned nr_events = 10;
    memset(&ctx, 0, sizeof(ctx));  // It's necessary, 这里一定要的
    int errcode = io_setup(nr_events, &ctx);
    if (errcode == 0)
            printf("io_setup successn");
    else
            printf("io_setup error: :%d:%sn", errcode, strerror(-errcode));

    // 如果不指定 O_DIRECT, 则 io_submit 操作和普通的 read/write 操作没有什么区别了, 将来的 LINUX 可能
    // 可以支持不指定 O_DIRECT 标志
    int fd = open("./direct.txt", O_CREAT|O_DIRECT|O_WRONLY, S_IRWXU|S_IRWXG|S_IROTH);
    printf("open: %sn", strerror(errno));

    char* buf;
    errcode = posix_memalign((void**)&buf, sysconf(_SC_PAGESIZE), sysconf(_SC_PAGESIZE));
    printf("posix_memalign: %sn", strerror(errcode));

    strcpy(buf, "hello xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");

    struct iocb *iocbpp = (struct iocb *)malloc(sizeof(struct iocb));
    memset(iocbpp, 0, sizeof(struct iocb));

    iocbpp[0].data           = buf;
    iocbpp[0].aio_lio_opcode = IO_CMD_PWRITE;
    iocbpp[0].aio_reqprio    = 0;
    iocbpp[0].aio_fildes     = fd;

    iocbpp[0].u.c.buf    = buf;
    iocbpp[0].u.c.nbytes = page_size;//strlen(buf); // 这个值必须按 512 字节对齐
    iocbpp[0].u.c.offset = 0; // 这个值必须按 512 字节对齐

    // 提交异步操作, 异步写磁盘
    int n = io_submit(ctx, 1, &iocbpp);
    printf("==io_submit==: %d:%sn", n, strerror(-n));

    struct io_event events[10];
    struct timespec timeout = {1, 100};
    // 检查写磁盘情况, 类似于 epoll_wait 或 select
    n = io_getevents(ctx, 1, 10, events, &timeout);
    printf("io_getevents: %d:%sn", n, strerror(-n));

    close(fd);
    io_destroy(ctx);
    return 0;
}
```
