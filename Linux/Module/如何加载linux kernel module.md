
# 相关资源

linux 中模块相关资源都在 `/lib/modules/$(uname -r)` 目录中.

```
$ ll /lib/modules/$(uname -r)
total 6328
drwxr-xr-x  5 root root    4096 6 月   2 16:11 ./
drwxr-xr-x  5 root root    4096 6 月   9 06:24 ../
lrwxrwxrwx  1 root root      40 5 月  18 23:44 build -> /usr/src/linux-headers-5.13.0-44-generic/
drwxr-xr-x  2 root root    4096 5 月  18 23:44 initrd/
drwxr-xr-x 15 root root    4096 6 月   2 16:09 kernel/
-rw-r--r--  1 root root 1490749 6 月   2 16:11 modules.alias
-rw-r--r--  1 root root 1461121 6 月   2 16:11 modules.alias.bin
-rw-r--r--  1 root root   10124 5 月  18 23:44 modules.builtin
-rw-r--r--  1 root root   25802 6 月   2 16:11 modules.builtin.alias.bin
-rw-r--r--  1 root root   12611 6 月   2 16:11 modules.builtin.bin
-rw-r--r--  1 root root   79337 5 月  18 23:44 modules.builtin.modinfo
-rw-r--r--  1 root root  689983 6 月   2 16:11 modules.dep
-rw-r--r--  1 root root  949679 6 月   2 16:11 modules.dep.bin
-rw-r--r--  1 root root     330 6 月   2 16:11 modules.devname
-rw-r--r--  1 root root  238468 5 月  18 23:44 modules.order
-rw-r--r--  1 root root    1274 6 月   2 16:11 modules.softdep
-rw-r--r--  1 root root  666558 6 月   2 16:11 modules.symbols
-rw-r--r--  1 root root  806768 6 月   2 16:11 modules.symbols.bin
drwxr-xr-x  3 root root    4096 6 月   2 16:09 vdso/
```

# kernel 目录

大部分的 module file 都按类别分好类存放在其中的 kernel 目录中.

```
$ ll /lib/modules/$(uname -r)/kernel
total 60
drwxr-xr-x  15 root root 4096 6 月   2 16:09 ./
drwxr-xr-x   5 root root 4096 6 月   2 16:11 ../
drwxr-xr-x   3 root root 4096 6 月   2 16:09 arch/
drwxr-xr-x   2 root root 4096 6 月   2 16:09 block/
drwxr-xr-x   4 root root 4096 6 月   2 16:09 crypto/
drwxr-xr-x 112 root root 4096 6 月   2 16:09 drivers/
drwxr-xr-x  58 root root 4096 6 月   2 16:09 fs/
drwxr-xr-x   2 root root 4096 6 月   2 16:09 kernel/
drwxr-xr-x  10 root root 4096 6 月   2 16:09 lib/
drwxr-xr-x   2 root root 4096 6 月   2 16:09 mm/
drwxr-xr-x  60 root root 4096 6 月   2 16:09 net/
drwxr-xr-x   4 root root 4096 6 月   2 16:09 samples/
drwxr-xr-x  16 root root 4096 6 月   2 16:09 sound/
drwxr-xr-x   3 root root 4096 6 月   2 16:09 ubuntu/
drwxr-xr-x   2 root root 4096 6 月   2 16:09 zfs/
```

# modules.dep

`modules.dep`, 所有的模块都在这个文件中, 在**安装模块**时, 依赖这个文件**査找所有的模块**, 所以不需要指定模块所在位置的绝对路径, 而且也依靠这个文件来解决模块的依赖性.

比如, `kvm-intel.ko` 就依赖 `kvm.ko`

```
kernel/arch/x86/kvm/kvm.ko:
kernel/arch/x86/kvm/kvm-intel.ko: kernel/arch/x86/kvm/kvm.ko
```

如果这个文件丢失可以使用 depmod 命令会自动扫描系统中已有的模块, 并生成 modules.dep 文件, 不加任何选项, depmod 命令会扫描系统中的内核模块, 并写入 modules.dep 文件

```
# depmod [选项]
```

选项:
* -a: 扫描所有模块;
* -A: 扫描新模块, 只有有新模块时, 才会更新 modules.dep 文件;
* -n: 把扫描结果不写入 modules.dep 文件, 而是输出到屏幕上



