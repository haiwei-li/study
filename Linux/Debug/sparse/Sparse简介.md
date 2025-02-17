
# Sparse 简介

Sparse 诞生于 2004 年, 是由 linux 之父开发的, 目的就是提供一个静态检查代码 的工具, 从而减少 linux 内核的隐患.

其实在 Sparse 之前, 已经有了一个不错的**代码静态检查工具** ("SWAT"), 只不过这个工具不是免费软件, 使用上有一些限制. 所以 linus 还是自己开发了一个静态检查工具.

Sparse 相关的资料可以参考下面链接:

- Sparse kernel Documentation: Documentation/dev-tools/sparse.rst

- Sparse kernel 中文文档: Documentation/translations/zh_CN/sparse.txt

- 2004 年文章: [Finding kernel problems automatically](https://lwn.net/Articles/87538/)

- [linus sparse](https://yarchive.net/comp/linux/sparse.html)

# Sparse 安装

Sparse 是一个独立于 linux 内核源码的静态源码分析工具, 开发者在使用 sparse 进行源码分析之前, 确保 sparse 工具**已经安装**, 如果没有安装, 可以通过下面几个种 方法进行安装.

下载源码

```
git clone git://git.kernel.org/pub/scm/devel/sparse/sparse.git
```

编译安装

```
make
make install
```

# Sparse 在编译内核中的使用

用 Sparse 对内核进行静态分析非常简单.

```
# 检查所有内核代码
make C=1 检查所有重新编译的代码
make C=2 检查所有代码, 不管是不是被重新编译
```

如果开发者**已经编译内核**, 可以使用该命令检查特定的文件, 如 `drivers/BiscuitOS/sparse.c` 命令如下:

```
make C=2 drivers/BiscuitOS/sparse.o
```

# Sparse 原理

Sparse 通过 gcc 的扩展属性 `__attribute__` 以及自己定义的 `__context__` 来对代码进行静态检查.

这些属性如下(尽量整理的,可能还有些不全的地方):

宏名称 | 宏定义 | 检查点
---------|----------|---------
`__bitwise` | `__attribute__((bitwise))` | 确保变量是相同的位方式(比如 `bit-endian`, `little-endiandeng`)
`__user` | `__attribute__((noderef, address_space(1)))` | 指针地址必须在用户地址空间
`__kernel` | `__attribute__((noderef, address_space(0)))` | 指针地址必须在内核地址空间
`__iomem` | `__attribute__((noderef, address_space(2)))` | 指针地址必须在设备地址空间
`__safe` | `__attribute__((safe))` | 变量可以为空
`__force` | `__attribute__((force))` | 变量可以进行强制转换
`__nocast` | `__attribute__((nocast))` | 参数类型与实际参数类型必须一致
`__acquires(x)` | `__attribute__((context(x, 0, 1)))` | 参数 x 在执行前引用计数必须是 0,执行后,引用计数必须为 1
`__releases(x)` | `__attribute__((context(x, 1, 0)))` | 与 `__acquires(x)` 相反
`__acquire(x)` | `__context__(x, 1)` | 参数 x 的引用计数 + 1
`__release(x)` | `__context__(x, -1)` | 与 `__acquire(x)` 相反
`__cond_lock(x,c)` | `((c) ? ({ __acquire(x); 1; }) : 0)` | 参数 c 不为 0 时,引用计数

其中 `__acquires(x)` 和 `__releases(x), __acquire(x)` 和 `__release(x)` 必须配对使用, 否则 Sparse 会给出警告

在 Linux 内核源码中, 使用上面的命令(`make C=2 drivers/BiscuitOS/sparse.o`), 在源码树根目录下 Makefile 中对应的逻辑 关系如下:

```makefile
# Call a source code checker (by default, "sparse") as part of the
# C compilation.
#
# Use 'make C=1' to enable checking of only re-compiled files.
# Use 'make C=2' to enable checking of *all* source files, regardless
# of whether they are re-compiled or not.
#
# See the file "Documentation/dev-tools/sparse.rst" for more details,
# including where to get the "sparse" utility.

ifeq ("$(origin C)", "command line")
  KBUILD_CHECKSRC = $(C)
endif
ifndef KBUILD_CHECKSRC
  KBUILD_CHECKSRC = 0
endif

CHECK           = sparse

CHECKFLAGS     := -D__linux__ -Dlinux -D__STDC__ -Dunix -D__unix__ \
                  -Wbitwise -Wno-return-void -Wno-unknown-attribute $(CF)

export KBUILD_CHECKSRC CHECK CHECKFLAGS
```

在根目录的 Makefile 中定义了 sparse 为静态检测工具, 并将 `CHECKFLAGS` 参数传递给 sparse 工具, 其执行过程位于内核源码树 `scripts/Makefile.build`

```makefile
# Linus' kernel sanity checking tool
ifeq ($(KBUILD_CHECKSRC),1)
  quiet_cmd_checksrc       = CHECK   $<
        cmd_checksrc       = $(CHECK) $(CHECKFLAGS) $(c_flags) $<
else ifeq ($(KBUILD_CHECKSRC),2)
  quiet_cmd_force_checksrc = CHECK   $<
        cmd_force_checksrc = $(CHECK) $(CHECKFLAGS) $(c_flags) $<
endif
```

从上面的逻辑可以看出 sparse 执行过程. Linux Kbuild 编译系统通过上面的 设置, 在源码中加入了 CHECK 宏, 以提供 sparse 的检测.



# 参考

https://biscuitos.github.io/blog/SPARSE/

https://www.cnblogs.com/wang_yb/p/3575039.html