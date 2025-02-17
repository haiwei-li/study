# 1. 在 g++ 中用一个 option 来指定

```
g++ -o main main.cpp -I /usr/local/include/python/
```

# 2. 通过环境变量来设置这样就可以不要在 g++ 中来指定了

```
export CPLUS_INCLUDE_PATH=/usr/local/include/python/
```

g++ -o main main.cpp