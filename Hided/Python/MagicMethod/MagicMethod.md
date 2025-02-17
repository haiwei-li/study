Python中的魔术方法: https://blog.windrunner.me/python/magic-methods-in-python.html

PYTHON-进阶-魔术方法小结(方法运算符重载):http://www.wklken.me/posts/2012/10/29/python-base-magic.html

Python魔术方法指南: http://pycoders-weekly-chinese.readthedocs.io/en/latest/issue6/a-guide-to-pythons-magic-methods.html

Python魔术方法指南: http://pyzh.readthedocs.io/en/latest/python-magic-methods-guide.html

Python的Magic Methods指南: https://www.oschina.net/translate/python-magicmethods

Python常用魔术方法: http://www.pydevops.com/2016/01/25/python-%E5%B8%B8%E7%94%A8%E7%9A%84%E9%AD%94%E6%9C%AF%E6%96%B9%E6%B3%95/

1. 关于__reduce__方法: 

``` 
相关: http://stackoverflow.com/questions/19855156/whats-the-exact-usage-of-reduce-in-pickler

官方: https://docs.python.org/2/library/pickle.html

object.__reduce__()
When the Pickler encounters an object of a type it knows nothing about — such as an extension type — it looks in two places for a hint of how to pickle it. One alternative is for the object to implement a __reduce__() method. If provided, at pickling time __reduce__() will be called with no arguments, and it must return either a string or a tuple.

If a string is returned, it names a global variable whose contents are pickled as normal. The string returned by __reduce__() should be the object's local name relative to its module; the pickle module searches the module namespace to determine the object's module.

When a tuple is returned, it must be between two and five elements long. Optional elements can either be omitted, or None can be provided as their value. The contents of this tuple are pickled as normal and used to reconstruct the object at unpickling time. The semantics of each element are:

A callable object that will be called to create the initial version of the object. The next element of the tuple will provide arguments for this callable, and later elements provide additional state information that will subsequently be used to fully reconstruct the pickled data.

In the unpickling environment this object must be either a class, a callable registered as a "safe constructor" (see below), or it must have an attribute __safe_for_unpickling__ with a true value. Otherwise, an UnpicklingError will be raised in the unpickling environment. Note that as usual, the callable itself is pickled by name.

A tuple of arguments for the callable object.

Changed in version 2.5: Formerly, this argument could also be None.

Optionally, the object's state, which will be passed to the object's __setstate__() method as described in section Pickling and unpickling normal class instances. If the object has no __setstate__() method, then, as above, the value must be a dictionary and it will be added to the object's __dict__.

Optionally, an iterator (and not a sequence) yielding successive list items. These list items will be pickled, and appended to the object using either obj.append(item) or obj.extend(list_of_items). This is primarily used for list subclasses, but may be used by other classes as long as they have append() and extend() methods with the appropriate signature. (Whether append() or extend() is used depends on which pickle protocol version is used as well as the number of items to append, so both must be supported.)

Optionally, an iterator (not a sequence) yielding successive dictionary items, which should be tuples of the form (key, value). These items will be pickled and stored to the object using obj[key] = value. This is primarily used for dictionary subclasses, but may be used by other classes as long as they implement __setitem__().
```
- reduce用于序列化和反序列化
- 下面例子
 
```
try:
    import cPickle as pickle
except ImportError:
    import pickle


class BaseError(Exception):
    def __init__(self, code=None, msg=None):
        self.code = code
        self.message = msg
        super(BaseError, self).__init__(code, msg)

    def __str__(self):
        return str({'errorCode': self.code, "args": self.message})

    def __reduce__(self):
        return (self.__class__, (self.code, self.message))
        
        
class Orm4redisError(BaseError):
    _msg = "orm4redis Exception."

    def __init__(self, message=None):
        self.message = message or self._msg
        super(Orm4redisError, self).__init__(code=ERRORCODE['REDIS_ERROR'], msg=self.message)

    def __reduce__(self):
        return (self.__class__, (self.message,))

class ParameterError(Orm4redisError):
    _msg = "redis parameter error."

    def __init__(self):
        self.message = "redis parameter error"
        super(ParameterError, self).__init__(self.message)

    def __reduce__(self):
        return (self.__class__, ())

if __name__ == '__main__':
    exception = BaseError(code='123456', msg='789456')
    exception_dumps = pickle.dumps(exception)
    print exception_dumps

    exception_loads = pickle.loads(exception_dumps)

    print exception_loads
    
```
注: Python认为一个元素的元组, 例如(123)的类型是int, 而不是元组类型; (123,)是tuple

```
>>> type((123,))
<type 'tuple'>
>>> type((123))
<type 'int'>
```

可以查看dumps的结果, reduce是用来序列化时候返回的内容, 该内容在反序列化时候, 会作为函数参数传递进去. 所以类ParameterError


注意下面情况: 
```
class Test(Exception):
    def __init__(self, *args, **kwargs):
        print 'Test init'
        print '-------', kwargs
        print '-------', args
        self.error_code = kwargs.get('code')
        print 'init code', self.error_code
        arg = list()
        for key in kwargs:
            if key != 'code':
                arg.append(str(kwargs[key]))
        self.arg = arg
        print 'init code', self.error_code
        print "end"

    def __str__(self):
        return str({'--------------errorCode': self.error_code, "args": self.arg})

'''
    def __reduce__(self):
        tuple_args = (self.__class__, (), {"++++++++++++code": self.error_code})
        obj_states = {"error_code": self.error_code, "arg": self.arg}
        return Test, tuple_args, obj_states
'''

class BaseError(Exception):
    def __init__(self, code=None, msg=None):
        self.code = code
        self.message = msg
        super(BaseError, self).__init__(code, msg)

    def __str__(self):
        return str({'errorCode': self.code, "args": self.message})

print "_+___________\n"
my_test = BaseError(code='123456')
dumps_test = pickle.dumps(my_test)
print dumps_test

print "_+___________\n"

loads_test = pickle.loads(dumps_test)
print loads_test

```

还有: 
```
try:
    import cPickle as pickle
except ImportError:
    import pickle

class Test(Exception):
    def __init__(self, *args, **kwargs):
        print 'Test init'
        print '-------', kwargs
        print '-------', args
        self.error_code = kwargs.get('code')
        print 'init code', self.error_code
        arg = list()
        for key in kwargs:
            if key != 'code':
                arg.append(str(kwargs[key]))
        self.arg = arg
        print 'init code', self.error_code
        print "end"

    def __str__(self):
        return str({'--------------errorCode': self.error_code, "args": self.arg})

    def __reduce__(self):
        return (self.__class__, (self.error_code, self.arg))

class BaseError(Exception):
    def __init__(self, code=None, msg=None):
        self.code = code
        self.message = msg
        super(BaseError, self).__init__(code, msg)

    def __str__(self):
        return str({'errorCode': self.code, "args": self.message})

my_test = Test(code='123456')
dumps_test = pickle.dumps(my_test)
print dumps_test

loads_test = pickle.loads(dumps_test)
print loads_test

result:
Test init
------- {'code': '123456'}
------- ()
init code 123456
init code 123456
end
c__main__
Test
p1
(S'123456'
p2
(lp3
tRp4
.
Test init
------- {}
------- ('123456', [])
init code None
init code None
end
{'args': [], '--------------errorCode': None}
```

以及: 
```
try:
    import cPickle as pickle
except ImportError:
    import pickle

class Test(Exception):
    def __init__(self, *args, **kwargs):
        print 'Test init'
        print '-------', kwargs
        print '-------', args
        self.error_code = kwargs.get('code')
        print 'init code', self.error_code
        arg = list()
        for key in kwargs:
            if key != 'code':
                arg.append(str(kwargs[key]))
        self.arg = arg
        print 'init code', self.error_code
        print "end"

    def __str__(self):
        return str({'--------------errorCode': self.error_code, "args": self.arg})

    #def __reduce__(self):
     #   return (self.__class__, (self.error_code, self.arg))

class BaseError(Exception):
    def __init__(self, code=None, msg=None):
        self.code = code
        self.message = msg
        super(BaseError, self).__init__(code, msg)

    def __str__(self):
        return str({'errorCode': self.code, "args": self.message})

my_test = Test(code='123456')
dumps_test = pickle.dumps(my_test)
print dumps_test

loads_test = pickle.loads(dumps_test)
print loads_test

result:
Test init
------- {'code': '123456'}
------- ()
init code 123456
init code 123456
end
c__main__
Test
p1
(tRp2
(dp3
S'error_code'
p4
S'123456'
p5
sS'arg'
p6
(lp7
sb.
Test init
------- {}
------- ()
init code None
init code None
end
{'args': [], '--------------errorCode': '123456'}
```
默认情况下, reduce传递的是对象本身, 所以能识别出来'123456', 自己定义的话返回self.__class__, 返回的是类. (涉及dumps以及loads的具体实现, 建议看源码)

```
def construct_Error(cls, arg, kw):
    print '------------ constructError arg ', arg, ' kw ', kw
    return cls.__new__(cls, *arg, **kw)
    
class VmReqMsgError(Exception):
    def __init__(self, *args, **kwargs):
        print '-----------init args ', args, ' kwargs ', kwargs
        self.error_code = kwargs['code']
        arg = list()
        for key in kwargs:
            if key != 'code':
                arg.append(str(kwargs[key]))
        self.arg = arg

    def __str__(self):
        print 'str class ', self.__class__.__name__, ' dir ', dir(self), ' args', self.args
        return str({'errorCode': self.error_code, "args": self.arg})

    def __reduce__(self):
        print '-------------reduce'
        tuple_args = (self.__class__, (), {"code": self.error_code})
        obj_states = {"error_code": self.error_code, "arg": self.arg}
        return construct_Error, tuple_args, obj_states
        
if __name__ == '__main__':
    try:
        import cPickle as pickle
    except ImportError:
        import pickle
    exception = VmReqMsgError(code='123456', msg='789456')

    print '++++++++++++++++dumps'
    exception_dumps = pickle.dumps(exception)
    print exception_dumps

    print '+++++++++++++++++loads'
    exception_loads = pickle.loads(exception_dumps)

    print exception_loads
    
    
result:

-----------init args  ()  kwargs  {'msg': '789456', 'code': '123456'}
++++++++++++++++dumps
-------------reduce
c__main__
construct_Error
p1
(c__main__
VmReqMsgError
p2
(t(dp3
S'code'
p4
S'123456'
p5
stRp6
(dp7
S'error_code'
p8
g5
sS'arg'
p9
(lp10
S'789456'
p11
asb.
+++++++++++++++++loads
------------ constructError arg  ()  kw  {'code': '123456'}
str class  VmReqMsgError  dir  ['__class__', '__delattr__', '__dict__', '__doc__', '__format__', '__getattribute__', '__getitem__', '__getslice__', '__hash__', '__init__', '__module__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__', '__setstate__', '__sizeof__', '__str__', '__subclasshook__', '__unicode__', '__weakref__', 'arg', 'args', 'error_code', 'message'] args ()
{'errorCode': '123456', 'args': ['789456']}
```