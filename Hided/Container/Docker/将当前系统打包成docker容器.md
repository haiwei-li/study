
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [1 将当前系统打包成tar文件](#1-将当前系统打包成tar文件)
* [2 导入镜像](#2-导入镜像)
* [3 运行镜像](#3-运行镜像)

<!-- /code_chunk_output -->

# 1 将当前系统打包成tar文件

```
tar -cvpf /home/system.tar --directory=/ --exclude=proc --exclude=sys --exclude=dev --exclude=run /
```

/proc、/sys、/run、/dev这几个目录都是系统启动时自动生成的！依赖与系统内核！

# 2 导入镜像

```
docker import system.tar
cat system.tar | docker import - redhat:6.5
```

# 3 运行镜像

```
docker images
```

```
docker run -it XXX /bin/bash
```