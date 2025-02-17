# Linux 中的 awk 命令

>
作者: 李天炜
原文链接: http://tianweili.github.io/blog/2015/02/24/linux-awk/

本文主要介绍了 Linux 中的 awk 命令的一些知识以及如何使用 awk 编程. 不同于 grep 的查找、sed 的编辑等命令, awk 命令在文本处理和生成报告等地方是经常用到的一个强大命令.

简介
--
awk 命令主要用于文本分析. 它的处理方式是读入文本, 将每行记录以一定的分隔符(默认为空格)分割成不同的域, 然后对不同的域进行各种处理与输出.

命令格式
--
awk 命令的一个基本格式如下:

> awk '{pattern + action}' {filenames}

无论 awk 命令简单还是复杂, 基本的格式如上所示. 其中引号为必须, 引号内代表一个 awk 程序. 大括号非必须, 括起来用于根据特定的模式对一系列指令进行分组. pattern 是在数据中查找内容, 支持正则匹配. action 对查找出来的记录执行相应的处理, 比如打印和输出等.

awk 三种调用方式
--

**命令行方式**

> awk [-F 'field-separator'] 'commands' input-file(s)

其中的-F 指令是可选的, 后面跟着指定的域分隔符, 比如 tab 键等(默认是空格). 后面的 commands 是真正的 awk 命令. input-file(s)代表输入的一个或多个文件.

命令行调用方式是最经常使用的一种方式, 也是本文所讲的重点.

**shell 脚本方式**
把平时所写的 shell 脚本的首行#!/bin/sh 换成#!/bin/awk. 把所有的 awk 命令插入脚本中, 通过调用脚本来执行 awk 命令.

**插入文件调用**
把所有的 awk 命令插入单独的文件中, 然后通过以下命令调用 awk:

> awk -f awk-script-file input-file(s)

其中-f 指定了要调用的包含 awk 命令的文件.


----------


awk 应用示例
--

**打印指定字段**

打印当前目录下所有的文件名和文件大小列表, 以 tab 键分割:

> ls -lh | awk '{print $5"\t"$9}'

$0 变量是指当前一行记录, $1 是指第一个域数据, $2 指第二个域数据......以此类推.

**print 与 printf**

awk 提供了 print 与 printf 两种打印输出的函数.

print 的参数可以是变量、数值和字符串. 参数用逗号分割, 字符串必须用双引号引用.

printf 与 C 语言中的 printf 函数类似, 可以用来格式化字符串.

> awk -F ':' '{printf("filename:%10s,linenumber:%s,columns:%s,linecontent:%s\n",FILENAME,NR,NF,$0)}

**根据指定分隔符切割域**

> ll | awk -F '\t' 'print $9'

**BEGIN...END**

> ls -lh | awk 'BEGIN {print "size\tfilename"}  {print $5"\t"$9} END {print "---end---"}'

BEGIN...END 语句的执行流程是, awk 命令读入数据, 然后从 BEGIN 语句开始, 依次读取每一行记录, 并打印相应的域, 当所有记录都处理后再执行 END 语句后的程序. 也就是说 BEGIN...END 语句块中的内容在读取数据过程中会反复执行, 直到数据读取完成.

**pattern 正则匹配**

下面的例子表示打印当前目录下, 所有以.bat 后缀结尾的文件名列表:

> ls -l | awk -F: '/\.dat$/{print $9}'


----------
awk 内置变量
--
awk 有许多内置变量用来设置环境变量信息, 这些变量都可以被改变. 常用的内置变量和作用如下所示:

>
ARGC               命令行参数个数
ARGV               命令行参数排列
ENVIRON            支持队列中系统环境变量的使用
FILENAME           awk 浏览的文件名
FNR                浏览文件的记录数
FS                 设置输入域分隔符, 等价于命令行-F 选项
NF                 浏览记录的域的个数
NR                 已读的记录数
OFS                输出域分隔符
ORS                输出记录分隔符
RS                 指定用来切片的分隔符

awk 中的内置变量都是很有用处的, 可以直接使用. 比如上面讲过的指定分隔符操作就可以用 FS 变量来代替:

> ll | awk '{FS="\t";} {print $9}'

下面会有很多实用 awk 内置变量的例子.

----------
awk 编程
--
**定义变量和运算**
awk 可以自定义变量, 并参与运算.

比如统计当前目录下列出的文件总大小, 以 M 为单位显示出来:

> ls -l | awk 'BEGIN {size=0;} {size+=$5;} END {print "size is ", size}'

注意此统计没有把文件夹下的所有文件算在内.

自定义的变量有时候可以不用作初始化操作, 不过正规起见, 还是建议作初始化操作为好.

**条件语句**

awk 中的条件语句跟 C 语言类似, 声明方式如下:

>
if(expression){
　　statement1;
　　statement2;
}
>
if(expression){
　　statement1;
} else {
　　statement2;
}
>
if(expression1){
　　statement1;
} else if (expression2) {
　　statement2;
} else {
　　statement3;
}

看下面例子, 将第三列为 12, 第六列为 0 的行打印输出:

> awk 'BEGIN {FS="\t"}{if($3==12 && $6==0) print $0} END' incoming_daily_20150223.dat

**循环语句**

awk 中的循环语句同样与 C 语言中的类似, 支持 while、do/while、for、break、continue 关键字.

看下面的例子, 输出每行的行号和第一列的数据:

>
awk 'BEGIN {FS="\t";} {data[NR] = $1} END {for(i=1; i<=NR; i++) print i"\t"data[i]}' incoming_daily_20150223.dat

**数组**

看下面例子, 统计第六列每一个值出现的次数:

> awk 'BEGIN {FS="\t"}{count[$6]++} END {for(x in count) print x,count[x]}' incoming_daily_20150223.