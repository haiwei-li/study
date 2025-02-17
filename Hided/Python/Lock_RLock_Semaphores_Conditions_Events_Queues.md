http://yoyzhou.github.io/blog/2013/02/28/python-threads-synchronization-locks/

Python锁的实现: https://www.apt-browse.org/browse/ubuntu/trusty/main/all/python-neutron/1%3A2014.1-0ubuntu1/file/usr/lib/python2.7/dist-packages/neutron/openstack/common/lockutils.py

当进程A获取到锁, 然后删除锁文件, 这时候B进程获取锁会等待, A释放锁后会生成文件(通过调用获取锁), B进程再获取锁