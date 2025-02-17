
Rust 会使用 DWARF 格式在 binary 中嵌入调试信息, 所以可以使用一些通用的调试工具, 比如 GDB 和 LLDB. Rust 提供了 `rust-gdb` 和 `rust-lldb` 两个命令用于调试, 其相比原生的 gdb 和 lldb 添加了一些方便调试的脚本

下面来初步的了解 rust-lldb 的使用, rustup 会安装 rust-lldb, 但不会安装 lldb, 需要自行安装

```
apt install lldb
```

LLDB 的命令结构如下

```
<noun> <verb> [-options [option-value]] [argument [argument...]]
```

本文用的代码:

```rust
fn binary_search(nums: Vec<i32>, target: i32) -> i32 {
    let mut size = nums.len();

    if size == 0 {
        return -1;
    }

    let mut base = 0usize;

    while size > 1 {
        let half = size / 2;
        let mid = base + half;

        if nums[mid] <= target {
            base = mid;
        }
        size = size - half;
    }

    if nums[base] == target {
        return base as i32;
    }
    return -1;
}


fn main() {
    assert_eq!(binary_search(vec![1, 4, 7, 10, 16, 19], 10), 3);
}
```

cargo build 默认会以 debug 模式进行构建, 所以含有用于调试的 symbol, 需要注意的是 `cargo install` 会以 release 模式构建, 需要 `cargo install --debug`

通过 rust-lldb 命令加载可执行文件(或者在 REPL 中通过 file 载入), 进入 LLDB 的 REPL. 比如

`rust-lldb -- target/debug/<bin-name> first_arg`

启动时会显示

```
(lldb) settings set -- target.run-args  "first_arg"
```

字样, 参数会存到 `target.run-args` 中, 可以在 REPL 中重置命令行参数

```
(lldb) settings set target.run-args "arg1"
(lldb) settings show target.run-args
target.run-args (array of strings) =
  [0]: "arg1"
(lldb) settings append target.run-args "arg2"
(lldb) settings show target.run-args
target.run-args (array of strings) =
  [0]: "arg1"
  [1]: "arg2"
```

gui 命令可以进入 GUI, 可以借助 [voltron](https://github.com/snare/voltron) 获得更改的体验

通过 b 命令来设置断点. b 命令是对于 GDB 中 break 命令的模拟, 通过 `help b` 查看更多用法

```
(lldb) help b
Set a breakpoint using one of several shorthand formats.  Expects 'raw' input (see 'help raw-input'.)

Syntax:
_regexp-break <filename>:<linenum>:<colnum>
              main.c:12:21          // Break at line 12 and column 21 of main.c

_regexp-break <filename>:<linenum>
              main.c:12             // Break at line 12 of main.c

_regexp-break <linenum>
              12                    // Break at line 12 of current file

_regexp-break 0x<address>
              0x1234000             // Break at address 0x1234000

_regexp-break <name>
              main                  // Break in 'main' after the prologue

_regexp-break &<name>
              &main                 // Break at first instruction in 'main'

_regexp-break <module>`<name>
              libc.so`malloc        // Break in 'malloc' from 'libc.so'

_regexp-break /<source-regex>/
              /break here/          // Break on source lines in current file
                                    // containing text 'break here'.


'b' is an abbreviation for '_regexp-break'
```


b 命令并**不是 LLDB 中的 breakpoint 的 alias**. `breakpoint set -n <func name>` 设置支持补全, `breakpoint set -f <文件路径>--line 15` 在指定的行设置断点

```
(lldb) b binary_search
Breakpoint 1: where = b`b::binary_search::hcb6e4fa332e0db67 + 13 at main.rs:2, address = 0x00000000000049bd
(lldb) b
Current breakpoints:
1: name = 'binary_search', locations = 1
  1.1: where = b`b::binary_search::hcb6e4fa332e0db67 + 13 at main.rs:2, address = b[0x00000000000049bd], unresolved, hit count = 0

2: name = 'binary_s', locations = 0 (pending)

3: name = 'binary_search', locations = 1
  3.1: where = b`b::binary_search::hcb6e4fa332e0db67 + 13 at main.rs:2, address = b[0x00000000000049bd], unresolved, hit count = 0
(lldb) breakpoint delete 2
1 breakpoints deleted; 0 breakpoint locations disabled.
```

通过 r 命令来运行程序

```
(lldb) r
There is a running process, kill it and restart?: [Y/n] y
Process 12494 launched: '/root/T/b/target/debug/b' (x86_64)
Process 12494 stopped
* thread #1, name = 'b', stop reason = breakpoint 1.1
    frame #0: 0x00005555555589bd b`b::binary_search::hcb6e4fa332e0db67(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:2
   1    fn binary_search(nums: Vec<i32>, target: i32) -> i32 {
-> 2        let mut size = nums.len();
   3
   4        if size == 0 {
   5            return -1;
   6        }
   7
```

通过 frame variable 可以看到当前栈中的变量

```
(lldb) frame variable
(alloc::vec::Vec<int>) nums = vec![1, 4, 7, 10, 16, 19]
(int) target = 10
```

通过 n 进行单步调试

```
(lldb) n
Process 20123 stopped
* thread #1, name = 'b', stop reason = step over
    frame #0: 0x00005555555589df b`b::binary_search::hcb6e4fa332e0db67(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:4
   1    fn binary_search(nums: Vec<i32>, target: i32) -> i32 {
   2        let mut size = nums.len();
   3
-> 4        if size == 0 {
   5            return -1;
   6        }
   7
(lldb) frame variable
(alloc::vec::Vec<int>) nums = vec![1, 4, 7, 10, 16, 19]
(int) target = 10
(unsigned long) size = 6
```

这都是模拟的 GDB 的命令族. LLDB 原生的则是

```
(lldb) thread select id
(lldb) thread step-in    // The same as gdb's "step" or "s"
(lldb) thread step-over  // The same as gdb's "next" or "n"
(lldb) thread step-out   // The same as gdb's "finish" or "f"
```

在断点处可以设置命令, 比如直接打印堆栈

```
(lldb) breakpoint command add 1
Enter your debugger command(s). Type 'DONE' to end.
> bt
> DONE
```

也可以直接通过 --command 参数设置

一个小例子, 在 half == 3 条件成立的时候打印堆栈信息

```
(lldb) list main.rs:10
   10
   11       while size > 1 {
   12           let half = size / 2;
   13           let mid = base + half;
   14
   15           if nums[mid] <= target {
   16               base = mid;
   17           }
   18           size = size - half;
   19       }
   20
(lldb) breakpoint set -c "half == 3" -f main.rs -l 13 -C bt
Breakpoint 1: where = b`b::binary_search::hfce4ad2766a2fe8f + 166 at main.rs:13, address = 0x0000000000004a56
(lldb) r
Process 31253 launched: '/root/T/b/target/debug/b' (x86_64)
(lldb)  bt
* thread #1, name = 'b', stop reason = breakpoint 1.1
  * frame #0: 0x0000555555558a56 b`b::binary_search::hfce4ad2766a2fe8f(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:13
    frame #1: 0x0000555555558b90 b`b::main::he42792ea9d7cc77a at main.rs:29
    frame #2: 0x00005555555582c0 b`std::rt::lang_start::_$u7b$$u7b$closure$u7d$$u7d$::h36f6beb6917ae1e7 at rt.rs:74
    frame #3: 0x0000555555561743 b`std::panicking::try::do_call::h4f8262c35e4e88a2 [inlined] std::rt::lang_start_internal::_$u7b$$u7b$closure$u7d$$u7d$::h10f59d0290367560 at rt.rs:59
    frame #4: 0x0000555555561737 b`std::panicking::try::do_call::h4f8262c35e4e88a2 at panicking.rs:307
    frame #5: 0x000055555556ebfa b`__rust_maybe_catch_panic at lib.rs:102
    frame #6: 0x0000555555562246 b`std::rt::lang_start_internal::ha81f57a8465b4dcb [inlined] std::panicking::try::h8abdfbcaa376c6de at panicking.rs:286
    frame #7: 0x000055555556220b b`std::rt::lang_start_internal::ha81f57a8465b4dcb [inlined] std::panic::catch_unwind::hcc1db352380c01f1 at panic.rs:398
    frame #8: 0x000055555556220b b`std::rt::lang_start_internal::ha81f57a8465b4dcb at rt.rs:58
    frame #9: 0x0000555555558299 b`std::rt::lang_start::h1bce8d1d740917a0(main=&0x555555558b30, argc=1, argv=&0x7fffffffe3c8) at rt.rs:74
    frame #10: 0x0000555555558f1a b`main + 42
    frame #11: 0x00007ffff7dc9223 libc.so.6`__libc_start_main + 243
    frame #12: 0x000055555555817e b`_start + 46

Process 31253 stopped
* thread #1, name = 'b', stop reason = breakpoint 1.1
    frame #0: 0x0000555555558a56 b`b::binary_search::hfce4ad2766a2fe8f(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:13
   10
   11       while size > 1 {
   12           let half = size / 2;
-> 13           let mid = base + half;
   14
   15           if nums[mid] <= target {
   16               base = mid;
```

可以通过 watch 来监控变量的变化

```
(lldb) list main.rs:10
   10
   11       while size > 1 {
   12           let half = size / 2;
   13           let mid = base + half;
   14
   15           if nums[mid] <= target {
   16               base = mid;
   17           }
   18           size = size - half;
   19       }
   20
(lldb) breakpoint set -f main.rs -l 11
Breakpoint 1: where = b`b::binary_search::hfce4ad2766a2fe8f + 88 at main.rs:11, address = 0x0000000000004a08
(lldb) r
Process 1997 launched: '/root/T/b/target/debug/b' (x86_64)
Process 1997 stopped
* thread #1, name = 'b', stop reason = breakpoint 1.1
    frame #0: 0x0000555555558a08 b`b::binary_search::hfce4ad2766a2fe8f(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:11
   8
   9        let mut base = 0usize;
   10
-> 11       while size > 1 {
   12           let half = size / 2;
   13           let mid = base + half;
   14
(lldb) watch set var base
Watchpoint created: Watchpoint 1: addr = 0x7fffffffdec0 size = 8 state = enabled type = w
    declare @ '/root/T/b/src/main.rs:9'
    watchpoint spec = 'base'
    new value: 0
(lldb) c
Process 1997 resuming

Watchpoint 1 hit:
old value: 0
new value: 3
Process 1997 stopped
* thread #1, name = 'b', stop reason = watchpoint 1
    frame #0: 0x0000555555558aa8 b`b::binary_search::hfce4ad2766a2fe8f(nums=vec![1, 4, 7, 10, 16, 19], target=10) at main.rs:18
   15           if nums[mid] <= target {
   16               base = mid;
   17           }
-> 18           size = size - half;
   19       }
   20
   21       if nums[base] == target {
```

expr 命令可以对表达式求值

```
lldb) frame variable
(unsigned long) size = 24
(unsigned long) align = 4
(lldb) expr size == 24
(bool) $0 = true
```

# reference

https://blockchain-fans.blog.csdn.net/article/details/119360032

LLDB Tutorial: https://lldb.llvm.org/use/tutorial.html