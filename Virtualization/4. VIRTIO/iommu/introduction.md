  - [5.1. 实现 virtio-iommu](#51-实现-virtio-iommu)
  - [5.2. virtio 设备的 vIOMMU 支持](#52-virtio-设备的-viommu-支持)
  - [5.3. vfio 设备的支持](#53-vfio-设备的支持)
  - [5.4. debug 相关](#54-debug-相关)
- [6. 现有实现](#6-现有实现)
8. `iommu_device_register()`, 注册 `viommu->iommu` 到全局 `iommu_device_list` 链表