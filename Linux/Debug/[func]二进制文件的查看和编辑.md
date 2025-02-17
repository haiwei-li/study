
# Linux 下查看二进制文件

xxd

od

hexdump

以十六进制格式输出:

```
od [选项] 文件
od -d 文件  十进制输出
   -o 文件  八进制输出
   -x 文件  十六进制输出
xxd 文件    输出十六进制
```

在 vi 命令状态下:

```
:%!xxd :%!od 将当前文本转化为 16 进制格式
:%!xxd -c 12 每行显示 12 个字节
:%!xxd -r    将当前文本转化回文本格式
```

## xxd


## hexdump

### 介绍

hexdump 命令一般用来查看"**二进制**"文件的**十六进制编码**, 但实际上它能查看任何文件, 而不只限于二进制文件.

### 用法

```
hexdump [选项] [文件]
```

### 选项

```
-n length 只格式化输入文件的前 length 个字节.
-C 单字节输出规范的十六进制和 ASCII 码.
-b 单字节八进制显示.
-c 单字节字符显示.
-d 双字节十进制显示.
-o 双字节八进制显示.
-x 双字节十六进制显示.
-s 从偏移量开始输出.
-e 指定格式字符串, 格式字符串包含在一对单引号中, 格式字符串形如: 'a/b "format1" "format2"'.
```

每个格式字符串由三部分组成, 每个由空格分隔, 第一个形如 a/b, b 表示对每 b 个输入字节应用 format1 格式, a 表示对每 a 个输入字节应用 format2 格式, 一般 a>b, 且 b 只能为 1, 2, 4, 另外 a 可以省略, 省略则 a=1. format1 和 format2 中可以使用类似 printf 的格式字符串, 如:

```
%02d: 两位十进制
%03x: 三位十六进制
%02o: 两位八进制
%c: 单个字符等
```

还有一些特殊的用法:

```
%_ad: 标记下一个输出字节的序号, 用十进制表示.
%_ax: 标记下一个输出字节的序号, 用十六进制表示.
%_ao: 标记下一个输出字节的序号, 用八进制表示.
%_p: 对不能以常规字符显示的用 . 代替.
```

同一行如果要显示多个格式字符串, 则可以跟多个-e 选项.

```
root@Gerry:hexdump -e '16/1 "%02X " "  |  "' -e '16/1 "%_p" "\n"' test
00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F  |  ................
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F  |  ................
20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F  |   !"#$%&'()*+,-./
```

### 示例

以文本文件 t1 为例:

```
Happy New Year!
Happy New Year!
Happy New Year!
```

1. 最简单的方式

hexdump t1, 等价于 hexdump -x t1

```
root@Gerry:/home/project/commands/hexdump# hexdump t1
0000000 6148 7070 2079 654e 2077 6559 7261 0a21
*
0000030
```

这种方式是**以两个字节**为一组, 其顺序取决于**本机字节序**. 比如在 x86 架构上就是以 blittle-endian 方式显示, 看起来会很费劲.

如第一行翻译成相应的 ascii 码:

```
6148   aH
7070   pp
2079   [空格]y
654e   eN
2077   [空格]w
6559   eY
7261   ra
0a21   [换行]!
```

为了避免这种情况, 就要用到下面的"以字节方式查看"

2. 以字节方式查看

hexdump -C t1 -s skip -n number

```
root@Gerry:/home/project/commands/hexdump# hexdump -C t1
00000000  48 61 70 70 79 20 4e 65  77 20 59 65 61 72 21 0a  |Happy New Year!.|
*
00000030
```

这种方式就不会有字节序问题了, 而且还能同时显示 16 进制与 ascii 码, 但是, 如果某几行的内容相同, 会省略掉后几行. 如何避免省略呢?

3. 不要省略

hexdump -v t1

字节方式显示且不要省略: hexdump -Cv t1

```
root@Gerry:/home/project/commands/hexdump# hexdump -Cv t1
00000000  48 61 70 70 79 20 4e 65  77 20 59 65 61 72 21 0a  |Happy New Year!.|
00000010  48 61 70 70 79 20 4e 65  77 20 59 65 61 72 21 0a  |Happy New Year!.|
00000020  48 61 70 70 79 20 4e 65  77 20 59 65 61 72 21 0a  |Happy New Year!.|
00000030
```

4. 显示某一段

hexdump -Cv t1 -s skip -n number

```
root@Gerry:/home/project/commands/hexdump# hexdump -Cv -n 2 t1
00000000  48 61                                             |Ha|
00000002
```

```
root@Gerry:/home/project/commands/hexdump# hexdump -Cv -s 2 -n 2 t1
00000002  70 70                                             |pp|
00000004
```

5. 以 ASCII 字符显示

hexdump 以 ASCII 字符显示时, 可以输出换行符, 这个功能可以用来检查文件是 Linux 的换行符格式还是 Widows 格式换行符. 如下所示

```
root@Gerry:/home/project/commands/hexdump# cat t1
Happy New Year!
Happy New Year!
Happy New Year!

root@Gerry:/home/project/commands/hexdump# unix2dos t1
unix2dos: converting file t1 to DOS format ...

root@Gerry:/home/project/commands/hexdump# file t1
t1: ASCII text, with CRLF line terminators

root@Gerry:/home/project/commands/hexdump# hexdump -cv t1
0000000   H   a   p   p   y       N   e   w       Y   e   a   r   !  \r
0000010  \n   H   a   p   p   y       N   e   w       Y   e   a   r   !
0000020  \r  \n   H   a   p   p   y       N   e   w       Y   e   a   r
0000030   !  \r  \n
0000033

root@Gerry:/home/project/commands/hexdump# dos2unix t1
dos2unix: converting file t1 to Unix format ...

root@Gerry:/home/project/commands/hexdump# file t1
t1: ASCII text

root@Gerry:/home/project/commands/hexdump# hexdump -cv t1
0000000   H   a   p   p   y       N   e   w       Y   e   a   r   !  \n
0000010   H   a   p   p   y       N   e   w       Y   e   a   r   !  \n
0000020   H   a   p   p   y       N   e   w       Y   e   a   r   !  \n
0000030
```

6.


# 参考

http://man.linuxde.net/hexdump

http://blog.csdn.net/zybasjj/article/details/7874720

http://blog.chinaunix.net/uid-20528014-id-4087756.html

https://blog.csdn.net/hansel/article/details/5097262