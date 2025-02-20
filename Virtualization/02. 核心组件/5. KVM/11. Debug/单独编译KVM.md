
1. 进入 KVM 代码目录

```
进入 KVM 代码目录

cd /home/sdp/workspace/src/open/linux/arch/x86/kvm



开始编译

make -C /lib/modules/`uname -r`/build M=`pwd` clean

make -C /lib/modules/`uname -r`/build M=`pwd` modules



拷贝编译结果出来, 并使用

cp *.ko /home/kvm/tools/modules/

cd /home/kvm/tools/modules/

modprobe -r kvm_intel
modprobe -r kvm


modprobe irqbypass
insmod kvm.ko

insmod kvm-intel.ko
```

2. 开始编译

```

```