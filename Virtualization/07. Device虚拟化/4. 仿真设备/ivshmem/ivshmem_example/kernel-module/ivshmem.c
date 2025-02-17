#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/pci.h>
#include <linux/interrupt.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/wait.h>
#include <linux/poll.h>
#include "../ivshmem_common.h"

#define DRIVER_NAME "ivshmem"

#define IVSHMEM_VENDOR_ID 0x1AF4
#define IVSHMEM_DEVICE_ID 0x1110
#define VECTOR_ID 1 //used for trigger interrupt
#define NUM_VECTOR 2



enum {
	/* KVM Inter-VM shared memory device register offsets */
	IntrMask        = 0x00,    /* Interrupt Mask */
	IntrStatus      = 0x04,    /* Interrupt Status */
	IVPosition      = 0x08,    /* VM ID */
	Doorbell        = 0x0c,    /* Doorbell */
};


static int major_nr;
static unsigned int bar0_addr;
static unsigned int bar2_addr;
static void __iomem * regs;
static void * base_addr;
static unsigned int ioaddr_size;

static int vectors[NUM_VECTOR];
static int irqs[NUM_VECTOR];
static int irq_flag = 0;

static DECLARE_WAIT_QUEUE_HEAD(fortune_wait);

irqreturn_t irq_handler(int irq, void *dev_id)
{
  int msg;
  msg = readl(base_addr);
  printk(KERN_INFO "SHUANGDAO: irq_handler get called!, irq_number: %d \
  msg received: 0x%x", irq, msg);
  irq_flag = 1;
  wake_up_interruptible(&fortune_wait);

  return IRQ_HANDLED;
}

static int ivshmem_probe(struct pci_dev *dev, const struct pci_device_id *id)
{
  int nvec;
  int ret, i;
  printk(KERN_DEBUG "Probe function get called\n");

  // print some info for experiments
  // print pci revision
  // using qemu version lower than 2.6 will read 0, otherwise 1
  printk(KERN_INFO "The device revision is %u\n", dev->revision);


  // enable the PCI device
  if (pci_enable_device(dev))
    return -ENODEV;
  printk(KERN_DEBUG "Successfully enable the device\n");

  // request the region
  if (pci_request_regions(dev, DRIVER_NAME))
    goto out_disable;
  printk(KERN_DEBUG "Successfully reserve the resource\n");

  // access BAR address using pci_resource_start

  bar0_addr = pci_resource_start(dev, 0);
  printk(KERN_INFO "BAR0: 0x%08x", bar0_addr);
  regs = pci_iomap(dev, 0, 0x100);

  bar2_addr = pci_resource_start(dev, 2);
  ioaddr_size = pci_resource_len(dev, 2);
  printk(KERN_INFO "BAR2: 0x%08x", bar2_addr);
  base_addr = pci_iomap(dev, 2, 0);

  /* set all masks to on */
  writel(0xffffffff, regs + IntrMask);

  // play with MSI
  // allocate 2 interrupt vector
  nvec = pci_alloc_irq_vectors(dev, NUM_VECTOR, NUM_VECTOR, PCI_IRQ_MSIX);
  if (nvec < 0){
    printk(KERN_ERR "Fail to allocate irq vectors %d", nvec);
    goto out_release;
  }

  printk(KERN_DEBUG "Successfully allocate %d irq vectors", nvec);

  // get the irq numbers for each requet
  for (i = 0; i < NUM_VECTOR; i++){
    vectors[i] = i;
    irqs[i] = pci_irq_vector(dev, i);
    printk(KERN_DEBUG "The irq number is %d for vector %d", irqs[i], i);

    ret = request_irq(irqs[i], irq_handler, IRQF_SHARED, DRIVER_NAME, dev);
    if (ret) {
      printk(KERN_ERR "Fail to request shared irq %d, error: %d", irqs[i], ret);
      goto out_free_vec;
    }
  }

  return 0;

out_free_vec:
  pci_free_irq_vectors(dev);
out_release:
  pci_release_regions(dev);
out_disable:
  pci_disable_device(dev);
  return -ENODEV;

}

unsigned int ivshmem_poll (struct file *file, struct poll_table_struct *wait){
  printk(KERN_INFO "Poll function get called, waiting for irq");
  if (irq_flag == 1){
    irq_flag = 0;
    printk(KERN_INFO "Message is ready, no need to wait");
    return POLLIN | POLLRDNORM;
  }
  poll_wait(file, &fortune_wait, wait);
  if (irq_flag == 1){
    irq_flag = 0;
    printk(KERN_INFO "Poll function returned");
    return POLLIN | POLLRDNORM;
  }
  printk(KERN_INFO "Poll failed");
  return 0;
}

static void ivshmem_remove(struct pci_dev *dev)
{
  int i;
  pci_iounmap(dev, regs);
  pci_iounmap(dev, base_addr);

  for (i = 0; i < NUM_VECTOR; i++){
    free_irq(irqs[i], dev);
  }

  pci_free_irq_vectors(dev);
  pci_release_regions(dev);
  pci_disable_device(dev);
  printk(KERN_DEBUG "Remove function get called, resource freed\n");
  return;
}

 static struct pci_device_id ivshmem_pci_ids[] = {
 	{PCI_DEVICE(IVSHMEM_VENDOR_ID, IVSHMEM_DEVICE_ID)},
 	{ /* end: all zeroes */ }
 };


 static struct pci_driver ivshmem_pci_driver = {
    .name = DRIVER_NAME,
    .id_table = ivshmem_pci_ids,
    .probe = ivshmem_probe,
    .remove = ivshmem_remove,
};

static ssize_t ivshmem_read(struct file * filp, char * buffer, size_t len,
  loff_t * poffset)
{
    return 0;
}


static int ivshmem_open(struct inode *i, struct file *f)
{
  printk(KERN_INFO "chardev file opened!");
  return 0;
}
static int ivshmem_close(struct inode *i, struct file *f)
{
  printk(KERN_INFO "chardev file closed!");
  return 0;
}

static long ivshmem_ioctl(struct file *f, unsigned int cmd, unsigned long arg){
  // print ivposition and status
  uint32_t vmid, msg;
  irq_arg i_arg;

  switch (cmd){
    case CMD_READ_SHMEM:
      msg = readl(base_addr);
      printk(KERN_INFO "IVSHMEM: read shared mem");
      if (copy_to_user((int *)arg, &msg, sizeof(int)))
        return -EACCES;
      break;
    case CMD_READ_VMID:
      vmid = readl(regs + IVPosition);
      printk(KERN_INFO "IVSHMEM: read vmid");
      if (copy_to_user((int *)arg, &vmid, sizeof(int)))
        return -EACCES;
      break;
    case CMD_INTERRUPT:
      if (copy_from_user(&i_arg, (irq_arg *)arg, sizeof(irq_arg))){
        return -EACCES;
      }
      printk(KERN_INFO "IVSHMEM: read dest vmid from user %d", i_arg.dest_id);
      msg = ((i_arg.dest_id & 0xffff) << 16) + (VECTOR_ID & 0xffff);
      printk(KERN_INFO "IVSHMEM: write 0x%x to Doorbell", msg);
      writel(msg, regs + Doorbell);
      writel(i_arg.msg, base_addr);
      break;
  }
  return 0;
}

static struct file_operations ivshmem_fops =
{
    .owner = THIS_MODULE,
    .open = ivshmem_open,
    .release = ivshmem_close,
    .read = ivshmem_read,
    .unlocked_ioctl = ivshmem_ioctl,
    .poll = ivshmem_poll
};

static int __init ivshmem_init_module(void)
{
	int ret;
  // print something to understand
  printk(KERN_INFO "command %ld, %ld, %ld\n",CMD_READ_SHMEM, CMD_READ_VMID, CMD_INTERRUPT);

  ret = register_chrdev(0, DRIVER_NAME, &ivshmem_fops);
	if (ret < 0) {
		printk(KERN_ERR "Unable to register ivshmem device\n");
		return ret;
  }
  major_nr = ret;
  printk("IVSHMEM: Major device number is: %d\n", major_nr);

  ret = pci_register_driver(&ivshmem_pci_driver);
  if (ret < 0) {
		goto error;
  }
	return 0;
error:
  	unregister_chrdev(major_nr, DRIVER_NAME);
  return ret;
}

static void __exit ivshmem_exit_module(void)
{
  pci_unregister_driver(&ivshmem_pci_driver);
  unregister_chrdev(major_nr, DRIVER_NAME);
  printk(KERN_DEBUG "Module exit");
}

MODULE_DEVICE_TABLE(pci, ivshmem_pci_ids);
MODULE_DESCRIPTION("A simple ivshmem PCI driver");
MODULE_AUTHOR("Gavin");
MODULE_LICENSE("GPL");
module_init(ivshmem_init_module);
module_exit(ivshmem_exit_module);
