
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 获取信息](#1-获取信息)
- [2 下载内核源码](#2-下载内核源码)
  - [2.1 从官网下载](#21-从官网下载)
  - [2.2 通过 yum 下载](#22-通过-yum-下载)
- [3 获得源码](#3-获得源码)

<!-- /code_chunk_output -->

# 1 获取信息

获取 centos 版本

```
[root@gerrylee ~]# cat /etc/redhat-release
CentOS Linux release 7.6.1810 (Core)
```

获取内核版本

```
[root@gerrylee ~]# uname -r
3.10.0-957.21.3.el7.x86_64
[root@gerrylee ~]# uname -a
Linux gerrylee 3.10.0-957.21.3.el7.x86_64 #1 SMP Tue Jun 18 16:35:19 UTC 2019 x86_64 x86_64 x86_64 GNU/Linux
```

# 2 下载内核源码

## 2.1 从官网下载

源代码的官网: http://vault.centos.org/

进入官网后, 依次是进入 7.6.1810/, 进入 os/, 进入 Source/, 进入 SPackages/, 找到 kernel-3.10.0-957.el7.src.rpm, 下载就行了.

## 2.2 通过 yum 下载

查找包信息

```
rpm -qf /bin/vim
```

下载源码包

```
# mkdir vim
# cd vim
# yumdownloader --source vim
```

# 3 获得源码

抽取源码包

```
[root@gerrylee vim]# rpm2cpio vim-7.4.160-1.el7.src.rpm |cpio -id
[root@gerrylee vim]# ls
7.4.001  7.4.016  7.4.031  7.4.046  7.4.061  7.4.076  7.4.091  7.4.106  7.4.121  7.4.136  7.4.151        gvim.desktop              vim-7.3-manpage-typo-668894-675480.patch
7.4.002  7.4.017  7.4.032  7.4.047  7.4.062  7.4.077  7.4.092  7.4.107  7.4.122  7.4.137  7.4.152        README.patches            vim-7.3-xsubpp-path.patch
7.4.003  7.4.018  7.4.033  7.4.048  7.4.063  7.4.078  7.4.093  7.4.108  7.4.123  7.4.138  7.4.153        spec-template             vim-7.4.160-5.el7.src.rpm
7.4.004  7.4.019  7.4.034  7.4.049  7.4.064  7.4.079  7.4.094  7.4.109  7.4.124  7.4.139  7.4.154        spec-template.new         vim-7.4-blowfish2.patch
7.4.005  7.4.020  7.4.035  7.4.050  7.4.065  7.4.080  7.4.095  7.4.110  7.4.125  7.4.140  7.4.155        vi_help.txt               vim-7.4-c++11.patch
7.4.006  7.4.021  7.4.036  7.4.051  7.4.066  7.4.081  7.4.096  7.4.111  7.4.126  7.4.141  7.4.156        vim                       vim-7.4-CVE-2016-1248.patch
7.4.007  7.4.022  7.4.037  7.4.052  7.4.067  7.4.082  7.4.097  7.4.112  7.4.127  7.4.142  7.4.157        vim-6.2-specsyntax.patch  vim-7.4-fstabsyntax.patch
7.4.008  7.4.023  7.4.038  7.4.053  7.4.068  7.4.083  7.4.098  7.4.113  7.4.128  7.4.143  7.4.158        vim-6.4-checkhl.patch     vim-7.4-syntax.patch
7.4.009  7.4.024  7.4.039  7.4.054  7.4.069  7.4.084  7.4.099  7.4.114  7.4.129  7.4.144  7.4.159        vim-7.0-fixkeys.patch     vim-7.4.tar.bz2
7.4.010  7.4.025  7.4.040  7.4.055  7.4.070  7.4.085  7.4.100  7.4.115  7.4.130  7.4.145  7.4.160        vim-7.0-rclocation.patch  vim-7.4-yamlsyntax.patch
7.4.011  7.4.026  7.4.041  7.4.056  7.4.071  7.4.086  7.4.101  7.4.116  7.4.131  7.4.146  Changelog.rpm  vim-7.0-specedit.patch    vim-manpagefixes-948566.patch
7.4.012  7.4.027  7.4.042  7.4.057  7.4.072  7.4.087  7.4.102  7.4.117  7.4.132  7.4.147  gvim16.png     vim-7.0-syncolor.patch    vimrc
7.4.013  7.4.028  7.4.043  7.4.058  7.4.073  7.4.088  7.4.103  7.4.118  7.4.133  7.4.148  gvim32.png     vim-7.0-warning.patch     vim.spec
7.4.014  7.4.029  7.4.044  7.4.059  7.4.074  7.4.089  7.4.104  7.4.119  7.4.134  7.4.149  gvim48.png     vim-7.1-nowarnings.patch
7.4.015  7.4.030  7.4.045  7.4.060  7.4.075  7.4.090  7.4.105  7.4.120  7.4.135  7.4.150  gvim64.png     vim72-rh514717.patch
```

解压得到源码

```
tar xvf vim-7.4.tar.bz2
```

参考

https://blog.csdn.net/derkampf/article/details/71189105