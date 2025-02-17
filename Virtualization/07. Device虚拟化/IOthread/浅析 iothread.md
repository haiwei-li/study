

`iothread_complete`(iothread.c) -> `iothread_run`


virtio-iommu 没有 iothread 选项

```
root@haiwei-pc:/data/images# /data/build/qemu/build/qemu-system-x86_64 -device virtio-iommu,? | grep -i iothread
root@haiwei-pc:/data/images#
root@haiwei-pc:/data/images# /data/build/qemu/build/qemu-system-x86_64 -device virtio-blk-pci,? | grep -i iothread
  iothread=<link<iothread>>
```

查看代码:

```cpp
//hw/virtio/virtio-iommu.c
static Property virtio_iommu_properties[] = {
    DEFINE_PROP_LINK("primary-bus", VirtIOIOMMU, primary_bus, "PCI", PCIBus *),
    DEFINE_PROP_END_OF_LIST(),
};
```

有 `primary_bus` 属性, 确实没有 `iothread`

`main(softmmu/main.c)` -> `qemu_init(softmmu/vl.c)` -> `qmp_x_exit_preconfig(softmmu/vl.c)` -> `qemu_create_cli_devices(softmmu/vl.c)`

```cpp
static void qemu_create_cli_devices(void)
{
    ......
    qemu_opts_foreach(qemu_find_opts("device"),
                      device_init_func, NULL, &error_fatal);
    ......
}
```

```cpp
device_init_func()
 └─ qdev_device_add(QemuOpts *opts, Error **errp);
    ├─ QDict *qdict = qemu_opts_to_qdict(opts, NULL);
    └─ qdev_device_add_from_qdict(qdict, false, errp);
       ├─ dev = qdev_new(driver);
       │  ├─ module_load_qom_one(name);
       │  └─ return DEVICE(object_new(name));
       ├─ dev->opts = qdict_clone_shallow(opts);

       ├─ object_set_properties_from_keyval(&dev->parent_obj, dev->opts, from_json,
       └─ qdev_realize(DEVICE(dev), bus, errp)
          ├─
	  └─ object_property_set_bool(OBJECT(dev), "realized", true, errp);
	     ├─ QBool *qbool = qbool_from_bool(value);
	     └─ object_property_set_qobject(obj, name, QOBJECT(qbool), errp);
	        ├─ Visitor *v = qobject_input_visitor_new(value);
		└─ object_property_set(obj, name, v, errp);
		   ├─ ObjectProperty *prop = object_property_find_err(obj, name, errp);
		   └─ prop->set(obj, v, name, prop->opaque, errp); 调用  device_set_realized
		      ├─ DeviceState *dev = DEVICE(obj);
		      ├─ DeviceClass *dc = DEVICE_GET_CLASS(dev);
		      ├─ dc->realize(dev, &local_err); 调用 virtio_pci_dc_realize







		      │  ├─ VirtioPCIClass *vpciklass = VIRTIO_PCI_GET_CLASS(qdev);
		      │  ├─ VirtIOPCIProxy *proxy = VIRTIO_PCI(qdev);
		      │  ├─ PCIDevice *pci_dev = &proxy->pci_dev;


		      │  └─ vpciklass->parent_dc_realize(qdev, errp);


```




`virtio_iommu_class_init` -> `vdc->realize = virtio_iommu_device_realize;`

`virtio_iommu_device_realize`









