
# 背景

## 原有开发

原有 UEFI 开发, 一个工程师, 面对着硕大的屏幕满满的代码, 主机上连着一个 DediProg SPI 烧写器, 旁边放着开发板, 工程师不停地修改着代码, 编译, 等待, 用镊子小心地从测试机上拿出 SPI ROM, 放到 DediProg 上, 点击烧写, 等待, 烧写完成后, 用镊子小心地把 SPI ROM 放到测试机上, 检查无误之后上电, 打开 log 窗口, 等待. . . 分析. . .

以上是一个 UEFI 工程师最常见的工作场景, 每一次验证, 都要花费大量的时间, 基本上很多时间都用来等待了.

## 模拟平台

实际上, 如果只是开发一个软件, 而不是调试硬件相关功能的话, 其实是不需要用测试机或者开发板的. 尽管我没有统计数据, 但是实际上据我观察, 除 Intel/AMD 这样的芯片厂之外, 其他大部分 UEFI 工程师有至少一半的工作是不需要一个真正的硬件的.

所以如果可以脱离硬件去开发 UEFI 的话, 会大大提高效率, 省下很多时间和精力.

另外, 很多人是没有条件进行平台验证, 这个时候, 一套模拟的平台就显得尤为必要了, 不仅仅提高效率, 而是给了很多入门者去接触 UEFI.

## OVMF

这件事在早就有人做了, Intel 的工程师基于 edk2 创建了一个叫做 **OVMF**(`Open Virtual Machine Firmware`)的项目, 旨在**为 UEFI 的开发**提供**虚拟机的支持**. 通过 OVMF, 我们可以将**编译好的 BIOS** 跑在 **Qemu 虚拟机**上.

那么, 接下来我就一步一步介绍如何使用 OVMF.

# 开发环境

OVMF 的开源版本默认是运行一个 bash shell 在 Linux 上编译, 所以这里就写 Linux 下的开发.

> 大部分 UEFI 工程师都在 windows 环境下开发, Windows 下使用 OVMF 也是可以的

开发环境的搭建主要包括两个部分: Linux OS 的配置, 代码准备.

关于 Linux 系统, 我个人倾向于装在虚拟机了, 一方面省了双系统切换的麻烦, 另一方面, windows 自带的 wls 用 qemu 不是很方便, 所以装虚拟机是最简单的方法. 如何装虚拟机我就不废话了, 装好之后运行下面的命令安装必要的工具和库.

```
sudo apt-get build-essential uuid-dev  git gcc  python3-distutils acpica-tools nasm qemu
```

接下来就是从 github 上拿最新的 edk2 的代码:

```
git clone https://github.com/tianocore/edk2.git
```

由于 edk2 的代码里面有几个文件夹是 sub module, 所以必须要运行下面的命令才可以拿到完整的代码:

```
cd edks
git submodule update --init
```

# 编译

第一步, **设置** `target.txt`

Conf 目录下的内容都是**编译相关的设置**, 默认情况下, 如果 Conf 目录下为**空**时, **编译脚本**会将 `BaseTool/Conf` 下的内容拷贝到 Conf 下, 但是这里的东西通常不是我们所需要的, 特别是我们需要设置的 `target.txt`.

一般的做法, 先把 `BaseTool/Conf` 下的 `target.template` 拷贝到 Conf/, 并**改名**为 `target.txt`

```
cp BaseTool/Conf/target.template Conf/target.txt
```

然后将 `target.txt` 的一些选项进行修改, 为编译我们的 OVMF 做准备.

具体如何修改 OVMF, 可以参见 `OvmfPkg/README`, 我今天做实验的例子如下, 供大家参考:

```
ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgX64.dsc
TARGET                = DEBUG
TARGET_ARCH           = X64
TOOL_CHAIN_TAG        = GCC5
```

设置好 target.txt 之后, 就可以来编译我们的第一个 OVMF BIOS 了.

第二步, **运行编译脚本**

下面是我编译 OVMF 所用的命令,  `build.sh` 是 OVMF 自带的编译脚本, `-a X64` 制定了架构类型, `-D DEBUG_ON_SERIAL_PORT` 是**打开串口 log**, 配合之后 **qemu** 的 `-serial` 参数, 可以获得 log 信息, 进行代码级调试. 关于 debug log 的详细信息, 也可以参见 README.

```
OvmfPkg/build.sh -a X64 -D DEBUG_ON_SERIAL_PORT
```

如果编译不出错误的话, 你就会在 `Build/OvmfX64/DEBUG_GCC5/FV` 下面看到一个叫做 `OVMF.fd` 的文件, 这就是我们的 OVMF BIOS image.

```
$ ll Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd
-rw-rw-r-- 1 ubuntu ubuntu 2097152  6 月 26 15:11 Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd
```

---

```
// 安装
sudo apt install gcc-10-multilib gcc-10 g++-10 g++-10-multilib

// 设置默认 gcc 10
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 30 --slave /usr/bin/g++ g++ /usr/bin/g++-10

// 设置默认 gcc 11
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 50 --slave /usr/bin/g++ g++ /usr/bin/g++-11


// 查看设置结果
sudo update-alternatives --config gcc

make -C BaseTools
export EDK_TOOLS_PATH=/home/ubuntu/haiwei/acrn-work/acrn-edk2/BaseTools
. edksetup.sh BaseTools
```

修改 Conf/target.txt

```
ACTIVE_PLATFORM = OvmfPkg/OvmfPkgX64.dsc
TARGET_ARCH = X64
TOOL_CHAIN_TAG=GCC5
```

```
build -p OvmfPkg/OvmfPkgX64.dsc -a X64 -DFD_SIZE_2MB -DDEBUG_ON_SERIAL_PORT=true

build -p OvmfPkg/OvmfPkgX64.dsc -a X64 -D DEBUG_ON_SERIAL_PORT=true -D FD_SIZE_2MB
```

清理

```
make -C BaseTools clean
build clean
build cleanall
```

# 运行

用的是 `qemu-system-x86_64` 这个程序, 因为我们编译的 x64 版本.

现在为了运行第一个 BIOS 而需要用到的 qemu 的参数, 实际上只有一类, 那就是告诉 qemu 去哪里 load BIOS image. 通常有两种方法:

## -pflash

这条参数告诉 qemu 用指定的文件作为 spi flash 上的 firmware, 类似我们在一个真实的机器上烧写它的 spi flash. 用这个参数执行的好处是 **UEFI variable** 都可以保存在 "**flash**" 上面, 基本 **reboot** 也**不会丢**

## -bios

这条参数只是简单的指定 BIOS 文件, 并不模拟 spi flash, 所以尽管在执行的时候, 大致效果与上面那条没什么不同, 但是 non-volatile 的 variable 会在 reboot 的时候丢失.

用下面最简单的命令跑一下, 看看会有什么效果.

```
cd Build/OvmfX64/DEBUG_GCC5/FV

qemu-system-x86_64 -bios OVMF.fd
```

或者

```
cd Build/OvmfX64/DEBUG_GCC5/FV

qemu-system-x86_64 -pflash OVMF.fd
```

运行命令之后, 命令行里的信息:

图

然后 qemu 就开始执行, 我们马上就看到了 tianocore 的 logo, 这宣布我们已经大功告成！

图

大概十秒之后, 系统就跑进了 EFI shell, 至此我们用虚拟机运行 UEFI 固件已经全部完成.

图

另外大家可能注意到我们执行 qemu-system-x86_64 -pflash OVMF.fd 这条命令的时候, 会有 warning 信息打印, 其实我们还有另一种做法可以避免这个 warning 消息:

```
qemu-system-x86_64 -drive file=OVMF.fd,format=raw,if=pflash
```

实际上如果不是一定要 debug log 的话, 可以简单的运行下面这样命令来一次性完成编译和运行, 但这种方式我并不是很建议.

```
OvmfPkg/build.sh -a X64 qemu
```

>
> qemu-system-x86_64 -name ubuntu -accel kvm -bios Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd -cpu host -m 2G -smp 2 -hda /home/ubuntu/haiwei/ubuntu22.04.qcow2 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic

# 调试

关于调试有太多要说的, 我这里就不展开, 我只告诉你, 如果在 qemu 运行的时候, 拿到 BIOS 的 debug log. source code level 的 debug log 是最好的调试信息, 几乎 90%以上的问题都可以基于 debug log 来调试.

有很多种方式拿到 debug log, 我这里只告诉你其中一种:

如前面所说, 编译代码的时候, 带上 `-D DEBUG_ON_SERIAL_PORT` 这个参数:

```
OvmfPkg/build.sh -a X64 -D DEBUG_ON_SERIAL_PORT
```

运行 qemu 的时候, 带上 `-serial file:debug.log` 这个参数:

```
qemu-system-x86_64 -drive file=OVMF.fd,format=raw,if=pflash -serial file:debug.log
```

>qemu-system-x86_64 -name ubuntu -accel kvm -drive file=Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd,format=raw,if=pflash -serial file:debug.log -cpu host -m 2G -smp 2 -hda /home/ubuntu/haiwei/ubuntu22.04.qcow2 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic

用上面这条命令执行后, 在当前目录就会出现一个叫做 debug.log 的文件, 这就是 BIOS 的打印的 log.

# 写一个自己的 Application

写一个自己的 UEFI 程序, 打印一个 hello world.

通常新加一个 UEFI 程序需要三部分:

1. 源文件

新建一个 c 源文件, 比如我就在 OvmfPkg 目录下新建了一个文件夹, 在里面添加一个叫做 test.c 的文件

```
$ cd OvmfPkg
$ mkdir haiwei
$ cd haiwei/
$ vim test.c
```

编辑 test.c 加入以下内容:

```cpp
#include <Uefi.h>
#include <Library/BaseLib.h>
#include <Library/BaseMemoryLib.h>
#include <Library/UefiDriverEntryPoint.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Library/UefiLib.h>
#include <Library/DebugLib.h>
#include <Library/ReportStatusCodeLib.h>

EFI_STATUS
EFIAPI
HaiweiTestEntry (
  IN EFI_HANDLE           ImageHandle,
  IN EFI_SYSTEM_TABLE     *SystemTable
  )
{
 DEBUG ((EFI_D_ERROR, "Haiwei: Hello world\n"));
 return EFI_SUCCESS;
}
```

上面就是 UEFI 的主体内容, `HaiweiTestEntry` 是入口程序, 需要在下来的 inf 文件中指定.

在同样的路径下添加一个叫做 `test.inf` 的文件, 这个文件是**每一个 UEFI 程序**必需的, 用来配置**程序属性**, 指定它**如何被编译**, 它可以提供什么, 它依赖什么, 它可以运行在什么架构之上, 有什么样的功能, 等等. 我们这个例子的内容如下:

```conf
[Defines]
 INF_VERSION                    = 0x00010005
 BASE_NAME                      = HaiweiTest
 FILE_GUID                      = D0B2C191-6255-4AC2-AE8E-73821B3E1F0F
 MODULE_TYPE                    = UEFI_DRIVER
 VERSION_STRING                 = 1.0

 ENTRY_POINT                    = HaiweiTestEntry

[Sources]
 test.c

[Packages]
 MdePkg/MdePkg.dec
 MdeModulePkg/MdeModulePkg.dec

[LibraryClasses]
  BaseLib
  UefiLib
  UefiRuntimeServicesTableLib
  UefiBootServicesTableLib
  UefiDriverEntryPoint
  DebugLib

[Guids]

[Protocols]

[Pcd]
```

一个简单的程序就这样写好了, 那么如何编译它呢?

我们需要把它放进 OVMF 里面去编译, 还记不记得我们在第二部分的时候, 在 target.txt 里面指定了:

```
ACTIVE_PLATFORM       = OvmfPkg/OvmfPkgX64.dsc
```

我们需要把 test.inf 加进 `OvmfPkgX64.dsc`, 才能保证在编译的时候, 我们自己的程序可以被编译.

打开 `OvmfPkgX64.dsc`, 在文件的最后加上下面的内容:

```
OvmfPkg/haiwei/test.inf {
     <LibraryClasses>
        DebugLib|MdePkg/Library/BaseDebugLibSerialPort/BaseDebugLibSerialPort.inf
  }
```

这样在编译 OVMF 的时候, 我们的程序也可以被编译到, 其中的 LibraryClasses 是指定了 debug log 通过那个库来打印, 有时候这个是默认不打印的, 所以我为了保险起见一般会加上这个.

这段代码放在最后, 严格地讲, 实际上是放在 `[Components]` 这个块之下的

程序就可以编译了, 但是只编译还不够, 还需要**放进**最后的 BIOS **image**, 并且在运行的时候要被执行, 那么就需要把 `test.inf` 同时包含进 `.fdf` 文件, 也就是对应的 `OvmfPkg/OvmfPkgX64.fdf`, 找到 `[FV.DXEFV]`, 加上以下内容:

```
INF  OvmfPkg/haiwei/test.inf
```

和上面一样的编译和运行的步骤:

```
OvmfPkg/build.sh -a X64 -D DEBUG_ON_SERIAL_PORT

qemu-system-x86_64 -drive file=./Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd,format=raw,if=pflash -serial file:debug.log
```

> qemu-system-x86_64 -name ubuntu -accel kvm -drive file=Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd,format=raw,if=pflash -serial file:debug.log -cpu host -m 2G -smp 2 -hda /home/ubuntu/haiwei/ubuntu22.04.qcow2 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -nographic

运行无误, 打开 debug.log

```
Loading driver at 0x0007ED4B000 EntryPoint=0x0007ED4C07A HaiweiTest.efi
InstallProtocolInterface: BC62157E-3E33-4FEC-9920-2D3B36D750DF 7ED70718
ProtectUefiImageCommon - 0x7ED70240
  - 0x000000007ED4B000 - 0x0000000000001CC0
Haiwei: Hello world
```

# 推荐命令

使用下面的命令可以起正常 vm

> qemu-system-x86_64 -name ubuntu -accel kvm -drive file=/home/ubuntu/haiwei/edk2/Build/OvmfX64/DEBUG_GCC5/FV/OVMF.fd,format=raw,if=pflash -cpu host -m 2G -smp 2 -hda /home/ubuntu/haiwei/ubuntu22.04.qcow2 -netdev user,id=hostnet0 -device rtl8139,netdev=hostnet0,id=net0,mac=52:54:00:36:32:aa,bus=pci.0,addr=0x5 -chardev socket,id=montest,server=on,wait=off,path=/tmp/mon_test -mon chardev=montest,mode=readline -serial mon:stdio -nographic

https://zhuanlan.zhihu.com/p/107360611

