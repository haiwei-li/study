## 1.1 在 linux 环境编译应用程式或 lib 的 source code 时

```
/usr/bin/ld: 找不到 -lcrypt
/usr/bin/ld: 找不到 -lm
```

这些讯息会随着编译不同类型的 source code 而有不同的结果出来如:

```
/usr/bin/ld: cannot find -lc
/usr/bin/ld: cannot find -lltdl
/usr/bin/ld: cannot find -lXtst
```

其中 xxx 即表示函式库文件名称, 如上例的: libc.so、libltdl.so、libXtst.so.
其命名规则是: lib+库名(即 xxx)+.so.

会发生这样的原因有以下三种情形:
1. 系统没有安装相对应的 lib
2. 相对应的 lib 版本不对
3. lib(.so 档)的 symbolic link 不正确, 没有连结到正确的函式库文件(.so)

对于上述三种原因有一篇文章写的很棒可参考这一篇文章的第４点:

[gcc 命令祥解](http://passby.tk/index.php?q=YUhSMGNEb3ZMM0JoYzNOaWVTNTBheTlwYm1SbGVDNXdhSEEvY1QxWlZXaFRUVWRPUldJeldrMU5NbEY2V2tock1FMVZNVmxWYlhocVRURktkMWx0TVdwa1ZtdDVUMWhTVFUxdFozZFpiR1F6WkdzeGNWVllXazVXUjJRMFZHNXJNV0l5VWtoTldFMGxNMFFtT1RnMU56VXhNakEx&1702098065)


解决方法:
(1)先判断在/usr/lib 下的相对应的函式库文件(.so) 的 symbolic link 是否正确
若不正确改成正确的连结目标即可解决问题.

(2)若不是 symbolic link 的问题引起, 而是系统缺少相对应的 lib 安装 lib 即可解决.

(3)如何安装缺少的 lib:

以上面三个错误讯息为例:

- 错误 1 缺少 libc 的 LIB
- 错误 2 缺少 libltdl 的 LIB
- 错误 3 缺少 libXtst 的 LIB
　

以 Ubuntu 为例:

先搜寻相对应的 LIB 再进行安装的作业如:

- apt-cache search libc-dev
- apt-cache search libltdl-dev
- apt-cache search libXtst-dev

实例:

在进行输入法 gcin 的 Source Code 的编译时出现以下的错误讯息:

/usr/bin/ld: cannot find -lXtst

经检查后发现是:

lib(.so 档)的 symbolic link 不正确

解决方法如下:

```
cd /usr/lib
ln -s libXtst.so.6 libXtst.so
```

如果在/usr/lib 的目录下找不到 libXtst.so 档, 那么就表示系统没有安装 libXtst 的函式库.

解法如下:

```
apt-get install libxtst-dev
```

## 2. 通常在软件编译时出现的 usr/bin/ld: cannot find -lxxx 的错误

主要的原因是库文件并没有导入的 ld 检索目录中.

解决方式:

1. 确认库文件是否存在, 比如-l123, 在/usr/lib, /usr/local/lib,或者其他自定义的 lib 下有无 lib123.so, 如果只是存在 lib123.so.1,那么可以通过 ln \-sv lib123.so.1   lib123.so, 建立一个连接重建 lib123.so.

2. 检查/etc/ld.so.conf 中的库文件路径是否正确, 如果库文件不是使用系统路径, /usr/lib, /usr/local/lib, 那么必须在文件中加入.

3.ldconfig 重建 ld.so.cache 文件, ld 的库文件检索目录存放文件. 尤其刚刚编译安装的软件, 必须运行 ldconfig, 才能将新安装的
库文件导入 ld.so.cache.

4.测试, gcc \-l123 \-\-verbose.

## 3. ldconfig 是一个动态链接库管理命令

为了让动态链接库为系统所共享,还需运行动态链接库的管理命令\-\-ldconfig
ldconfig 命令的用途,主要是在默认搜寻目录(/lib 和/usr/lib)以及动态库配置文件/etc/ld.so.conf 内所列的目录下,搜索出可共享的动态链接库(格式如前介绍,lib\*.so\*),进而创建出动态装入程序(ld\.so)所需的连接和缓存文件.缓存文件默认为 /etc/ld.so.cache,此文件保存已排好序的动态链接库名字列表.

ldconfig 通常在系统启动时运行,而当用户安装了一个新的动态链接库时,就需要手工运行这个命令.

ldconfig 命令行用法如下:

ldconfig [-v|--verbose] [-n] [-N] [-X] [-f CONF] [-C CACHE] [-r ROOT] [-l] [-p|--print-cache] [-c FORMAT] [--format=FORMAT] [-V] [- |--help|--usage] path...

ldconfig 可用的选项说明如下:

(1) -v 或--verbose : 用此选项时,ldconfig 将显示正在扫描的目录及搜索到的动态链接库,还有它所创建的连接的名字.

(2) -n : 用此选项时,ldconfig 仅扫描命令行指定的目录,不扫描默认目录(/lib,/usr/lib),也不扫描配置文件/etc/ld.so.conf 所列的目录.

(3) -N : 此选项指示 ldconfig 不重建缓存文件(/etc/ld.so.cache).若未用-X 选项,ldconfig 照常更新文件的连接.

(4) -X : 此选项指示 ldconfig 不更新文件的连接.若未用-N 选项,则缓存文件正常更新.

(5) -f CONF : 此选项指定动态链接库的配置文件为 CONF,系统默认为/etc/ld.so.conf.

(6) -C CACHE : 此选项指定生成的缓存文件为 CACHE,系统默认的是/etc/ld.so.cache,此文件存放已排好序的可共享的动态链接库的列表.

(7) -r ROOT : 此选项改变应用程序的根目录为 ROOT(是调用 chroot 函数实现的).选择此项时,系统默认的配置文件/etc/ld.so.conf,实际对应的为 ROOT/etc/ld.so.conf.如用-r /usr/zzz 时,打开配置文件/etc/ld.so.conf 时,实际打开的是/usr/zzz/etc/ld.so.conf 文件.用此选项,可以 大大增加动态链接库管理的灵活性.

(8) -l : 通常情况下,ldconfig 搜索动态链接库时将自动建立动态链接库的连接.选择此项时,将进入专家模式,需要手工设置连接.一般用户不用此项.

(9) -p 或--print-cache : 此选项指示 ldconfig 打印出当前缓存文件所保存的所有共享库的名字.

(10) -c FORMAT 或 --format=FORMAT : 此选项用于指定缓存文件所使用的格式,共有三种: ld(老格式),new(新格式)和 compat(兼容格式,此为默认格式).

(11) -V : 此选项打印出 ldconfig 的版本信息,而后退出.

(12) - 或 --help 或 --usage : 这三个选项作用相同,都是让 ldconfig 打印出其帮助信息,而后退出.

注: 先去分析编译的参数, 如果是-static 的, 那么需要装的包是 glibc-static, 而不是 glibc