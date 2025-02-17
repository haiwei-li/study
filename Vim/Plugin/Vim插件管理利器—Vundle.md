
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 简介](#1-简介)
- [2. Vundle 的安装和使用](#2-vundle-的安装和使用)
  - [1. Vundle 的安装](#1-vundle-的安装)
  - [2. 配置说明](#2-配置说明)
  - [3. 配置 vundle 插件](#3-配置-vundle-插件)
  - [4. 安装需要的插件](#4-安装需要的插件)
  - [5. 卸载插件](#5-卸载插件)
- [3. Vundle 常用命令](#3-vundle-常用命令)
- [4. 参考](#4-参考)

<!-- /code_chunk_output -->
## 1. 简介

Vundle 是基于 Git 仓库的插件管理软件. Vundle 将插件的安装简化为类似 yum 软件安装的过程, 只要`:BundleInstall` 插件就安装完了, `:BundleClean` 之后插件就卸载了.

- 在.vimrc 中跟踪和管理插件
- 安装特定格式的插件(a.k.a. scripts/bundle)
- 更新特定格式插件
- 通过插件名称搜索 Vim scripts 中的插件
- 清理未使用的插件
- 可以通过单一按键完成以上操作,详见[interactive mode](https://github.com/VundleVim/Vundle.vim/blob/v0.10.2/doc/vundle.txt#L319-L360)

Vundle 自动完成

- 管理已安装插件的 runtime path
- 安装和更新后,重新生成帮助标签

## 2. Vundle 的安装和使用

### 1. Vundle 的安装

```
$ git clone https://github.com/VundleVim/Vundle.vim.git  ~/.vim/bundle/vundle
```

### 2. 配置说明

插件有三种类型:

1. Github 上 vim-scripts 仓库的插件
2. Github 上非 vim-scripts 仓库的插件
3. 不在 Github 上的插件

对于不同的插件, vundle 自动管理和下载插件的时候, 有不同的地址填写方法, 有如下三类:

1. 在 Github 上 vim-scripts 用户下的仓库,只需要写出 repos(仓库)名称
2. 在 Github 其他用户下的 repos, 需要写出"用户名/repos 名"
3. 不在 Github 上的插件, 需要写出 git 全路径

### 3. 配置 vundle 插件

可以在终端通过 vim 打开~/.vimrc 文件

添加的配置信息(样例)

注: 以后安装新插件就直接编辑 vimrc, 添加 plugin 就行了, 在这里我们添加的 plugin 只是例子, 你可以不安装这些插件, 换上自己需要安装的插件.

```
set nocompatible              " 去除 VI 一致性,必须要添加
filetype off                  " 必须要添加

" 设置包括 vundle 和初始化相关的 runtime path
set rtp+=~/.vim/bundle/vundle
call vundle#begin()
" 另一种选择, 指定一个 vundle 安装插件的路径
"call vundle#begin('~/some/path/here')

" 让 vundle 管理插件版本,必须
Plugin 'VundleVim/Vundle.vim'

" 以下范例用来支持不同格式的插件安装.
" 请将安装插件的命令放在 vundle#begin 和 vundle#end 之间.
" Github 上的插件
" 格式为 Plugin '用户名/插件仓库名'
Plugin 'tpope/vim-fugitive'
" 来自 http://vim-scripts.org/vim/scripts.html 的插件
" Plugin '插件名称' 实际上是 Plugin 'vim-scripts/插件仓库名' 只是此处的用户名可以省略
Plugin 'L9'
" 由 Git 支持但不再 github 上的插件仓库 Plugin 'git clone 后面的地址'
Plugin 'git://git.wincent.com/command-t.git'
" 本地的 Git 仓库(例如自己的插件) Plugin 'file:///+本地插件仓库绝对路径'
Plugin 'file:///home/gmarik/path/to/plugin'
" 插件在仓库的子目录中.
" 正确指定路径用以设置 runtimepath. 以下范例插件在 sparkup/vim 目录下
Plugin 'rstacruz/sparkup', {'rtp': 'vim/'}
" 安装 L9, 如果已经安装过这个插件, 可利用以下格式避免命名冲突
Plugin 'ascenator/L9', {'name': 'newL9'}

" 你的所有插件需要在下面这行之前
call vundle#end()            " 必须
filetype plugin indent on    " 必须 加载 vim 自带和插件相应的语法和文件类型相关脚本
" 忽视插件改变缩进,可以使用以下替代:
"filetype plugin on
"
" 常用的命令
" :PluginList       - 列出所有已配置的插件
" :PluginInstall     - 安装插件,追加 `!` 用以更新或使用 :PluginUpdate
" :PluginSearch foo - 搜索 foo ; 追加 `!` 清除本地缓存
" :PluginClean      - 清除未使用插件,需要确认; 追加 `!` 自动批准移除未使用插件
"
" 查阅 :h vundle 获取更多细节和 wiki 以及 FAQ
" 将你自己对非插件片段放在这行之后
```

### 4. 安装需要的插件

将想要安装的插件, 按照地址填写方法, 将地址填写在 vundle#begin 和 vundle#end 之间就可以

打开 vim, 输入:BundleInstall

```
$ vim
:BundleInstall
```

### 5. 卸载插件

如果要卸载插件就只需要删除.vimrc 中的 Bundle, 然后在 Vim 中执行

```
:BundleClean
```

## 3. Vundle 常用命令

```
:BundleList             -列举列表(也就是.vimrc)中配置的所有插件
:BundleInstall          -安装列表中的全部插件
:BundleInstall!         -更新列表中的全部插件
:BundleSearch foo       -查找 foo 插件
:BundleSearch! foo      -刷新 foo 插件缓存
:BundleClean            -清除列表中没有的插件
:BundleClean!           -清除列表中没有的插件
```

## 4. 参考

[Vundle 项目](https://github.com/gmarik/vundle)

[vim-scripts](http://vim-scripts.org/)维护的[GitHub repo](https://github.com/vim-scripts)

http://blog.csdn.net/jiaolongdy/article/details/17889787/

http://blog.csdn.net/zhangpower1993/article/details/52184581
