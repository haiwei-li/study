
## 1. 问题

64 位 Linux 系统编译 32 位汇编程序的时候需要仿真 32 位系统的需求发现使用-m32 参数后编译提示错误如下:

```
/usr/bin/ld: 未知的仿真模式: 32
支持的仿真:  elf_x86_64 elf32_x86_64 elf_i386 i386linux elf_l1om elf_k1om i386pep i386pe
collect2: error: ld returned 1 exit status
```

## 2. 解决

**2.1 2.2 步是 Ubuntu 下的操作**

### 2.1 打开 64 位系统对 32 位的支持

第一步确认 64 为架构的内核

ubuntu 下

```
root@Gerry:~# dpkg --print-architecture
amd64
```

表明是 64 位内核

第二步: 确认打开了多架构支持功能

```
root@Gerry:~# dpkg --print-foreign-architectures
i386
```

说明已打开如果没有需要手动打开

打开多架构支持

```
sudo dpkg --add-architecture i386
sudo apt -get update
sudo apt-get dist-upgrade
```

这样 64 位系统对 32 位程序的支持

### 2.2 安装 gcc multilab

```
apt-get install gcc-multilib g++-multilib
```

### 2.3 汇编编译

汇编程序最开头加上 .code32

```
as -o hello.o hello.s -32
```

### 2.4 链接程序

```
ld -o hello -m elf_i386 hello.o
```

通过命令查看 ld 支持的仿真模式

```
root@Gerry:/home/project/as# ld -V
GNU ld (GNU Binutils for Ubuntu) 2.26.1
  Supported emulations:
   elf_x86_64
   elf32_x86_64
   elf_i386
   elf_iamcu
   i386linux
   elf_l1om
   elf_k1om
   i386pep
   i386pe
```

如果汇编中引用了 C 函数链接时候需要如下:

```
ld -m elf_i386 -dynamic-linker /lib/ld-linux.so.2 -o hello hello.o /usr/lib/libc.so.6
```

```
ld -m elf_i386 -dynamic-linker /lib/i386-linux-gnu/ld-linux.so.2 -o hello hello.o /lib/i386-linux-gnu/libc.so.6
```

也就是两个链接库文件 ld-linux.so.2、libc.so.6