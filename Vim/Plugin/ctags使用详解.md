
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

  - [1. ctags 可以识别哪些语言, 是如何识别的](#1-ctags-可以识别哪些语言-是如何识别的)
  - [2. ctags 可以识别和记录哪些语法元素](#2-ctags-可以识别和记录哪些语法元素)
  - [3. ctags 是怎么记录的](#3-ctags-是怎么记录的)
  - [4. vi 大概是怎样使用 ctags 生成的 tags 文件的](#4-vi-大概是怎样使用-ctags-生成的-tags-文件的)
  - [5. 我的一条 ctags 命令](#5-我的一条-ctags-命令)
  - [6. 本文内容来源](#6-本文内容来源)
  - [7. 使用 tags](#7-使用-tags)
  - [8. 分隔窗口](#8-分隔窗口)
  - [9. 多个 tags 文件](#9-多个-tags-文件)
  - [10. 单个 tags 文件](#10-单个-tags-文件)
  - [11. 同名 tag](#11-同名-tag)
  - [12. tag 的名字](#12-tag-的名字)
  - [13. tags 的浏览器](#13-tags-的浏览器)
  - [14. 其它相关主题](#14-其它相关主题)
- [参考](#参考)

<!-- /code_chunk_output -->

我用的是 Exuberant Ctags

## 1. ctags 可以识别哪些语言, 是如何识别的

ctags 识别很多语言, 可以用如下命令来查看:

```
ctags --list-languages
```

还可以识别自定义语言.

ctags 是可以根据文件的扩展名以及文件名的形式来确定该文件中是何种语言, 从而使用正确的分析器. 可以使用如下命令来查看默认哪些扩展名对应哪些语言:

```
ctags --list-maps
```

还可以指定 ctags 用特定语言的分析器来分析某种扩展名的文件或者名字符合特定模式的文件. 例如如下命令告知 ctags, 以 inl 为扩展名的文件是 c++文件.

```
ctags --langmap=c++:+.inl –R
```

并不十分清楚 ctags 使用何种技术来解析内容, 估计包括正则表达式、词法分析、语法分析等等. 但 ctags 不是编译器也不是预处理器, 它的解析能力是有限的. 例如它虽然可以识别宏定义, 但对于使用了宏的语句的识别还是有缺陷的, 在一些稍微正规点的代码(例如 ACE 的库或 VC 的头文件等)中的某些常规的宏使用方式会导致 ctags 无法识别, 或者识别错误, 从而使得 ctags 没有记录 user 想记录的内容, 或者记录下的信息不准确. 另一方面 ctags 也有聪明的一面, 例如在 cpp 文件中扫描到 static 的全局变量时, ctags 会记录这个变量, 而且还会标明说这个变量是局限于本文件的, 同样的定义, 如果放在 h 文件中, ctags 则不会标明说这个变量是局限于本文件的, 因为 ctags 认为 h 文件是头文件的一种, 会被其他文件 include, 所以在其他文件中可能会用到该 h 文件里定义的这个全局变量.

## 2. ctags 可以识别和记录哪些语法元素

可以用如下命令查看 ctags 可以识别的语法元素:

```
ctags --list-kinds
```

或者单独查看可以识别的 c++的语法元素

```
ctags --list-kinds=c++
```
ctags 识别很多元素, 但未必全都记录, 例如"函数声明"这一语法元素默认是不记录的, 可以控制 ctags 记录的语法元素的种类. 如下命令要求 ctags 记录 c++文件中的函数声明和各种外部和前向声明:

```
ctags -R --c++-kinds=+px
```

## 3. ctags 是怎么记录的

不管一次扫描多少文件, 一条 ctags 命令把记录的内容都记到一个文件里去, 默认是当前目录的 tags 文件, 当然这是可以更改的.

每个语法元素对应文件里的一行, 学名叫 tag entry.

1) 开头是 tag 的名字, 其实也就是语法元素的名字, 例如记录的是函数的话则 tag 名就是函数名, 记录的是类的话, tag 名就是类名.

2) 接下来是一个 tab.

3) 接下来是语法元素所在的文件名.

4) 又是一个 tab.

5) 一条"命令". 这个要解释一下意义: ctags 所记录的内容的一个功能就是要帮助像 vi 这样的编辑器快速定位到语法元素所在的文件中去. 前面已经记录了语法元素所在的文件, 这条命令的功能就是一旦在 vi 中打开语法元素所在的文件, 并且执行了该"命令"后, vi 的光标就能定位到语法元素在文件中的具体位置. 所以该"命令"的内容一般分两种, 一种是一个正则表达式的搜索命令, 一种是第几行的指向命令. 默认让 ctags 在记录时自行选择命令的种类, 选择的依据不详, 可以通过命令行参数来强制 ctags 使用某种命令, 这里就不多谈了.

6) 对于本 tag entry(简称 tag)所对应的语法元素的描述, 例如语法元素的类型等. 具体内容和语法元素的种类密切相关. 显示哪些描述, 显示的格式等都是可以在命令行指定的. 例如如下命令要求描述信息中要包含: a 表示如果语法元素的类的成员的话, 要标明其 access(即是 public 的还是 private 的); i 表示如果有继承, 标明父类; K 表示显示语法元素的类型的全称; S 表示如果是函数, 标明函数的 signature; z 表示在显示语法元素的类型是使用 kind:type 的格式.

```
ctags -R --fields=+aiKSz
```

ctags 除了记录上述的各种内容之外, 还可以在 tags 文件中记录本次扫描的各个文件, 一个文件名对应一个 tag entry. 默认是不记录的, 要强制记录要是使用如下命令:

```
ctags –R --extra=+f
```

还可以强制要求 ctags 做这样一件事情——如果某个语法元素是类的一个成员, 当然 ctags 默认会给其记录一个 tag entry(说白了就是在 tags 文件里写一行), 可以要求 ctags 对同一个语法元素再记一行. 举一个例子来说明: 假设语法元素是一个成员函数, ctags 默认记录的 tag entry 中的 tag 的名字就是该函数的名字(不包括类名作为前缀), 而我们强制要求 ctags 多记的那个 tag entry 的 tag 的名字是包含了类明作为前缀的函数的全路径名. 这样做有什么好处见下文分析. 强制 ctags 给类的成员函数多记一行的命令为:

```
ctags -R --extra=+q
```

## 4. vi 大概是怎样使用 ctags 生成的 tags 文件的

估计 vi 是这样使用 tags 文件的: 我们使用 vi 来定位某个 tag 时, vi 根据我们输入的 tag 的名字在 tags 文件中一行行查找, 判断每一行 tag entry 的 tag 名字(即每行的开头)是否和用户给出的相同, 如果相同就认为找到一条记录, 最后 vi 显示所有找到的记录, 或者根据这些记录直接跳转到对应文件的特定位置.

考虑到 ctags 记录的内容和方式, 出现同名的 tag entry 是很常见的现象, 例如函数声明和函数定义的 tag 名字是一样的, 重载函数的 tag 名字是一样的等等. vi 只是使用 tag 名字来搜索, 还没智能到可以根据函数的 signature 来选择相应的 tag entry. vi 只能简单的显示 tag entry 的内容给 user, 让 user 自行选择.

ctags 在记录成员函数时默认是把函数的名字(仅仅是函数的名字, 不带任何类名和 namespace 作为前缀)作为 tag 的名字的, 这样就导致很多不同类但同名的函数所对应的 tag entry 的名字都是一样的, 这样 user 在 vi 中使用函数名来定位时就会出现暴多选择, 挑选起来十分麻烦. user 可能会想在 vi 中用函数的全路径名来进行定位, 但这样做会失败, 因为 tags 文件中没有对应名字的 tag entry. 要满足用户的这种心思, 就要求 ctags 在记录时针对类的成员多记录一条 tag entry, 该 tag entry 和已有的 tag entry 的内容都相同, 除了 tag 的名字不同, 该 tag entry 的名字是类的成员的全路径名(包括了命名空间和类名). 这就解释了 ctags 的--extra=+q 这样一条命令行选项(见四).

## 5. 我的一条 ctags 命令

```
ctags-R --languages=c++ --langmap=c++:+.inl -h +.inl --c++-kinds=+px--fields=+aiKSz --extra=+q --exclude=lex.yy.cc --exclude=copy_lex.yy.cc
```

命令太长, 可以考虑把命令的各个参数写到文件里去了(具体做法就不谈了).

1.

```
-R
```

表示扫描当前目录及所有子目录(递归向下)中的源文件. 并不是所有文件 ctags 都会扫描, 如果用户没有特别指明, 则 ctags 根据文件的扩展名来决定是否要扫描该文件——如果 ctags 可以根据文件的扩展名可以判断出该文件所使用的语言, 则 ctags 会扫描该文件.

2.

```
--languages=c++
```

只扫描文件内容判定为 c\+\+的文件——即 ctags 观察文件扩展名, 如果扩展名对应 c++, 则扫描该文件. 反之如果某个文件叫 aaa.py(Python 文件), 则该文件不会被扫描.

3.

```
--langmap=c++:+.inl
```

告知 ctags, 以 inl 为扩展名的文件是 c\+\+语言写的, 在加之上述 2 中的选项, 即要求 ctags 以 c\+\+语法扫描以 inl 为扩展名的文件.

4.

```
-h +.inl
```

告知 ctags, 把以 inl 为扩展名的文件看作是头文件的一种(inl 文件中放的是 inline 函数的定义, 本来就是为了被 include 的). 这样 ctags 在扫描 inl 文件时, 就算里面有 static 的全局变量, ctags 在记录时也不会标明说该变量是局限于本文件的(见第一节描述).

5.

```
--c++-kinds=+px
```

记录类型为函数声明和前向声明的语法元素(见第三节).

6.

```
--fields=+aiKSz
```

控制记录的内容(见第四节).

7.

```
--extra=+q
```

让 ctags 额外记录一些东西(见第四、五节).

8.

```
--exclude=lex.yy.cc --exclude=copy_lex.yy.cc
```
告知 ctags 不要扫描名字是这样的文件. 还可以控制 ctags 不要扫描指定目录, 这里就不细说了.

9.

```
-f tagfile
```

指定生成的标签文件名, 默认是 tags. tagfile 指定为 - 的话, 输出到标准输出.

## 6. 本文内容来源

Exuberant Ctags 附带的帮助文档(ctags.html).

## 7. 使用 tags

tag 是什么?一个位置. 它记录了关于一个标识符在哪里被定义的信息, 比如 C 或 C\+\+程序中的一个函数定义. 这种 tag 聚集在一起被放入一个 tags 文件. 这个文件可以让 Vim 能够从任何位置起跳达到 tag 所指示的位置－标识符被定义的位置.

下面的命令可以为当前目录下的所有 C 程序文件生成对应的 tags 文件:

```
(shell command) ctags *.c
```

现在你在 Vim 中要跳到一个函数的定义(如 startlist)就可以用下面的命令:

```
(ex command) :tag startlist
```

这个命令会带你到函数"startlist"的定义处, 哪怕它是在另一个文件中.

注意: 运行 vim 的时候, 必须在"tags"文件所在的目录下运行. 否则, 运行 vim 的时候还要用":set tags="命令设定"tags"文件的路径, 这样 vim 才能找到"tags"文件. 在完成编码时, 可以手工删掉 tags 文件.

有时候系统提示"找不到 tag"时不要一味着急, 有可能你想要查询的函数时系统函数, 可以使用 Shift+K 来查询.

CTRL+] 命令会取当前光标下的 word 作为 tag 的名字并直接跳转. 这使得在大量 C 程序中进行探索更容易一些. 假设你正看函数"write block", 发现它调用了一个叫"write line"的函数, 这个函数是干什么的呢?你可以把光标置于"write_line"上, 按下 CTRL+] 即可. 如果"write_line"函数又调用了 "write_ char".你当然又要知道这个函数又是什么功能. 同时, 置光标于"write_char"上按下 CTRL+]. 现在你位于函数"write_char"的定义处.

":tags"命令会列出现在你就已经到过哪些 tag 了:

```
(ex command):tags
#      TO          tag        FROM line         in file/text
1       1       write_line        8             write_block.c
2       1       write_char        7             write_line.c
```

现在往回走. CTRL+T 命令会跳到你前一次的 tag 处. 在上例中它会带你到调用了"write_char"的"write_line"函数的地方. CTRL+T 可以带一个命令记数, 以此作为往回跳的次数, 你已经向前跳过了, 现在正在往回跳, 我们再往前跳一次.

下面的命令可以直接跳转到当前 tag 序列的最后:

```
(ex command) :tag
```

你也可以给它一个前辍, 让它向前跳指定的步长. 比如":3tag". CTRL+T 也可以带一个前辍. 这些命令可以让你向下深入一个函数调用树(使用 CTRL+]), 也可以回溯跳转(使用 CTRL+T). 还可以随时用":tags"看你当前的跳转历史记录.

## 8. 分隔窗口

":tag"命令会在当前窗口中载入包含了目标函数定义的文件. 但假设你不仅要查看新的函数定义, 还要同时保留当前的上下文呢?你可以在":tag"后使用一个分隔窗口命令":split". Vim 还有一个一举两得的命令:

```
(ex command) :stag tagname
```

要分隔当前窗口并跳转到光标下的 tag:

```
(normal mode command) CTRL+W+]
```

如果同时还指定了一个命令记数, 它会被当作新开窗口的行高.

## 9. 多个 tags 文件

如果你的源文件位于多个目录下, 你可以为每个目录都建一个 tags 文件. Vim 会在使用某个目录下的 tags 文件进行跳转时只在那个目录下跳转.

要使用更多 tags 文件, 可以通过改变'tags'选项的设置来引入更多的 tags 文件. 如:

```
(ex command) :set tags=./tags, ./../tags, ./*/tags
```

这样的设置使 Vim 可以使用当前目录下的 tags 文件, 上一级目录下的 tags 文件, 以及当前目录下所有层级的子目录下的 tags 文件. 这样可能会引入很多的 tags 文件, 但还有可能不敷其用. 比如说你正在编辑"~/proj/src"下的一个文件, 但又想使用"~/proj/sub/tags"作为 tags 文件. 对这种 Vim 情况提供了一种深度搜索目录的形式. 如下:

```
(ex command) :set tags=~/proj/**/tags
```

## 10. 单个 tags 文件

Vim 在搜索众多的 tags 文件时, 你可能会听到你的硬盘在咔嗒咔嗒拼命地叫. 显然这会降低速度. 如果这样还不如花点时间生成一个大一点的 tags 文件. 这需要一个功能丰富的 ctags 程序, 比如上面提到的那个. 它有一个参数可以搜索整个目录树:

```
(shell command)cd ~/proj
ctags -R
```

用一个功能更强的 ctags 的好处是它能处理多种类型的文件. 不光是 C 和 C++源程序, 也能对付 Eiffel 或者是 Vim 脚本. 你可以参考 ctags 程序的文件调整自己的需要. 现在你只要告诉 Vim 你那一个 tags 文件在哪就行了:

```
(ex command) :set tags=~/proj/tags
```

## 11. 同名 tag

当一个函数被多次重载(或者几个类里都定义了一些同名的函数), ":tag"命令会跳转到第一个符合条件的. 如果当前文件中就有一个匹配的, 那又会优先使用它. 当然还得有办法跳转到其它符合条件的 tag 去:

```
(ex command) :tnext
```

重复使用这个命令可以发现其余的同名 tag. 如果实在太多, 还可以用下面的命令从中直接选取一个:

```
(ex command) :tselect tagname
```

Vim 会提供给你一个选择列表, 例如: (Display)

```
#     pri     kind     tag               file
1      F        f      mch_init     os_amiga.c
                        mch_init()
2      F        f      mch_init     os_mac.c
                        mch_init()
3      F        f      mch_init     os_msdos.c
                        mch_init(void)
4      F        f      mch_init     os_riscos.c
                        mch_init()
Enter nr of choice (<CR> to abort):
```

现在你只需键入相应的数字(位于第一栏的).  其它栏中的信息是为了帮你作出决策的. 在多个匹配的 tag 之间移动, 可以使用下面这些命令:

```
(ex command):tfirst             Go to first match
           :[count]tprevious   go to [count] previous match
           :[count]tnext       go to [count] next match
           :tlast              go to last match
```

如果没有指定[count], 默认是 1.

## 12. tag 的名字

命令补齐真是避免键入一个长 tag 名的好办法. 只要输入开头的几个字符然后按下制表符:

```
(ex command) :tag write_<Tab>
```

Vim 会为你补全第一个符合的 tag 名. 如果还不合你意, 接着按制表符直到找到你要的. 有时候你只记得一个 tag 名的片段, 或者有几个 tag 开头相同. 这里你可以用一个模式匹配来告诉 Vim 你要找的 tag.

假设你想跳转到一个包含"block"的 tag. 首先键入命令:

```
(ex command) :tag /block.
```

现在使用命令补齐: 按<Tab>.

Vim 会找到所有包含"block"的 tag 并先提供给你第一个符合的. "/"告诉 Vim 下面的名字不是一五一十的 tag 名, 而是一个搜索模式. 通常的搜索技巧都可以用在这里.

比如你有一个 tag 以"write "开始:

```
(ex command) :tselect /^write_
```

"^"表示这个 tag 以"write_"开始. 不然在半中间出现 write 的 tag 也会被搜索到. 同样"$"可以用于告诉 Vim 要查找的 tag 如何结束.

## 13. tags 的浏览器

CTRL+]可以直接跳转到以当前光标下的 word 为 tag 名的地方去, 所以可以在一个 tag 列表中使用它. 下面是一个例子. 首先建立一个标识符的列表(这需要一个好的 ctags):

```
(shell command) ctags --c-types=f -f functions *.c
```

现在直接启动 Vim, 以一个垂直分隔窗口的编辑命令打开生成的文件:

```
(shell command) vim:vsplit functions
```

这个窗口中包含所有函数名的列表. 可能会有很多内容, 但是你可以暂时忽略它. 用一个":setlocal ts=99"命令清理一下显示. 在该窗口中, 定义这样的一个映射:

```
(ex command):nnoremap <buffer> <CR> 0ye<C-W>w:tag <C-R>"<CR>
```

现在把光标移到你想要查看其定义的函数名上, 按下回车键, Vim 就会在另一个窗口中打开相应的文件并定位到到该函数的定义上.

## 14. 其它相关主题

设置'ignorecase'也可以让 tag 名的处理忽略掉大小写.

'tagsearch'选项告诉 Vim 当前参考的 tags 文件是否是排序过的. 默认情况假设该文件是排序过的, 这会使 tag 的搜索快一些, 但如果 tag 文件实际上没有排序就会在搜索时漏掉一些 tag.

'taglength'告诉 Vim 一个 tag 名字中有效部分的字符个数. 例:

```
#include <stdio.h>
int very_long_variable_1;
int very_long_variable_2;
int very_long_variable_3;
int very_long_variable_4;
int main()
{
    very_long_variable_4 = very_long_variable_1 *
    very_long_variable_2;
}
```

对于上面这段代码, 4 个变量长度都为 20, 如果将'taglength'设为 10, 则:

```
(ex command):tag very_long_variable_4
```

会匹配到 4 个 tag, 而不是 1 个, 光标停留在 very_long_variable_1 所在行上, 因为被搜索的 tag 部分只有前面的 10 个字符:  "very_long_", 相应的显示是(是 gvim 中文版的真正显示, 不是翻译的):

(Display)找到 tag: 1/4 或更多


# 参考

http://blog.csdn.net/gangyanliang/article/details/6889860