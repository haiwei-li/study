# yield

> 参考
彻底理解: http://www.jianshu.com/p/d09778f4e055
Python关键字yield的解释: http://pyzh.readthedocs.io/en/latest/the-python-yield-keyword-explained.html
Python yield与实现: http://www.cnblogs.com/coder2012/p/4990834.html

## 1. 提问者的问题

Python关键字yield的作用是什么?用来干什么的?

比如, 我正在试图理解下面的代码:

```
def node._get_child_candidates(self, distance, min_dist, max_dist):
    if self._leftchild and distance - max_dist < self._median:
        yield self._leftchild
    if self._rightchild and distance + max_dist >= self._median:
        yield self._rightchild
```

下面的是调用:

```
result, candidates = list(), [self]
while candidates:
    node = candidates.pop()
    distance = node._get_dist(obj)
    if distance <= max_dist and distance >= min_dist:
        result.extend(node._values)
    candidates.extend(node._get_child_candidates(distance, min_dist, max_dist))
return result
```

当调用 _get_child_candidates 的时候发生了什么?返回了一个列表?返回了一个元素?被重复调用了么? 什么时候这个调用结束呢?

## 2. 回答部分

为了理解什么是 yield,你必须理解什么是生成器. 在理解生成器之前, 让我们先走近迭代. 

## 3. 可迭代对象
当你建立了一个列表, 你可以逐项地读取这个列表, 这叫做一个可迭代对象:

```
>>> mylist = [1, 2, 3]
>>> for i in mylist :
...    print(i)
1
2
3
```

mylist 是一个可迭代的对象. 当你使用一个列表生成式来建立一个列表的时候, 就建立了一个可迭代的对象:

```
>>> mylist = [x*x for x in range(3)]
>>> for i in mylist :
...    print(i)
0
1
4
```

所有你可以使用 for .. in .. 语法的叫做一个迭代器: 列表, 字符串, 文件......你经常使用它们是因为你可以如你所愿的读取其中的元素, 但是你把所有的值都存储到了内存中, 如果你有大量数据的话这个方式并不是你想要的. 

3.4. 生成器
生成器是可以迭代的, 但是你只可以读取它一次, 因为它并不把所有的值放在内存中, 它是实时地生成数据:

```
>>> mygenerator = (x*x for x in range(3))
>>> for i in mygenerator :
...    print(i)
0
1
4
```

看起来除了把 [] 换成 () 外没什么不同. 但是, 你不可以再次使用 for i in mygenerator , 因为生成器只能被迭代一次: 先计算出0, 然后继续计算1, 然后计算4, 一个跟一个的...

## yield关键字

yield 是一个类似 return 的关键字, 只是这个函数返回的是个生成器. 

```
>>> def createGenerator() :
...    mylist = range(3)
...    for i in mylist :
...        yield i*i
...
>>> mygenerator = createGenerator() # create a generator
>>> print(mygenerator) # mygenerator is an object!
<generator object createGenerator at 0xb7555c34>
>>> for i in mygenerator:
...     print(i)
0
1
4
```

这个例子没什么用途, 但是它让你知道, 这个函数会返回一大批你只需要读一次的值.

为了精通 yield ,你必须要理解: **当你调用这个函数的时候, 函数内部的代码并不立马执行 , 这个函数只是返回一个生成器对象**, 这有点蹊跷不是吗. 

那么, 函数内的代码什么时候执行呢?当你使用for进行迭代的时候.

现在到了关键点了！

第一次迭代中你的函数会执行, 从开始到达 yield 关键字, 然后返回 yield 后的值作为第一次迭代的返回值. 然后, 每次执行这个函数都会继续执行你在函数内部定义的那个循环的下一次, 再返回那个值, 直到没有可以返回的. 

如果生成器内部没有定义 yield 关键字, 那么这个生成器被认为成空的. 这种情况可能因为是循环进行没了, 或者是没有满足 if/else 条件. 


## 总结

阅读别人的python源码时碰到了这个yield这个关键字, 各种搜索终于搞懂了, 在此做一下总结: 

1. 通常的for...in...循环中, in后面是一个数组, 这个数组就是一个可迭代对象, 类似的还有链表, 字符串, 文件. 它可以是mylist = [1, 2, 3], 也可以是mylist = [x*x for x in range(3)]. 
它的缺陷是所有数据都在内存中, 如果有海量数据的话将会非常耗内存. 

2. 生成器是可以迭代的, **但只可以读取它一次**. 因为用的时候才生成. 比如 mygenerator = (x*x for x in range(3)), 注意这里用到了(), 它就不是数组, 而上面的例子是[]. 

3. 我理解的生成器(generator)能够迭代的关键是它有一个next()方法, 工作原理就是通过重复调用next()方法, 直到捕获一个异常. 可以用上面的mygenerator测试. 

4. 带有 yield 的函数不再是一个普通函数, 而是一个生成器generator, 可用于迭代, 工作原理同上. 

5. yield 是一个类似 return 的关键字, 迭代一次遇到yield时就返回yield后面的值. 重点是: 下一次迭代时, 从上一次迭代遇到的yield后面的代码开始执行. 

6. 简要理解: yield就是 return 返回一个值, 并且记住这个返回的位置, 下次迭代就从这个位置后开始. 

7. 带有yield的函数不仅仅只用于for循环中, 而且可用于某个函数的参数, 只要这个函数的参数允许迭代参数. 比如array.extend函数, 它的原型是array.extend(iterable). 

8. send(msg)与next()的区别在于send可以传递参数给yield表达式, 这时传递的参数会作为yield表达式的值, 而yield的参数是返回给调用者的值. ——换句话说, 就是send可以强行修改上一个yield表达式值. 比如函数中有一个yield赋值, a = yield 5, 第一次迭代到这里会返回5, a还没有赋值. 第二次迭代时, 使用.send(10), 那么, 就是强行修改yield 5表达式的值为10, 本来是5的, 那么a=10

9. send(msg)与next()都有返回值, 它们的返回值是当前迭代遇到yield时, yield后面表达式的值, 其实就是当前迭代中yield后面的参数. 

10. 第一次调用时必须先next()或send(None), 否则会报错, send后之所以为None是因为这时候没有上一个yield(根据第8条). 可以认为, next()等同于send(None). 

代码示例1: 

```
#encoding:UTF-8  
def yield_test(n):  
    for i in range(n):  
        yield call(i)  
        print("i=",i)  
    #做一些其它的事情      
    print("do something.")      
    print("end.")  

def call(i):  
    return i*2  

#使用for循环  
for i in yield_test(5):  
    print(i,",")
```

结果是: 

```
>>>   
0 ,  
i= 0  
2 ,  
i= 1  
4 ,  
i= 2  
6 ,  
i= 3  
8 ,  
i= 4  
do something.  
end.  
>>>
```

理解的关键在于: 下次迭代时, 代码从yield的下一跳语句开始执行. 



















