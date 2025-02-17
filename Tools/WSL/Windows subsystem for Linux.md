
# 1. Windows10 更新

将 windows10 更新到最新系统

# 2. 打开功能

"控制面板" —— "程序" —— "程序和功能" —— "启用或关闭 Windows 功能" —— 打开"适用于 Linux 的 Windows 子系统"

### 3. 安装 ubuntu

在 Windows Store 中搜索并安装 ubuntu

### 4. 启用 root 以及 ssh

替换掉/etc/shadow 或者修改里面内容, 将 root 密码删掉(置空)

修改 ssh 服务的配置文件(一般在 `/etc/ssh/sshd_config`), 参照当前目录下文件.

在 `/root/.bashrc` 尾添加下面内容

```
service ssh status > /dev/null

if [ $? -ne 0 ]
then
    service ssh start
else
    echo "ssh service is already running"
fi
```

### 5. 修改 ubuntu 的软件源

ubuntu 的软件源文件是/etc/apt/sources.list.

查看当前 OS 的版本:

```
root@Gerry:~# cat /etc/issue
Ubuntu 16.04.3 LTS \n \l

root@Gerry:~# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 16.04.3 LTS
Release:        16.04
Codename:       xenial
```

清华镜像源配置: https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/

根据版本选择一个源.

### 6. 更新下所有软件

```
apt-get dist-upgrade
```