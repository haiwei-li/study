obj-m+=ivshmem.o

all:
	make -C /lib/modules/$(shell uname -r)/build/ M=$(PWD) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build/ M=$(PWD) clean; \
  rm -f *.ko *.o ivshmem.mod.c *.cmd *.mk Module.symvers modules.order
