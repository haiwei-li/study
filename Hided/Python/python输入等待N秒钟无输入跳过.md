## 方案1

用多线程或多进程 实现. 

```
#!usr/bin/env python  
#-*- coding:utf-8 _*- 

import time

from threading import Thread

def foo():
     raw_input('Enter any key')
     print '123456'

thd = Thread(target=foo)
thd.daemon = True
thd.start()

seconds = 10
time.sleep(seconds)

```

## 方案2

信号量

```
# -*- coding: utf-8 -*-
import signal

class InputTimeoutError(Exception):
    pass

def interrupted(signum, frame):
    raise InputTimeoutError


signal.signal(signal.SIGALRM, interrupted)
signal.alarm(10)

try:
    name = raw_input('请在10秒内输入你的名字: ')
except InputTimeoutError:
    print('\ntimeout')
    name = '无名'

signal.alarm(0)  # 读到输入的话重置信号
print('你的名字是: %s' % name)
```