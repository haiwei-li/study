从内核移植到用户空间的 SLUB 分配器. SLUB 分配器是内核用于提供小粒度的虚拟内存分配器, 其提供了缓存和 kmalloc 的核心实现. 这次分享的项目中包括了
1) `kmem_cache_alloc`/`kmem_cache_free` 逻辑
2) `kmalloc`/`kzalloc`/`kfree` 实现逻辑
3) `kstrdup`/`kstrdup_const`/`kasprintf` 名字内存分配器. 想了解 kmalloc 和 slub 分配器实现逻辑的童鞋, 可以参考 https://github.com/BiscuitOS/HardStack/tree/master/Memory-Allocator/slab/slub_userspace

