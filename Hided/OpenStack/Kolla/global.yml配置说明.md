1、docker_registry: "192.168.136.137:4000", 此处为配置的source的离线私有docker仓库的IP以及端口号. 

2、docker_namespace: "kolla", 这个是仓库镜像的统一命名空间即是前缀, 我给的镜像的前缀就是"kolla/"开头的. 

3、kolla_internal_vip_address: "17.17.62.2" , 这个是openstack的内部管理网络地址, 走的是"ens37"网卡. 

4、kolla_external_vip_address: "192.168.136.136" , 这个是openstack的外部管理网络地址, 走的是"ens33"网卡, 对外可以访问. 选取的外网136网段的一个空白的没有使用过的地址. 

5、network_interface: "ens37", 这个是openstack内部的api服务都会绑定到这个网卡接口上, 除此之外, vxlan和隧道和存储网络也默认走这个网络接口. 

6、kolla_external_vip_interface: " ens33", 此处选取为openstack的对外和外部沟通走的网卡接口. 这个网卡也是该台机器的外网网卡. 

7、cluster_interface: "ens38", 这个是ceph集群默认单独走的一个网卡接口. 

8、neutron_external_interface: "ens33", openstack的外部管理网络的网卡接口. 

9、kolla_enable_tls_external: "yes", openstack内外网地址映射的的tls协议需要开启, 此处需要yes, 不然openstack的外部管理网络地址开启不了. 

10、enable_ceph: "yes"和enable_ceph_rgw: "yes", 选择为yes, 就可默认安装ceph. 

11、enable_haproxy: "yes", openstack的外部管理网络地址没有使用过, 需要启用高可用proxy, 确定可以使用. 

12、ceph_pool_pg_num: 128和ceph_pool_pgp_num: 128, 参照如下: 

- 小于5个OSD时可把pg_num设置为128
- OSD数量在5到10个之间的, 可以把pg_num设置为512
- OSD数量在10到50个时候, 可以把pg_num设置为4096
- OSD大于50时, 理解权衡方法, 借助pgcalc工具计算pg_num取值

13、neutron_plugin_agent: "openvswitch"和enable_neutron_dvr: "yes", 此处设置, 是为了创建虚机的时候可以直接选择外网地址创建, 而不需要内网地址来映射, 再分配浮动IP. 