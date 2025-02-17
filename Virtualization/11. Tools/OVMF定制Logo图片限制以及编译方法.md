
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. OVMF LOGO 格式](#1-ovmf-logo-格式)
  - [1.1. 图片格式限制](#11-图片格式限制)
  - [1.2. 图片大小限制](#12-图片大小限制)
  - [1.3. 图片分辨率限制](#13-图片分辨率限制)
- [2. OVMF 编译方法](#2-ovmf-编译方法)
  - [2.1. 建立 EDKII 编译环境](#21-建立-edkii-编译环境)
  - [2.2. 安装编译依赖](#22-安装编译依赖)
  - [2.3. 初始化编译环境和基本组件](#23-初始化编译环境和基本组件)
  - [2.4. 直接编译](#24-直接编译)
  - [2.5. 重新配置](#25-重新配置)
  - [2.6. 运行 QEMU 测试 OVMF](#26-运行-qemu-测试-ovmf)

<!-- /code_chunk_output -->

# 1. OVMF LOGO 格式

## 1.1. 图片格式限制

- 8bit 位图
- 256 色
- Windows 3.x format

验证方式:

```
[root@centos7 ~]# file tsinghua.bmp tsinghua.bmp: PC bitmap, Windows 3.x format, 500 x 204 x 8
```

## 1.2. 图片大小限制

图片大小应该小于 1024KB.

验证方式:

```
[root@centos7 ~]# du -sh tsinghua.bmp 104K tsinghua.bmp
```

## 1.3. 图片分辨率限制

分辨率并无特殊需求, OVMF 会居中显示. 建议使用特定比例如: 4: 3、19:6 等.

# 2. OVMF 编译方法

## 2.1. 建立 EDKII 编译环境

下载源代码:

```
#> git clone https://github.com/tianocore/edk2.git
```

## 2.2. 安装编译依赖

编译依赖列表:

- ACPI Source Language (ASL) Compiler Setup
- The NASM assembler
- Python2.7

```
#> yum -y install nasm acpica-tools python-devel libuuid-devel
```

## 2.3. 初始化编译环境和基本组件

```
#> source edksetup.sh BaseTools
WORKSPACE: /root/edk2
EDK_TOOLS_PATH: /root/edk2/BaseTools
CONF_PATH: /root/edk2/Conf/
build_rule.txt
tools_def.txt       -->  Information about 3rd party tools
target.txt            -->  Restricts a build to defined values
编辑 target.txt 文件
TARGET = RELEASE
ACTIVE_PLATFORM  = OvmfPkg/OvmfPkgX64.dsc
TOOL_CHAIN_TAG = GCC48
TARGET_ARCH  = X64
编译基本组件:
make -C edk2/BaseTools
配置 Conf/target.txt 可直接使用 build
```

## 2.4. 直接编译

```
#> build -a X64 -p OvmfPkg/OvmfPkgX64.dsc -DSECURE_BOOT_ENABLE -t GCC48 -b RELEASE --cmd-len=65536 --hash
```

## 2.5. 重新配置

```
#> . edksetup.sh --reconfig
```

## 2.6. 运行 QEMU 测试 OVMF

QEMU 加入下列参数:

```
-drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/OVMF_CODE.fd -drive if=pflash,format=raw,file=/usr/share/ovmf/OVMF_VARS.fd
```