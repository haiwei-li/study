
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1 概述](#1-概述)
- [2 reconfigure使用](#2-reconfigure使用)
- [3 reconfigure 代码流程](#3-reconfigure-代码流程)
  - [3.1 ansible role是什么?](#31-ansible-role是什么)
  - [3.2 reconfigure具体代码](#32-reconfigure具体代码)
    - [3.2.1 config.yml](#321-configyml)
- [参考](#参考)

<!-- /code_chunk_output -->

# 1 概述

kolla的配置管理主要是管理openstack service config文件; 

主要实现是

```
kolla-ansible reconfigure
```

# 2 reconfigure使用

下面以1个例子来演示下

修改nova.conf,重启相关服务

在部署节点

```
### 修改rpc_response超时时间
vim ／etc/kolla/config/nova/nova.conf
rpc_response_timeout = 350

## 执行reconfigure
kolla-ansible reconfigure
```

# 3 reconfigure 代码流程

kolla-ansible 的核心代码在ansible实现的

先介绍下ansible role是什么?如何使用?

先看看下面nova role的代码目录

```
[root@control01 ansible]# tree -d
.
├── action_plugins
├── group_vars
├── inventory
├── library
└── roles
    ├── nova
    │   ├── defaults
    │   ├── handlers
    │   ├── meta
    │   ├── tasks
    │   └── templates
    .  
    .
    .
```

## 3.1 ansible role是什么?

Ansible Role 是一种分类 & 重用的概念, 透过将 vars, tasks, files, templates, handler ... 等等根据不同的目的(例如: nova、glance、cinder), 规划后至于独立目录中, 后续便可以利用 include 的概念來使用. 

若同样是 include 的概念, 那 role 跟 include 之间不一样的地方又是在哪里呢?

答案是: role 的 include 机制是自动的!

我们只要提前将 role 的 vars / tasks / files / handler .... 等等事先定义好按照特定的结构(下面會提到)放好, Ansible 就会自动 include 完成, 不需要再自己一个一个指定 include. 

透过这样的方式, 管理者可以透过設定 role 的方式將所需要安裝設定的功能分门别类, 拆成细项來管理并编写相对应的 script, 让原本可能很庞大的设定工作可以细分成多个不同的部分來分別设定, 不仅仅可以让自己重复利用特定的设定, 也可以共享給其他人一同使用. 

要设计一個 role, 必須先知道怎麼將 files / templates / tasks / handlers / vars .... 等等拆开设定

看看下面kolla-ansible下nova role的代码目录

```
[root@control01 ansible]# tree -d
.
├── action_plugins
├── group_vars
├── inventory
├── library
└── roles
    ├── nova
    │   ├── defaults
    │   ├── handlers
    │   ├── meta
    │   ├── tasks
    │   └── templates
    .  
    .
    .
```

以上就是一个基本完整的一个role结构, 当然还有file、vars; 我们这里没有使用这个2个; 如果没有的部分可以不用. 

ansible会针对role(x)进行以下处理: 

1. 如果role/x/**task**/main.yml存在, 则会**自动**加到playbook中的**task list**中
2. 如果role/x/**handlers**/main.yml存在, 则会自动加到playbook中的**handler list**中
3. 如果role/x/**vars**/mani.yml存在, 则会自动加入到playbook中的variables list中
4. 如果role/x/**meta**/main.yml存在, 任何与**指定的role**想**依赖的其他的role设置**都会被**自动加入**
5. roles/x/**templates**/ 目录中的 **template tasks**, 在 playbook 中使用时**不需要指定绝对(absolutely**) or **相对(relatively)路径**
6. 在 roles/x/**files**/ 目录中的 copy tasks 或是 script tasks, 在 playbook 中使用时不需要指定绝对(absolutely) or 相对(relatively)路径
7. 定义在 roles/x/defaults/main.yml 中的**变量**將会是**使用该role时所取得的预设变量**

## 3.2 reconfigure具体代码

再返回来看来 kolla-ansible reconfigure 具体代码就能理解了

```
[root@control01 ansible]# kolla-ansible reconfigure
Reconfigure OpenStack service : ansible-playbook -i /usr/share/kolla-ansible/ansible/inventory/all-in-one -e @/etc/kolla/globals.yml -e @/etc/kolla/passwords.yml -e CONFIG_DIR=/etc/kolla  -e action=reconfigure -e serial=0 /usr/share/kolla-ansible/ansible/site.yml
```

以 glance tasks main.yml为例

```
[root@control01 tasks]# cat /root/kolla-ansible/ansible/roles/glance/tasks/main.yml
---
- include: "{{ action }}.yml"
```

从上面命令就可以看出, tasks是根据action去找相应的操作. 那我们去跳到reconfigure.yml

```
[root@control01 tasks]# cat reconfigure.yml
---
- include: deploy.yml
```

```
[root@control01 tasks]# cat deploy.yml
---
- include: ceph.yml
  when:
    - (enable_ceph | bool) and (glance_backend_ceph | bool)
    - inventory_hostname in groups['ceph-mon'] or
      inventory_hostname in groups['glance-api'] or
      inventory_hostname in groups['glance-registry']
- include: external_ceph.yml
  when:
    - (enable_ceph | bool == False) and (glance_backend_ceph | bool)
    - inventory_hostname in groups['glance-api'] or
      inventory_hostname in groups['glance-registry']
- include: register.yml
  when: inventory_hostname in groups['glance-api']
- include: config.yml
  when: inventory_hostname in groups['glance-api'] or
        inventory_hostname in groups['glance-registry']
- include: bootstrap.yml
  when: inventory_hostname in groups['glance-api']
- name: Flush handlers
  meta: flush_handlers
- include: check.yml
  when: inventory_hostname in groups['glance-api'] or
        inventory_hostname in groups['glance-registry']
```

整体的一个脉络流程就是这样; 

下面我们一个一个去细看他们的实现. 

这里我们主要是看config.yml和flush_handlers这个2个的实现

### 3.2.1 config.yml

config.yml 是用来**生成openstack sevice config文件**

```
[root@control01 tasks]# cat config.yml
---
### 生成 node_config_directory(默认是/etc/kolla,  你可以在all.yml中设置)sevice目录
- name: Ensuring config directories exist
  file:
    path: "{{ node_config_directory }}/{{ item.key }}"
    state: "directory"
    recurse: yes
  when:
    - inventory_hostname in groups[item.value.group]
    - item.value.enabled | bool
  with_dict: "{{ glance_services }}"
### copy config.json file 到node_config_directory/service 目录下
- name: Copying over config.json files for services
  template:
    src: "{{ item.key }}.json.j2"
    dest: "{{ node_config_directory }}/{{ item.key }}/config.json"
  register: glance_config_jsons
  when:
    - item.value.enabled | bool
    - inventory_hostname in groups[item.value.group]
  with_dict: "{{ glance_services }}"
  notify:
    - Restart glance-api container
    - Restart glance-registry container
- name: Copying over glance-*.conf
  merge_configs:
    vars:
      service_name: "{{ item.key }}"
    sources:
      - "{{ role_path }}/templates/{{ item.key }}.conf.j2"
      - "{{ node_custom_config }}/global.conf"
      - "{{ node_custom_config }}/database.conf"
      - "{{ node_custom_config }}/messaging.conf"
      - "{{ node_custom_config }}/glance.conf"
      - "{{ node_custom_config }}/glance/{{ item.key }}.conf"
      - "{{ node_custom_config }}/glance/{{ inventory_hostname }}/{{ item.key }}.conf"
    dest: "{{ node_config_directory }}/{{ item.key }}/{{ item.key }}.conf"
  register: glance_confs
  when:
    - item.value.enabled | bool
    - inventory_hostname in groups[item.value.group]
  with_dict: "{{ glance_services }}"
  notify:
    - Restart glance-api container
    - Restart glance-registry container
- name: Check if policies shall be overwritten
  local_action: stat path="{{ node_custom_config }}/glance/policy.json"
  register: glance_policy
- name: Copying over existing policy.json
  template:
    src: "{{ node_custom_config }}/glance/policy.json"
    dest: "{{ node_config_directory }}/{{ item.key }}/policy.json"
  register: glance_policy_jsons
  when:
    - glance_policy.stat.exists
    - inventory_hostname in groups[item.value.group]
  with_dict: "{{ glance_services }}"
  notify:
    - Restart glance-api container
    - Restart glance-registry container
- name: Check glance containers
  kolla_docker:
    action: "compare_container"
    common_options: "{{ docker_common_options }}"
    name: "{{ item.value.container_name }}"
    image: "{{ item.value.image }}"
    volumes: "{{ item.value.volumes }}"
  register: check_glance_containers
  when:
    - action != "config"
    - inventory_hostname in groups[item.value.group]
    - item.value.enabled | bool
  with_dict: "{{ glance_services }}"
  notify:
    - Restart glance-api container
    - Restart glance-registry container
```

这里最核心的实现就是**merge\_configs**. 

action plugin中在**merge\_configs.py**作用是导入template模板, 并且run. 代码在/usr/share/kolla-ansible/ansible/action\_plugins/merge\_configs.py

```python
import collections
import inspect
import os
from ansible.plugins import action
from six import StringIO
from oslo_config import iniparser
class OverrideConfigParser(iniparser.BaseParser):
    def __init__(self):
        self._cur_sections = collections.OrderedDict()
        self._sections = collections.OrderedDict()
        self._cur_section = None
    def assignment(self, key, value):
        cur_value = self._cur_section.get(key)
        if len(value) == 1 and value[0] == '':
            value = []
        if not cur_value:
            self._cur_section[key] = [value]
        else:
            self._cur_section[key].append(value)
    def parse(self, lineiter):
        self._cur_sections = collections.OrderedDict()
        super(OverrideConfigParser, self).parse(lineiter)
        # merge _cur_sections into _sections
        for section, values in self._cur_sections.items():
            if section not in self._sections:
                self._sections[section] = collections.OrderedDict()
            for key, value in values.items():
                self._sections[section][key] = value
    def new_section(self, section):
        cur_section = self._cur_sections.get(section)
        if not cur_section:
            cur_section = collections.OrderedDict()
            self._cur_sections[section] = cur_section
        self._cur_section = cur_section
        return cur_section
    def write(self, fp):
        def write_key_value(key, values):
            for v in values:
                if not v:
                    fp.write('{} =\n'.format(key))
                for index, value in enumerate(v):
                    if index == 0:
                        fp.write('{} = {}\n'.format(key, value))
                    else:
                        fp.write('{}   {}\n'.format(len(key)*' ', value))
        def write_section(section):
            for key, values in section.items():
                write_key_value(key, values)
        for section in self._sections:
            fp.write('[{}]\n'.format(section))
            write_section(self._sections[section])
            fp.write('\n')
class ActionModule(action.ActionBase):
    TRANSFERS_FILES = True
    def read_config(self, source, config):
        # Only use config if present
        if os.access(source, os.R_OK):
            with open(source, 'r') as f:
                template_data = f.read()
            result = self._templar.template(template_data)
            fakefile = StringIO(result)
            config.parse(fakefile)
            fakefile.close()
    def run(self, tmp=None, task_vars=None):
        if task_vars is None:
            task_vars = dict()
        result = super(ActionModule, self).run(tmp, task_vars)
        # NOTE(jeffrey4l): Ansible 2.1 add a remote_user param to the
        # _make_tmp_path function.  inspect the number of the args here. In
        # this way, ansible 2.0 and ansible 2.1 are both supported
        make_tmp_path_args = inspect.getargspec(self._make_tmp_path)[0]
        if not tmp and len(make_tmp_path_args) == 1:
            tmp = self._make_tmp_path()
        if not tmp and len(make_tmp_path_args) == 2:
            remote_user = (task_vars.get('ansible_user')
                           or self._play_context.remote_user)
            tmp = self._make_tmp_path(remote_user)
        sources = self._task.args.get('sources', None)
        extra_vars = self._task.args.get('vars', list())
        if not isinstance(sources, list):
            sources = [sources]
        temp_vars = task_vars.copy()
        temp_vars.update(extra_vars)
        config = OverrideConfigParser()
        old_vars = self._templar._available_variables
        self._templar.set_available_variables(temp_vars)
        for source in sources:
            self.read_config(source, config)
        self._templar.set_available_variables(old_vars)
        # Dump configparser to string via an emulated file
        fakefile = StringIO()
        config.write(fakefile)
        remote_path = self._connection._shell.join_path(tmp, 'src')
        xfered = self._transfer_data(remote_path, fakefile.getvalue())
        fakefile.close()
        new_module_args = self._task.args.copy()
        new_module_args.pop('vars', None)
        new_module_args.pop('sources', None)
        new_module_args.update(
            dict(
                src=xfered
            )
        )
        result.update(self._execute_module(module_name='copy',
                                           module_args=new_module_args,
                                           task_vars=task_vars,
                                           tmp=tmp))
        return result
```

# 参考

http://zhubingbing.cn/2017/07/09/openstack/kolla-reconfigure/

