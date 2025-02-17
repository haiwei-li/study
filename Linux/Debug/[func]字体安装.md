
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 检查](#1-检查)
- [2. 安装字体库](#2-安装字体库)
- [3. 添加字体](#3-添加字体)
- [4. 修改目录的权限](#4-修改目录的权限)
- [5. 处理字体信息](#5-处理字体信息)
- [6. 刷新缓存](#6-刷新缓存)
- [7. 确认字体列表](#7-确认字体列表)
- [8. 参考](#8-参考)

<!-- /code_chunk_output -->

# 1. 检查

查看字体列表

```
# fc-list
```

提示命令无效, 在/usr/share/目录下没有 fonts 和 fontconfig 目录, 说明没有字体库.

# 2. 安装字体库

```
# yum install -y fontconfig
```

fontconfig 用来安装字体库

/usr/share 目录就可以看到 fonts 和 fontconfig 目录

ttmkfdir 用来搜索目录中所有的字体信息, 并汇总生成 fonts.scale 文件

# 3. 添加字体

为字体创建目录

```
# mkdir /usr/share/fonts/SourceCodePro
```

从 https://github.com/ryanoasis/nerd-fonts/releases 下载 SourceCodePro.zip

并解压放到该目录下(不需要子目录)

# 4. 修改目录的权限

```
# chmod -R 755 /usr/share/fonts/SourceCodePro
```

# 5. 处理字体信息

安装 ttmkfdir 来搜索目录中所有的字体信息, 并汇总生成 fonts.scale 文件

```
# yum -y install ttmkfdir
```

执行 ttmkfdir 命令

```
# ttmkfdir -e /usr/share/X11/fonts/encodings/encodings.dir
```

修改字体配置文件

```
# vim /etc/fonts/fonts.conf
```

有个 Font directory list, 即字体列表, 将字体位置加进去:

```
<!-- Font directory list -->

        <dir>/usr/share/fonts</dir>
        <dir>/usr/share/X11/fonts/Type1</dir> <dir>/usr/share/X11/fonts/TTF</dir> <dir>/usr/local/share/fonts</dir>
        <dir>/usr/share/fonts/SourceCodePro</dir>
        <dir prefix="xdg">fonts</dir>
        <!-- the following element will be removed in the future -->
        <dir>~/.fonts</dir>
```

但是其实注意, 已经有了 /usr/share/fonts 目录, 也就是说会自动扫描这个目录下的子目录, 所以其实也不用额外添加

# 6. 刷新缓存

```
# fc-cache
```

# 7. 确认字体列表

```
# fc-list
```

# 8. 参考

https://blog.csdn.net/wlwlwlwl015/article/details/51482065