
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 evacuate实例](#1-evacuate实例)
* [2 撤离一个实例](#2-撤离一个实例)
* [3 撤离所有实例](#3-撤离所有实例)
* [4 源码分析](#4-源码分析)
	* [4.1 evacuate操作](#41-evacuate操作)
	* [4.2 从原主机删除](#42-从原主机删除)
* [5 将快速疏散功能加入VM HA程序中](#5-将快速疏散功能加入vm-ha程序中)
* [6 参考](#6-参考)

<!-- /code_chunk_output -->

# 1 evacuate实例

nova evacuate 实现当虚拟机所在宿主机出现宕机后, 虚拟机可以通过evacuate将虚拟机从宕机的物理节点迁移至其它节点.  

nova evacuate其实是通过虚拟机rebuild的过程完成的, 原compute节点在重新恢复后会进行虚拟机删除

如果您需要把一个实例从一个有故障或已停止运行的 compute 节点上移到同一个环境中的其它主机服务器上时, 可以使用 nova evacuate 命令对实例进行撤离(evacuate). 

- 撤离的操作只有在实例的磁盘在共享存储上, 或实例的磁盘是块存储卷时才有效. 因为在其它情况下, 磁盘无法被新 compute 节点访问. 

- 实例只有在它所在的服务器停止运行的情况下才可以被撤离; 如果服务器没有被关闭, evacuate 命令会运行失败. 

# 2 撤离一个实例

使用以下命令撤离一个实例: 

```
# nova evacuate [--password pass] [--on-shared-storage] instance_name [target_host]
```

其中: 

- \-\-password pass \- 撤离实例的 admin 密码(如果指定了 \-\-on\-shared\-storage, 则无法使用). 如果没有指定密码, 一个随机密码会被产生, 并在**撤离操作完成后被输出**. 

- \-\-on\-shared\-storage \- 指定所有实例文件都在共享存储中. 

- instance\_name \- 要撤离的实例名称. 

- target\_host \- 实例撤离到的主机; 如果您没有指定这个主机, Compute 调度会为您选择一个主机. 您可以使用以下命令找到可能的主机: 

```
# nova host-list | grep compute
```

例如: 

```
# nova evacuate myDemoInstance Compute2_OnEL7.myDomain
```

# 3 撤离所有实例

使用以下命令在一个特定主机上撤离所有实例: 

```
# nova host-evacuate instance_name [--target target_host] [--on-shared-storage] source_host
```

其中: 


- \-\-target target\_host \- 实例撤离到的主机; 如果您没有指定这个主机, Compute 调度会为您选择一个主机. 您可以使用以下命令找到可能的主机: 

```
# nova host-list | grep compute
```

- \-\-on\-shared\-storage \- 指定所有实例文件都在共享存储中. 

- source\_host \- 被撤离的主机名. 

例如: 

```
# nova host-evacuate --target Compute2_OnEL7.localdomain myDemoHost.localdomain
```

# 4 源码分析

nova evacuate 实现当虚拟机所在宿主机出现宕机后, 虚拟机可以通过evacuate将虚拟机从宕机的物理节点迁移至其它节点.  

nova evacuate其实是通过虚拟机rebuild的过程完成的, 原compute节点在重新恢复后会进行虚拟机删除

## 4.1 evacuate操作

入口文件nova/api/openstack/compute/evacuate.py中Controller类下的\_evacuate方法

```python
def _evacuate(self, req, id, body):
    try:
        self.compute_api.evacuate(context, instance, host,
                                    on_shared_storage, password, force)
```

调用compute\_api的evacuate

```python
def evacuate(self, context, instance, host, on_shared_storage,
                admin_password=None, force=None):
    # 在这个地方进行了instance host获取
    inst_host = instance.host
    service = objects.Service.get_by_compute_host(context, inst_host)
    # 判断了host的服务状态, nova-compute service
    if self.servicegroup_api.service_is_up(service):
        LOG.error('Instance compute service state on %s '
                    'expected to be down, but it was up.', inst_host)
        raise exception.ComputeServiceInUse(host=inst_host)

    request_spec = objects.RequestSpec.get_by_instance_uuid(
        context, instance.uuid)

    instance.task_state = task_states.REBUILDING
    instance.save(expected_task_state=[None])
    self._record_action_start(context, instance, instance_actions.EVACUATE)
    # 调用rebuild重建
    return self.compute_task_api.rebuild_instance(context,
                    instance=instance,
                    new_pass=admin_password,
                    injected_files=None,
                    image_ref=None,
                    orig_image_ref=None,
                    orig_sys_metadata=None,
                    bdms=None,
                    recreate=True,
                    on_shared_storage=on_shared_storage,
                    host=host,
                    request_spec=request_spec,
                    )
```

调用nova/conductor/api.py中的ComputeTaskAPI类下的rebuild_instance方法

```python
def rebuild_instance(self, context, instance, orig_image_ref, image_ref,
                        injected_files, new_pass, orig_sys_metadata,
                        bdms, recreate=False, on_shared_storage=False,
                        preserve_ephemeral=False, host=None,
                        request_spec=None, kwargs=None):
    # kwargs unused but required for cell compatibility
    self.conductor_compute_rpcapi.rebuild_instance(context,
            instance=instance,
            new_pass=new_pass,
            injected_files=injected_files,
            image_ref=image_ref,
            orig_image_ref=orig_image_ref,
            orig_sys_metadata=orig_sys_metadata,
            bdms=bdms,
            recreate=recreate,
            on_shared_storage=on_shared_storage,
            preserve_ephemeral=preserve_ephemeral,
            host=host,
            request_spec=request_spec)
```

调用nova/conductor/rpcapi.py中的ComputeTaskAPI类下的rebuild\_instance方法

```python
def rebuild_instance(self, ctxt, instance, new_pass, injected_files,
    image_ref, orig_image_ref, orig_sys_metadata, bdms,
    recreate=False, on_shared_storage=False, host=None,
    preserve_ephemeral=False, request_spec=None, kwargs=None):
    version = '1.12'
    kw = {'instance': instance,
            'new_pass': new_pass,
            'injected_files': injected_files,
            'image_ref': image_ref,
            'orig_image_ref': orig_image_ref,
            'orig_sys_metadata': orig_sys_metadata,
            'bdms': bdms,
            'recreate': recreate,
            'on_shared_storage': on_shared_storage,
            'preserve_ephemeral': preserve_ephemeral,
            'host': host,
            'request_spec': request_spec,
            }
    if not self.client.can_send_version(version):
        version = '1.8'
        del kw['request_spec']
    cctxt = self.client.prepare(version=version)
    cctxt.cast(ctxt, 'rebuild_instance', **kw)
```

RPC调用, 转到nova/conductor/manager.py中的rebuild\_instance方法

```python
@targets_cell
def rebuild_instance(self, context, instance, orig_image_ref, image_ref,
                    injected_files, new_pass, orig_sys_metadata,
                    bdms, recreate, on_shared_storage,
                    preserve_ephemeral=False, host=None,
                    request_spec=None):
    ......
    # 这里开始调用compute上的manager.py中的rebuild_instance方法
    self.compute_rpcapi.rebuild_instance(context,
            instance=instance,
            new_pass=new_pass,
            injected_files=injected_files,
            image_ref=image_ref,
            orig_image_ref=orig_image_ref,
            orig_sys_metadata=orig_sys_metadata,
            bdms=bdms,
            recreate=recreate,
            on_shared_storage=on_shared_storage,
            preserve_ephemeral=preserve_ephemeral,
            migration=migration,
            host=host, node=node, limits=limits,
            request_spec=request_spec)
```

转到nova/compute/manager.py中的rebuild\_instance方法

```python
def rebuild_instance(self, context, instance, orig_image_ref, image_ref,
                    injected_files, new_pass, orig_sys_metadata,
                    bdms, recreate, on_shared_storage,
                    preserve_ephemeral, migration,
                    scheduled_node, limits, request_spec):
    if evacuate:
        # This is an evacuation to a new host, so we need to perform a
        # resource claim.
        rebuild_claim = self.rt.rebuild_claim
    else:
        # This is a rebuild to the same host, so we don't need to make
        # a claim since the instance is already on this host.
        rebuild_claim = claims.NopClaim

    # NOTE(mriedem): On an evacuate, we need to update
    # the instance's host and node properties to reflect it's
    # destination node for the evacuate.
    if not scheduled_node:
        if evacuate:
            try:
                compute_node = self._get_compute_info(context, self.host)
                scheduled_node = compute_node.hypervisor_hostname
            except exception.ComputeHostNotFound:
                LOG.exception('Failed to get compute_info for %s',
                                self.host)
        else:
            scheduled_node = instance.node

    with self._error_out_instance_on_exception(context, instance):
        try:
            claim_ctxt = rebuild_claim(
                context, instance, scheduled_node,
                limits=limits, image_meta=image_meta,
                migration=migration)
            self._do_rebuild_instance_with_claim(
                claim_ctxt, context, instance, orig_image_ref,
                image_meta, injected_files, new_pass, orig_sys_metadata,
                bdms, evacuate, on_shared_storage, preserve_ephemeral,
                migration, request_spec)

def _do_rebuild_instance_with_claim(self, claim_context, *args, **kwargs):
    """Helper to avoid deep nesting in the top-level method."""

    with claim_context:
        self._do_rebuild_instance(*args, **kwargs)

def _do_rebuild_instance(self, context, instance, orig_image_ref,
                        image_meta, injected_files, new_pass,
                        orig_sys_metadata, bdms, evacuate,
                        on_shared_storage, preserve_ephemeral,
                        migration, request_spec):
    if evacuate:
        self.network_api.setup_networks_on_host(
                context, instance, self.host)
        # For nova-network this is needed to move floating IPs
        # For neutron this updates the host in the port binding
        # TODO(cfriesen): this network_api call and the one above
        # are so similar, we should really try to unify them.
        self.network_api.setup_instance_network_on_host(
                context, instance, self.host, migration)
        # TODO(mriedem): Consider decorating setup_instance_network_on_host
        # with @base_api.refresh_cache and then we wouldn't need this
        # explicit call to get_instance_nw_info.
        network_info = self.network_api.get_instance_nw_info(context,
                                                                instance)
    else:
        network_info = instance.get_network_info()

    ......

    def detach_block_devices(context, bdms):
        for bdm in bdms:
            if bdm.is_volume:
                # NOTE (ildikov): Having the attachment_id set in the BDM
                # means that it's the new Cinder attach/detach flow
                # (available from v3.44). In that case we explicitly
                # attach and detach the volumes through attachment level
                # operations. In this scenario _detach_volume will delete
                # the existing attachment which would make the volume
                # status change to 'available' if we don't pre-create
                # another empty attachment before deleting the old one.
                attachment_id = None
                if bdm.attachment_id:
                    # detach volume
                    attachment_id = self.volume_api.attachment_create(
                        context, bdm['volume_id'], instance.uuid)['id']
                self._detach_volume(context, bdm, instance,
                                    destroy_bdm=False)
                if attachment_id:
                    bdm.attachment_id = attachment_id
                    bdm.save()

    files = self._decode_files(injected_files)
    kwargs = dict(
        context=context,
        instance=instance,
        image_meta=image_meta,
        injected_files=files,
        admin_password=new_pass,
        allocations=allocations,
        bdms=bdms,
        detach_block_devices=detach_block_devices,
        attach_block_devices=self._prep_block_device,
        block_device_info=block_device_info,
        network_info=network_info,
        preserve_ephemeral=preserve_ephemeral,
        evacuate=evacuate)
    try:
        with instance.mutated_migration_context():
            # 没实现
            self.driver.rebuild(**kwargs)
    except NotImplementedError:
        # NOTE(rpodolyaka): driver doesn't provide specialized version
        # of rebuild, fall back to the default implementation
        # 真正调用
        self._rebuild_default_impl(**kwargs)
```

可以看下libvirtDriver, 没有实现, 父类是ComputeDriver, 直接抛出NotImplementedError异常

```python
from nova.virt import driver
self.driver = driver.load_compute_driver(self.virtapi, compute_driver)
compute_driver = libvirt.LibvirtDriver
```

转到rebuld_default_impl方法

```python
    def _rebuild_default_impl(self, context, instance, image_meta,
                              injected_files, admin_password, allocations,
                              bdms, detach_block_devices, attach_block_devices,
                              network_info=None,
                              evacuate=False, block_device_info=None,
                              preserve_ephemeral=False):
        if preserve_ephemeral:
            # The default code path does not support preserving ephemeral
            # partitions.
            raise exception.PreserveEphemeralNotSupported()

        if evacuate:
            # 调用的detach volume
            detach_block_devices(context, bdms)
        else:
            self._power_off_instance(context, instance, clean_shutdown=True)
            detach_block_devices(context, bdms)
            self.driver.destroy(context, instance,
                                network_info=network_info,
                                block_device_info=block_device_info)

        instance.task_state = task_states.REBUILD_BLOCK_DEVICE_MAPPING
        instance.save(expected_task_state=[task_states.REBUILDING])

        new_block_device_info = attach_block_devices(context, instance, bdms)

        instance.task_state = task_states.REBUILD_SPAWNING
        instance.save(
            expected_task_state=[task_states.REBUILD_BLOCK_DEVICE_MAPPING])

        with instance.mutated_migration_context():
            # 通过driver的spawn方法来实现driver上的操作,完成最终实现
            self.driver.spawn(context, instance, image_meta, injected_files,
                              admin_password, allocations,
                              network_info=network_info,
                              block_device_info=new_block_device_info)
```

## 4.2 从原主机删除

当原nova\-compue节点恢复后, 会对evacuate的虚拟机进行删除清理

入口文件在nova/compute/manager.py中ComputeManager下的init\_host方法

```python
class ComputeManager(manager.Manager):
    ......
    def init_host(self):
        try:
            # checking that instance was not already evacuated to other host
            evacuated_instances = self._destroy_evacuated_instances(context)
```

再次调用

```python
def _destroy_evacuated_instances(self, context):

        for instance in evacuated:
            migration = evacuations[instance.uuid]
            LOG.info('Deleting instance as it has been evacuated from '
                     'this host', instance=instance)
            try:
                network_info = self.network_api.get_instance_nw_info(
                    context, instance)
                bdi = self._get_instance_block_device_info(context,
                                                           instance)
                destroy_disks = not (self._is_instance_storage_shared(
                    context, instance))
            except exception.InstanceNotFound:
                network_info = network_model.NetworkInfo()
                bdi = {}
                LOG.info('Instance has been marked deleted already, '
                         'removing it from the hypervisor.',
                         instance=instance)
                # always destroy disks if the instance was deleted
                destroy_disks = True
            # 调用driver的destroy方法删除
            self.driver.destroy(context, instance,
                                network_info,
                                bdi, destroy_disks)
```

转到nova/virt/libvirt/driver.py方法

```python
def destroy(self, context, instance, network_info, block_device_info=None,
            destroy_disks=True, migrate_data=None):
    # 先做了关机
    self._destroy(instance)
    # 这里做了清理, 包括删除虚拟机本地存储的信息, 以及网络等
    self.cleanup(context, instance, network_info, block_device_info,
                destroy_disks, migrate_data)
```

# 5 将快速疏散功能加入VM HA程序中



# 6 参考

- https://access.redhat.com/documentation/zh-CN/Red_Hat_Enterprise_Linux_OpenStack_Platform/6/html/Administration_Guide/section-evacuation.html

- https://blog.fabian4.cn/2016/10/27/nova-evacuate/

- 将快速疏散功能加入VM HA程序中: https://www.backendcloud.cn/2017/06/10/add-quick-evacuate/

- 深挖Openstack Nova - evacuate疏散函數: https://www.twblogs.net/a/5b7ae65c2b7177392c970b0e