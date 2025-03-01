
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 概述](#1-概述)
- [2. why](#2-why)
  - [2.1. 各种架构 CPU 的模拟和实现](#21-各种架构-cpu-的模拟和实现)
  - [2.2. 模拟 device 与 bus 的关系](#22-模拟-device-与-bus-的关系)
- [3. QOM 模型的数据结构](#3-qom-模型的数据结构)
  - [3.1. TypeImpl: 对数据类型的抽象数据结构](#31-typeimpl-对数据类型的抽象数据结构)
  - [3.2. ObjectClass: 是所有类的基类](#32-objectclass-是所有类的基类)
  - [3.3. Object: 是所有对象的 base Object](#33-object-是所有对象的-base-object)
  - [3.4. TypeInfo](#34-typeinfo)
- [4. 怎样使用 QOM 模型创建新类型](#4-怎样使用-qom-模型创建新类型)
- [5. 参考](#5-参考)

<!-- /code_chunk_output -->

# 1. 概述

QEMU 提供了一套面向对象编程的模型 —— QOM, 即 **QEMU Object Module**, 几乎**所有的设备**如 CPU、内存、总线等都是利用这一面向对象的模型来实现的. QOM 模型的实现代码位于**qom/文件夹**下的文件中.

# 2. why

为什么 QEMU 中要实现对象模型

## 2.1. 各种架构 CPU 的模拟和实现

QEMU 中要实现对**各种 CPU 架构**的模拟, 而且对于**同一种架构**的 CPU, 比如 `X86_64` 架构的 CPU, 由于包含的特性不同, 也会有**不同的 CPU 模型**.

任何 CPU 中都有 CPU **通用的属性**, 同时也包含各自**特有的属性**.

为了便于模拟这些 CPU 模型, **面向对象的编程模型**是必不可少的.

## 2.2. 模拟 device 与 bus 的关系

在**主板**上, **一个 device！！！** 会通过 **bus！！！** 与**其他的 device！！！** 相连接, **一个 device** 上可以通过**不同的 bus 端口**连接到**其他的 device**, 而其他的 device 也可以进一步通过 bus 与其他的设备连接, 同时一个 bus 上也可以连接多个 device, 这种**device 连 bus**、**bus 连 device 的关系**, qemu 是需要模拟出来的.

为了方便模拟设备的这种特性, 面向对象的编程模型也是必不可少的.

# 3. QOM 模型的数据结构

这些数据结构中 TypeImpl 定义在 **qom/object.c** 中, **ObjectClass**、**Object**、**TypeInfo** 定义在 `include/qom/object.h` 中.

在 `include/qom/object.h` 的注释中, 对它们的每个字段都有比较明确的说明, 并且说明了 QOM 模型的用法.

## 3.1. TypeImpl: 对数据类型的抽象数据结构

```cpp
struct TypeImpl
{
    const char *name;

    size_t class_size;  /*该数据类型所代表的类的大小*/

    size_t instance_size;  /*该数据类型产生的对象的大小*/

    /*类的 Constructor & Destructor*/
    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);
    void (*class_finalize)(ObjectClass *klass, void *data);

    void *class_data;

    /*实例的 Contructor & Destructor*/
    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;  /*表示类是否是抽象类*/

    const char *parent;  /*父类的名字*/
    TypeImpl *parent_type;  /*指向父类 TypeImpl 的指针*/

    ObjectClass *class;  /*该类型对应的类的指针*/

    int num_interfaces;  /*所实现的接口的数量*/
    InterfaceImpl interfaces[MAX_INTERFACES];
};

其中 InterfaceImpl 的定义如下, 只是一个类型的名字
struct InterfaceImpl
{
    const char *typename;
};
```

## 3.2. ObjectClass: 是所有类的基类

```c
typedef struct TypeImpl *Type;

struct ObjectClass
{
    /*< private >*/
    Type type;  /**/
    GSList *interfaces;

    const char *object_cast_cache[OBJECT_CLASS_CAST_CACHE];
    const char *class_cast_cache[OBJECT_CLASS_CAST_CACHE];

    ObjectUnparent *unparent;
};
```

## 3.3. Object: 是所有对象的 base Object

```c
struct Object
{
    /*< private >*/
    ObjectClass *class;
    ObjectFree *free;  /*当对象的引用为 0 时, 清理垃圾的回调函数*/
    GHashTable *properties; /*Hash 表记录 Object 的属性*/
    uint32_t ref;    /*该对象的引用计数*/
    Object *parent;
};
```

## 3.4. TypeInfo

是用户用来定义一个 Type 的工具型的数据结构, 用户定义了一个 TypeInfo, 然后调用 type_register(TypeInfo )或者 type_register_static(TypeInfo )函数, 就会生成相应的 TypeImpl 实例, 将这个 TypeInfo 注册到全局的 TypeImpl 的 hash 表中.

```c
/*TypeInfo 的属性与 TypeImpl 的属性对应,
实际上 qemu 就是通过用户提供的 TypeInfo 创建的 TypeImpl 的对象
*/
struct TypeInfo
{
    const char *name;
    const char *parent;

    size_t instance_size;
    void (*instance_init)(Object *obj);
    void (*instance_post_init)(Object *obj);
    void (*instance_finalize)(Object *obj);

    bool abstract;
    size_t class_size;

    void (*class_init)(ObjectClass *klass, void *data);
    void (*class_base_init)(ObjectClass *klass, void *data);
    void (*class_finalize)(ObjectClass *klass, void *data);
    void *class_data;

    InterfaceInfo *interfaces;
};
```

# 4. 怎样使用 QOM 模型创建新类型

使用 QOM 模型**创建新类型**时, 需要用到以上的**OjectClass**、**Object**和**TypeInfo**.

关于 QOM 的用法, 在 include/qom/object.h 一开始就有一长串的注释, 这一长串的注释说明了创建新类型时的各种用法. 我们下面是对这些用法的简要说明.

1. 从最简单的开始, 创建一个最小的 type:

```c
#include "qdev.h"

#define TYPE_MY_DEVICE "my-device"

// 用户需要定义新类型的类和对象的数据结构
// 由于不实现父类的虚拟函数, 所以直接使用父类的数据结构作为子类的数据结构
// No new virtual functions: we can reuse the typedef for the
// superclass.
typedef DeviceClass MyDeviceClass;
typedef struct MyDevice
{
	DeviceState parent;  //父对象必须是该对象数据结构的第一个属性, 以便实现父对象向子对象的 cast

	int reg0, reg1, reg2;
} MyDevice;

static const TypeInfo my_device_info = {
	.name = TYPE_MY_DEVICE,
	.parent = TYPE_DEVICE,
	.instance_size = sizeof(MyDevice),  //必须向系统说明对象的大小, 以便系统为对象的实例分配内存
};

//向系统中注册这个新类型
static void my_device_register_types(void)
{
	type_register_static(&my_device_info);
}
type_init(my_device_register_types)
```

2. 为了方便编程, 对于每个新类型, 都会定义由**ObjectClass**动态 cast 到 MyDeviceClass 的方法, 也会定义由 Object 动态 cast 到 MyDevice 的方法. 以下涉及的函数`OBJECT_GET_CLASS`、`OBJECT_CLASS_CHECK`、`OBJECT_CHECK`都在 include/qemu/object.h 中定义.

```c
#define MY_DEVICE_GET_CLASS(obj) \
    OBJECT_GET_CLASS(MyDeviceClass, obj, TYPE_MY_DEVICE)
#define MY_DEVICE_CLASS(klass) \
	OBJECT_CLASS_CHECK(MyDeviceClass, klass, TYPE_MY_DEVICE)
#define MY_DEVICE(obj) \
	OBJECT_CHECK(MyDevice, obj, TYPE_MY_DEVICE)
```

3. 如果我们在定义新类型中, 实现了父类的虚拟方法, 那么需要定义新的 class 的初始化函数, 并且在 TypeInfo 数据结构中, 给 TypeInfo 的 class\_init 字段赋予该初始化函数的函数指针.

```c
#include "qdev.h"

void my_device_class_init(ObjectClass *klass, void *class_data)
{
	DeviceClass *dc = DEVICE_CLASS(klass);
	dc->reset = my_device_reset;
}

static const TypeInfo my_device_info = {
	.name = TYPE_MY_DEVICE,
	.parent = TYPE_DEVICE,
	.instance_size = sizeof(MyDevice),
	.class_init = my_device_class_init, /*在类初始化时就会调用这个函数, 将虚拟函数赋值*/
};
```

4. 当我们需要从一个类创建一个派生类时, 如果需要覆盖 类原有的虚拟方法, 派生类中, 可以增加相关的属性将类原有的虚拟函数指针保存, 然后给虚拟函数赋予新的函数指针, 保证父类原有的虚拟函数指针不会丢失.

```c
typedef struct MyState MyState;
  typedef void (*MyDoSomething)(MyState *obj);

  typedef struct MyClass {
      ObjectClass parent_class;

      MyDoSomething do_something;
  } MyClass;

  static void my_do_something(MyState *obj)
  {
      // do something
  }

  static void my_class_init(ObjectClass *oc, void *data)
  {
      MyClass *mc = MY_CLASS(oc);

      mc->do_something = my_do_something;
  }

  static const TypeInfo my_type_info = {
      .name = TYPE_MY,
      .parent = TYPE_OBJECT,
      .instance_size = sizeof(MyState),
      .class_size = sizeof(MyClass),
      .class_init = my_class_init,
  };

  typedef struct DerivedClass {
      MyClass parent_class;

      MyDoSomething parent_do_something;
  } DerivedClass;

  static void derived_do_something(MyState *obj)
  {
      DerivedClass *dc = DERIVED_GET_CLASS(obj);

      // do something here
      dc->parent_do_something(obj);
      // do something else here
  }

  static void derived_class_init(ObjectClass *oc, void *data)
  {
      MyClass *mc = MY_CLASS(oc);
      DerivedClass *dc = DERIVED_CLASS(oc);

      dc->parent_do_something = mc->do_something;
      mc->do_something = derived_do_something;
  }

  static const TypeInfo derived_type_info = {
      .name = TYPE_DERIVED,
      .parent = TYPE_MY,
      .class_size = sizeof(DerivedClass),
      .class_init = derived_class_init,
  };
```




# 5. 参考

https://blog.csdn.net/u011364612/article/details/53485856