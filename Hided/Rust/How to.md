
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. method](#1-method)
- [2. materials](#2-materials)
- [3. Blog](#3-blog)

<!-- /code_chunk_output -->

# 1. method

第一步: 环境搭建

* 查阅 [Rust 官方文档](https://www.rust-lang.org/learn/get-started), 安装配置好 Rust 的开发环境.
* 使用 cargo new hello-world 新建一个 Rust  项目, 并且使用自己喜欢的开发工具打开(VSCode, Clion). 我个人比较喜欢 VSCode + Docker 用配置 [devcontainer](https://code.visualstudio.com/docs/remote/containers) 的方式学习一门新的编程语言, 这样的好处是可以不用考虑容器之外的开发环境, 做到最高效、不踩坑.

第二步: Cargo 学习

* 不要急于求成, 先熟悉编程语言"周边工具", 这样可以大大提高你学习和使用 Rust 的效率. 我推荐先去熟悉 cargo: Rust 的项目和依赖管理工具. 具体的方法是直接看一本叫做 [The Cargo Book](https://doc.rust-lang.org/cargo/index.html) 的书籍.
* 看 The Cargo Book 的同时在自己配置好的开发环境里面尝试使用 cargo , 通过实践来学习 `cargo.toml` 的作用和写法, 命令, 理解为什么 `cargo.lock` 在工程作为一个 lib 的时候要加入 `.gitignore`, 而作为 command-line application 的时候又要加入 `.git`这类的东西.

第三步: Rust 语言学习

* 到了这一步才真正开始 Rust 的学习, 关于任何编程语言的学习, 都是从阅读官方文档开始. Rust 社区发行了一个简明的开源教程: [The Rust Programming Language](https://doc.rust-lang.org/book/#the-rust-programming-language) / [中文版](https://rustwiki.org/zh-CN/book/), 强烈推荐阅读.
* 如果不太适应英文教材的阅读, 可以看这本书的中文翻译版本: [Rust 程序设计语言(第二版 & 2018 edition)简体中文版](https://kaisery.gitbooks.io/trpl-zh-cn/content/).
* 在阅读官方文档的时候, 就可以根据上述的进行一些编程练习了. 不过 Rust 的**官方文档**相对于其他编程语言文档来说, 比较注重的是 Rust 的**几个编程特性**: 零成本抽象, 所有权特性等, 在阅读这些的时候不推荐自己瞎写练习, 应该对比阅读文档和其他的开源 Rust 代码.
* 推荐辅助阅读张汉东的《Rust 编程之道》
* 关注 Rust 几个重要的特性, 如 ownership, borrowing, lifetimes 等, 这三节请看官方一手资料, 别看博客: [Ownership](https://doc.rust-lang.org/book/ownership.html)

[The book](https://github.com/rust-lang/book), 中文翻译: [The book](https://github.com/KaiserY/rust-book-chinese)

第四步: Rust 编程练习

* 在充分感受 Rust 的编程范式以后, 应该进入一定量的练习阶段.
* 这个时候推荐学习的材料是: [Rust by Example](https://doc.rust-lang.org/rust-by-example/) / [中文版](https://rustwiki.org/zh-CN/rust-by-example/index.html), 直接通过在线修改代码阅读样例来学习.
* 快速过一遍 Rust by Example 之后, 相信现在至少可以开始上手写一些 Rust 代码了, 个人喜欢把以前的一些小项目用新学习的编程语言重写, 例如实现一个最简单的 DBMS, 通过这样的行为不仅可以加深对新学语言的熟练度, 还可以通过与原有实现的对比, 感受 Rust 语言特性.
* 有系列文章叫 [Learning Rust With Entirely Too Many Linked Lists](https://rust-unofficial.github.io/too-many-lists/) 非常推荐. 写的很有趣也很实用.

第五步: 进阶提高

* 之后主要通过项目练手, 阅读开源代码, 逐步提高.
* 多留意 Rust 标准库中处理并发和同步的一些使用和具体实现会很有帮助.
* Rust 代码和资料的精选列表: [Awesome Rust](https://github.com/rust-unofficial/awesome-rust) , 汇集了 Github 上几乎全部的优秀 Rust 开源项目. 举例几个有名的项目: Mozilla 的 Servo 浏览器引擎, AWS 的 Firecracker MicroVM, Web 框架 actix-web, 当然还有最近 Facebook 发布的 Libra.
* Rust 语言 Cheat Sheet(各种很全的资料): https://cheats.rs/

# 2. materials

RFC: https://rust-lang.github.io/rfcs/

官方快速配置 Rust 开发环境并编写一个小应用！: [Getting started](https://www.rust-lang.org/learn/get-started)

Cargo 书籍: [The Cargo Book](https://doc.rust-lang.org/cargo/index.html)

在线执行 Rust: [Playground](https://play.rust-lang.org/)

Rust 语言 Cheat Sheet(各种很全的资料): https://cheats.rs/

官方入门书籍: [The book](https://doc.rust-lang.org/book/), [中文版](https://kaisery.github.io/trpl-zh-cn/)

[Rust 编程之道](https://book.douban.com/subject/30418895/), 作者 https://github.com/ZhangHanDong

通过一系列代码示例, 用于说明各种 Rust 概念和标准库: [Rust by Example](https://doc.rust-lang.org/stable/rust-by-example/), [中文版](https://rustwiki.org/zh-CN/rust-by-example/)

通过多个链表例子教会你 Rust 基本和高级编程: https://rust-unofficial.github.io/too-many-lists/

Rust 代码和资料的精选列表: [Awesome Rust](https://github.com/rust-unofficial/awesome-rust) , 汇集了 Github 上几乎全部的优秀 Rust 开源项目. 举例几个有名的项目: Mozilla 的 Servo 浏览器引擎, AWS 的 Firecracker MicroVM, Web 框架 actix-web, 当然还有最近 Facebook 发布的 Libra.

有些关键的概念, 如 ownership, borrowing, lifetimes 这三节请看官方一手资料, 别看博客:
[Ownership](https://doc.rust-lang.org/book/ownership.html)

Rust 中的异步编程: https://huangjj27.github.io/async-book/01_getting_started/01_chapter.html

# 3. Blog

Rust 实战 - 使用套接字联网 API: https://segmentfault.com/a/1190000018864788

Rust 学习之 Some、Option、Result: https://blog.vgot.net/archives/rust-some.html


为什么 Rust 标准库的 TreeMap 采用 B+树实现, 而不是常用的红黑树? - NecoKeine 的回答 - 知乎
https://www.zhihu.com/question/516912481/answer/2350931515

