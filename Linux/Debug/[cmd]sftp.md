
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. sftp 是什么](#1-sftp-是什么)
- [2. 用法](#2-用法)
  - [2.1. 登录远程主机](#21-登录远程主机)
  - [2.2. 查询帮助手册](#22-查询帮助手册)
  - [2.3. 远程操作和本地操作](#23-远程操作和本地操作)
  - [2.4. 从远程主机下载文件](#24-从远程主机下载文件)
  - [2.5. 从远程主机下载一个目录及其内容](#25-从远程主机下载一个目录及其内容)
  - [2.6. 上传文件到远程主机的当前目录](#26-上传文件到远程主机的当前目录)
  - [2.7. 上传目录到远程主机的当前目录](#27-上传目录到远程主机的当前目录)
  - [2.8. 退出 sftp](#28-退出-sftp)

<!-- /code_chunk_output -->

# 1. sftp 是什么

sftp(Secure File Transfer Protocol)安全的文件传输协议.

sftp 是 ssh 的一部分, 使用 sftp 时也是通过 ssh 建立一个可靠的通信线路来进行文件传输的.

# 2. 用法

## 2.1. 登录远程主机

```
# sftp -P port username@remote_hostname_or_IP
sftp>
```

由此进入了 sftp, 既可以在远程主机上操作, 也可以在本地主机上操作

## 2.2. 查询帮助手册

两种方式

```
sftp> ?
sftp> help
Available commands:
bye                                Quit sftp
cd path                            Change remote directory to 'path'
chgrp grp path                     Change group of file 'path' to 'grp'
chmod mode path                    Change permissions of file 'path' to 'mode'
chown own path                     Change owner of file 'path' to 'own'
df [-hi] [path]                    Display statistics for current directory or
                                   filesystem containing 'path'
exit                               Quit sftp
get [-afPpRr] remote [local]       Download file
reget [-fPpRr] remote [local]      Resume download file
reput [-fPpRr] [local] remote      Resume upload file
help                               Display this help text
lcd path                           Change local directory to 'path'
lls [ls-options [path]]            Display local directory listing
lmkdir path                        Create local directory
ln [-s] oldpath newpath            Link remote file (-s for symlink)
lpwd                               Print local working directory
ls [-1afhlnrSt] [path]             Display remote directory listing
lumask umask                       Set local umask to 'umask'
mkdir path                         Create remote directory
progress                           Toggle display of progress meter
put [-afPpRr] local [remote]       Upload file
pwd                                Display remote working directory
quit                               Quit sftp
rename oldpath newpath             Rename remote file
rm path                            Delete remote file
rmdir path                         Remove remote directory
symlink oldpath newpath            Symlink remote file
version                            Show SFTP version
!command                           Execute 'command' in local shell
!                                  Escape to local shell
?                                  Synonym for help
```

## 2.3. 远程操作和本地操作

进入 sftp 后, 我们既可以在远程主机上操作, 也可以在本地主机上操作

```
// 远程主机上的操作
sftp> pwd
sftp> ls
sftp> cd
// 本地主机上的操作
sftp> lpwd
sftp> lls
sftp> lcd
```

还有一个通用的法则, 在命令前面加一个！表示命令在本地主机上执行

```
// 在远程主机上执行
sftp> vim test.sh
// 在本地主机上执行
sftp> !vim test.sh
```

## 2.4. 从远程主机下载文件

```
//下载到本机主机当前目录, 并且文件名与 remoteFile 相同
sftp> get remoteFile

//下载到本机主机当前目录, 并且文件名改为 localFile
sftp> get remoteFile localFile
```

## 2.5. 从远程主机下载一个目录及其内容

```
sftp> get -r Directory
```

## 2.6. 上传文件到远程主机的当前目录

```
sftp> put localFile
```

## 2.7. 上传目录到远程主机的当前目录

```
sftp> put -r localDirectory
```

## 2.8. 退出 sftp

```
sftp> exit
```
