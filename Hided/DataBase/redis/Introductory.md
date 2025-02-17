## Redis简介

### 1 Overview

#### 1.1 资料

- [<The Little Redis Book>](http://openmymind.net/2012/1/23/The-Little-Redis-Book/), 最好的入门小册子, 可以先于一切文档之前看. 
- [作者Antirez的博客](http://antirez.com/), [Antirez维护的Redis推特](https://twitter.com/redisfeed). 
- [<Redis weekly>](http://redisweekly.com/), Redis周报. 
- [Redis命令中文版](http://redis.readthedocs.org/en/latest/), [huangz](http://weibo.com/huangz1990)的翻译, 同时还有Redis官网几篇重要文档的翻译. 
- [Redis设计与实现](http://www.redisbook.com/en/latest/), huangz的巨作, 深入了解内部实现机制. 
- [Redis 2.6源码中文注释版](https://github.com/huangz1990/annotated_redis_source/), huangz的功德. 
- [NoSQL Fan里面Redis的分类](http://blog.nosqlfan.com/topics/redis)
- [《Redis in Action》](http://www.manning.com/carlson/) (Manning, 2013)挺实战的一本书. 

#### 1.2 优缺点

非常非常的快, 有测评说比Memcached还快(当都是单CPU的时候), 而且是无短板的快, 读写都一样快, 所有API都差不多, 也没有MySQL Cluster/MongoDB那样更新同一条记录如Counter时候慢下去的毛病.   

丰富的数据结构, 超越了一般的Key-Value数据库而被认为是一个数据结构服务器. 组合各种结构, 限制Redis用途的是你的想象力, 作者自己写的[用途入门](http://oldblog.antirez.com/post/take-advantage-of-redis-adding-it-to-your-stack.html). 

因为是个人作品, Redis的源代码只有2、3万行, Keep it simple的死硬做法, 使得普通公司也能吃透. [Redis宣言](http://oldblog.antirez.com/post/redis-manifesto.html)就是作者的自白. "代码像首诗", "设计是一场与复杂性的战斗", "Coding是一件艰苦的事情, 唯一的办法是享受它. 如果它已不能带来快乐就停止它. 为了防止这一天的出现, 我们要尽量避免把Redis往乏味的路上带. "

单线程结构, 使得代码不用处理平时最让人头疼的并发而大量简化, 也不用担心作者的并发没有写对, 但也带来CPU的瓶颈, 而且单线程被慢操作所阻塞时, 其他请求的延时变的不确定. 

Redis不是什么?
- Redis不是Big data, 数据都在内存中, 无法以T为单位. 
- 在Redis3.0的Redis-Cluster发布并被稳定使用之前, Redis没有真正的平滑水平扩展能力. 
- Redis不支持Ad-Hoc Query, 提供的只是数据结构的API, 没有SQL一样的查询能力. 

#### 1.3 Feature速览

- 所有数据都在内存中
- 五种数据结构: String/Hash/List/Set/Ordered Set
- 数据过期时间支持
- 不完全的事务支持
- 服务端脚本: 使用Lua Script编写, 作用类似于存储过程
- PubSub: 消息一对多发布订阅功能, 起码Redis-Sentinel在使用
- 持久化: 支持定期导出内存的Snapshot与记录写操作日志的Append Only File两种模式
- Replication: Master-Slave模式, Master可连接多个只读Slave, Geographic Replication也只支持Active-Standby. 
- Fail-Over: Redis-Sentinel节点负责监控Master节点, 在master失效时提升slave. 
- Sharing: 开发中的Redis-Cluster. 
- 动态配置: 所有参数可用命令行动态配置不需要重启, 2.8版本可以重新写回配置文件中, 对云上的大规模部署非常合适. 

#### 1.4 八卦
- 作者是意大利的Salvatore Sanfilippo(antirez), 又是VMWare大善人聘请了他专心写Redis. 
- EMC与VMWare将旗下的开源产品如Redis和Spring都整合到了孙公司Pivotal公司. 
- [Pivotal做的antirez访谈录](http://blog.gopivotal.com/pivotal-people/pivotal-people-salvatore-sanfilippo-inventor-of-redis), 内含一切八卦, 比如他的爱好是举重、跑步和品红酒. 
- 默认端口6379, 是手机按键上MERZ对应的号码, 意大利歌女Alessia Merz是antirez和朋友们认为愚蠢的代名词. 

### 2 数据结构

#### 2.1 Key
- Key 不能太长, 比如1024字节, 但antirez也不喜欢太短如"u:1000:pwd", 要表达清楚意思才好. 他私人建议用":"分隔域, 用"."作为单词间的连接, 如"comment:12345:reply.to". 
- [Keys](http://redis.readthedocs.org/en/latest/key/keys.html), 返回匹配的key, 支持通配符如 "keys a*" 、 "keys a?c", 但不建议在生产环境大数据量下使用. 
- [SCAN](http://redis.readthedocs.org/en/latest/key/scan.html)命令, 针对Keys的改进, 支持分页查询Key. 在迭代过程中, Keys有增删怎么办?要锁定写操作么?--不会, 不做任何保证, 撞大运, 甚至同一条key可能会被返回多次. 
- [Sort](http://redis.readthedocs.org/en/latest/key/sort.html), 对集合按数字或字母顺序排序后返回或另存为list, 还可以关联到外部key等. 因为复杂度是最高的O(N+M*log(M))(N是集合大小, M 为返回元素的数量), 有时会安排到slave上执行. 
- [Expire/ExpireAt/Persist/TTL](http://redis.readthedocs.org/en/latest/key/expire.html), 关于Key超时的操作. 默认以秒为单位, 也有p字头的以毫秒为单位的版本,  Redis的内部实现见2.9 过期数据清除. 

#### 2.2 String
最普通的key-value类型, 说是String, 其实是任意的byte[], 比如图片, 最大512M. 所有常用命令的复杂度都是O(1), 普通的Get/Set方法, 可以用来做Cache, 存Session, 为了简化架构甚至可以替换掉Memcached. 

[Incr/IncrBy/IncrByFloat/Decr/DecrBy](http://redis.readthedocs.org/en/latest/string/decr.html), 可以用来做计数器, 做自增序列. key不存在时会创建并贴心的设原值为0. IncrByFloat专门针对float, 没有对应的decrByFloat版本?用负数啊. 

[SetNx](http://redis.readthedocs.org/en/latest/string/setnx.html),  仅当key不存在时才Set. 可以用来选举Master或做分布式锁: 所有Client不断尝试使用SetNx master myName抢注Master, 成功的那位不断使用Expire刷新它的过期时间. 如果Master倒掉了key就会失效, 剩下的节点又会发生新一轮抢夺. 

其他Set指令: 

- SetEx,  Set + Expire 的简便写法, p字头版本以毫秒为单位. 
GetSet,  设置新值, 返回旧值. 比如一个按小时计算的计数器, 可以用GetSet获取计数并重置为0. 这种指令在服务端做起来是举手之劳, 客户端便方便很多. 
MGet/MSet/MSetNx,  一次get/set多个key. 
2.6.12版开始, Set命令已融合了Set/SetNx/SetEx三者, SetNx与SetEx可能会被废弃, 这对Master抢注非常有用, 不用担心setNx成功后, 来不及执行Expire就倒掉了. 可惜有些懒惰的Client并没有快速支持这个新指令. 
GetBit/SetBit/BitOp,与或非/BitCount,  BitMap的玩法, 比如统计今天的独立访问用户数时, 每个注册用户都有一个offset, 他今天进来的话就把他那个位设为1, 用BitCount就可以得出今天的总人数. 

Append/SetRange/GetRange/StrLen, 对文本进行扩展、替换、截取和求长度, 只对特定数据格式如字段定长的有用, json就没什么用. 

#### 2.3 Hash

key-HashMap结构, 相比String类型将这整个对象持久化为JSON格式, Hash将对象的各个属性存入Map里, 可以只读取/更新对象的某些属性. 这样有些属性超长就让它