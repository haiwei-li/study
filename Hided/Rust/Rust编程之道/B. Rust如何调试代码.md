
# print debug

使用 `println!("{:?}", variable);`

```rust
pub fn main() {
	let test = vec![100, 101, 102, 103];
	println!("{:?}", test);
}
```

```
[100, 101, 102, 103]
```

利用 `{:?}` 打印 struct, 需要添加 debug 属性:

```rust
pub fn main() {
	let test = Person { name: "test", age: 20 };
	println!("{:?}", test);
}

#[derive(Debug)]	// Add this
struct Person<'a> {
	name: &'a str,
	age: u8
}
```

```
Person { name: "test", age: 20 }
```

对于 enum 也是:

```rust
pub fn main() {
    let test = Fruits::Apple("ringo".to_string());
    println!("{:?}", test);
}

#[derive(Debug)] // Add this.
enum Fruits {
    Apple(String),
    Grape(String),
    Orange(String)
}
```

```
Apple("ringo")
```

# dbg! 宏

Rust 1.32.0 引入. 这将打印操作所在的文件和行数.

```rust
pub fn main() {
    let people = [
        Person { name: "test1", age: 20 },
        Person { name: "test2", age: 25 },
        Person { name: "test3", age: 30 },
    ];
    dbg!(&people);
}

#[derive(Debug)]
struct Person<'a> {
    name: &'a str,
    age: u8
}
```

```
[debug.rs:7] &people = [
    Person {
        name: "test1",
        age: 20,
    },
    Person {
        name: "test2",
        age: 25,
    },
    Person {
        name: "test3",
        age: 30,
    },
]
```

# Print debug info only in debug build


# Use breakpoints in VSCode


# debug with rust-lldb

见 `.\Debug\rust-lldb.md`


# reference

https://dev.to/lechatthecat/how-to-debug-rust-program-1c4i