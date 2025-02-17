
方法一:

for i in {1..10}; do echo "Hello, World"; done

方法二

在`~/.bashrc`文件中创建一个 run 函数(函数名字随意):

```sh
function run() {
    number=$1
    shift
    for n in $(seq $number); do
      $@
    echo ""
    echo "------------ $n end ----------------"
    done
}
```

使`./bashrc`生效

```
souce ~/./bashrc
```

示例

```
run 10 echo "Hello, World"
```