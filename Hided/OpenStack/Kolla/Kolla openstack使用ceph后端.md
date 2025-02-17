
OpenStack 里有三个地方可以和 Ceph 块设备结合: 

- Images:  OpenStack 的 Glance 管理着 VM 的 image . Image 相对恒定,  OpenStack 把它们当作二进制文件、并以此格式下载. 
- Volumes:  Volume 是块设备,  OpenStack 用它们引导虚拟机、或挂载到运行中的虚拟机上.  OpenStack 用 Cinder 服务管理 Volumes . 
- Guest Disks: Guest disks 是装有客户操作系统的磁盘. 默认情况下, 启动一台虚拟机时, 它的系统盘表现为 hypervisor 文件系统的一个文件(通常位于 /var/lib/nova/instances/<uuid>/). 在 Openstack Havana 版本前, 在 Ceph 中启动虚拟机的唯一方式是使用 Cinder 的 boot-from-volume 功能. 不过, 现在能够在 Ceph 中直接启动虚拟机而不用依赖于 Cinder, 这一点是十分有益的, 因为可以通过热迁移更方便地进行维护操作. 另外, 如果你的 hypervisor 挂掉了, 也可以很方便地触发 nova evacuate , 并且几乎可以无缝迁移虚拟机到其他地方. 

# 1 配置ceph

## 1.1 创建存储池

### 1.1.1 创建镜像pool

用于保存Glance镜像

```
$ sudo ceph osd pool create images 2048 2048
pool 'images' created
```

### 1.1.2 创建卷pool

用于保存cinder的卷

```
$ sudo ceph osd pool create volumes 2048 2048
pool 'volume' created
```

用于保存cinder的卷备份

```
$ sudo ceph osd pool create backups 2048 2048
pool 'backups' created
```

### 1.1.3 创建虚拟机pool

用于保存虚拟机系统卷

```
$ sudo ceph osd pool create vms 2048 2048
pool 'vm' created
```

### 1.1.4 查看pool

```
$ sudo ceph osd lspools
3 volume,4 vm,5 images,6 rbd,7 backups,
```

## 1.2 创建用户

### 1.2.1 创建Glance用户

创建glance用户, 并给images存储池访问权限

```
$ sudo ceph auth get-or-create client.glance
[client.glance]
	key = AQC+3IVc37ZBEhAAS/F/FgSoGn5xYsclBs8bQg==

$ sudo ceph auth caps client.glance mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=images'
updated caps for client.glance
```

查看并保存glance用户的keyring文件

```
$ sudo ceph auth get client.glance
exported keyring for client.glance
[client.glance]
	key = AQDUwYhck8ztNhAAwi14fGR2OvMXQwLMPNJFVg==
	caps mon = "allow r"
	caps osd = "allow class-read object_prefix rbd_children, allow rwx pool=images"

$ sudo ceph auth get client.glance -o /var/openstack/ceph/ceph.client.glance.keyring
exported keyring for client.glance
```

### 1.2.2 创建Cinder用户

创建cinder-volume用户, 并给volume存储池权限

```
$ sudo ceph auth get-or-create client.cinder-volume
[client.cinder-volume]
	key = AQAf3oVcN2nMORAAl740sqdkcwE/8a/niSTIeg==

$ ceph auth caps client.cinder-volume mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images'
updated caps for client.cinder-volume
```

查看并保存cinder-volume用户的keyring文件

```
$ sudo ceph auth get client.cinder-volume
exported keyring for client.cinder-volume
[client.cinder-volume]
	key = AQDVwYhcaWb9IBAABJC+LDNPmVky6gFL0gK4yQ==
	caps mon = "allow r"
	caps osd = "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rx pool=images"

$ sudo ceph auth get client.cinder-volume -o /var/openstack/ceph/ceph.client.cinder-volume.keyring
exported keyring for client.cinder-volume
```

创建cinder-backup用户, 并给volume和backups存储池权限

```
$ sudo ceph auth get-or-create client.cinder-backup
[client.cinder-backup]
	key = AQDH3oVcaAfVJxAAMvwYBYLKNP86OkT6lPNMRQ==

$ sudo ceph auth caps client.cinder-backup mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=backups'
updated caps for client.cinder-backup
```

查看并保存cinder-backup用户的KeyRing文件

```
$ sudo ceph auth get client.cinder-backup
exported keyring for client.cinder-backup
[client.cinder-backup]
	key = AQDWwYhcZrliCxAAKDFlvyBQ7lY+tAFhDtwREg==
	caps mon = "allow r"
	caps osd = "allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=backups"

$ sudo ceph auth get client.cinder-backup -o /var/openstack/ceph/ceph.client.cinder-backup.keyring
exported keyring for client.cinder-backup
```

### 1.2.3 创建Nova用户

创建nova用户, 并给vm存储池权限

```
$ sudo ceph auth get-or-create client.nova
[client.nova]
	key = AQA334VczU4tOBAAdvUyAv2wsn02MdQiW4o8sg==

$ sudo ceph auth caps client.nova mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images'
updated caps for client.nova
```

查看并保存nova用户的keyring文件

```
$ $ sudo ceph auth get client.nova
exported keyring for client.nova
[client.nova]
	key = AQDWwYhcHdDCMBAA5c1skJ54ZyjfaA68dUXhHw==
	caps mon = "allow r"
	caps osd = "allow class-read object_prefix rbd_children, allow rwx pool=vms, allow rwx pool=volumes, allow rwx pool=images"

$ sudo ceph auth get client.nova -o /var/openstack/ceph/ceph.client.nova.keyring
exported keyring for client.nova
```

## 1.3 同步ceph配置文件以及用户keyring文件

```
$ ssh {部署节点} sudo tee /etc/ceph/ceph.conf </etc/ceph/ceph.conf
$ scp /var/openstack/ceph/* root@{部署节点}:/etc/ceph/
```

# 2 配置Kolla-Ansible

按照AutoStack配置, 在部署节点, 其配置阶段做下面关于ceph的工作

## 2.1 配置服务

在配置阶段, 修改global.yml的下面配置项

```
# 禁止在当前节点部署ceph
enable_ceph: "no"

# 开启cinder服务
enable_cinder: "yes"

# 开启cinder glance和nova的后端ceph功能
glance_backend_ceph: "yes"
cinder_backend_ceph: "yes"
nova_backend_ceph: "yes"
```

根据自己的情况, 修改global.yml文件

kolla网络相关参数

- network\_interface: 为下面几种interface提供默认值
- api_interface: 用于management network,即openstack内部服务间通信, 以及服务于数据库通信的网络. 这是系统的风险点, 所以, 这个网络推荐使用内网, 不能够接出到外网, 默认值为: network_interface
- kolla_external_vip_interface: 这是一个公网网段, 当你想要HAProxy Public endpoint暴漏在不同的网络中的时候, 需要用到. 当kolla_enables_tls_external设置为yes的时候, 是个必选项. 默认值为: network\_interface
- storage\_interface: 虚拟机与Ceph通信接口, 这个接口负载较重, 推荐放在10Gig网口上. 默认值为: network\_interface
- cluster\_interface: 这是Ceph用到的另外一个接口, 用于数据的replication, 这个接口同样负载很重, 当其成为bottleneck的时候, 会影响数据的一致性和整个集群的性能, 只有当前节点是ceph节点时候才有效. 默认: network_interface
- tunnel_interface: 这个接口用于虚拟机与虚拟机之间的通信, 通过 tunneled网路进行, 比如: Vxlan, GRE等, 默认为: network_interface
- neutron_external_interface: 这是Neutron提供VM对外网络的接口, Neutron会将其绑定在br-ex上, 既可以是flat网络, 也可以是tagged vlan网络, 必须单独设置

使用ceph的话需要修改storage\_interface和cluster\_interface

## 2.2 配置Glance

配置glance使用glance用户以及images存储池

### 2.2.1 glance服务的存储池相关配置文件

最终效果是, 在kolla\-ansible配置目录下创建目录glance, 下面不要手动配置, 见下面操作

```
$ mkdir -p /etc/kolla/config/glance

$ cat /etc/kolla/config/glance/glance-api.conf
[glance_store]
stores = rbd
default_store = rbd
rbd_store_pool = images
rbd_store_user = glance
rbd_store_ceph_conf = /etc/ceph/ceph.conf
```

下面针对上面需要生成的conf文件, 需要手动配置是如下内容

其中, 当globals.yml中"glance\_backend\_ceph"为"yes"时候, 根据文件"kolla-ansible/ansible/roles/glance/defaults/main.yml"中的"glance\_store\_backends"会在"kolla-ansible/ansible/roles/glance/templates/glance\-api.conf.j2"文件中的"stores"值会变成

```
stores = rbd     
```

配置文件生成原理, 参见kolla-ansible/ansible/roles/cinder/tasks/config.yml中的"name: Copying over cinder.conf"

当"glance\_backend\_ceph"为"yes"时, 在glance\-api.conf.j2中会显示为

```          
default_store = rbd
```

通过修改all.yml中的"ceph\_glance\_pool\_name"可定义如下属性

```
rbd_store_pool = images
```

当"glance\_backend\_ceph"为"yes"时, 在glance\-api.conf.j2中会显示为下面值, 当然可以自己修改该值或者在conf中和all.yml中添加变量, 尽量在all.yml中配置信息; 我已经修改了all.yml和glance\-api.conf.j2

```
rbd_store_user = glance
```

我已经修改glance\-api.conf.j2文件, 添加了"rbd_store\_ceph\_conf = {{ ceph_conf_path }}", 然后在all.yml中添加变量并赋值ceph_conf_path: "/etc/ceph/ceph.conf", 因为ceph的配置文件是全局的, 所以默认会生成

```
rbd_store_ceph_conf = /etc/ceph/ceph.conf
```

### 2.2.2 ceph客户端配置以及glance用户的keyring文件

新增glance的ceph客户端配置, 参照ceph的ceph.conf文件内容, 这个文件在各个服务之间是通用的

```
$ cat /etc/kolla/config/glance/ceph.conf
[global]
fsid = 9853760c-b976-4e3c-8228-9f7a76c336bc
mon_initial_members = BJ-IDC1-10-10-31-26
mon_host = 10.10.31.26
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
```

glance用户的keyring文件拷贝

```
$ cp /etc/ceph/ceph.client.glance.keyring /etc/kolla/config/glance/ceph.client.glance.keyring
```

## 2.3 配置Cinder

配置Cinder卷服务使用Ceph的cinder-volume用户使用volume存储池, Cinder卷备份服务使用Ceph的cinder-backup用户使用backups存储池: 

### 2.3.1 cinder\-volume服务的存储池相关配置文件

最终效果是, 创建cinder目录, 下面不要手动配置, 见下面操作

```
$ mkdir -p /etc/kolla/config/cinder

$ cat /etc/kolla/config/cinder/cinder-volume.conf
[DEFAULT]
enabled_backends=rbd-1

[rbd-1]
rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=cinder-volume
backend_host=rbd:volumes
rbd_pool=volumes
volume_backend_name=rbd-1
volume_driver=cinder.volume.drivers.rbd.RBDDriver
rbd_secret_uuid = {{ cinder_rbd_secret_uuid }}
```

下面针对上面需要生成的conf文件, 需要手动配置是如下内容

其中, 我已修改main.yml, 使得global.yml中的"cinder\_backend\_ceph"为"yes", 根据"kolla-ansible/ansible/roles/cinder/defaults/main.yml"文件中的"cinder\_enabled\_backends"从而最终在"kolla\-ansible/ansible/roles/cinder/templates/cinder.conf.j2"中生成如下

```
enabled_backends=rbd-1
```

在all.yml中配置"ceph_conf_path"为全局配置

```
rbd_ceph_conf = /etc/ceph/ceph.conf
```

global.yml中的"cinder\_backend\_ceph"为"yes", 下面内容是默认的, 

```
volume_backend_name = rbd-1
volume_driver = cinder.volume.drivers.rbd.RBDDriver
rbd_secret_uuid = {{ cinder_rbd_secret_uuid }}
```

我已经添加了"backend\_host=rbd:{{ ceph\_cinder\_pool\_name }}", 所以在kolla-ansible/ansible/group_vars/all.yml中修改"ceph\_cinder\_pool\_name", 在kolla-ansible/ansible/group_vars/all.yml中修改"ceph_cinder_user_name"(这个对应cinder-volume的user名), 即可实现

```
backend_host=rbd:{{ ceph_cinder_pool_name }}
rbd_pool={{ ceph_cinder_pool_name }}
rbd_user={{ ceph_cinder_user_name }}
```

### 2.3.2 cinder\-backup服务的存储池相关配置文件

最终效果, 先不手动配置

```
$ cat /etc/kolla/config/cinder/cinder-backup.conf
[DEFAULT]
backup_ceph_conf=/etc/ceph/ceph.conf
backup_ceph_user=cinder-backup
backup_ceph_chunk_size = 134217728
backup_ceph_pool=backups
backup_driver = cinder.backup.drivers.ceph.CephBackupDriver
backup_ceph_stripe_unit = 0
backup_ceph_stripe_count = 0
restore_discard_excess_bytes = true
```

通过all.yml中的"ceph_conf_path"配置ceph配置文件路径, 这是全局的.

```
backup_ceph_conf=/etc/ceph/ceph.conf
```

通过all.yml中的"ceph_cinder_backup_user_name"配置cinder-backup对应的pool的user名字, 通过"ceph_cinder_backup_pool_name"配置pool名字

```
backup_ceph_user=cinder-backup
backup_ceph_pool=backups
```

下面是默认值, enable_cinder_backup为yes就可以了

```
backup_ceph_chunk_size = 134217728
backup_driver = cinder.backup.drivers.ceph.CephBackupDriver
backup_ceph_stripe_unit = 0
backup_ceph_stripe_count = 0
restore_discard_excess_bytes = true
```

### 2.3.3 ceph客户端配置和keyring文件

新增Cinder的卷服务和卷备份服务的Ceph客户端配置和KeyRing文件: 

```
$ cp /etc/kolla/config/glance/ceph.conf /etc/kolla/config/cinder/ceph.conf

$ mkdir -p /etc/kolla/config/cinder/cinder-backup/ /etc/kolla/config/cinder/cinder-volume/

$ cp -v /etc/ceph/ceph.client.cinder-volume.keyring /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-volume.keyring

$ cp -v /etc/ceph/ceph.client.cinder-backup.keyring /etc/kolla/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring

$ cp -v /etc/ceph/ceph.client.cinder-volume.keyring /etc/kolla/config/cinder/cinder-volume/ceph.client.cinder-volume.keyring

$ cp -v /etc/ceph/ceph.client.glance.keyring /etc/kolla/config/cinder/cinder-volume/ceph.client.glance.keyring

$ cp -v /etc/ceph/ceph.client.nova.keyring /etc/kolla/config/cinder/cinder-volume/ceph.client.nova.keyring
```

## 2.4 配置nova

### 2.4.1 nova\-compute服务的存储池相关配置文件

配置Nova使用Ceph的nova用户使用vm存储池, 手动配置目的是, 新方案往下走: 

```
$ mkdir -p /etc/kolla/config/nova

$ cat /etc/kolla/config/nova/nova-compute.conf
[libvirt]
images_rbd_pool=vms
images_type=rbd
images_rbd_ceph_conf=/etc/ceph/ceph.conf
rbd_user=nova
```

配置all.yml的"ceph_nova_pool_name"即可

```
images_rbd_pool=vms
```

下面内容默认

```
images_type=rbd
```

通过all.yml中的"ceph_conf_path"配置ceph配置文件路径, 这是全局的.

```
images_rbd_ceph_conf=/etc/ceph/ceph.conf
```

通过all.yml中的ceph_nova_user_name即可修改

```
rbd_user=nova
```

### 2.4.2 ceph客户端配置和keyring文件


新增nova的客户端配置和keyring文件

```
$ cp -v /etc/kolla/config/glance/ceph.conf /etc/kolla/config/nova/ceph.conf

$ cp -v /etc/ceph/ceph.client.nova.keyring /etc/kolla/config/nova/ceph.client.nova.keyring

$ cp -v /etc/ceph/ceph.client.cinder-volume.keyring /etc/kolla/config/nova/ceph.client.cinder.keyring

$ cp -v /etc/ceph/ceph.client.glance.keyring /etc/kolla/config/nova/ceph.client.glance.keyring
```

注: 这里的nova使用cinder-volume的keyring文件必须改为cinder.keyring

```
# ll /etc/kolla/config/*/
/etc/kolla/config/cinder/:
总用量 12
-rw-r--r--. 1 root root 276 4月   9 23:43 ceph.conf
drwxr-xr-x. 2 root root  88 4月   9 23:43 cinder-backup
-rw-r--r--. 1 root root 291 4月   9 23:42 cinder-backup.conf
drwxr-xr-x. 2 root root 113 4月   9 23:44 cinder-volume
-rw-r--r--. 1 root root 264 4月   9 23:42 cinder-volume.conf

/etc/kolla/config/glance/:
总用量 12
-rw-r--r--. 1 root root 167 4月   9 23:41 ceph.client.glance.keyring
-rw-r--r--. 1 root root 276 4月   9 23:41 ceph.conf
-rw-r--r--. 1 root root 138 4月   9 23:38 glance-api.conf

/etc/kolla/config/nova/:
总用量 20
-rw-r--r--. 1 root root 217 4月   9 23:44 ceph.client.cinder.keyring
-rw-r--r--. 1 root root 167 4月   9 23:44 ceph.client.glance.keyring
-rw-r--r--. 1 root root 209 4月   9 23:44 ceph.client.nova.keyring
-rw-r--r--. 1 root root 276 4月   9 23:44 ceph.conf
-rw-r--r--. 1 root root 101 4月   9 23:44 nova-compute.conf
```

```
# ll /etc/kolla/config/cinder/*
-rw-r--r--. 1 root root 276 4月   9 23:43 /etc/kolla/config/cinder/ceph.conf
-rw-r--r--. 1 root root 291 4月   9 23:42 /etc/kolla/config/cinder/cinder-backup.conf
-rw-r--r--. 1 root root 264 4月   9 23:42 /etc/kolla/config/cinder/cinder-volume.conf

/etc/kolla/config/cinder/cinder-backup:
总用量 8
-rw-r--r--. 1 root root 199 4月   9 23:43 ceph.client.cinder-backup.keyring
-rw-r--r--. 1 root root 217 4月   9 23:43 ceph.client.cinder-volume.keyring

/etc/kolla/config/cinder/cinder-volume:
总用量 12
-rw-r--r--. 1 root root 217 4月   9 23:43 ceph.client.cinder-volume.keyring
-rw-r--r--. 1 root root 167 4月   9 23:43 ceph.client.glance.keyring
-rw-r--r--. 1 root root 209 4月   9 23:44 ceph.client.nova.keyring
```

# 3 部署

按照AutoStack的Deployment开始部署


ansible.vars.hostvars.HostVarsVars object' has no attribute u'ansible_br-ex'

查看group为"baremetal"的值:

ansible baremetal -m setup -i ../../multinode > /home/baremetal

