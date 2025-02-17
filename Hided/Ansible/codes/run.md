
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [compute_name.yml](#compute_nameyml)
* [date.yml](#dateyml)
* [test.yml](#testyml)

<!-- /code_chunk_output -->

# compute_name.yml

```
[root@controller124 tools]# ansible-playbook -i ../../multinode test.yml

PLAY [Test] *************************************************************************************************************************

TASK [Get compute node name] ********************************************************************************************************
ok: [localhost] => (item=compute1) => {
    "msg": "compute1"
}
ok: [localhost] => (item=controller124) => {
    "msg": "controller124"
}

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=1    changed=0    unreachable=0    failed=0
```

# date.yml

```
# ansible-playbook -i ../../multinode data.yml

PLAY [Print debug infomation eg1] ***************************************************************************************************

TASK [Command run line] *************************************************************************************************************
changed: [compute1]

TASK [Show debug info] **************************************************************************************************************
ok: [compute1] => {
    "result": {
        "changed": true,
        "cmd": "date",
        "delta": "0:00:00.002723",
        "end": "2019-05-13 05:20:32.249264",
        "failed": false,
        "rc": 0,
        "start": "2019-05-13 05:20:32.246541",
        "stderr": "",
        "stderr_lines": [],
        "stdout": "2019年 05月 13日 星期一 05:20:32 EDT",
        "stdout_lines": [
            "2019年 05月 13日 星期一 05:20:32 EDT"
        ]
    }
}

PLAY RECAP **************************************************************************************************************************
compute1                   : ok=2    changed=1    unreachable=0    failed=0

```

# test.yml

```
# ansible-playbook -i ../../multinode test.yml

# hosts: deployment
PLAY [Test] *************************************************************************************************************************

TASK [show shell info] **************************************************************************************************************
changed: [localhost] => (item=groups['compute'])

TASK [show debug info] **************************************************************************************************************
ok: [localhost] => (item=groups['compute']) => {
    "msg": "host is groups['compute']"
}

TASK [debug] ************************************************************************************************************************
ok: [localhost] => (item=compute1) => {
    "msg": "compute1"
}
ok: [localhost] => (item=controller124) => {
    "msg": "controller124"
}
ok: [localhost] => (item=localhost) => {
    "msg": "localhost"
}

TASK [debug] ************************************************************************************************************************
ok: [localhost] => (item=localhost) => {
    "msg": "localhost"
}

PLAY RECAP **************************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0
```

```
# hosts: compute
PLAY [Test] *************************************************************************************************************************

TASK [show shell info] **************************************************************************************************************
changed: [controller124] => (item=groups['compute'])
changed: [compute1] => (item=groups['compute'])

TASK [show debug info] **************************************************************************************************************
ok: [compute1] => (item=groups['compute']) => {
    "msg": "host is groups['compute']"
}
ok: [controller124] => (item=groups['compute']) => {
    "msg": "host is groups['compute']"
}

TASK [debug] ************************************************************************************************************************
ok: [compute1] => (item=compute1) => {
    "msg": "compute1"
}
ok: [compute1] => (item=controller124) => {
    "msg": "controller124"
}
ok: [compute1] => (item=localhost) => {
    "msg": "localhost"
}
ok: [controller124] => (item=compute1) => {
    "msg": "compute1"
}
ok: [controller124] => (item=controller124) => {
    "msg": "controller124"
}
ok: [controller124] => (item=localhost) => {
    "msg": "localhost"
}

TASK [debug] ************************************************************************************************************************
ok: [compute1] => (item=compute1) => {
    "msg": "compute1"
}
ok: [compute1] => (item=controller124) => {
    "msg": "controller124"
}
ok: [controller124] => (item=compute1) => {
    "msg": "compute1"
}
ok: [controller124] => (item=controller124) => {
    "msg": "controller124"
}

PLAY RECAP **************************************************************************************************************************
compute1                   : ok=4    changed=1    unreachable=0    failed=0
controller124              : ok=4    changed=1    unreachable=0    failed=0
```
