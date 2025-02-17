c.vim 是 vim 一个用来开发 C/C++插件, [官网](http://www.vim.org/scripts/script.php?script_id=213)

## 1. 插件安装步骤

1. 下载安装包(cvim.zip)

2. 安装插件

```
$ mkdir ~/.vim
$ cd ~/.vim
$ unzip /usr/src/cvim.zip
```

3. Enable 插件

```
$ vim ~/.vimrc
filetype plugin on
```

## 2. c.vim 使用

1. 安装完成之后, 当新建的一个`*.c/*.cpp/*.c++`文件时, 就会自动加入一些说明字符.

```
/*
 * =====================================================================================
 *
 *       Filename:  test.c
 *
 *    Description:
 *
 *        Version:  1.0
 *        Created:  01/27/2015 04:17:54 PM
 *       Revision:  none
 *       Compiler:  gcc
 *
 *         Author:  YOUR NAME (),
 *   Organization:
 *
 * =====================================================================================
 */
```

如果要修改这些默认的字符, 可以直接修改文件(\~/.vim/c-support/templates/Templates)中关于宏的定义.

```
SetMacro( 'AUTHOR',      'YOUR NAME' )
SetMacro( 'AUTHORREF',   '' )
SetMacro( 'COMPANY',     '' )
SetMacro( 'COPYRIGHT',   '' )
SetMacro( 'EMAIL',       '' )
SetMacro( 'LICENSE',     '' )
SetMacro( 'ORGANIZATION','' )
```

2. c.vim 的快捷键, 比如要新建一个代码块, 可以在三种模式(插入模式、一般模式、快模式)下, 直接输入\sb 字符即可.

![config](images/9.png)

![config](images/10.png)

3. 修改默认的模板设置, 有用的参考文档在这个路径(\~/.vim/doc)下面, 放置模板路径(\~/.vim/c-support/templates), 例如, 我要修改默认的 main 函数格式

默认 main 函数格式:

```
int
main ( int argc, char *argv[] )
{
    return EXIT_SUCCESS;
}
```

在默认 main 函数格式里面, 返回值类型单独放在一行, 并且前面有一个 tab 键, 在模板文件里面找到关于 main 函数的模板格式文件(\~/.vim/c-support/templates/c.idioms.template), 找到 main 函数的格式定义, 然后把返回值类型和 main 函数参数都放在一行里面

模板里面 main 函数格式定义:

```
== Idioms.main == map:im, shortcut:m  ==
#include    <stdlib.h>

/*
 * ===  FUNCTION  ======================================================================
 *         Name:  main
 *  Description:
 * =====================================================================================
 */
int
main ( int argc, char *argv[] )
{<CURSOR>
<SPLIT> return EXIT_SUCCESS;
}               /* ----------  end of function main  ---------- */
```

修改之后, 直接用(\im)显示的 main 函数:

```
int main ( int argc, char *argv[] )
{
    return EXIT_SUCCESS;
}
```