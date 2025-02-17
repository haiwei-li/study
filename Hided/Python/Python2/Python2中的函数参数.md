# Python2中的函数参数

> 
原文: [点击进入](http://www.liaoxuefeng.com/wiki/001374738125095c955c1e6d8bb493182103fac9270762a000/001374738449338c8a122a7f2e047899fc162f4a7205ea3000 "廖雪峰的网站")  
作者: 廖雪峰  

---
默认参数
----

 - 必选参数必须在前, 默认参数在后. 
 - 设置参数: 当函数有多个参数时候, 把变化大的参数放前面, 变化小的参数放后面. 变化小的参数可以作为默认参数. 

下面看一个例子: 
```
def add_end(L=[]):
　　L.append('END')
　　return L
``` 
当正常调用: 
```
1. add_end([1, 2, 3])
　　[1, 2, 3, 'END']
2. add_end(['x', 'y', 'z'])
　　['x', 'y', 'z', 'END']
```
当你使用默认参数调用时候, 一开始结果也是对的: 
```
add_end()
　　['END']
```
但是当再次调用时候, 结果就不对了: 
```
1. add_end()
['END', 'END']
2. add_end()
['END', 'END', 'END']
```
原因解释如下: 

Python函数在定义时候, 默认参数L的值就被计算出来了, 即[], 因为默认参数L也是一个变量, 它指向对象[], 每次调用该函数, 如果改变了L的内容, 则下次调用时, 默认参数的内容就变了, 不再是函数定义时候的[]了. 
所以, 定义默认参数要牢记一点: 默认参数必须指向不变对象. 


----------

可变参数
----
以数学题为例, 给定一组数字a,b,c..., 计算a*a+b*b+c*c

 - 首先想到可以把a,b,c...作为一个list或tuple传进来
```
def calc(numbers):
　　sum = 0
　　for n in numbers:
　　　　sum = sum + n * n
　　return sum  
```
但是调用的时候, 需要组装一个list或tuple:   
```
calc([1,2,3])
　　14
calc((1,3,5,7))
　　84
```
 - 如果利用可变参数, 调用函数的方式可以简化成这样: 
``` 
calc(1,2,3)
　　14
calc(1,3,5,7)
　　84  
```  
所以, 我们把函数的参数改为可变参数: 
```
def calc(*numbers):
　　sum = 0
　　for n in numbers:
　　　　sum = sum + n * n
　　return sum
```
定义可变参数和定义list或tuple参数相比, 仅仅在参数前面加一个*号. **在函数内部, 参数numbers接收到的是一个tuple**, 因此, 函数代码完全不变. 但是, 调用该函数时, 可以传入任意个参数, 包括0个.   
```
calc(1,2)
　　5
calc()
　　0
```
如果已经有一个list或tuple, 要调用一个可变参数怎么办?可以这样做:   
```
nums = [1, 2, 3]
calc(*nums)
　　14  
```
这种写法相当有用, 而且很常见. 

关键字参数
----
可变参数允许你传入0个或任意个参数, 这些可变参数在函数调用时自动组装为一个tuple. 而关键字参数允许你传入0个或任意个含参数名的参数, 这些关键字参数在函数内部自动组装成一个dict. 请看示例:   
```
def person(name, age, **kw):
　　print 'name:', name, 'age:', age, 'other:', kw
```
函数person除了必须按参数name和age外, 还接受关键字参数kw. 在调用该函数时候, 可以只传入必选参数: 
```
person('Michael', 30)
　　name:Michael age:30 other:{}
```
也可以传入任意个数的关键字参数: 
```
>>> person('Bob', 35, city='Beijing')
name: Bob age: 35 other: {'city': 'Beijing'}
>>> person('Adam', 45, gender='M', job='Engineer')
name: Adam age: 45 other: {'gender': 'M', 'job': 'Engineer'}
```
关键参数有什么用?它可以扩展函数的功能. 比如, 在person函数里, 我们保证能接受到name和age这两个参数, 但是, 如果调用者愿意提供更多的参数, 我们也能收到. 试想, 你正在做用户注册的功能, 除了用户名和年龄是必填项, 其他都是可选项, 利用关键字参数来定义这个函数就能满足注册的需求. 
和可变参数类似, 也可以先组装一个dict, 然后, 把该dict转换成关键字参数传进去: 
```
>>> kw = {'city': 'Beijing', 'job': 'Engineer'}
>>> person('Jack', 24, city=kw['city'], job=kw['job'])
name: Jack age: 24 other: {'city': 'Beijing', 'job': 'Engineer'}
```
当然, 上面复杂的调用可以用简化的写法: 
```
>>> kw = {'city': 'Beijing', 'job': 'Engineer'}
>>> person('Jack', 24, **kw)
name: Jack age: 24 other: {'city': 'Beijing', 'job': 'Engineer'}
```
参数组合
----
在Python中定义函数, 可以使用必选参数、默认参数、可变参数和关键字参数, 这四种可以一起使用或组合使用, 但是参数定义顺序必须是: 必选参数、默认参数、可变参数和关键字参数. 
比如定义一个函数, 包含上述4中参数: 
```
def func(a, b, c=0, *args, **kw):
    print 'a =', a, 'b =', b, 'c =', c, 'args =', args, 'kw =', kw
```
在函数调用时候, Python解释器自动按照参数位置和参数名将对应的参数传进去. 
```
>>> func(1, 2)
a = 1 b = 2 c = 0 args = () kw = {}
>>> func(1, 2, c=3)
a = 1 b = 2 c = 3 args = () kw = {}
>>> func(1, 2, 3, 'a', 'b')
a = 1 b = 2 c = 3 args = ('a', 'b') kw = {}
>>> func(1, 2, 3, 'a', 'b', x=99)
a = 1 b = 2 c = 3 args = ('a', 'b') kw = {'x': 99}
```
最神奇是, 通过一个tuple和dict, 你也可以调用该函数: 
```
>>> args = (1, 2, 3, 4)
>>> kw = {'x': 99}
>>> func(*args, **kw)
a = 1 b = 2 c = 3 args = (4,) kw = {'x': 99}
```
所以, 对于任意函数, 都可以通过类似func(*args, **kw)的形式调用它, 无论它的参数是如何定义的. 
小结
----
- Python的函数具有非常灵活的参数形态, 既可以实现简单的调用, 又可以传入非常复杂的参数. 
- 默认参数一定要用不可变对象, 如果是可变对象, 运行会有逻辑错误. 
- 要注意定义可变参数和关键字参数的语法: 
```
*args是可变参数, args接受的是一个tuple; 
**kw是关键字参数, kw接收的是一个dict. 
```
- 以及调用函数时如何传入可变参数和关键字参数的语法: 
```
可变参数既可以直接传入: func(1, 2, 3),又可以先组装list或tuple, 在通过*args传入: func(*(1, 2, 3))
关键字参数既可以直接传入: func(a-1, b=2), 又可以先组装dict, 通过**kw传入:func(**{'a':1, 'b':2})
注: 使用*args和**kw是Python的习惯用法, 当然也可以用其他参数名, 但最好使用习惯用法
```

参考链接
---
函数对象: https://github.com/Vamei/Python-Tutorial-Vamei/blob/master/content/intermediate07.md  
