

# Kolla-Ansible

Two nodes are used for the deployment, with hostname `controller` and `compute1`. `controller` also serves as the `deployment host`. All the following procedures are using `root` user.

## Prepare

Disable firewall:
```
systemctl stop firewalld && systemctl disable firewalld && systemctl status firewalld
```

Disable selinux:
```
 vim /etc/selinux/config
 # Modily following line
 SELINUX=disabled
 # reboot
 ```
## Network

### Ethernet
There is one normal NIC(`enp10s0f0`) and one Infiniband Card(`ib0`) on each node.  

`enp10s0f0` will be bound by the services of OpenStack, such as API, vxlan, etc, which require an IP address. So, configure `enp10s0f0` as follow for each node.
```
controller: 10.121.2.124/24
compute1  : 10.121.2.125/24
```

Add the following host entries into `/etc/hosts`:

```
10.121.2.124 controller
10.121.2.125 compute1
```

### Infiniband setup
On each Node

Do not set IP address or subnet for the second interface `ib0`, as it will be used by `neutron` or `linux-bridge`.

Download Infiniband driver:
```
wget http://content.mellanox.com/ofed/MLNX_OFED-4.5-1.0.1.0/MLNX_OFED_LINUX-4.5-1.0.1.0-rhel7.6-x86_64.tgz
tar xvf MLNX_OFED_LINUX-4.5-1.0.1.0-rhel7.6-x86_64.tgz
cd MLNX_OFED_LINUX-4.5-1.0.1.0-rhel7.6-x86_64
```
Install Driver dependencies:
```
yum install gtk2 atk cairo tcl tk
```

Install:
```
cd MLNX_OFED_LINUX-4.5-1.0.1.0-rhel7.6-x86_64
./mlnxofedinstall
```

After a successful install, reboot the system and run the following commands:

```
/etc/init.d/openibd restart
```

## Setup Docker
On each node
```
yum install -y yum-utils   device-mapper-persistent-data   lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce

systemctl start docker
```

On a large scale deployment, set up a local docker registry is necessary:
[Multinode Deployment of Kolla](https://docs.openstack.org/project-deploy-guide/kolla-ansible/ocata/multinode.html/)

## Install Dependencies
On `deployment host`
```
yum install epel-release
yum install python-pip
pip install -U pip

yum install python-devel libffi-devel gcc openssl-devel libselinux-python
```

As mentioned in the official doc, install ansible with yum then update with pip:
```
yum install ansible
pip install ansible
```

## Install Kolla-ansible

On `deployment host`

Clone giit repos:
```
export OPS_INSTALL_HOME=/root
cd $OPS_INSTALL_HOME
git clone https://github.com/openstack/kolla
git clone https://github.com/openstack/kolla-ansible
cd kolla-ansible
git checkout cdc664b7f7ef295cbe58f133a9434e3da82d3a73
cd ..
cd kolla
git checkout 5922c22d8af6c34eb5c34250c3fa90dc3f853688
```
Install dependencies:
```
pip install -r kolla/requirements.txt
pip install -r kolla-ansible/requirements.txt
```

Copy the configuration files to `/etc/kolla` directory. kolla-ansible holds the configuration files ( `globals.yml` and `passwords.yml`) in `/etc/kolla`.

```
mkdir -p /etc/kolla
cp -r kolla-ansible/etc/kolla/* /etc/kolla
```
Copy a invertory file

```
cp kolla-ansible/ansible/inventory/multinode $OPS_INSTALL_HOME
```

# Configuration
On `deployment host`

Generate passwords in ` /etc/kolla/passwords.yml`:
```
cd $OPS_INSTALL_HOME/kolla-ansible/tools
./generate_passwords.py
```

Edit `$OPS_INSTALL_HOME/multinode` as follow, 
```yaml
[control]
controller

[network]
controller

[compute]
compute1

[monitoring]
controller

[storage]
# empty as no storage service is used

[deployment]
localhost       ansible_connection=local

....  # leave the rest unchanged
```

Edit `/etc/kolla/globals.yml`, modify the following items:
```
...
kolla_base_distro: "centos"
kolla_install_type: "binary"
openstack_release: "master"
kolla_internal_vip_address: "10.121.2.210"
kolla_external_vip_address: "10.121.2.211"
# Neutron
network_interface: "enp10s0f0"
neutron_externalinterface: "ib0"

# OpenStack Options
# As we do not deploy storage services,
enable_ceph: "no"


memcached_dimensions:
  ulimits:
    nofile:
      soft: 98304
      hard: 98304

...
```

## Deployment 
```
cd $OPS_INSTALL_HOME/kolla-ansible/tools
./kolla-ansible -i ../../multinode bootstrap-servers
./kolla-ansible -i ../../multinode preczhecks
./kolla-ansible -i ../../multinode deploy
```
### Troubling shooting 
* If `Yum Update Cache` faile with `fatal: [galera-dev]: FAILED! => {"changed": false, "failed": true, "msg": "one of the following is required: name,list"}`.

Modify `$OPS_INSTALL_HOME/kolla-ansible/ansible/roles/baremetal/tasks/install.yml`
```yaml
- name: Update yum cache
  command: yum makecache
#  yum:
#    update_cache: yes
  become: True
  when: ansible_os_family == 'RedHat'
```

Reference: https://github.com/ansible/ansible/issues/33461

* If docker related tasks got, such error
```
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/Users/.../env/lib/python2.7/site-packages/docker/client.py", line 81, in from_env
    **kwargs_from_env(**kwargs))
  File "/Users/.../env/lib/python2.7/site-packages/docker/client.py", line 38, in __init__
    self.api = APIClient(*args, **kwargs)
  File "/Users/.../env/lib/python2.7/site-packages/docker/api/client.py", line 110, in __init__
    config_dict=self._general_configs
TypeError: load_config() got an unexpected keyword argument 'config_dict'
exit code 1
```
This is caused be the comflict between python package `docker` and its dapercated version `docker-py`. 
```
pip uninstall docker-py
pip uninstall docker
pip install docker==3.7.0
```

* If python `ImportError` happens to `decorator`, `docker`, or other python packages

Remove the package, and reinstall it with pip.

* Refer to [Official Troubleshooting Guide](https://docs.openstack.org/kolla-ansible/latest/user/troubleshooting.html)

## Using OpenStack

Install CLI client:
```
pip install python-openstackclient python-glanceclient python-neutronclient
```
Initialize:
```
cd $OPS_INSTALL_HOME/kolla-ansible/tools
./kolla-ansible post-deploy
. /etc/kolla/admin-openrc.sh
./init-runonce
```

## Reference
https://docs.openstack.org/project-deploy-guide/kolla-ansible/rocky/quickstart.html#host-machine-requirements

https://www.youtube.com/watch?v=BKYJuYsT4z4

https://blog.csdn.net/liuyanwuyu/article/details/80821677

https://github.com/openstack/kolla-ansible/commit/38c0a4f2d210dea95b97675fb29d12f656a19bf8#diff-0a325c383ea8f21015c6e005c0b28763
## Clean Up
On `deployment host`

If at any stage, the installation is massed up. Use the following procedure to cleanup:
```
cd $OPS_INSTALL_HOME/kolla-ansible/tools
./kolla-ansible -i ../../multinode destroy
./cleanup-containers 
./cleanup-host
./cleanup-images --all
```



stable mariadb unable to start fixed in 38c0a4f2d210dea95b97675fb29d12f656a19bf8

stable no ulimit 