

How to debug Virtualization problems: https://fedoraproject.org/wiki/How_to_debug_Virtualization_problems

KVM tracing: https://www.linux-kvm.org/page/Tracing

技术分享: 虚拟化环境下解析 Windows IO 性能: https://zhuanlan.51cto.com/art/201706/542731.htm


很多 trace 等可以使用`kvm-unit-test/x86`下面的, 当然可以自己编写


还有`tools/testing/selftests/kvm/`下面内容

社区很有意思的一系列 debug 的 patch: https://patchwork.kernel.org/project/kvm/cover/20210315221020.661693-1-mlevitsk@redhat.com/