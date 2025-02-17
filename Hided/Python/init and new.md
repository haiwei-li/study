
>
文章来自连接链接: http://www.cnblogs.com/ifantastic/p/3175735.html

python中__new__() 是在新式类中新出现的方法, 它作用在构造方法建造实例之前, 可以这么理解, 在 Python 中存在于类里面的构造方法__init__()负责将类的实例化, 而在__init__()启动之前, 方法__new__() 决定是否要使用该__init__()方法, 因为__new__() 可以调用其他类的构造方法或者直接返回别的对象来作为本类的实例. 

如果将类比喻为工厂, 那么__init__()方法则是该工厂的生产工人, 该方法接受的初始化参数则是生产所需原料, 会按照方法中的语句负责将原料加工成实例以供工厂出货. 而__new__()则是生产部经理, 该方法可以决定是否将原料提供给该生产部工人, 同时它还决定着出货产品是否为该生产部的产品, 因为这名经理可以借该工厂的名义向客户出售完全不是该工厂的产品. 

##### 方法__new__()的特性: 
- 是在类准备将自身实例化时调用. 
- 方法始终都是类的静态方法, 即使没有被加上静态方法装饰器. 
- 类的实例化和它的构造方法通常都是这个样子: 

```
class MyClass(object):
    def __init__(self, *args, **kwargs):
        ...

# 实例化
myclass = MyClass(*args, **kwargs)
```
正如上面所说, 一个类可以有多个位置参数和多个命名参数, 而在实例化开始之后, 在调用__init__()方法之前, Python首先调用__new__()方法: 

```
def __new__(cls, *args, **kwargs):
    ···
```

第一个参数cls是当前正在实例化的类. 

- 如果要得到当前类的实例, 应当在当前类中的__new__()方法语句中调用当前类的父类的__new__()方法. 

例如, 如果当前类是直接继承自object, 那当前类的__new__()方法返回的对象应该为: 

```
def __new__(cls, *args, **kwargs):
    ···
    return object.__new__(cls)
```

##### 注意: 

事实上如果(新式)类中没有重写__new__()方法, 即在定义新式类时没有重新定义__new__()时, Python默认是调用该类的直接父类的__new__()方法来构造该类的实例, 如果该类的父类也没有重写__new__(), 那么将一直按此规矩追溯至object的__new__()方法, 因为object是所有新式类的基类. 

而如果新式类中重写了__new__()方法, 那么你可以自由选择任意一个的其他的新式类(必定要是新式类, 只有新式类必定都有__new__(), 因为所有新式类都是object的后代, 而经典类则没有__new__()方法)的__new__()方法来制造实例, 包括这个新式类的所有前代类和后代类, 只要它们不会造成递归死循环. 具体看以下代码解释: 

```
class Foo(object):
    def __init__(self, *args, **kwargs):
        ...
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls, *args, **kwargs)    

# 以上return等同于 
# return object.__new__(Foo, *args, **kwargs)
# return Stranger.__new__(cls, *args, **kwargs)
# return Child.__new__(cls, *args, **kwargs)

class Child(Foo):
    def __new__(cls, *args, **kwargs):
        return object.__new__(cls, *args, **kwargs)
# 如果Child中没有定义__new__()方法, 那么会自动调用其父类的__new__()方法来制造实例, 即 Foo.__new__(cls, *args, **kwargs). 
# 在任何新式类的__new__()方法, 不能调用自身的__new__()来制造实例, 因为这会造成死循环. 因此必须避免类似以下的写法: 
# 在Foo中避免: return Foo.__new__(cls, *args, **kwargs)或return cls.__new__(cls, *args, **kwargs). Child同理. 
# 使用object或者没有血缘关系的新式类的__new__()是安全的, 但是如果是在有继承关系的两个类之间, 应避免互调造成死循环, 例如:(Foo)return Child.__new__(cls), (Child)return Foo.__new__(cls). 
class Stranger(object):
    ...
# 在制造Stranger实例时, 会自动调用 object.__new__(cls)
```

- 通常来说, 新式类开始实例化时, 方法__new__()会返回cls(cls指代当前类)的实例, 然后该类的__init__()方法作为构造方法会接收这个实例(即self)作为自己的第一个参数, 然后依次传入__new__()方法中接收的位置参数和命名参数. 

注意: 如果__new__()没有返回cls(即当前类)的实例, 那么当前类的__init__()方法是不会被调用的. 如果__new__()返回其他类(新式类或经典类均可)的实例, 那么只会调用被返回的那个类的构造方法. 

```
class Foo(object):
    def __init__(self, *args, **kwargs):
        ...
    def __new__(cls, *args, **kwargs):
        return object.__new__(Stranger, *args, **kwargs)  

class Stranger(object):
    ...

foo = Foo()
print type(foo)    

# 打印的结果显示foo其实是Stranger类的实例. 

# 因此可以这么描述__new__()和__ini__()的区别, 在新式类中__new__()才是真正的实例化方法, 为类提供外壳制造出实例框架, 然后调用该框架内的构造方法__init__()使其丰满. 
# 如果以建房子做比喻, __new__()方法负责开发地皮, 打下地基, 并将原料存放在工地. 而__init__()方法负责从工地取材料建造出地皮开发招标书中规定的大楼, __init__()负责大楼的细节设计, 建造, 装修使其可交付给客户. 
```

---

- 疑问一

在类体(class body)外调用__new__()方法, cls 之外的参数是好像不会传递给__init__()方法. 

```
class Myclass(object):
    def __init__(self, x):
        self.x = x
     
c1 = Myclass(11)
c2 = Myclass.__new__(Myclass, 12)
print c1.x, c2.x

#报错, c2没有x属性
```

而应该在调用__new__()方法后显式调用__init__()方法: 

```
class Myclass(object):
    def __init__(self, x):
        self.x = x
     
c1 = Myclass(11)
c2 = Myclass.__new__(Myclass, 12)
if isinstance(c2, Myclass):
    type(c2).__init__(c2, 12)
print c1.x, c2.x

# 11 12
```

在面向对象编程中, 实例化基本遵循创建实例对象、初始化实例对象、最后返回实例对象这个过程.   
Python中的__new__()方法负责创建一个实例对象, 方法__init__负责将该实例对象进行初始化. 
  
当你进行 c1 = MyClass(11) 这样的操作的时候, 其内部流程是首先调用MyClass.__new__方法创建实例对象, 紧接着就调用该对象的__init__方法完成初始化, 然后将该实例对象引用给 c1 变量. 


c2 = Myclass.__new__(Myclass, 12)这条语句其实只是调用__new__完成了创建实例对象, 但没有调用__init__完成对象的初始化, 因此 print c2.x 是会提示没有该属性的错误的. 

下面给出三段代码可以帮助你了解 __new__,  __init__ , 实例对象的参数传递, 以及对继承的影响. 

代码一: 
```
>>> class Foo(object):
    def __new__(cls, x, *args, **kwargs):
        self = object.__new__(cls)
        self.x = x
        return self
    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs
 
         
>>> foo = Foo(10, "args", name="bar")
>>> print foo.x, foo.args, foo.kwargs
10 (10, 'args') {'name': 'bar'}
 
>>> class Bar(Foo):
    def __init__(self, *args, **kwargs):
        self.bar_args = args
        self.bar_kwargs = kwargs
 
         
>>> bar = Bar(10, "args", name="bar")
>>> print bar.__dict__
{'x': 10, 'bar_args': (10, 'args'), 'bar_kwargs': {'name': 'bar'}}

# 有__init__所以不会调用父类, 除非子类显式调用
```

代码二: 
```
>>> class Foo(object):
    def __new__(cls, *args, **kwargs):
        self = object.__new__(cls)
        self.x = args[0]
        self.args = args
        self.kwargs = kwargs
        return self
 
     
>>> foo = Foo(10, "args", name="bar")
>>> print foo.x, foo.args, foo.kwargs
10 (10, 'args') {'name': 'bar'}
 
>>> class Bar(Foo):
    def __init__(self, *args, **kwargs):
        self.bar_args = args
        self.bar_kwargs = kwargs
 
         
>>> bar = Bar(10, "args", name="bar")
>>> print bar.__dict__
{'x': 10, 'args': (10, 'args'), 'bar_args': (10, 'args'), 'bar_kwargs': {'name': 'bar'}, 'kwargs': {'name': 'bar'}}
```

代码三: 
```
>>> class Foo(object):
    def __init__(self, *args, **kwargs):
        self.x = args[0]
        self.args = args
        self.kwargs = kwargs
 
         
>>> foo = Foo(10, "args", name="bar")
>>> print foo.x, foo.args, foo.kwargs
10 (10, 'args') {'name': 'bar'}
 
>>> class Bar(Foo):
    def __init__(self, *args, **kwargs):
        self.bar_args = args
        self.bar_kwargs = kwargs
 
         
>>> bar = Bar(10, "args", name="bar")
>>> print bar.__dict__
{'bar_args': (10, 'args'), 'bar_kwargs': {'name': 'bar'}}
```

以上三种写法看起来是等价的, 但如果有一个类继承自 Foo 类, 它们各自的表现就不一定相同了. 因为实际编程中, 一个子类往往会覆写父类的__init__方法, 但很少去覆写父类的__new__方法. 

- 疑问二

```
class Foo(object):
    def __init__(self, *args, **kwargs):
        print 'foo'
    def __new__(cls, *args, **kwargs):
        return object.__new__(Stranger, *args, **kwargs)
 
class Stranger(object):
    def __init__(self,*args,**kwargs):
        print 'stranger'
        self.name='name'
    def display(self):
        print self.name
foo = Foo()
```
对于这段代码, 实际上没有调用Stranger中重写的__init__函数, 但是在blog中你有写到"如果__new__()返回其他类(新式类或经典类均可)的实例, 那么只会调用被返回的那个类的构造方法. " 对这一点我有些疑问, 是否这个__init__方法也需要在实例创建之后手动调用呢?


是的, 你需要手动调用__init__方法. 

在 Python 中, 实例化一个类, 一般就是 foo = Foo(), foo 是类 Foo 的实例. 

在这个表达式底下, 其实是通过调用__new__和__init__两个方法实现. 其中__new__是对象构造函数, 方法__init__是初始化函数. foo = Foo() 这一表达式底下还有一个规则是, 只有__new__方法返回的是 Foo 类的实例, 才会自动调用__init__对__new__返回的实例进行初始化. 

你的示例中, 重新定义了 Foo 的__new__方法, 并且返回的是一个 Stranger 实例.  但你是通过调用__new__的方法来构造 Stranger 实例, 而不是 Stranger() 这种方式来获取 Stranger 实例, 因此如果你想得到你预期的 Stranger 实例, 那你就必须自己去完成 Stranger 的初始化. 

其实 Python 构造实例的逻辑很简单, 就是两个步骤, 首先构造一个实例, 然后初始化这个实例. 如果你使用 Foo() 方法进行实例构造, 那这两个步骤自动完成. 如果你选择手动构造, 那就要自己来控制构造实例与初始化实例. 