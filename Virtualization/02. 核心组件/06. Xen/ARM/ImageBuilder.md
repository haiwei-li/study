


# 从 U-Boot 启动 Xen

从 U-Boot 启动 Xen 需要:

- 手动指定每个二进制文件的加载地址, 并确保它们之间不会相互重叠:

  - (Xen, Dom0 kernel, Dom0 ramdisk, 设备树二进制文件, 以及 Dom0-less 的 DomU 内核), ramdisk 和用于直通的部分设备树文件.

- 在设备树中添加相关节点:

  - 需要在设备树的 `/chosen` 节点下指定 **Dom0 内核**和 **ramdisk** 的加载地址.

可以参考 [`booting.txt`](https://xenbits.xenproject.org/docs/unstable/misc/arm/device-tree/booting.txt) 文件作为参考.

# ImageBuilder

整个过程可以通过 **ImageBuilder** 来自动化:

https://gitlab.com/xen-project/imagebuilder

ImageBuilder 可以作为容器用于构建自动化, 但它的有用脚本也可以手动调用. 特别是,`script/uboot-script-gen` 脚本, 它可以**生成一个 U-Boot 脚本**.

给定一组二进制文件, 比如 (Xen、Dom0 和多个 Dom0-less 的 DomU),ImageBuilder 会负责计算所有加载地址、用必要信息编辑设备树, 甚至预先配置一个包含**内核**和**根文件系统**的磁盘映像。

为了使用它, 你需要先编写一个配置文件.

## 配置文件

```
MEMORY_START="0x0"
MEMORY_END="0x80000000"
LOAD_CMD="tftpb"
BOOT_CMD="booti"

DEVICE_TREE="mpsoc.dtb"
XEN="xen"
XEN_CMD="console=dtuart dtuart=serial0 dom0_mem=1G dom0_max_vcpus=1 bootscrub=0 vwfi=native sched=null"
PASSTHROUGH_DTS_REPO="git@github.com:Xilinx/xen-passthrough-device-trees.git device-trees-2021.2/zcu102"
DOM0_KERNEL="Image-dom0"
DOM0_CMD="console=hvc0 earlycon=xen earlyprintk=xen clk_ignore_unused"
DOM0_RAMDISK="dom0-ramdisk.cpio"
DOM0_MEM=1024
DOM0_VCPUS=1

NUM_DT_OVERLAY=1
DT_OVERLAY[0]="host_dt_overlay.dtbo"

NUM_DOMUS=2
DOMU_KERNEL[0]="zynqmp-dom1/Image-domU"
DOMU_PASSTHROUGH_PATHS[0]="/axi/ethernet@ff0e0000 /axi/serial@ff000000"
DOMU_CMD[0]="console=ttyPS0 earlycon console=ttyPS0,115200 clk_ignore_unused rdinit=/sbin/init root=/dev/ram0 init=/bin/sh"
DOMU_RAMDISK[0]="zynqmp-dom1/domU-ramdisk.cpio"
DOMU_COLORS[0]="6-14"
DOMU_KERNEL[1]="zynqmp-dom2/Image-domU"
DOMU_CMD[1]="console=ttyAMA0 clk_ignore_unused rdinit=/sbin/init root=/dev/ram0 init=/bin/sh"
DOMU_RAMDISK[1]="zynqmp-dom2/domU-ramdisk.cpio"
DOMU_MEM[1]=512
DOMU_VCPUS[1]=1

BITSTREAM=download.bit

NUM_BOOT_AUX_FILE=2
BOOT_AUX_FILE[0]="BOOT.BIN"
BOOT_AUX_FILE[1]="uboot.cfg"

UBOOT_SOURCE="boot.source"
UBOOT_SCRIPT="boot.scr"
APPEND_EXTRA_CMDS="extra.txt"
FDTEDIT="imagebuilder.dtb"
FIT="boot.fit"
FIT_ENC_KEY_DIR="dir/key"
FIT_ENC_UB_DTB="uboot.dtb"
```

字段的含义是显而易见的, 但你可以在 `readme` 文件中找到更详细的信息. 请确保使用 Xen 的原始二进制文件, 以及所有内核和根文件系统, 而不是 U-Boot 二进制文件 (不要使用 `mkimage` 的输出).

## uboot-script-gen

一旦你有了配置文件, 就可以按照以下方式调用 `uboot-script-gen`:

```
$ bash ./scripts/uboot-script-gen -c /path/to/config -d . -t tftp -o bootscript
```

`uboot-script-gen` 会生成一个名为 `bootscript` 的 **U-Boot 脚本**, 该脚本将使用 tftp 自动加载所有二进制文件.

配置文件中指定的所有路径都是相对于传递给 `-d` 的目录. 在这个例子中, `Image-dom0` 和 `dom1/Image-domU` 必须相对于当前目录, 因为我们传递了 `-d .` 给 `uboot-script-gen`.

现在, 你只需要加载生成的 `boot.scr` 并从 U-Boot 中执行它:

```
u-boot> tftpb 0xC00000 boot.scr; source 0xC00000
```

加载二进制文件的命令可以自定义, 例如你可以让 `uboot-script-gen` 生成一个从 SD 卡加载二进制文件的 U-Boot 脚本, 通过传递 `-t sd`, 这相当于传递 `-t "load scsi 0:1"`:

```
$ bash ./scripts/uboot-script-gen -c /path/to/config -d . -t sd
```

# 重要注意事项

## Xen 和 Dom0 命令行

ImageBuilder 默认使用 `sched=null`. 如果你想更改它, 并修改其他 Xen 和 / 或 Dom0 命令行选项, 你需要编辑生成的 U-Boot 脚本: `boot.source`. 找到 `sched=null` 并按需进行编辑. 然后你需要使用 `mkimage` 重新生成 **boot.scr**, 并指定与 `uboot-script-gen` 之前打印的相同的加载地址:

```
$ mkimage -A arm64 -T script -C none -a 0xC00000 -e 0xC00000 -d boot.source boot.scr
```

## U-Boot 二进制文件与原始二进制文件

`uboot-script-gen` 只接受原始二进制文件作为输入. 如果你有一个 U-Boot 二进制文件, 并且想将其转换回原始二进制文件, 可以使用以下命令:

```
$ dd if=uboot-binary-source of=raw-binary-dest bs=64 skip=1
```

## 作为原始二进制文件启动 Xen

如果你使用的 Xen 版本早于 4.12, 则需要确保你的 Xen 树中 backport 了以下提交:

```
4f3d0ed5d9 xen:arm: Populate arm64 image header
```

这是从 U-Boot 启动 Xen 作为原始二进制文件的必要条件.

# reference

https://wiki.xenproject.org/wiki/ImageBuilder
