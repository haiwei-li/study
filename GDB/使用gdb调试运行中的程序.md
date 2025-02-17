
下面介绍我调试时经常遇到的三种问题, 如果大家也有类似的问题交流一下解决方法:

情景 1: 在不中止程序服务的情况下, 怎么调试正在运行时的程序

情景 2: 需要同时看几个变量的值或者批量查看多个 core 文件的堆栈信息怎么办

情景 3: 遇到需要查看, 队列, 链表, 树, 堆等数据结构里的变量怎么办

1. 情景 1: 在不中止程序服务的情况下, 怎么调试正在运行时的程序

我们在生产环境或者测试环境, 会遇到一些异常, 我们需要知道程序中的变量或者内存的值来确定程序运行状态

之前听过@淘宝褚霸讲过用 systemstap 可以实现这种功能, 但 systamstap 写起来复杂一些, 还有时候在低内核版本的操作系统上用 stap 之后, 程序或者操作系统都有可能死掉.

看过多隆调试程序时用 pstack(修改了 pstack 代码, 用 gdb 实现的, 详见 http://blog.yufeng.info/archives/873)查看和修改一个正在执行程序的全局变量, 感觉很神奇, 尝试用 gdb 实现这种功能:

保存下面代码到文件 runstack.sh

```bash
#!/bin/sh
if test $# -ne 2; then
    echo "Usage: `basename $0 .sh` <process-id> cmd" 1>&2
    echo "For exampl: `basename $0 .sh` 1000 bt" 1>&2
    exit 1
fi
if test ! -r /proc/$1; then
    echo "Process $1 not found." 1>&2
    exit 1
fi
result=""
GDB=${GDB: -/usr/bin/gdb}
# Run GDB, strip out unwanted noise.
result=`$GDB --quiet -nx /proc/$1/exe $1 <<EOF 2>&1
$2
EOF`
echo "$result" | egrep -A 1000 -e "^\(gdb\)" | egrep -B 1000 -e "^\(gdb\)"
```

用于测试 runstack.sh 调试的 c 代码

```cpp
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct slist {
    struct slist *next;
    char         data[4096];
} slist;

slist input_list = {NULL, {'\0'}};
int count = 0;

static void stdin_read (int fd)
{
    char buf[4096];
    int ret;

    memset(buf, 0, 4096);

    fprintf(stderr, "please input string: ");

    while (ret = read(fd, buf, 4096)) {

        slist *node = calloc(1, sizeof(slist));
        memcpy(node->data, buf, ret);
        node->next = input_list.next;
        input_list.next = node;
        count ++;

        if (memcmp(buf, "quit", 4) == 0) {
            fprintf(stdout, "input quit: \n");
            return;
        }
        fprintf(stderr, "ret: %d, there is %d strings, current is %s\nplease input string: ", ret, count, buf);
    }
}

int main()
{
    fprintf(stderr, "main run! \n");

    stdin_read(STDIN_FILENO);

    slist *nlist;
    slist *list = input_list.next;
    while (list) {
        fprintf(stderr, "%s\n", list->data);
        nlist = list->next;
        free(list);
        list = nlist;
    }

    return 0;
}
```

编译 c 代码: `gcc -g -o read_input read_input.c`

执行 `. /read_input` 我们开始使用`runstack.sh`来调试

使用方法: `sh ./runstack.sh pid "command"`

来试验一下:

```
[shihao@xxx]$ ps aux |grep read_input|grep -v grep
shihao 10933 0.0 0.0 3668 332 pts/4 S+ 09: 41 0: 00 ./read_input
```

10933 是一个 read_input 程序的进程号

1)打印代码

`sudo sh ./runstack.sh 10933 "list main"`

结果

```
(gdb) 35 fprintf(stderr, "ret: %d, there is %d strings, current is %s\nplease input string: ", ret, count, buf);
36 }
37 }
38
39 int main()
40 {
41 fprintf(stderr, "main run! \n");
42
43 stdin_read(STDIN_FILENO);
44
(gdb) quit
```

2)显示程序全局变量值

```
./runstack.sh 10933 "p count"
(gdb) $1 = 1
(gdb) quit
```

3)修改变量值

执行下面命令

```
[shihao@tfs036097 gdb]$ runstack.sh 11190 "set count=100″
(gdb) (gdb) quit
```

我们可以用上面命令看我们修改成功没有

```
[shihao@tfs036097 gdb]$ runstack.sh 11190 "p count"
(gdb) $1 = 100
(gdb) quit
```

全局变量 count 变成 100 了.

注: 1)有一些程序经过操作系统优化过, 直接用上面的方法可能有找不到符号表的情况

```
result=`$GDB --quiet -nx /proc/$1/exe $1 <<EOF 2>&1
$2
EOF`
```

可以把上面的代码改成下面的试试, 如果不行可能是其他原因

```
BIN=`readlink -f /proc/$1/exe`
result=`$GDB --quiet -nx $BIN $1 <<EOF 2>&1
$2
EOF`
```

2)需要有查看和修改运行的进程的权限

2. 情景 2: 需要同时看几个变量的值或者批量查看多个 core 文件的信息怎么办

1)多个变量的情景

我们同时看一下 count 和 input_list 里面的值和堆栈信息, 我们可以写一个 script.gdb

```
$ cat script.gdb
p input_list
p count
bt
f 1
p buf
```

执行

```
runstack.sh 10933 "source script.gdb"
(gdb) $1 = {next = 0x597c020, data = " }
$2 = 2
#0 0x0000003fa4ec5f00 in __read_nocancel () from /lib64/libc.so.6
#1 0x00000000004007c7 in stdin_read (fd=0) at read_input.c: 23
#2 0×0000000000400803 in main () at read_input.c: 43
#1 0x00000000004007c7 in stdin_read (fd=0) at read_input.c: 23
23 while (ret = read(fd, buf, 4096)) {
$3 = "12345\n", "
(gdb) quit
```

这样就可以同时做多个操作

2)批处理查看 core 的情况

有的时候会出现很多 core 文件, 我们想知道哪些 core 文件是因为相同的原因, 哪些是不相同的, 看一个两个的时候还比较轻松

```
$ ls core.*
core.12281 core.12282 core.12283 core.12284 core.12286 core.12287 core.12288 core.12311 core.12313 core.12314
```

像上面有很多 core 文件, 一个一个用 gdb 去执行 bt 去看 core 在哪里有点麻烦, 我们想有把所有的 core 文件的堆栈和变量信息打印出来
我对 runstack 稍作修改就可以实现我们的需求, 我们起名叫 corestack.sh

```bash
#!/bin/sh

if test $# -ne 3; then
    echo "Usage: `basename $0 .sh` program core cmd" 1>&2
    echo "For example: `basename $0 .sh` ./main core.1111 bt" 1>&2
    exit 1
fi

if test ! -r $1; then
    echo "Process $1 not found." 1>&2
    exit 1
fi

result=""
GDB=${GDB: -/usr/bin/gdb}
# Run GDB, strip out unwanted noise.
result=`$GDB --quiet -nx $1 $2 <<EOF 2>&1
$3
EOF`
echo "$result" | egrep -A 1000 -e "^\(gdb\)" | egrep -B 1000 -e "^\(gdb\)"
```

我们可以这样执行:

```
./corestack.sh ./read_input core.12281 "bt"
```

执行结果:

```
(gdb) #0 0x0000003fa4e30265 in raise (sig=)
at ../nptl/sysdeps/unix/sysv/linux/raise.c: 64
#1 0x0000003fa4e31d10 in abort () at abort.c: 88
#2 0x0000003fa4e296e6 in __assert_fail (assertion=,
file=, line=,
function=) at assert.c: 78
#3 0x00000000004008ba in main () at read_input.c: 55
(gdb) quit
```

查看多个 core 文件堆栈信息的准备工作差不多了, 我们写个脚本就可以把所有的 core 文件堆栈打印出来了

执行以下:

```
for i in `ls core.*`; do ./corestack.sh ./read_input $i "bt"; done
(gdb) #0 0x0000003fa4e30265 in raise (sig=)
at ../nptl/sysdeps/unix/sysv/linux/raise.c: 64
#1 0x0000003fa4e31d10 in abort () at abort.c: 88
#2 0x0000003fa4e296e6 in __assert_fail (assertion=,
file=, line=,
function=) at assert.c: 78
#3 0x00000000004008ba in main () at read_input.c: 55
(gdb) quit
......
(gdb) #0 0x0000003fa4e30265 in raise (sig=)
at ../nptl/sysdeps/unix/sysv/linux/raise.c: 64
#1 0x0000003fa4e31d10 in abort () at abort.c: 88
#2 0x0000003fa4e296e6 in __assert_fail (assertion=,
file=, line=,
function=) at assert.c: 78
#3 0x00000000004008ba in main () at read_input.c: 55
(gdb) quit
```

ok, 我们看到了所有 core 文件的堆栈.

3. 情景 3: 遇到需要查看, 队列, 链表, 树, 堆等数据结构里的变量怎么办?

下面介绍链表怎么处理, 对其他数据结构感兴趣的同学可以自己尝试编写一些 gdb 脚本(麻烦@周哲士豪一下我, 我也学习学习),

希望我们可以实现一个 gdb 调试工具箱

gdb 是支持编写的脚本的 http://sourceware.org/gdb/onlinedocs/gdb/Command-Files.html

我们写个 plist.gdb, 用 while 循环来遍历链表

```
$ cat plist.gdb

set $list=&input_list

while($list)
    p *$list
    set $list=$list->next
end
```

我们执行一下:

```
runstack.sh 13434 "source plist.gdb"
(gdb) $1 = {next = 0x3d61040, data = " }
$2 = {next = 0x3d60030, data = "123456\n", " }
$3 = {next = 0x3d5f020, data = "12345\n", " }
$4 = {next = 0x3d5e010, data = "1234\n", " }
$5 = {next = 0×0, data = "123\n", " }
(gdb) quit
```

实际上我们可以把 plist 写成自定义函数, 执行 gdb 的时候会在当前目下查找. gdbinit 文件加载到 gdb:

```
$ cat .gdbinit

define plist

    set $list=$arg0

    while($list)
        p *$list
        set $list=$list->next
    end
end
```

这样就可以用 plist 命令遍历 list 的值

```
$ runstack.sh 13434 "plist &input_list"
(gdb) $1 = {next = 0x3d61040, data = " }
$2 = {next = 0x3d60030, data = "123456\n", " }
$3 = {next = 0x3d5f020, data = "12345\n", " }
$4 = {next = 0x3d5e010, data = "1234\n", " }
$5 = {next = 0×0, data = "123\n", " }
(gdb) quit
```

# 参考资料

http://csrd.ruoguschool.com/p=1663/

霸爷的博客: http://blog.yufeng.info/archives/873

gdb 从脚本加载命令: http://blog.lifeibo.com/p=380

gdb 官方文档: http://sourceware.org/gdb/onlinedocs/gdb/Command-Files.html

gdb 回退: http://sourceware.org/gdb/news/reversible.html

gdb stl 调试脚本: http://www.yolinux.com/TUTORIALS/src/dbinit_stl_views-1.03.txt

gdb 高级调试方法: http://blog.csdn.net/wwwsq/article/details/7086151

