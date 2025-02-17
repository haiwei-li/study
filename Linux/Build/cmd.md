
正常 build

```
make -j224
sudo make INSTALL_MOD_STRIP=1 modules_install -j224
sudo make install -j224
```

自定义 build 目录

```
mkdir build

cp kernel_config build/.config

make olddefconfig O=build

make -j 12 O=build

make modules_install INSTALL_MOD_PATH=rootfs O=build

tar zcvf /home/ubuntu/haiwei/modules.tar.gz ./build/rootfs/lib/modules

cp ./build/arch/x86_64/boot/bzImage /home/ubuntu/haiwei/
```


