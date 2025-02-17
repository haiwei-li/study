# Ivshmem-example
This repo demostrate the usage of qemu ivshmem pci device. 

## What is ivshmem
 The Inter-VM shared memory device (ivshmem) is designed to share a
memory region between multiple QEMU processes running different guests
and the host.  In order for all guests to be able to pick up the
shared memory area, it is modeled by QEMU as a PCI device exposing
said memory to the guest as a PCI BAR.

Specification: [see here](https://github.com/qemu/qemu/blob/master/docs/specs/ivshmem-spec.txt)

## How to use it
This project is using qemu version > 2.5.0, so the revision of ivshmem is 1, I have not try with the older version, but I believe it should work, you just need pass some different options to qemu

### Server setup
1. run ivshmem server: `ivshmem-server -vF -n 2` make it run in verbose and foreground mode and set the number of msi vector to 2. (Using default n = 1 is enough, but I just want to try with more vectors, in this project, only vector 1 get used)

2. open two virtual machines with option `-device ivshmem-doorbell,vectors=2,chardev=ivshmem -chardev socket,path=/tmp/ivshmem_socket,id=ivshmem` 

### Kernel module setup
In two virtual machines, setup the kernel module:

1. `sudo insmod ivshmem.ko` 
2. Using `dmsg` command to read the device *major number*
3. Create the char device `sudo mknod /dev/ivshmem c <major_nr> 0`

### User space application
Use `./userctl`

- `-d` read the *guest id*
- on one of the vm, run `sudo ./userctl -p`
- on the other vm, run `sudo ./userctl -c <destination_guest_id>`


