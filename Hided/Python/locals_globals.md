# local, global and free variable

> 
参考: 
http://www.cnblogs.com/wanxsb/archive/2013/05/07/3064783.html
http://www.jianshu.com/p/e1fd4f14136a

Python有两个内置的函数, locals() 和globals(), 它们提供了基于字典的访问局部和全局变量的方式. 

Python使用叫做名字空间的东西来记录变量的轨迹. 名字空间只是一个字典, 它的键字就是变量名, 字典的值就是那些变量的值. 实际上, 名字空间可以象Python的字典一样进行访问, 一会我们就会看到. 

在一个Python程序中的任何一个地方, 都存在几个可用的名字空间. 每个函数都有着自已的名字空间, 叫做局部名字空间, 它记录了函数的变量, 包括函数的参数和局部定义的变量. 每个模块拥有它自已的名字空间, 叫做全局名字空间, 它记录了模块的变量, 包括函数、类、其它导入的模块、模块级的变量和常量. 还有就是内置名字空间, 任何模块均可访问它, 它存放着内置的函数和异常. 

Python的作用域解析是基于叫做LEGB(Local(本地), Enclosing(封闭), Global(全局), Built-in(内置))的规则进行操作的. 

当一行代码要使用变量 x 的值时, Python会到所有可用的名字空间去查找变量, 按照如下顺序: 

- 局部名字空间 - 特指当前函数或类的方法. 如果函数定义了一个局部变量x, Python将使用这个变量, 然后停止搜索. 
- 全局名字空间 - 特指当前的模块. 如果模块定义了一个名为x的变量, 函数或类, Python将使用这个变量然后停止搜索. 
- 内置名字空间 - 对每个模块都是全局的. 作为最后的尝试, Python将假设 x 是内置函数或变量. 

如果Python在这些名字空间找不到 x, 它将放弃查找并引发一个 NameError 的异常, 同时传 递 There is no variable named 'x' 这样一条信息

像Python中的许多事情一样, 名字空间在运行时直接可以访问. 特别地, 局部名字空间可以通过内置的 locals 函数来访问. 全局(模块级别)名字空间可以通过 globals 函数来访问. 

### 理解 global and local variable

```
>>>
>>> var = 'outer val'
>>> def func1():
...     var = 'inner val'
...     print "Inside func1(), val: ", var
...     print "locals(): ", locals()
...     print "globals(): ", globals()
...
>>> func1()
Inside func1(), val:  inner val
locals():  {'var': 'inner val'}
globals():  {'func1': <function func1 at 0x10a20b938>, '__builtins__': <module '__builtin__' (built-in)>, '__package__': None, 'var': 'outer val', '__name__': '__main__', '__doc__': None}
>>>
>>> print "var: ", var
var:  outer val
>>>
```

在func1内部, var的值为"inner val", 离开了函数, 其值又变成了"outer val", 为什么?看看输出的本地和全局变量列表答案就明显了, var既出现在本地变量列表, 又出现在全局变量列表, 但绑定的值不一样, 因为他们本就是两个不同的变量. 也就是说, **当你想在子代码块中对某个全局变量重新赋值时(不算使用), 实际上你只是定义了一个同名的本地变量, 这并不会改变全局变量的值**. 

对于Python2而言, 对于一个全局变量, 你的函数里如果只使用到了它的值, 而没有对其赋值(指a = XXX这种写法)的话, 就不需要声明global. 相反, 如果你对其赋了值的话, 那么你就需要声明global. 声明global的话, 就表示你是在向一个全局变量赋值, 而不是在向一个局部变量赋值. 

```
>>> x = 10
>>> def foo():
...     x += 1
...     print x
...
>>> foo()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "<stdin>", line 2, in foo
UnboundLocalError: local variable 'x' referenced before assignment
```

```
This is because when you make an assignment to a variable in a scope, that variable becomes local to that scope and shadows any similarly named variable in the outer scope.
```

**在一个作用域里面给一个变量赋值的时候, Python自动认为这个变量是这个作用域的本地变量, 并屏蔽作用域外的同名的变量. **

如何修改全局变量的值?需要在函数中使用global statement. 先看一例: 

```
>>> def func2():
...     global var2
...     var2 = 'who am i'
...     print "locals(): ", locals()
...     print "globals(): ", globals()
...
>>> func2()
locals():  {}
globals():  {'func2': <function func2 at 0x10a20bd70>, 'func1': <function func1 at 0x10a20b938>, 'var2': 'who am i', '__builtins__': <module '__builtin__' (built-in)>, '__package__': None, '__name__': '__main__', '__doc__': None}
>>>
>>> print var2
who am i
>>>
```

看看输出结果, 发现竟然可以在函数代码块中定义一个全局变量, 太神奇了！因为全局变量的作用域是整个模块, 所以离开了定义函数, 依然可以读取它. 

尝试修改全局变量的值: 

```
>>> global_var = 'outer'
>>> def func3():
...     global global_var
...     global_var = 'inner'
...     print "locals(): ", locals()
...     print "globals(): ", globals()
...
>>> func3()
locals():  {}
globals():  {'func3': <function func3 at 0x109dce938>, '__builtins__': <module '__builtin__' (built-in)>, 'global_var': 'inner', '__package__': None, '__name__': '__main__', '__doc__': None}
>>>
>>> print global_var
inner
>>>
```

做个总结吧, **要在函数代码块中修改全局变量的值, 就使用global statement声明一个同名的全局变量, 然后就可以修改其值了; 如果事先不存在同名全局变量, 此语句就会定义一个, 即使离开了当前函数也可以使用它**. 

### 理解 global and free variable

来自于python官方文档 [Execution Model](https://docs.python.org/2/reference/executionmodel.html)的解释: 

```
When a name is used in a code block, it is resolved using the nearest enclosing scope. The set of all such scopes visible to a code block is called the block's environment.

If a name is bound in a block, it is a local variable of that block. If a name is bound at the module level, it is a global variable. (The variables of the module code block are local and global.) If a variable is used in a code block but not defined there, it is a free variable.
```

对于模块代码块来说, **模块级的变量**就是它的本地变量, 但对于模块中其他更小的代码块来说, 这些变量就是全局的. 那再进一步, 什么是模块级的变量, 是指那些在模块内部, 但在其所有子代码块之外定义的变量吗?用代码验证: 

```
code 4

>>>
>>> global_var = 'global_val'
>>> def showval():
...     local_var = 'local_val'
...     print "before defining inner func, showval.locals(): ", locals()
...     def innerFunc():
...         print "Inside innerFunc, local_var: ", local_var
...         print "innerFunc.locals:", locals()
...     print "after defining inner func, showval.locals(): ", locals()
...     print "showval.globals():", globals()
...     return innerFunc
...
>>> a_func = showval()
before defining inner func, showval.locals():  {'local_var': 'local_val'}
after defining inner func, showval.locals():  {'innerFunc': <function innerFunc at 0x109caed70>, 'local_var': 'local_val'}
showval.globals(): {'__builtins__': <module '__builtin__' (built-in)>, 'global_var': 'global_val', '__package__': None, '__name__': '__main__', '__doc__': None, 'showval': <function showval at 0x109cae938>}
>>>
>>> a_func
<function innerFunc at 0x109caed70>
>>> a_func()
Inside innerFunc, local_var:  local_val
innerFunc.locals: {'local_var': 'local_val'}
>>>
```

变量local_var、函数innerFunc是在函数代码块showval中定义的, 所以它们是该代码块的局部变量. 首次输出globals时, 变量global_var、函数showval在所有子代码块之外定义, 所以它们是当前模块的全局变量. 再次输出globals时, 多了一个全局变量globals. 

注意看, 全局变量中还有: ```__builtins__、__package__、__name__、__doc__```. 这些变量的含义可参考 [python模块的内置方法](http://segmentfault.com/blog/shibingwen/1190000000494023). 

现在来看自由变量, local_var被innerFunc函数使用, 但是并未在其中定义, 所以对于innerFunc代码块来说, 它就是自由变量. 问题来了, 自由变量为什么出现在
innerFunc.locals()的输出结果中?这就需要看看[locals()API文档](https://docs.python.org/2/library/functions.html#locals)了: 

> 
Update and return a dictionary representing the current local symbol table. Free variables are returned by locals() when it is called in function blocks, but not in class blocks.

```
code 5

>>>
>>> global_var = 'foo'
>>> def ex1():
...     local_var = 'bar'
...     print "locals(): ", locals()
...     print global_var
...     print local_var
...     global_var = 'foo2'
...
>>> ex1()
locals():  {'local_var': 'bar'}
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "<stdin>", line 4, in ex1
UnboundLocalError: local variable 'global_var' referenced before assignment
>>>
>>> def ex2():
...     local_var = 'bar'
...     print "locals(): ", locals()
...     print "globals(): ", globals()
...     print global_var
...     print local_var
...
>>> ex2()
locals():  {'local_var': 'bar'}
globals():  {'__builtins__': <module '__builtin__' (built-in)>, 'global_var': 'foo', '__package__': None, 'ex2': <function ex2 at 0x10b91aed8>, 'ex1': <function ex1 at 0x10b91aaa0>, '__name__': '__main__', '__doc__': None}
foo
bar
>>>
```

首先分析输出结果. 执行ex1()函数失败, 原因: UnboundLocalError: local variable 'global_var' referenced before assignment, 意思是global_var这个本地变量还未赋值就被引用了. 等等, global_var怎么是本地变量了?与ex2()函数做个对比, 发现因为有这行代码global_var = 'foo2', 解释器就认为global_var是一个本地变量, 而不是全局变量. 
那最外面定义的global_var到底是本地还是全局变量?看看第二部分的输出, 可以很确定地知道最外面定义的global_var是一个全局变量. 

简单点说, 就是这里存在两个同名的变量, 一个是最外面定义的全局变量global_var, 另一个是函数ex1()中定义的本地变量global_var. 

再等等, 矛盾出现了. 按照之前对自由变量的理解, 在一个代码块中被使用, 但是并未在那儿定义, 外部定义的global_var在函数块ex1()中被使用, 完全符合, 它为什么不是一个自由变量?还是我们对自由变量的理解有问题?

与code 4中确定是自由变量的local_var比较, 发现local_var是一个函数代码块的本地变量, 而code 5中的global_var是一个模块代码块的本地变量. 当local_var被定义它的函数内的嵌套函数使用时, 它就变成了一个自由变量, 此时函数的嵌套就形成了闭包(closure), 可见自由变量的应用场景就是闭包. 
而global_var对模块本身来说它是一个本地变量, 但在模块中的其他代码块中也可以使用它, 所以它同时又是一个全局变量. 

到这儿就可以对自由变量的理解做个总结了: **如果一个变量在函数代码块中定义, 但在其他代码块中被使用, 例如嵌套在外部函数中的闭包函数, 那么它就是自由变量. 注意, 给变量赋值不算是使用该变量, 使用指的是读取变量值, 具体区别后面再详述. **

### 理解 free and local variable

修改全局变量的值需要使用global, 那修改自由变量的值又会如何?先用自然思维方式试试: 

```
>>>
>>> def outerfunc():
...     var = 'free'
...     def innerfunc():
...         var = 'inner'
...         print "Inside innerfunc, var: ", var
...         print "Inside innerfunc, locals(): ", locals()
...     innerfunc()
...     print "var: ", var
...     print "locals(): ", locals()
...
>>> outerfunc()
Inside innerfunc, var:  inner
Inside innerfunc, locals():  {'var': 'inner'}
var:  free
locals():  {'var': 'free', 'innerfunc': <function innerfunc at 0x102cf0410>}
>>>
```

在innerfunc函数中我试图修改自由变量var的值, 结果却发现修改只在innerfunc函数内有效, 离开此函数后其值仍然是"free". 看看输出的outerfunc和innerfunc函数的本地变量列表就知道咋回事儿了. 当你想在闭包函数中对自由变量重新赋值时, 实际上你只是在这里定义了一个本地变量, 这并不会改变自由变量的值. 

那怎样才能修改自由变量的值?在 [Notes on Python variable scope](http://www.saltycrane.com/blog/2008/01/python-variable-scope-notes/) 中找到了两种不错的方式: 

```
class Namespace: pass
def ex7():
    ns = Namespace()
    ns.var = 'foo'
    def inner():
        ns.var = 'bar'
        print 'inside inner, ns.var is ', ns.var
    inner()
    print 'inside outer function, ns.var is ', ns.var
ex7()

# console output
inside inner, ns.var is  bar
inside outer function, ns.var is  bar
```

```
def ex8():
    ex8.var = 'foo'
    def inner():
        ex8.var = 'bar'
        print 'inside inner, ex8.var is ', ex8.var
    inner()
    print 'inside outer function, ex8.var is ', ex8.var
ex8()

# console output
inside inner, ex8.var is  bar
inside outer function, ex8.var is  bar
```

### Python解析

```
def funa():
    print 'a'
    funb()

print globals()
print locals()
funa()


def funb():
    print 'b'
    

output:
{'__builtins__': <module '__builtin__' (built-in)>, '__file__': 'D:/Project/PythonProject/testcode/iport/c.py', '__package__': None, 'funa': <function funa at 0x00000000027659E8>, '__name__': '__main__', '__doc__': None}
{'__builtins__': <module '__builtin__' (built-in)>, '__file__': 'D:/Project/PythonProject/testcode/iport/c.py', '__package__': None, 'funa': <function funa at 0x00000000027659E8>, '__name__': '__main__', '__doc__': None}
a
Traceback (most recent call last):
  File "D:/Project/PythonProject/testcode/iport/c.py", line 7, in <module>
    funa()
  File "D:/Project/PythonProject/testcode/iport/c.py", line 3, in funa
    funb()
NameError: global name 'funb' is not defined
```

Python是一个解析性语言, 所以globals和locals都是一步一步加载进去. 当你使用一个变量时候, 在全局变量、局部变量、内置变量找不到便会报错








