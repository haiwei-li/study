
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 概述](#1-概述)
- [2 kolla\-ansible命令](#2-kolla-ansible命令)
- [2 ansible](#2-ansible)
  - [2.1 Host Inventory(主机清单)](#21-host-inventory主机清单)
  - [2.2 Module(模块)](#22-module模块)
    - [2.2.1 一个例子: ping](#221-一个例子-ping)
    - [2.2.2 自定义模块](#222-自定义模块)
    - [2.2.3 action moudle](#223-action-moudle)
    - [2.2.4 模块学习](#224-模块学习)
- [3 ansible\-playbook](#3-ansible-playbook)
- [4 Playbook(剧本)](#4-playbook剧本)
  - [4.1 一个简单的playbook](#41-一个简单的playbook)
  - [4.2 playbook中的元素](#42-playbook中的元素)
    - [4.2.1 hosts and remote\_user](#421-hosts-and-remote_user)
    - [4.2.2 tasks](#422-tasks)
    - [4.2.3 vars](#423-vars)
    - [4.2.4 handlers](#424-handlers)
  - [4.3 使用role和include更好的组织playbook](#43-使用role和include更好的组织playbook)
    - [4.3.1 role](#431-role)
    - [4.3.2 include](#432-include)
- [5 kolla\-ansible中常见的ansible语法](#5-kolla-ansible中常见的ansible语法)
  - [5.1 条件语句](#51-条件语句)
  - [5.2 迭代](#52-迭代)
  - [5.3 failed\_when](#53-failed_when)
  - [5.4 changed\_when](#54-changed_when)
  - [5.5 run\_once](#55-run_once)
  - [5.6 serial](#56-serial)
  - [5.7 until](#57-until)
  - [5.8 wait_for](#58-wait_for)
- [6 参考](#6-参考)

<!-- /code_chunk_output -->

# 1 概述

kolla\-ansible是一个结构相对简单的项目, 它通过一个shell脚本, 根据用户的参数, 选择不同的playbook和不同的参数调用ansible-playbook执行, 没有数据库, 没有消息队列, 所以本文的重点是ansible本身的语法. 

# 2 kolla\-ansible命令

查看kolla-ansible/tools/kolla-ansible文件内容, 主要命令代码如下:

```sh
function find_base_dir {
    # 略
}

function process_cmd {
    echo "$ACTION : $CMD"
    $CMD
    if [[ $? -ne 0 ]]; then
        echo "Command failed $CMD"
        exit 1
    fi
}

function usage {
cat <<EOF
# 略   
EOF
}

function bash_completion {
cat <<EOF
# 略  
EOF
}

INVENTORY="${BASEDIR}/ansible/inventory/all-in-one"
PLAYBOOK="${BASEDIR}/ansible/site.yml"
VERBOSITY=
EXTRA_OPTS=${EXTRA_OPTS}
CONFIG_DIR="/etc/kolla"
PASSWORDS_FILE="${CONFIG_DIR}/passwords.yml"
DANGER_CONFIRM=
INCLUDE_IMAGES=
INCLUDE_DEV=
BACKUP_TYPE="full"

while [ "$#" -gt 0 ]; do
    case "$1" in

    (--inventory|-i)
            INVENTORY="$2"
            shift 2
            ;;
# 支持的各种参数, 略
esac
done

case "$1" in

(prechecks)
        ACTION="Pre-deployment checking"
        EXTRA_OPTS="$EXTRA_OPTS -e kolla_action=precheck"
        ;;
(check)
        ACTION="Post-deployment checking"
        EXTRA_OPTS="$EXTRA_OPTS -e kolla_action=check"
        ;;
# 以下忽略
esac

CONFIG_OPTS="-e @${CONFIG_DIR}/globals.yml -e @${PASSWORDS_FILE} -e CONFIG_DIR=${CONFIG_DIR}"
CMD="ansible-playbook -i $INVENTORY $CONFIG_OPTS $EXTRA_OPTS $PLAYBOOK $VERBOSITY"
process_cmd
```

可以看到, 执行当我们执行kolla\-ansible deploy时, kolla-ansible命令帮我们调用了对应的ansible\-playbook执行, 除此之外, 没有其他工作. 所以对于kolla\-ansible项目, 主要学习ansible语法即可. 

# 2 ansible

一个简单的ansible命令示例如下: 

```
# ansible -i /root/myhosts ha01 -m setup
```

这个命令的作用是, 对/root/hosts文件中的所有属于ha01分类的主机, 执行setup模块收集该主机的信息, 它包括两种元素, 主机清单和模块, 下面分别介绍这两种元素. 

## 2.1 Host Inventory(主机清单)

host inventory 是一个文件, 存放了所有被ansible管理的主机, 可以在调用anabile命令时, 通过\-i参数指定. 

1. 下面是一个最简单的hosts file的例子, 包含1个主机ip和两个主机名: 
```
193.192.168.1.50
ha01
ha02
```

可以执行以下命令检查ha01是否能够连通

```
# ansible -i $filename ha01 -m ping

ha01 | SUCCESS => {
    "changed": false, 
    "ping": "pong"
}
```

2. 我们可以把主机分类, 示例如下

```
deploy-node

[ha]
ha01
ha02

[compute]
compute01
compute02
compute03
```


如果主机数量比较多, 也可以用正则表达, 示例如下: 

```
deploy-node

[ha]
ha[01:02]

[openstack-compute]
compute[01:50]

[openstack-controller]
controller[01:03]

[databases]
db-[a:f].example.com
```

所有的controller和compute, 都是openstack的节点, 所以我们可以再定义一个类别openstack\-common, 把他们里面的主机都包括进去

```
[openstack-common:children]
openstack-controller
openstack-compute

[common:children]
openstack-common
databases
ha
```

当我们有了如上的inventory 文件后, 可以执行如下命令, 检验是不是所有机器都能够被ansible管理

```
ansible -i $file common -m ping
```

## 2.2 Module(模块)

ansible封装了很多**python脚本**作为**module**提供给使用者, 如: yum、copy、template, command, etc. 

当我们给特定主机执行某个module时, **ansible**会把**这个module**对应的**python脚本**, **拷贝到目标主机上执行**. 可以使用ansible\-doc \-l来查看ansible支持的所有module. 

使用ansible \-v 模块名 来查看该模块的详细信息. 

### 2.2.1 一个例子: ping

上文的例子, **使用了\-m ping参数**, 意思是对这些主机, 执行**ping模块**, ping 模块是一个**python脚本**, 作用是用来判断: 目标机器是否能够通过ssh连通并且已经安装了python. 

```python
# ping module主要源码
description:
   - A trivial test module, this module always returns C(pong) on successful
     contact. It does not make sense in playbooks, but it is useful from
     C(/usr/bin/ansible) to verify the ability to login and that a usable python is configured.
   - This is NOT ICMP ping, this is just a trivial test module.
options: {}

from ansible.module_utils.basic import AnsibleModule


def main():
    module = AnsibleModule(
        argument_spec=dict(
            data=dict(required=False, default=None),
        ),
        supports_check_mode=True
    )
    #什么都不做, 构建一个json直接返回
    result = dict(ping='pong')
    if module.params['data']:
        if module.params['data'] == 'crash':
            raise Exception("boom")
        result['ping'] = module.params['data']
    module.exit_json(**result)

if __name__ == '__main__':
    main()
```

### 2.2.2 自定义模块

example: [Ansible模块开发-自定义模块](https://zhuanlan.zhihu.com/p/27512427)

如果默认模块不能满足需求, 可以自定义模块放到ansible指定的目录, 默认的ansible配置文件是/etc/ansible/ansible.cfg, library配置项是自定义模块的目录. 

openstack的**kolla\-ansbile**项目的**ansible/library目录**下面存放着kolla**自定义的module**,这个目录下每一个文件都是一个自定义moudle. 可以使用如下的命令来查看自定义module的使用方法: 

```
ansible-doc -M /usr/share/kolla-ansible/ansible/library -v merge_configs
```

### 2.2.3 action moudle

如上文所述, ansible moudle**最终执行的位置是目标机器**, 所以module脚本的执行**依赖于目标机器上安装了对应的库**, 如果目标机器上没有安装对应的库, 脚本变不能执行成功. 这种情况下, 如果我们不打算去改动目标机器, 可以使用**action moudle**, action moudle是一种用来在**管理机器上执行**, 但是可以最终**作用到目标机器上的module**. 

例如, OpenStack/kolla-ansible项目部署容器时, 几乎对**每一台机器**都要**生成自己对应的配置文件**, 如果这个步骤在**目标机器**上执行, 那么需要在每个**目标机器**上都按照配置文件对应的**依赖python库**. 

为了减少依赖, kolla\-ansible定义了**action module**, 在**部署节点生成配置文件**, 然后通过**cp module**将生成的文件**拷贝到目标节点**, 这样就不必在每个被部署节点都安装yml, **oslo\_config等python库**, 目标机器只需要支持scp即可. 

kolla\-ansible的**action module**存放的位置是**ansible/action\_plugins**.

### 2.2.4 模块学习

不建议深入去学, 太多了, 用到的时候一个个去查就好了

- 这篇文章介绍了ansible常用模块的用法: http://blog.csdn.net/iloveyin/article/details/46982023
- ansible官网提供了所有module的用法: http://docs.ansible.com/ansible/latest/modules_by_category.html
- ansible 所有module源码存放路径: /usr/lib/python2.7/site-packages/ansible/modules/

# 3 ansible\-playbook

待补充

# 4 Playbook(剧本)

前文提到的**ansible命令**, 都是一些**类似shell命令**的功能, 如果要做一些比较**复杂的操作**, 比如说: 部署一个**java应用**到**10台服务器**上, 一个模块显然是无法完成的, 需要**安装模块**, **配置模块**, **文件传输模块**, **服务状态管理模块等**模块**联合工作**才能完成. 

把这些**模块的组合使用**, 按**特定格式记录到一个文件**上, 并且使**该文件具备可复用性**, 这就是**ansible的playbook**. 

如果说**ansible模块**类似于**shell命令**, 那**playbook**类似于**shell脚本**的功能. 

这里举一个使用playbook集群的例子, kolla\-ansible deploy 实际上就是调用了: 

```
ansible-playbook -i /usr/share/kolla-ansible/ansible/inventory/all-in-one -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=deploy /usr/share/kolla-ansible/ansible/site.yml
```

## 4.1 一个简单的playbook

```
---
- hosts: webservers
  vars:
    http_port: 80
    max_clients: 200
  remote_user: root
  tasks:
  - name: ensure apache is at the latest version
    yum: name=httpd state=latest
  - name: write the apache config file
    template: src=/srv/httpd.j2 dest=/etc/httpd.conf
    notify:
    - restart apache
  - name: ensure apache is running (and enable it at boot)
    service: name=httpd state=started enabled=yes
  handlers:
    - name: restart apache
      service: name=httpd state=restarted
```

这个playbook来自ansible官网, 包含了一个play, 功能是在所有webservers节点上安装配置apache服务, 如果配置文件被重写, 重启apache服务, 在任务的最后, 确保服务在启动状态. 

## 4.2 playbook中的元素

### 4.2.1 hosts and remote\_user

play中的**hosts**代表这个play要在**哪些主机**上执行, 这里可以使**一个**或者**多个主机**, 也可以是**一个**或者**多个主机组**. 

**remote\_user**代表要以指定的**用户身份**来执行此play. 

remote\_user可以细化到**task层**. 

```
---
- hosts: webservers
  remote_user: root
  tasks:
    - name: test connection
      ping:
      remote_user: yourname
```

### 4.2.2 tasks

task是要在目标机器上执行的一个最小任务, 一个play可以包含**多个task**, 所有的task顺序执行. 

### 4.2.3 vars

在play中可以定义一些参数, 如上文webservers中定义的http\_port和max\_clients, 这两个参数会作用到这个play中的task上, 最终template模块会使用这两个参数的值来生成目标配置文件. 

### 4.2.4 handlers

当**某个task**对主机造成了改变时, 可以**触发notify**操作, notify会唤起对应的handler处理该变化. 

比如说上面的例子中, 如果**template module重写/etc/httpd.conf文件**后, 该文件内容发生了变化, 就会触发task中notify部分定义的handler重启apache服务, 如果**文件内容未发生变化**, 则**不触发handler**. 


也可以通过listen来触发想要的handler, 示例如下: 

```
handlers:
    - name: restart memcached
      service: name=memcached state=restarted
      listen: "restart web services"
    - name: restart apache
      service: name=apache state=restarted
      listen: "restart web services"

tasks:
    - name: restart everything
      command: echo "this task will restart the web services"
      notify: "restart web services"
```

## 4.3 使用role和include更好的组织playbook

### 4.3.1 role

上文给出的**webserver playbook**中, **task**和**hanler**的部分是最通用的, vars部分其次, hosts参数最次. 

其他人拿到这个playbook想到使用, 一般**不需要修改task**, 但是**host**和**vars**部分, 就需要修改成自己需要的值. 

所以ansible这里引入了**role的概念**, 把**host**从**playbook中移出**, 把**剩下的内容**按照下面示例的**样式**, 拆成几部分, 

- **handler**存放到**handlers目录**中, 
- **task**存放到**task目录**中去, 
- **默认变量**存放到**default**中, 
- 使用到的**文件'httpd.j2**'存放到**templates目录**下

按照这样的目录格式组织完成后, 我们就得到了一个**webserber role**. 

**tasks**中可以有很多task, 被执行的**入口**是**main.yml！！！**

```
# 官网的一个role目录结构的例子
site.yml
webservers.yml
fooservers.yml
roles/
   common/
     tasks/
         main.yml
     handlers/
     files/
     templates/
     defaults/
     meta/
   webservers/
     tasks/
         main.yml
     defaults/
     meta/
     templates/
```

**role的使用方法**, 可以参考下面的例子, 下面的playbook作用是: 对**所有的webservers**机器, 执行common, weservers, foo\_app\_instance对应的task, 执行最后一个role时, 传递了dir和app_port两个参数. 

```
---
- hosts: webservers
  roles:
     - common
     - webservers
     - { role: foo_app_instance, dir: '/opt/a', app_port: 5000 }
```

### 4.3.2 include

可以考虑这样两个问题: 

1. 上文我们定义webserver role作用是在指定服务器上安装并确保apache服务运行, 那么如果我们**想要升级**, **关闭或者卸载apache服务**呢, 该怎么办, 再定义新的role, webserver\-upgrade看起来似乎太蠢笨了. 能不能像面向对象那样, **一个对象支持不同的操作**?
2. 上文中的webserver服务安装比较简单, 所以我们的playbook也比较简单, 但是有时候会遇到比较麻烦的需求, 比如说**安装openstack的neutron服务**, 它需要**先检查设置**, **再生成配置文件**, **同步数据库**, 等步骤, 这项功能如果都写成一个playbook, 这个playbook是不是太大了, 很难维护. 可不可以把**检查**, **配置**, **同步**等功能做成**不同的playbook**, 然后从一个主playbook中看情况调用?

include功能可以解决这样的问题, 一个include的例子如下

```
tasks/
   bootstrap.yml
   ceph.yml
   config.yml
   check.yml
   deploy.yml
   upgrade.yml
   precheck.yml
   register.yml
   main.yml

main.yml
---
- include: "{{ action }}.yml"

deploy.yml
---
- include: ceph.yml
  when:
    - enable_ceph | bool and nova_backend == "rbd"
    - inventory_hostname in groups['ceph-mon'] or
      略

- include: register.yml
  when: inventory_hostname in groups['nova-api']

- include: config.yml

- include: bootstrap.yml
  when: inventory_hostname in groups['nova-api'] or
        inventory_hostname in groups['compute']

略
```

当**nova role**被赋给一台服务器后, 如果用户指定的**action是deploy**, **ansible**会引入**deploy.yml**, 如果是**upgrade**,则引入**upgrade.yml**. 这样根据用户参数的不同, **include不同的playbook**, 从而实现**一个role支持多种功能**. 

deploy playbook又由**多个不同的playbook组成**, 根据用户的配置的参数, 有不同的组合方式, 很灵活. 

我的理解是, 在**role**的**task**中, **一个play**就好像一个**内部函数**, **一个playbook**是由一个由**多个play组成的公有函数**, 被其他**playbook**根据**include参数组合调用**. 

# 5 kolla\-ansible中常见的ansible语法

kolla-ansible中的play都比上面的例子复杂很多, 它很多时候都不直接调用module, 而是加了很多判断, 循环, 错误处理之类的逻辑, 一个例子: 

```ansible
ansible.roles.prechecks.tasks.package_checks.yml
---
- name: Checking docker SDK version
  command: "/usr/bin/python -c \"import docker; print docker.__version__\""
  register: result
  changed_when: false
  when: inventory_hostname in groups['baremetal']
  failed_when: result | failed or
               result.stdout | version_compare(docker_py_version_min, '<')
```

这个playbook的功能是: 

1. 开始**执行book**中的**第一个play**: Checking docker SDK version
2. 判断**目标主机inventory\_hostname**是否属于**主机清单中的baremetal组**
3. 如果**属于**, 到这台主机上执行**command module**, **参数**是"/usr/bin/python -c "import docker; print docker.\_\_version\_\_""
4. 将**执行的结果**赋值给**result变量**(register)
5. 因为**这个模块不会更改目标主机上的任何设置**, 所以**change\_when是false**, 无论执行结果如何, 都不会去改变这个当然任务的changed属性
6. 将**result变量**传递给**failed函数**, 判断命令是否执行成功
7. 如果命令执行成功, 将result中的输出结果, 传递给version\_compare函数, 判断版本是否符合要求
8. 因为这个模块不会更改目标主机上的任何设置, 所以change\_when永远是false
9. 如果failed_when判断结果为失败, 则设置任务状态为失败, 停止执行此playbook

下面分别介绍几种kolla\-ansible中常用的ansible语法. 

## 5.1 条件语句

when, faild\_when, change_when 后面可以接入一个条件语句, 条件语句的值是true或者false, 条件语句示例如下: 

```
ansible_os_family == "Debian" 
test == 1 or run == always
hostname in [1,2,3,4]
```

ansible除了上文的==, or, in来进行判断外, **ansible**还支持通过**管道调用**ansible**自定义的test plugin**进行判断, 上文中的`result | failed or result.stdout | version_compare(docker_py_version_min, '<')`用到了**version\_compare**和**failed**两个**test plugin**, 这两个test plugin本质是**ansible指定目录下两个python函数**, 用来**解析字符串判断版本版本是否匹配**, 执行命令是否成功. 

它们的源码位于**ansible.plugins.test.core**, ansible. 

所有test plugin位于ansible.plugins.test, ansible支持自定义test plugin. 

## 5.2 迭代

with\_itmes 是ansible的迭代语句, 作用类似python的 for item in {}, 用法示例: 

```
- name: test list
  command: echo {{ item }}
  with_items: [ 0, 2, 4, 6, 8, 10 ]
  when: item > 56

- name: Setting sysctl values
  sysctl: name={{ item.name }} value={{ item.value }} sysctl_set=yes
  with_items:
    - { name: "net.bridge.bridge-nf-call-iptables", value: 1}
    - { name: "net.bridge.bridge-nf-call-ip6tables", value: 1}
    - { name: "net.ipv4.conf.all.rp_filter", value: 0}
    - { name: "net.ipv4.conf.default.rp_filter", value: 0}
  when:
    - set_sysctl | bool
    - inventory_hostname in groups['compute']
```

## 5.3 failed\_when

一种错误处理机制, 一般用来检测执行的结果, 如果执行失败, 终止任务, 和条件语句搭配使用

## 5.4 changed\_when

当我们控制一些远程主机执行某些任务时, 当任务在远程主机上成功执行, 状态发生更改时, 会返回changed状态响应, 状态未发生更改时, 会返回OK状态响应, 当任务被跳过时, 会返回skipped状态响应. 我们可以通过changed_when来手动更改changed响应状态. 

## 5.5 run\_once

当对一个主机组赋予进行操作时, 有部分操作并不需要在每个主机上都执行, 比如说nova服务安装时, 需要初始化nova数据库, 这个操作只需要在一个节点上执行一次就可以了, 这种情况可以使用run_once标记, 被标记的任务不会在多个节点上重复执行. 

delegate_to可以配合run_once使用, 可以在playbook中指定数据库任务要执行的主机, 下面的例子中, 指定要执行数据库创建的主机是groups['nova\-api'][0]

```
- name: Creating Nova databases
  kolla_toolbox:
    module_name: mysql_db
    module_args:
      login_host: "{{ database_address }}"
      login_port: "{{ database_port }}"
      login_user: "{{ database_user }}"
      login_password: "{{ database_password }}"
      name: "{{ item }}"
  register: database
  run_once: True
  delegate_to: "{{ groups['nova-api'][0] }}"
  with_items:
    - "{{ nova_database_name }}"
    - "{{ nova_database_name }}_cell0"
    - "{{ nova_api_database_name }}"
```

delegate_to指定的机器可以当前任务的机器没有任何关系, 比如, 在部署nova服务时, 可以delegate_to的目标不限于nova机器, 可以到delegate_to ansible控制节点或者存储机器上执行任务. 例如: 

hosts: app_servers
tasks:
name: gather facts from db servers
setup:
delegate_to: "{{item}}"
delegate_facts: True
with_items: "{{groups['dbservers'}}"
该例子会收集dbservers的facts并分配给这些机器, 而不会去收集app_servers的facts

## 5.6 serial

一般情况下, ansible会同时在所有服务器上执行用户定义的操作, 但是用户可以通过serial参数来定义同时可以在多少太机器上执行操作.

name: test play
hosts: webservers
serial: 3
webservers组中的3台机器完全完成play后, 其他3台机器才会开始执行

## 5.7 until

这种循环由三个指令完成: 

until是一个条件表达式, 如果满足条件循环结束
retry是重试的次数
delay是延迟时间
示例如下: 

action: shell /usr/bin/foo
register: result
until: result.stdout.find("all systems go") != -1
retries: 5
delay:

## 5.8 wait_for

wait_for 可以让ansible等待一段时间, 直到条件满足, 再继续向下执行, 这个模块主要用来等待之前的操作完成, 比如服务启动成功, 锁释放. 

下面是一个kolla-ansible判断murano-api服务是否启动成功的例子: 
在murano-api[0]节点上, 尝试和api_interface_address:murano_api_port建立链接, 如果成功建立连接, 结束等待. 如果1秒(connect_timeout)内未建立成功, 放弃, 休眠1秒(参数sleep, 未配置, 默认值)后重试, 如果60秒(timeout)内没有成功创建链接, 任务失败. 

- name: Waiting for Murano API service to be ready on first node
  wait_for:
    host: "{{ api_interface_address }}"
    port: "{{ murano_api_port }}"
    connect_timeout: 1
    timeout: 60
  run_once: True
  delegate_to: "{{ groups['murano-api'][0] }}"

# 6 参考

- https://www.cnblogs.com/zhangyufei/p/7645804.html
- ansible入门书: https://ansible-book.gitbooks.io/ansible-first-book/content/begin/basic_module/module_list_details.html
- ansible循环用法: http://www.cnblogs.com/PythonOrg/p/6593910.html
- 自定义过滤器:http://rfyiamcool.blog.51cto.com/1030776/1440686/
- 异步和轮询: http://www.mamicode.com/info-detail-1202005.html
- ansible 语法: http://blog.csdn.net/ggz631047367/article/details/50359127
- ansible官网: http://docs.ansible.com/ansible/latest/