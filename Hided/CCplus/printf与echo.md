第一种情况: 

```
void main(){
    printf("hello");
}

# gcc return.c

#./a.out
hello

# echo $?
5

# gcc -S return.c

	.file	"return.c"
	.section	.rodata
.LC0:
	.string	"hello"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$.LC0, %edi
	movl	$0, %eax
	call	printf
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.9) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
```

第二种情况

```
int main(){
    return 0;
}

# gcc return.c

# ./a.out

# echo $?
0

# gcc -S return.c

	.file	"return.c"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	movl	$0, %eax
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.9) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
```

第三种情况

```
int main(){
    printf("hello");
    return -1;
}

# gcc return.c

# ./a.out
hello

# echo $?
255
```

第四种情况

```
int main(){
    printf("hello");
    return 2;
}

# gcc return.c

# ./a.out
hello

# echo $?
2
```

第五种情况

```
void main(){
}

# gcc return.c

# ./a.out

# echo $?
214

# gcc -S return.c

# cat return.s

	.file	"return.c"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	nop
	popq	%rbp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (Ubuntu 5.4.0-6ubuntu1~16.04.9) 5.4.0 20160609"
	.section	.note.GNU-stack,"",@progbits
```

当一个进程执行完毕时, 该进程会调用一个名为 \_exit 的例程来通知内核它已经做好"消亡"的准备了. 该进程会提供一个退出码(一个整数)表明它准备退出的原因. 按照惯例, 0用来表示正常的或者说"成功"的终止. Linux本身调用程序后会自动加上\_exit调用, 传递的参数是程序返回值(也就是eax/rax寄存器值). 

也就是说我们在执行 echo $? 时反回的值就是进程的退出码. 而且, 这个退出码是由刚刚执行完的进程提供给系统内核的. 

反编译成汇编后, 无论32位还是64位, 都是汇编代码执行完以后返回值(eax寄存器或rax寄存器值). 对于第一个void main, 因为没有返回值, 而printf函数会有返回值(该返回值存放在rax寄存器中), 后续rax寄存器没有使用, 所以当main执行完以后, rax寄存器值还是printf返回值(也就是打印的字符个数). 然后调用\_exit, 将rax值作为参数. 

总而言之, 一个程序的返回值其实取决于其二进制可执行程序返回值. 将可执行文件反汇编后, 可以看到整个逻辑. Linux在每个程序执行完了后, 都需要进行系统调用退出. 32位系统通过int 0x80调用内核功能, 通过指定eax值说明系统调用功能号(sys\_exit是1), ebx值是退出代码; 64位系统通过syscall调用内核功能, 通过指定rax值说明系统调用功能号(sys\_exit是60), rdi值是退出代码(等于程序返回值, 也就是rax寄存器值). 详细见汇编部分知识. 

这里的返回值就是指rdi/ebx寄存器值, 这个值可能由程序本身代码实现设置(比如C语言的函数return会设置该值, 也就是rax寄存器值), 可能被编译器封装设置了寄存器(没有return的执行程序编译器可能有默认设置), 也有可能是之前系统运行产生的随机值. 