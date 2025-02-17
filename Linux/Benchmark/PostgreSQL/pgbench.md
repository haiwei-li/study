

pgbench 是基于 tpc-b 模型的 postgresql 测试工具. 它属于开源软件, 主要为对 PostgreSQL 进行压力测试的一款简单程序, SQL 命令可以在一个连接中顺序地执行, 通常会开多个数据库 Session, 并且在测试最后形成测试报告, 得出每秒平均事务数, pgbench 可以测试 select,update,insert,delete 命令, 用户可以编写自己的脚本进行测试.

yum install -y postgresql-server

yum install -y postgresql-contrib

postgresql-setup initdb

