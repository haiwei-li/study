CONFIG_MODULE_SIG=n

obj-m += ivpci.o
all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules
	gcc -g -O0 ioctl.c -o ioctl
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
	rm -rf ioctl