Python字符串: https://github.com/rainyear/pytips/blob/master/Tips/2016-03-15-Unicode-String.ipynb

Python中Unicode的正确用法

Python字节与字节数组: https://github.com/rainyear/pytips/blob/master/Tips/2016-03-16-Bytes-and-Bytearray.ipynb

Python中常见的两个错误: 

```
UnicodeEncodeError: 'ascii' codec can't encode characters in position 0-1: ordinal not in range(128)

UnicodeDecodeError: 'utf-8' codec can't decode bytes in position 0-1: invalid continuation byte
```

python中的str对象其实就是"8-bit string" , 字节字符串, 本质上类似java中的byte[].    
而python中的unicode对象应该才是等同于java中的String对象, 或本质上是java的char[]. 

- s.decode方法和u.encode方法是最常用的   

简单说来就是, python内部表示字符串用unicode(其实python内部的表示和真实的unicode是有点差别的, 对我们几乎透明, 可不考虑), 和人交互的时候用str对象. unicode相当于明文. 

s.decode -------->将s解码成unicode, 参数指定的是s本来的编码方式. 这个和unicode(s,encodename)是一样的.  (解码: str->unicode)  

u.encode -------->将unicode编码成str对象, 参数指定使用的编码方式. (编码: unicode->str)在调用该接口时候, 涉及一个隐形的类型转化, 会先将str转化为unicode, 才能进行编码. str.encode()相当于str.decode(sys.defaultencoding).encode(). 而sys.defaultencoding一般是ascii, 它是不能用来编码中文字符的. 


unicode: 这个是Python的内建函数, 位于unicode类. unicode(string [, encoding[, errors]]) -> object, 这个函数的作用是将string按照encoding的格式编码成为unicode对象. 省略参数将用python默认的ASCII来解码


助记:   
decode to unicode from parameter   
encode to parameter from unicode 

只有decode方法和unicode构造函数可以得到unicode对象. 

上述最常见的用途是比如这样的场景, 我们在python源文件中指定使用编码cp936,  

```
# coding=cp936或#-*- coding:cp936 -*-或#coding:cp936的方式(不写默认是ascii编码) 
```

这样在源文件中的str对象就是cp936编码的, 我们要把这个字符串传给一个需要保存成其他编码的地方(比如xml的utf-8,excel需要的utf-16),通常这么写:  

```
strobj.decode("cp936").encode("utf-16") 
```

- 似乎有了unicode对象的encode方法和str的decode方法就足够了. 奇怪的是, unicode也有decode, 而str也有encode, 到底这两个是干什么的.  
- decode和encode都可以用于常规字符串和unicode字符串. 
但是:   
    str.decode()和unicode.encode()是直接正规的使用.   
    unicode.decode()会先将unicode转化成str, 然后再执行decode(). 
这里面涉及隐式类型转化的问题