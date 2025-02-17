
http://blog.csdn.net/fwenzhou/article/details/8742838
# Python的import

> 
参考: 
http://www.jianshu.com/p/a379fc18b7a1

在python用import或者from...import来导入相应的模块. 模块其实就是一些函数和类的集合文件, 它能实现一些相应的功能, 当我们需要使用这些功能的时候, 直接把相应的模块导入到我们的程序中, 我们就可以使用了. 这类似于C语言中的include头文件, Python中我们用import导入我们需要的模块. 

```
_*: 这种标示符不会被 from module import *导入. 
在交互式解释器中, 它被用来保存最后一次求值的结果. 它被保存在__builtin__模块中. 当处于非交互式模式时, 名称"_"并无特殊含义, 也未被定义. 
注意, "_"经常与国际化一起使用. 
```

### import

导入/引入一个python标准模块, 其中包括.py文件、带有```__init__.py```文件的目录. 

e.g: 

```
[python] view plain copy
import module_name[,module1,...]  
from module import *|child[,child1,...]  
```

说明: 
多次重复使用import语句时, 不会重新加载被指定的模块, 只是把对该模块的内存地址给引用到本地变量环境. 

测试: 

```
a.py  
#!/usr/bin/env python    
#encoding: utf-8  
import os  
print 'in a',id(os)  
  
m.py  
#!/usr/bin/env python    
#encoding: utf-8  
import a   #第一次会打印a里面的语句  
import os  #再次导入os后, 其内存地址和a里面的是一样的, 因此这里只是对os的本地引用  
print 'in c',id(os)  
import a  #第二次不会打印a里面的语句, 因为没有重新加载  
```


### ```__import__```

> 
参考: http://www.cnblogs.com/huazi/archive/2012/11/30/2796237.html

作用: 同import语句同样的功能, 但```__import__```是一个函数, 并且只接收字符串作为参数, 所以它的作用就可想而知了. 其实import语句就是调用这个函数进行导入工作的, ```import sys <==>sys = __import__('sys')```

```
e.g: 
__import__(module_name[, globals[, locals[, fromlist]]]) #可选参数默认为globals(),locals(),[]
__import__('os')    
__import__('os',globals(),locals(),['path','pip'])  #等价于from os import path, pip
```

说明: 
通常在动态加载时可以使用到这个函数, 比如你希望加载某个文件夹下的所用模块, 但是其下的模块名称又会经常变化时, 就可以使用这个函数动态加载所有模块了, 最常见的场景就是插件功能的支持. 
扩展: 
既然可以通过字符串来动态导入模块, 那么是否可以通过字符串动态重新加载模块吗?试试reload('os')直接报错, 是不是没有其他方式呢?虽然不能直接reload但是可以先unimport一个模块, 然后再__import__来重新加载模块. 现在看看unimport操作如何实现, 在Python解释里可以通过globals(),locals(),vars(),dir()等函数查看到当前环境下加载的模块及其位置, 但是这些都只能看不能删除, 所以无法unimport; 不过除此之外还有一个地方是专门存放模块的, 这就是sys.modules, 通过sys.modules可以查看所有的已加载并且成功的模块, 而且比globals要多, 说明默认会加载一些额外的模块, 接下来就是unimport了. 

### reload

作用: 对已经加载的模块进行重新加载, 一般用于原模块有变化等特殊情况, reload前该模块必须已经import过. 

```
e.g: 
import os
reload(os)
```

说明: reload会重新加载已加载的模块, 但原来已经使用的实例还是会使用旧的模块, 而新生产的实例会使用新的模块; reload后还是用原来的内存地址; 不能支持from. . import. . 格式的模块进行重新加载. 

测试

```
a.py  
#!/usr/bin/env python    
#encoding: utf-8  
import os  
print 'in a',id(os)  
  
m.py  
#!/usr/bin/env python    
#encoding: utf-8  
import a   #第一次import会打印a里面的语句  
print id(a) #原来a的内存地址  
reload(a)  #第二次reload还会打印a里面的语句, 因为有重新加载  
print id(a) #reload后a的内存地址, 和原来一样  
```

### import和from ... import xx

import和from import都是将其他模块导入当前模块中. 刚开始一直以为import和from import唯一的区别, 就是from import可以少写一些模块名. 虽然from XX import会污染当前名字空间, 但似乎仅限如此. 但其实from import还有一个相当严重的陷阱. 

举例来说: 

```
#a.py

test = 2
print 'in a'

#b.py

from a import *
print test
test = 3
from c import *
print test

#c.py

from a import *
print test
test = 4
```

结果为: 

```
#python b.py

in a
2
2
4
```

修改代码: 

```
#a.py

test = 2
print 'in a'

#b.py

import a
print a.test
a.test = 3
import c
print c.a.test

#c.py

import a
print a.test
a.test = 4
```

结果为: 

```
#python b.py

in a
2
3
4
```

如果, 我们把a.py中的test = 2修改为 test = [2], 后面对test的修改改为对test[0]的修改, 则会发现, import和from import的结果完全一致. 

通过以上的分析. 基本可以得到这样的结论: 

1 重复import或from import多次都只会作用一次. import和from  import语句可以出现在程序中的任何位置. 但是有一点是: 无论import语句被使用了多少次, 每个模块中的代码仅加载和执行一次, 后续的import语句仅将模块名称绑定到前一次导入所创建的模块对象上. 

2 import和from import的作用机制完全不同

3 **import的机制是将目标模块中的对象完整的引入当前模块, 但并不引入新的变量名**

4 from import的机制则是通过引入新的变量名的形式, 将目标模块的对象的引用拷贝到新的变量名下的方式引入当前模块

5 在Python解释里可以通过globals(),locals(),vars(),dir()等函数查看到当前环境下加载的模块及其位置, 使用sys.modules可查看当前加载的所有模块(比globals多, 默认会加载一些额外的模块). 

这样描述可能有点抽象, 根据上面的例子来说就是: 

1. 当使用import时, 只存在一个名为a.test变量, 且只有这一个, 无论是在b模块, 还是c模块中
2. 当使用from import时, 在b模块中, 存在一个新的变量b.test, 开始时, b.test=a.test(它们共同指向同一个对象), 当发生赋值时, b.test指向了一个新的对象, 但a.test仍指向原来的对象. 

具体来说就是: 

(1) 初始时, 在a中存在a.test变量, 它指向一个整数对象'2'

(2) 在执行b.py时, from a import * 的执行, 相当于引入了一个新的变量名b.test, b.test = a.test, 这时, b.test和a.test都指向整数对象'2'

(3) 之后的赋值操作(test = 3), 使得b.test = 3, 使得b.test指向了整数对象'3', 而a.test仍指向整数对象'2'

(4) 继续执行from c import * 时, 进入c.py, 在c模块中, 执行from a import *, 将引入新的变量名c.test, c.test = a.test, 它们都指向整数对象'2', 之后的赋值操作(test = 4),使得c.test = 4, 现在, c.test指向了整数对象'4', 而a.test仍指向整数对象'2'

(5) 回到b.py, 由于b.test已存在, 因此, 不引人新的变量, 而是直接执行b.test = c.test, 这时, b.test指向整数对象'4'
最终的结果, a.test指向'2', b.test指向'4', c.test指向'4'

3. 当test变为list时, b.test[0]的修改, 并没有引起b.test本身的变化, 换言之, b.test和a.test仍指向同一个对象, 只不过这个对象内部被修改了

总结: 
1 from import很危险, 如果不了解其作用机制, 慎用
2 即便知道了机制, 一样要慎用

在使用 from xxx import * 时, 如果想精准的控制模块导入的内容, 可以使用 ```__all__ = [xxx,xxx] ```来实现, 例如: 

```
__all__ = ['a','b'] #__为双横线
class two():
    def __init__(self):
        print('this is two')
a = 'this is two a'
b = 'this is two b'
if __name__=='__main__':
    t = two()



one.py

from two import *
print a
print b
t = two()

这时, 类two() 将不会被 import * 导入进来
```

### 关于Import中的路径搜索问题

系统就会在```sys.path```的路径列表中搜索相应的文件, 可以自行添加要搜索路径. 

```
import sys
sys.append('D:/xx/code')
```

当我们import一个module时, python会做以下几件事情

- 导入一个module
- 将module对象加入到sys.modules, 后续对该module的导入将直接从该dict中获得
- 将module对象加入到globals dict中

当我们引用一个模块时, 将会从globals中查找. 这里如果要替换掉一个标准模块, 我们得做以下两件事情

1. 将我们自己的module加入到sys.modules中, 替换掉原有的模块. 如果被替换模块还没加载, 那么我们得先对其进行加载, 否则第一次加载时, 还会加载标准模块. (这里有一个import hook可以用, 不过这需要我们自己实现该hook, 可能也可以使用该方法hook module import)
2. 如果被替换模块引用了其他模块, 那么我们也需要进行替换, 但是这里我们可以修改globals dict, 将我们的module加入到globals以hook这些被引用的模块. 

### cannot import XXX

文件a.py

```
import sys
print 'a++++++++', sys.modules # a no b

from b import varb

def afunc():
    #print b.varb

    print varb

vara = 1
```

文件b.py

```
#import a
import sys
print 'b--------', sys.modules # 1, __main__, no B; 2, a,b

from a import vara


def bfunc():
    #print a.vara
    print vara

print '-------'
varb = 2
```

执行b.py文件, 报错如下: 

```
b--------   __main__, no a,b
a++++++++   a no b
Traceback (most recent call last):
  File "D:/Project/PythonProject/testcode/iport/b.py", line 5, in <module>
    from a import vara
  File "D:\Project\PythonProject\testcode\iport\a.py", line 4, in <module>
    from b import varb
  File "D:\Project\PythonProject\testcode\iport\b.py", line 5, in <module>
    from a import vara
ImportError: cannot import name vara
b-------- a, b
```

分析过程: 
Python是一个解析性语言, 执行b.py, 第一次输出模块时候, 没有a和b, 因为没有存在导入. 然后从a里面导入vara, 加载a模块, 将a加入到sys.modules, 所以a里面打印sys.modules是有a的, 但是此时a里面globals除了内置变量其余都没有, 解析a, a又从b里面导入变量varb, 加载b模块, 将b加入到sys.modules, 所以打印包括a和b, 然后解析b, b导入a模块的vara, 因为a模块已经在sys.modules了, 所以不再导入, 但是a此时的globals不存在vara, 所以报错. 
