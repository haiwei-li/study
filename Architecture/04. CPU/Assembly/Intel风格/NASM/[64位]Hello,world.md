
## 1. 代码

```
[bits 64]

global _start

section .data
message db "Hello, world!"

section .text

_start:
    mov rax, 1
    mov rdx, 13
    mov rsi, message
    mov rdi, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall
```

## 2. 可执行文件

### 2.1 生成目标文件

```
root@Gerry:/home/project/nasm# nasm -f elf64 -o hello-world.o  hello-world.asm
```

"-f elf64"说明让 nasm 生成一个 elf64 格式的目标文件.

**通过 hexdump 工具查看文件的机器码适用于所有文件**

```
root@Gerry:/home/project/nasm# ll -h hello-world.o
-rw-r--r-- 1 root root 864 Nov 27 15:34 hello-world.o

root@Gerry:/home/project/nasm# file hello-world.o
hello-world.o: ELF 64-bit LSB relocatable, x86-64, version 1 (SYSV), not stripped

root@Gerry:/home/project/nasm# hexdump hello-world.o
0000000 457f 464c 0102 0001 0000 0000 0000 0000
0000010 0001 003e 0001 0000 0000 0000 0000 0000
0000020 0000 0000 0000 0000 0040 0000 0000 0000
0000030 0000 0000 0040 0000 0000 0040 0007 0003
0000040 0000 0000 0000 0000 0000 0000 0000 0000
*
0000080 0001 0000 0001 0000 0003 0000 0000 0000
0000090 0000 0000 0000 0000 0200 0000 0000 0000
00000a0 0011 0000 0000 0000 0000 0000 0000 0000
00000b0 0004 0000 0000 0000 0000 0000 0000 0000
···
0000340 000c 0000 0000 0000 0001 0000 0002 0000
0000350 0000 0000 0000 0000 0000 0000 0000 0000
0000360
```

通过 hexdump 查看文件的机器码可以看到一共有 0x(360 - 0)= 864 字节和查出来的一致.

### 2.2 生成可执行文件

```
root@Gerry:/home/project/nasm# ld -o hello-world hello-world.o

root@Gerry:/home/project/nasm# file hello-world
hello-world: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, not stripped
```

ld 就是把目标文件组合转换成可执行文件.

## 3. 理解寄存器

寄存器就是 cpu 内部的小容量的存储器我们关心的主要是三类寄存器数据寄存器地址寄存器和通用寄存器.

- 数据寄存器保存数值(比如整数和浮点值)
- 地址寄存器保存内存中的地址
- 通用寄存器既可以用过数据寄存器也可以用做地址寄存器.

汇编程序员大部分工作都是在操作这些寄存器.

## 4. 分析源码

```
[bits 64]
```

这是告诉 nasm 我们想要得到可以运行在 64 位处理器上的代码.

```
global _start
```

告诉 nasm 用\_start 标记的代码段(section)应该被看成全局的全局的部分通常允许其他的目标文件引用它在我们的这个例子中我们把\_start 段标记为全局的以便让链接器知道我们的程序从哪里开始.

```
section .data
message db "Hello, World!"
```

告诉 nasm 后面跟着的代码是 data 段 data 段包含全局和静态变量.

声明静态变量. message db "Hello, World!"db 被用来声明初始化数据 message 是一个变量名与"Hello, World!"关联.

```
section .text
```

告诉 nasm 把紧跟着的代码存到 text 段 text 段有时候也叫做 code 段它是包含可执行代码的目标文件的一部分.

最后程序部分.

```
_start:
mov rax, 1
mov rdx, 13
mov rsi, message
mov rdi, 1
syscall

mov rax, 60
mov rdi, 0
syscall
```

第一行. \_start:把它后面的代码和_start 标记相关联起来.

```
mov rax, 1
mov rdx, 13
mov rsi, message
mov rdi, 1
```

上面这四行都是加载值到不同的寄存器里 RAX 和 RDX 都是通用寄存器我们使用他们分别保存 1 和 13RSI 和 RDI 是源和目标数据索引寄存器我们设置源寄存器 RSI 指向 message 而目标寄存器指向 1.

现在当寄存器加载完毕后我们有 syscall 指令这是告诉计算机我们想要使用我们已经加载到寄存器的值执行一次系统调用我们加载的第一个数也就是**RAX 寄存器的值告诉计算机我们想使用哪一个系统调用**syscalls 表和其对应的数字在文件/usr/include/x86\_64-linux-gnu/asm/unistd\_64.h 中(32 位在文件 unistd\_32.h 中).

注意: 上面针对的都是 x86 架构功能号定义在文件/usr/include/bits/syscall.h 中然后针对不同架构有具体文件(如上面)

对比两个文件会发现 32 位和 64 位的内容不同.

32 位文件会发现系统调用号 1 是退出 4 是写
```
#ifndef _ASM_X86_UNISTD_32_H
#define _ASM_X86_UNISTD_32_H 1

#define __NR_restart_syscall 0
#define __NR_exit 1
#define __NR_fork 2
#define __NR_read 3
#define __NR_write 4
#define __NR_open 5
···
```

64 位文件会发现系统调用号 1 是写 60 是退出

```
#ifndef _ASM_X86_UNISTD_64_H
#define _ASM_X86_UNISTD_64_H 1

#define __NR_read 0
#define __NR_write 1
#define __NR_open 2
#define __NR_close 3
#define __NR_stat 4
#define __NR_fstat 5
···
#define __NR_execve 59
#define __NR_exit 60
#define __NR_wait4 61
#define __NR_kill 62
#define __NR_uname 63
···
```

```
mov rax, 1
mov rdx, 13
mov rsi, message
mov rdi, 1
```

RAX 里的 1 意味着我们想要调用 write(int fd, const void* buf, size\_t bytes). 下一条指令 mov rdx,13 则是我们想要调用的函数 write()的最后一个参数值最后一个参数 size\_t bytes 指令了 message 的大小此处 13 也就是"Hello, World!"的长度.

下两条指令 mov rsi, message 和 mov rdi,1 则分别作了其他两个参数因此当我们把他们放在一起当要执行 syscall 的时候我们是告诉计算机执行 write(1, message, 13)1 就是标准输出 stdout 因此本质上我们是告诉计算机从 message 里取 13 个字节输出到 stdout. 其他使用默认参数.

```
mov rax, 60
mov rdi, 0
syscall
```

这个是退出调用 exit(0)

