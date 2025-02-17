为什么从 u64 到 usize 的类型转换允许使用 `as` 而不是 `From`?
[英] Why is type conversion from u64 to usize allowed using `as` but not `From`?
查看: 21 发布时间: 2022/1/13 8:15:53 rust type-conversion numbers
本文介绍了为什么从 u64 到 usize 的类型转换允许使用 `as` 而不是 `From`?的处理方法, 对大家解决问题具有一定的参考价值, 需要的朋友们下面随着小编来一起学习吧！
问题描述
使用 'as' 的第一个转换可以编译, 但使用 'From' 特征的第二个转换不会:

fn main() {
    let a: u64 = 5;
    let b = a as usize;
    let b = usize::from(a);
}
使用 Rust 1.34.0, 我收到以下错误:

```
error[E0277]: the trait bound `usize: std::convert::From<u64>` is not satisfied
 --> src/main.rs:4:13
  |
4 |     let b = usize::from(a);
  |             ^^^^^^^^^^^ the trait `std::convert::From<u64>` is not implemented for `usize`
  |
  = help: the following implementations were found:
            <usize as std::convert::From<bool>>
            <usize as std::convert::From<std::num::NonZeroUsize>>
            <usize as std::convert::From<u16>>
            <usize as std::convert::From<u8>>
  = note: required by `std::convert::From::from`
```

当我将 u64 替换为 u8 时, 不再出现错误.从错误消息中, 我了解到 From 特征仅适用于 u8, 而不适用于其他整数类型.

如果有充分的理由, 那么为什么使用 'as' 的转换也不应该编译失败?

推荐答案

as 转换与 From 转换有着根本的不同. From 转换是简单 且安全的", 而 as 转换纯粹是安全的".考虑数字类型时, From 转换仅在保证输出相同 时存在, 即没有信息丢失(没有截断或地板或精度损失).但是, as 类型转换没有这个限制.

引用文档,

[usize] 的大小是引用内存中任何位置需要多少字节.例如, 在 32 位目标上, 这是 4 个字节, 而在 64 位目标上, 这是 8 个字节."

由于大小取决于目标架构, 并且无法在编译前确定, 因此无法保证数字类型和 usize 之间的 From 转换是可能的.但是, as 转换将始终按照列出的规则运行 这里.

例如, 在 32 位系统上, usize 等价于 u32.由于 usize 小于 u64, 因此在将 u64 转换为 usize<时可能会丢失信息(截断)/code>, 因此 From 转换不存在.但是, usize 的大小始终保证为 8 位或更大, 并且 u8 到 usize From 转换永远存在.


https://stackoverflow.com/questions/47786322/why-is-type-conversion-from-u64-to-usize-allowed-using-as-but-not-from