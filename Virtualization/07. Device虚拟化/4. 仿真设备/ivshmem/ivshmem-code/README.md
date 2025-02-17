IVSHMEM testing code
====================

This is the code repository for the shared memory device for KVM/Qemu.  This
GIT repository contains code and scripts that demonstrate how to make use of
the shared memory device.  I use the name 'Nahanni' to refer to my device and
system.  It is not that the system is so substantial that it requires its own
name, but having a name makes discussion easier.

**The Device**

The device specification is in the file device-spec.txt.  If you want to write
a device driver for a different OS than Linux, the device spec will describe
how the device works.

**Directories in this repo**

kernel_module - Linux kernel modules and makefiles to build them against the
currently running kernel.
There are two kinds of drivers.  "Normal" pci
drivers and a UIO_PCI driver.  *Use the UIO_PCI driver.*  The other driver is only
kept their for legacy purposes.  With
UIO_PCI, device registers and memory regions are usually mapped to userspace
and accessed directly which has certain advantages.

scripts - these aren't shared memory scripts, but are networking scripts when
using DNSmasq for networking.  Perhaps they don't belong here.

startup_files - these are Linux init scripts for different Linux distros namely
ubuntu, fedora and SUSE.  Init scripts formats can change and so some tweaking
may be necessary for newer versions of distros.
There is also a UIO_PCI init script which is different than regular device
init scripts.

tests - test programs for using shared memory device WITHOUT UIO_PCI.  These
tests rely on mmap to access the shared region and ioctl calls to trigger
interrupts in other guests.

uio - test programs for the UIO driver that uses the assigned mappings of
registers and memory to trigger notifications rather than ioctl calls as in the
other 'tests' directory.

