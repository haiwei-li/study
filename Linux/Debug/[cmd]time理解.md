
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->



<!-- /code_chunk_output -->

Linux 中 time 命令, 我们经常用来计算某个程序的运行耗时, 用户态 cpu 耗时, 系统态 cpu 耗时.

例如:

```
$ time foo
real        0m0.003s
user        0m0.000s
sys         0m0.004s$
```

那么这三个时间都具体代表什么意思呢?

\[1] real : 表示 foo 程序**整个的运行耗时**, 可以理解为 foo 运行开始时刻你看了一下手表, foo 运行结束时, 你又看了一下手表, 两次时间的差值就是本次 real 代表的值

举个极端的例子如下: 可以看到 real time 恰好为 2 秒.

```
# time sleep 2

real    0m2.003s
user    0m0.000s
sys     0m0.000s
```

\[2] user   0m0.000s: 这个时间代表的是 foo 运行在用户态的 cpu 时间, 什么意思?

这个指的是程序 foo 运行在用户态的 cpu 时间, cpu 时间不是墙上的钟走过的时间, 而是指**CPU 工作时间**.

\[3] sys   0m0.004s : 这个时间代表的是 foo 运行在核心态的 cpu 时间.

这三者之间没有严格的关系, 常见的误区有:

误区一:  real\_time = user\_time \+ sys\_time

我们错误的理解为, real time 就等于 user time \+ sys time, 这是不对的, real time 是时钟走过的时间, user time 是程序在用户态的 cpu 时间, sys time 为程序在核心态的 cpu 时间.

利用这三者, 我们可以计算程序运行期间的 cpu 利用率如下:

```
%cpu_usage = (user_time + sys_time)/real_time * 100%
```

如:

```
# time sleep 2

real     0m2.003s
user    0m0.000s
sys     0m0.000s
```

cpu 利用率为 0, 因为本身就是这样的, sleep 了 2 秒, **时钟走过了 2 秒**, 但是**cpu 时间都为 0**, 所以利用率为 0

误区二: real\_time \> user\_time \+ sys\_time

一般来说, 上面是成立的, 上面的情况在单 cpu 的情况下, 往往都是对的.

但是在多核 cpu 情况下, 而且代码写的确实很漂亮, 能把多核 cpu 都利用起来, 那么这时候上面的关系就不成立了, 例如可能出现下面的情况, 请不要惊奇.

```
real 1m47.363s

user 2m41.318s

sys 0m4.013s
```

误区三: real\_time \< user\_time \+ sys\_time

多 CPU 情况下, 比如

```
# time make -j8
...
real	27m10.153s
user	87m9.447s
sys	16m19.984s
```