
search: https://lore.kernel.org/linux-fsdevel/?q=Detaching+mounts+on+unlink

DoS with unprivileged mounts:

https://lore.kernel.org/linux-fsdevel/CAJfpegsxgnSRUW-E5HM3uT5QfGyUtn_v=i4Ppkkkutp34287AA@mail.gmail.com/

在**任何命名空间**中的**任何 mount 实例**中. 有一种简单有效的方法, 可以通过简单地在文件或目录上 mount 某些东西来**防止** unlink(2)和 rename(2)在任何文件或目录上运行.

在非特权 mount 设计中是否考虑了这一点?

> Eric W. Biederman
> 重点是不要欺骗特权应用程序, 而实际上应该更深入地考虑的一些次要效果却被忽略了.

从理论上讲, 该解决方案也很简单: 将**非特权私有命名空间**中的 mount 标记为"易失性"(volatile), 并在 unlink 类型操作中分解.

> Andy Lutomirski
> 我实际上更喜欢相反的情况: 无特权的挂载不会阻止 unlink 和 rename.  如果该 dentry 消失了, 那么在 mount 点没有文件的情况下, 该挂载仍将存在.  (网络文件系统已支持此功能. )

这样的易失性 mount 通常也很有用.

> Eric W. Biederman
> 同意
>
> 通常, 使用挂接名称空间通常会遇到这个问题.
>
> 我认为真正的技术障碍是在某个随机 mount 命名空间中找到 mount t.  一旦我们可以相对有效地做到这一点, 其余的就变得简单了.

> Miklos Szeredi
> 我们已经在 Dentry 上 hashed 了一个"struct mountpoint".  在那个挂载点上链接挂载是微不足道的.  我们需要一个 MNT_VOLATILE 标志, 仅此而已.  如果我们担心遍历 Dentry 上的 mount 列表以检查非易失性 mount , 则还可以为 struct mountpoint 添加一个单独的 volatile 计数器, 并为 Dentry 添加一个匹配标志.  但是我认为那不是真的必要.


当然, 我们在网络文件系统中通过伪装 rename/unlink 方式实现, 实际上没有发生此操作. VFS 坚持认为这是谎言, 而不是反映实际发生的情况. (Of course we do this in network filesystems by pretending the rename/unlink did not actually happen.  The vfs insists that it be lied to instead of mirroring what actually happened.)

同样, 所有这些都是关于有效数据结构的问题, 而不是真正的语义问题.  可以以不减慢 vfs 的方式实现任一语义吗?

> 鉴于 vfs_unlink 具有:
```
	if (d_mountpoint(dentry))
		error = -EBUSY;
```
> 我认为这只是更改/删除该代码的问题.

删除代码是完全不可接受的, 因为它会生成永远无法 unmount 的 mount.

更改此代码是我们正在讨论的内容.  我的观点是, 有效的替换并不是立即显而易见的, 并且降低 vfs 快速路径性能以使这种情况更好地工作的解决方案不太可能被接受.






点击 author 名字, 然后删掉上面的 `Archived = No`, 如下

https://lore.kernel.org/patchwork/project/lkml/list/?submitter=353&archive=both


看提交的 patch, 找到相关 patch 的最初版本

* RFC: https://lore.kernel.org/patchwork/cover/411005/
* v1: https://lore.kernel.org/patchwork/cover/442167/
* 3.15 v2: https://lore.kernel.org/patchwork/cover/444858/

git repo:

https://git.kernel.org/pub/scm/linux/kernel/git/ebiederm/user-namespace.git/refs/heads vfs-detach-mounts*








以 `Detach mounts on unlink` 为例

首先, 确定最初的 patchset. 通过`tig blame fs/namei.c` 查看 `vfs_rmdir()` 函数中的 `detach_mounts(dentry);`确定了一个 commit:

```
8ed936b5671bfb33d89bc60bdcc7cf0470ba52fe, "vfs: Lazily remove mounts on unlinked files and directories.", Tue Oct 1 18:33:48 2013
```

通过 `patchwork.kernel` 没有搜索到相关 patch 数据:

https://patchwork.kernel.org/project/linux-fsdevel/list/?series=&submitter=&state=*&q=Lazily+remove+mounts+on+unlinked+files+and+directories&archive=both&delegate=

这是 2013 年的, 所以可能没有数据, 所以从 `lore.kernel.org/patchwork` 搜索, 得到了, 链接如下:

https://lore.kernel.org/patchwork/project/lkml/list/?series=&submitter=&state=*&q=Lazily+remove+mounts+on+unlinked+files+and+directories&archive=both&delegate=

![2021-05-22-22-51-40.png](./images/2021-05-22-22-51-40.png)

这里得到了 4 个版本的

* RFC: https://lore.kernel.org/patchwork/cover/411005/, Oct. 4, 2013, 10:41 p.m. UTC
* v1: https://lore.kernel.org/patchwork/cover/413940/, Oct. 15, 2013, 8:15 p.m. UTC
* v2: https://lore.kernel.org/patchwork/cover/442167/, Feb. 15, 2014, 9:34 p.m. UTC
* v3: https://lore.kernel.org/patchwork/cover/444858/, Feb. 25, 2014, 9:33 a.m. UTC

但是从时间上看, 很明显没有最终版本的

**还有个办法**, 点击 author 名字, 然后删掉上面的 `Archived = No`, 得到如下

https://lore.kernel.org/patchwork/project/lkml/list/?submitter=353&archive=both

看提交的时间和名字, 找到相关 patch 的最初版本

很明显, 也没有找到`2014-10-01`的版本, 所以也可比较明确知道, 这个应该是通过其他途径合入的, 这里就不细究了.

这里就得到了最初始的 RFC 版本.

最后再通过 `lore.kernel.org/lists.html` 的模块进行搜索:

https://lore.kernel.org/linux-fsdevel/?q=Detaching+mounts+on+unlink

根据时间相近性得到了 `DoS with unprivileged mounts`:

https://lore.kernel.org/linux-fsdevel/CAJfpegsxgnSRUW-E5HM3uT5QfGyUtn_v=i4Ppkkkutp34287AA@mail.gmail.com/







# 资料

https://git.kernel.org/pub/scm/linux/kernel/git/ebiederm/user-namespace.git/refs/heads


https://git.kernel.org/pub/scm/linux/kernel/git/ebiederm/user-namespace.git/log/?h=vfs-detach-mounts

https://lore.kernel.org/linux-fsdevel/?q=Detaching+mounts+on+unlink

https://lore.kernel.org/linux-fsdevel/8761v7h2pt.fsf@tw-ebiederman.twitter.com/

https://lore.kernel.org/patchwork/project/lkml/list/?submitter=353&archive=both&param=6&page=7

https://lore.kernel.org/patchwork/cover/411005/

https://lore.kernel.org/patchwork/cover/444858/

