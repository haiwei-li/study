32 位汇编参见《Linux 汇编入门 - 32 位》

## 一、不同

1. 系统调用号不同. 比如 x86 中 sys_write 是 4, sys_exit 是 1; 而 x86_64 中 sys_write 是 1, `sys_exit` 是 60. linux 系统调用号实际上定义在 `/usr/include/asm/unistd_32.h` 和 `/usr/include/asm/unistd_64.h` 中.

2. 系统调用所使用的寄存器不同 x86_64 中使用与 eax 对应的 rax 传递系统调用号但是 x86_64 中分别使用 `rdi/rsi/rdx` 传递前三个参数而不是 x86 中的 ebx/ecx/edx.

- 对于 32 位程序应调用 int $0x80 进入系统调用将系统调用号传入 eax 各个参数按照 ebx、ecx、edx 的顺序传递到寄存器中系统调用返回值储存到 eax 寄存器.

- 对于 64 位程序应调用 syscall 进入系统调用将系统调用号传入 rax 各个参数按照 rdi、rsi、rdx 的顺序传递到寄存器中系统调用返回值储存到 rax 寄存器.

3. 系统调用使用"syscall"而不是"int 80"

4. 32 位和 64 位程序的地址空间范围不同.

例子:

32 位

```
global _start
_start:
        jmp short ender
starter:
        xor eax, eax    ;clean up the registers
        xor ebx, ebx
        xor edx, edx
        xor ecx, ecx

        mov al, 4       ;syscall write
        mov bl, 1       ;stdout is 1
        pop ecx         ;get the address of the string from the stack
        mov dl, 5       ;length of the string
        int 0x80

        xor eax, eax
        mov al, 1       ;exit the shellcode
        xor ebx,ebx
        int 0x80
ender:
        call starter    ;put the address of the string on the stack
        db 'hello',0x0a
```

64 位

```
global _start           ; global entry point export for ld
_start:
    jump short string   ; get message addr
code:
    ; sys_write(stdout, message, length)
    pop     rsi         ; message address
    mov     rax, 1      ; sys_write
    mov     rdi, 1      ; stdout
    mov     rdx, 13     ; message string length + 0x0a
    syscall

    ; sys_exit(return_code)
    mov     rax, 60     ; sys_exit
    mov     rdi, 0      ; return 0 (success)
    syscall

string:
    call    code
    db 'Hello!',0x0a    ; message and newline
```



## 二、兼容

由于硬件指令的兼容 32 位的程序在用户态不受任何影响的运行由于**内核保留了 0x80 号中断作为 32 位程序的系统调用服务**因此 32 位程序可以安全触发 0x80 号中断使用系统调用由于内核为 0x80 中断安排了另一套全新的系统调用表因此可以安全地转换数据类型成一致的 64 位类型再加上应用级别提供了两套 c 库可以使 64 位和 32 位程序链接不同的库.

## 三、内联汇编

### 1. 程序代码和问题

首先看如下一段简单的 C 程序(test.c)

```
#include <unistd.h>
int main(){
    char str[] = "Hello\n";
    write(0, str, 6);
    return 0;
}
```

这段程序调用了 write 函数其接口为:

```
int write(int fd /*输出位置句柄*/, const char* src /*输出首地址*/ int len /*长度*/)
```

fd 为 0 则表示输出到控制台. 因此上述程序的执行结果为: 向控制台输出一个长度为 6 的字符串"Hello\n".

在控制台调用 gcc test.c 可以正确输出.

为了更好地理解在汇编代码下的系统调用过程可把上述代码改写成内联汇编的格式(参照《用 asm 内联汇编实现系统调用》)

```cpp
test_asm_A.c
int main(){
    char str[] = "Hello\n";
    asm volatile(
        "int $0x80\n\t"
        :
        :"a"(4), "b"(0), "c"(str), "d"(6)
        );
    return 0;
}
```

其中 4 是 write 函数的系统调用号 ebx/ecx/edx 是系统调用的前三个参数.

然而执行 gcc test\_asm\_A.c 编译后再运行程序发现程序没有任何输出. 一个很奇怪的问题是如果采用如下 test\_asm\_B.c 的写法则程序可以正常地输出:

```
test_asm_B.c
#include <stdlib.h>

int main(){
    char *str = (char*)malloc(7 * sizeof(char));
    strcpy(str, "Hello\n");
    asm volatile(
        "int $0x80\n\t"
        :
        :"a"(4), "b"(0), "c"(str), "d"(6)
        );
    free(str);
    return 0;
}
```

输出如下:

```
[root@tsinghua-pcm C]# gcc test_asm_B.c
test_asm_B.c: 在函数'main'中:
test_asm_B.c:4:2: 警告: 隐式声明与内建函数'strcpy'不兼容 [默认启用]
  strcpy(str, "Hello\n");
  ^
[root@tsinghua-pcm C]# ./a.out
Hello
[root@tsinghua-pcm C]# cp inline_assembly.c test_asm_A.c
[root@tsinghua-pcm C]# gcc test_asm_A.c
[root@tsinghua-pcm C]# ./a.out
[root@tsinghua-pcm C]#
```

两段代码唯一的区别是 test\_asm\_A.c 中的 str 存储在栈空间而 test\_asm\_B.c 中的 str 存储在堆空间.

那么为什么存储位置的不同会造成完全不同的结果呢?

### 2. 原因分析

将上述代码用 32 位的方式编译即 gcc test\_asm\_A.c -m32 和 gcc test\_asm\_B.c -m32 可以发现两段代码都能正确输出. 这说明上述代码按 32 位编译可以得到正确的结果.

```
[root@tsinghua-pcm C]# gcc test_asm_A.c -m32
[root@tsinghua-pcm C]# ./a.out
Hello
[root@tsinghua-pcm C]# gcc test_asm_B.c -m32
test_asm_B.c: 在函数'main'中:
test_asm_B.c:4:2: 警告: 隐式声明与内建函数'strcpy'不兼容 [默认启用]
  strcpy(str, "Hello\n");
  ^
[root@tsinghua-pcm C]# ./a.out
Hello
```

如果没有-m32 标志则 gcc 默认按照 64 位方式编译. 32 位和 64 位程序在编译时有如下区别(上面已经提到):

- 32 位和 64 位程序的地址空间范围不同.

- 32 位和 64 位程序的系统调用号不同如本例中的 write 在 32 位系统中调用号为 4 在 64 位系统中则为 1.

- 对于 32 位程序应调用 int $0x80 进入系统调用将系统调用号传入 eax 各个参数按照 ebx、ecx、edx 的顺序传递到寄存器中系统调用返回值储存到 eax 寄存器.

- 对于 64 位程序应调用 syscall 进入系统调用将系统调用号传入 rax 各个参数按照 rdi、rsi、rdx 的顺序传递到寄存器中系统调用返回值储存到 rax 寄存器.

再看上面两段代码它们都是调用 int $0x80 进入系统调用却**按照 64 位方式编译**则会出现如下不正常情形:

- 程序的地址空间是 64 位地址空间.

- 0x80 号中断进入的是 32 位系统调用函数因此仍按照 32 位的方式来解释系统调用即所有寄存器只考虑低 32 位的值.

再看程序中传入的各个参数系统调用号(4)第 1 个和第 3 个参数(0 和 6)都是 32 位以内的但是 str 的地址是 64 位地址在 0x80 系统调用中只有低 32 位会被考虑.

这样 test\_asm\_A.c 不能正确执行而 test\_asm\_B.c 可以正确执行的原因就很明确了:

- 在 test\_asm\_A.c 中 str 存储在栈空间中**而栈空间在系统的高位开始**只取低 32 位地址得到的是错误地址.

- 在 test\_asm\_B.c 中 str 存储在堆空间中**而堆空间在系统的低位开始**在这样一个小程序中 str 地址的高 32 位为 0 只有低 32 位存在非零值因此不会出现截断错误.

对于存储器堆栈可以查看 Computer_Architecture/x86/指令系统/ 下内容

可见 test\_asm\_B.c 正确执行只是一个假象. 由于堆空间从低位开始如果开辟空间过多堆空间也进入高位的时候这段代码同样可能出错.

### 3. 64 位系统的系统调用代码

给出 64 位系统下可正确输出的 asm 系统调用代码:

```
//test_asm_C.c
int main(){
    char str[] = "Hello\n";
    //注意: 64 位系统调用中 write 函数调用号为 1
    asm volatile(
        "mov %2, %%rsi\n\t"
        "syscall"
        :
        :"a"(1), "D"(0), "b"(str), "d"(6)
        );
    return 0;
}
```