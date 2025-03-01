

参见 `Linux/Benchmark/selftest`

官方文档: `Documentation/dev-tools/kselftest.rst`

```
yum install libcap-devel -y
yum install libmount-devel -y
yum install libcap-ng-devel -y
yum install libmnl-devel -y
```


`tools/testing/selftests/kvm`

make O=/tmp/kselftest TARGETS=kvm kselftest

make -C tools/testing/selftests TARGETS=kvm

make -C tools/testing/selftests TARGETS=kvm run_tests

make -C tools/testing/selftests TARGETS=kvm O=/tmp/kselftest run_tests



单独执行

```
cd tools/testing/selftests/kvm

./kvm_create_max_vcpus
```

如果 /usr/include 中没有一些定义, 那就执行 `make headers_install`: Exporting kernel headers for use by userspace