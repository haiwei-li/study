```
参考:
http://blog.csdn.net/tianwailaibin/article/details/7094936
```

《一个操作系统的实现》中对于 boot loader 的简单代码

```
    org 07c00h
    mov ax, cs
    mov ds, ax
    mov es, ax
    call DispStr
    jmp $

DispStr:
    mov ax, BootMessage
    mov bp, ax
    mov cx, 16
    mov ax, 01301h
    mov bx, 000ch
    mov dl, 0
    int 10h     ;10h vector, screen display I/O
    ret

BootMessage:    db "Hello, OS world!"
times   510-($ -$$)     db 0
dw 0xaa55
```

实际上 BIOS 会自动将 boot loader 加载到 0x7c00(7c00h)处也就是说无论什么代码都会被 BIOS 加载到 07c00h 处. 那为什么还要加 org 7c00h?

org 在编译阶段影响到内存寻址指令的编译(编译器会将所有程序用到的段内偏移地址自动加上 org 后的数值)而自身不会被编译到机器码. 就是为程序中所有引用地址(**需要计算的相对地址**)增加一个段内偏移值. org 指令本身**不能决定程序将要加载的内存的什么位置**它只是告诉编译器程序在编译好后需要加载到 xxx 地址所以在编译时帮我调整好数据访问时的地址.

如果没有 org 指令那么编译器计算偏移量(虽然 nasm 中没有 offset 但编译器仍会进行这个运算)是从 0x0000 开始的如果有了 org 就会在最后加上 org 后面跟的数字.

在这个引导程序中: `mov ax, BootMessage` 在编译时候实际上是将 mov ax, BootMessage 所在的地址与 BootMessage 同当前语句(mov ax, BootMessage)地址的偏移量相加所计算出来的. 没有 org 则偏移量从 0000h 开始于是虽然整个代码被加载到 0x7c00 处但当执行到 mov ax, BootMessage 一句时候由于没有算入偏移量 7c00 从而没有将 BootMessage 字符串首地址放入 ax 以至于发生错误.

ndisasm -o 0x0000 boot.bin >> disboot1.asm 所得到的汇编文件

ndisasm –o 0x7c00 boot.bin >> disboot2.asm 所得到的汇编文件


disboot1.asm 内容:

```
00000000  8CC8              mov ax,cs
00000002  8ED8              mov ds,ax
00000004  8EC0              mov es,ax
00000006  E80200            call word 0xb
00000009  EBFE              jmp short 0x9
0000000B  B81E7C            mov ax,0x7c1e
0000000E  89C5              mov bp,ax
00000010  B91000            mov cx,0x10
00000013  B80113            mov ax,0x1301
00000016  BB0C00            mov bx,0xc
00000019  B200              mov dl,0x0
0000001B  CD10              int 0x10
0000001D  C3                ret
0000001E  48                dec ax
0000001F  656C              gs insb
00000021  6C                insb
00000022  6F                outsw
00000023  2C20              sub al,0x20
00000025  4F                dec di
00000026  53                push bx
00000027  20776F            and [bx+0x6f],dh
0000002A  726C              jc 0x98
0000002C  642100            and [fs:bx+si],ax
0000002F  0000              add [bx+si],al
00000031  0000              add [bx+si],al
···
000001F9  0000              add [bx+si],al
000001FB  0000              add [bx+si],al
000001FD  0055AA            add [di-0x56],dl
```

disboot2.asm 内容:

```
00007C00  8CC8              mov ax,cs
00007C02  8ED8              mov ds,ax
00007C04  8EC0              mov es,ax
00007C06  E80200            call word 0x7c0b
00007C09  EBFE              jmp short 0x7c09
00007C0B  B81E7C            mov ax,0x7c1e
00007C0E  89C5              mov bp,ax
00007C10  B91000            mov cx,0x10
00007C13  B80113            mov ax,0x1301
00007C16  BB0C00            mov bx,0xc
00007C19  B200              mov dl,0x0
00007C1B  CD10              int 0x10
00007C1D  C3                ret
00007C1E  48                dec ax
00007C1F  656C              gs insb
00007C21  6C                insb
00007C22  6F                outsw
00007C23  2C20              sub al,0x20
00007C25  4F                dec di
00007C26  53                push bx
00007C27  20776F            and [bx+0x6f],dh
00007C2A  726C              jc 0x7c98
00007C2C  642100            and [fs:bx+si],ax
00007C2F  0000              add [bx+si],al
00007C31  0000              add [bx+si],al
···
00007DF9  0000              add [bx+si],al
00007DFB  0000              add [bx+si],al
00007DFD  0055AA            add [di-0x56],dl
```

通过反汇编模拟了引导程序被加载到 0000: 0000 处和 0000: 7c00 处时的不同情形. 第一次为 0000: 0000 第二次为 0000: 7C00. 而对于 mov ax,BootMessage 一句的翻译却是一样的都是 mov ax,0x7c1e . 显然第一次发生了错误(因为在整个程序中就没有出现 0x7c1e 这个地址也就是说这是个无效地址). 错误产生的原因就是由于当代码被编译器编译的时候编译器是按照从 7c00 处开始计算地址的. 也证明了 BootMessage 的地址是由编译器计算出来的.