ssh-copy-id 得用name而不是ip去copy


查看group为"baremetal"的值:

ansible baremetal -m setup -i ../../multinode > /home/baremetal


```
./kolla-ansible deploy -i ../../multinode --limit controller124
```

