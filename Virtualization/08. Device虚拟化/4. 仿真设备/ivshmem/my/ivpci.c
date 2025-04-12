#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/version.h>
#include <linux/delay.h>
#include <linux/err.h>
#include <linux/fs.h>
#include <linux/mm.h>
#include <linux/pci.h>
#include <linux/pci_regs.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/uaccess.h>
#include <linux/interrupt.h>
#include <linux/ioctl.h>
#include <linux/sched.h>
#include <linux/wait.h>

#define DRV_NAME        "ivpci"
#define DRV_VERSION     "0.1"
#define PFX             "[IVPCI] "
#define DRV_FILE_FMT    DRV_NAME"%d"

#define IVPOSITION_OFF  0x08    /* VM ID */
#define DOORBELL_OFF    0x0c    /* Doorbell */

#define IOCTL_MAGIC         ('f')
#define IOCTL_RING          _IOW(IOCTL_MAGIC, 1, u32)
#define IOCTL_WAIT          _IO(IOCTL_MAGIC, 2)
#define IOCTL_IVPOSITION    _IOR(IOCTL_MAGIC, 3, u32)

static int g_max_devices = 2;
MODULE_PARM_DESC(g_max_devices, "number of devices can be supported");
module_param(g_max_devices, int, 0400);

static unsigned long g_interrupts= 0;
MODULE_PARM_DESC(g_interrupts, "number of interrupts");
module_param(g_interrupts, ulong, 0600);

static unsigned long interrupts_1time = 1;
MODULE_PARM_DESC(interrupts_1time, "trigger number of interrupts one time");
module_param(interrupts_1time, ulong, 0600);

static unsigned long itr_delay = 0;
MODULE_PARM_DESC(itr_delay, "trigger delay(us) of interrupts");
module_param(itr_delay, ulong, 0600);

struct ivpci_private {
    struct pci_dev      *dev;
    struct cdev         cdev;
    int                 minor;

    u8                  revision;
    u32                 ivposition;

    u8 __iomem          *base_addr;
    u8 __iomem          *regs_addr;

    unsigned int        bar0_addr;
    unsigned int        bar0_len;
    unsigned int        bar1_addr;
    unsigned int        bar1_len;
    unsigned int        bar2_addr;
    unsigned int        bar2_len;

    char                (*msix_names)[256];
    struct msix_entry   *msix_entries;
    int                 nvectors;
};

static int event_toggle;
DECLARE_WAIT_QUEUE_HEAD(wait_queue);

/* store major device number shared by all ivshmem devices */
static dev_t g_ivpci_devno;
static int  g_ivpci_major;

static struct class *g_ivpci_class;

/* number of devices owned by this driver */
static int g_ivpci_count;

static struct ivpci_private *g_ivpci_devs;

static struct pci_device_id ivpci_id_table[] = {
    { 0x1af4, 0x1110, PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0},
    { 0 },
};
MODULE_DEVICE_TABLE(pci, ivpci_id_table);

static struct ivpci_private *ivpci_get_private(void)
{
    int i;

    for (i = 0; i < g_max_devices; i++) {
        if (g_ivpci_devs[i].dev == NULL) {
            return &g_ivpci_devs[i];
        }
    }

    return NULL;
}

static struct ivpci_private *ivpci_find_private(int minor)
{
    int i;
    for (i = 0; i < g_max_devices; i++) {
        if (g_ivpci_devs[i].dev != NULL && g_ivpci_devs[i].minor == minor) {
            return &g_ivpci_devs[i];
        }
    }

    return NULL;
}

static irqreturn_t ivpci_interrupt(int irq, void *dev_id)
{
    struct ivpci_private *ivpci_dev = dev_id;

    if (unlikely(ivpci_dev == NULL)) {
        return IRQ_NONE;
    }

    dev_info(&ivpci_dev->dev->dev, PFX "interrupt: %d\n", irq);

    event_toggle = 1;
    wake_up_interruptible(&wait_queue);

    return IRQ_HANDLED;
}

static int ivpci_request_msix_vectors(struct ivpci_private *ivpci_dev, int n)
{
    int ret, i;

    ret = -EINVAL;

    dev_info(&ivpci_dev->dev->dev, PFX "request msi-x vectors: %d\n", n);

    ivpci_dev->nvectors = n;

    ivpci_dev->msix_entries = kmalloc(n * sizeof(struct msix_entry),
            GFP_KERNEL);
    if (ivpci_dev->msix_entries == NULL) {
        ret = -ENOMEM;
        goto error;
    }

    ivpci_dev->msix_names = kmalloc(n * sizeof(*ivpci_dev->msix_names),
            GFP_KERNEL);
    if (ivpci_dev->msix_names == NULL) {
        ret = -ENOMEM;
        goto free_entries;
    }

    for (i = 0; i < n; i++) {
        ivpci_dev->msix_entries[i].entry = i;
    }

    ret = pci_enable_msix_exact(ivpci_dev->dev, ivpci_dev->msix_entries, n);
    if (ret) {
        dev_err(&ivpci_dev->dev->dev, PFX "unable to enable msix: %d\n", ret);
        goto free_names;
    }

    for (i = 0; i < ivpci_dev->nvectors; i++) {
        snprintf(ivpci_dev->msix_names[i], sizeof(*ivpci_dev->msix_names),
                "%s%d-%d", DRV_NAME, ivpci_dev->minor, i);

        ret = request_irq(ivpci_dev->msix_entries[i].vector,
                ivpci_interrupt, 0, ivpci_dev->msix_names[i], ivpci_dev);

        if (ret) {
            dev_err(&ivpci_dev->dev->dev, PFX "unable to allocate irq for " \
                    "msix entry %d with vector %d\n", i,
                    ivpci_dev->msix_entries[i].vector);
            goto release_irqs;
        }

        dev_info(&ivpci_dev->dev->dev,
                PFX "irq for msix entry: %d, vector: %d\n",
                i, ivpci_dev->msix_entries[i].vector);
    }

    return 0;

release_irqs:
    for ( ; i > 0; i--) {
        free_irq(ivpci_dev->msix_entries[i - 1].vector, ivpci_dev);
    }
    pci_disable_msix(ivpci_dev->dev);

free_names:
    kfree(ivpci_dev->msix_names);

free_entries:
    kfree(ivpci_dev->msix_entries);

error:
    return ret;
}

static void ivpci_free_msix_vectors(struct ivpci_private *ivpci_dev)
{
    int i;

    for (i = ivpci_dev->nvectors; i > 0; i--) {
        free_irq(ivpci_dev->msix_entries[i - 1].vector, ivpci_dev);
    }
    pci_disable_msix(ivpci_dev->dev);

    kfree(ivpci_dev->msix_names);
    kfree(ivpci_dev->msix_entries);
}

static int ivpci_open(struct inode *inode, struct file *filp)
{
    int minor = iminor(inode);
    struct ivpci_private *ivpci_dev;

    ivpci_dev = ivpci_find_private(minor);
    filp->private_data = (void *) ivpci_dev;
    BUG_ON(filp->private_data == NULL);

    dev_info(&ivpci_dev->dev->dev, PFX "open ivpci\n");

    return 0;
}

static int ivpci_mmap(struct file *filp, struct vm_area_struct *vma)
{
    int ret;
    unsigned long len;
    unsigned long off;
    unsigned long start;
    struct ivpci_private *ivpci_dev;

    ivpci_dev = (struct ivpci_private *)filp->private_data;
    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);

    dev_info(&ivpci_dev->dev->dev, PFX "mmap ivpci bar2\n");

    /* `vma->vm_start` and `vma->vm_end` had aligned to page size */
    WARN_ON(offset_in_page(vma->vm_start));
    WARN_ON(offset_in_page(vma->vm_end));

    off = vma->vm_pgoff << PAGE_SHIFT;
    start = ivpci_dev->bar2_addr;

    /* Align up to page size. */
    len = PAGE_ALIGN((start & ~PAGE_MASK) + ivpci_dev->bar2_len);
    start &= PAGE_MASK;

    dev_info(&ivpci_dev->dev->dev, PFX "mmap vma pgoff: %lu, 0x%0lx - 0x%0lx," \
            " aligned length: %lu\n", vma->vm_pgoff, vma->vm_start,
            vma->vm_end, len);

    if (vma->vm_end - vma->vm_start + off > len) {
        dev_err(&ivpci_dev->dev->dev,
                PFX "mmap overflow the end, %lu - %lu + %lu > %lu",
                vma->vm_end, vma->vm_start, off, len);
        ret = -EINVAL;
        goto error;
    }

    off += start;
    vma->vm_pgoff = off >> PAGE_SHIFT;
    vma->vm_flags |= VM_IO|VM_SHARED|VM_DONTEXPAND|VM_DONTDUMP;

    if (io_remap_pfn_range(vma, vma->vm_start, off >> PAGE_SHIFT,
                vma->vm_end - vma->vm_start, vma->vm_page_prot)) {
        dev_err(&ivpci_dev->dev->dev, PFX "mmap bar2 failed\n");
        ret = -ENXIO;
        goto error;
    }

    ret = 0;

error:
    return ret;
}

static ssize_t ivpci_read(struct file *filp, char *buffer, size_t len,
        loff_t *poffset)
{
    int bytes_read = 0;
    unsigned long offset;
    struct ivpci_private *ivpci_dev;

    ivpci_dev = (struct ivpci_private *)filp->private_data;

    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);


    offset = *poffset;
    dev_info(&ivpci_dev->dev->dev, PFX "read ivpci bar2, offset: %lu\n",
            offset);

    /* beyoud the end */
    if (len > ivpci_dev->bar2_len - offset) {
        len = ivpci_dev->bar2_len - offset;
    }

    if (len == 0) {
        return 0;
    }

    bytes_read = copy_to_user(buffer, (char *)ivpci_dev->base_addr + offset,
            len);
    if (bytes_read > 0) {
        dev_err(&ivpci_dev->dev->dev,
                PFX "read ivpci bar2, copy_to_user() failed: %d\n", bytes_read);
        return -EFAULT;
    }

    *poffset += len;
    return len;
}

static long ivpci_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
    int ret, i;
    struct ivpci_private *ivpci_dev;
    u16 ivposition;
    u16 vector;
    u32 value;

    ivpci_dev = (struct ivpci_private *)filp->private_data;

    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);

    switch (cmd) {
    case IOCTL_RING:
        if (copy_from_user(&value, (u32 *) arg, sizeof(value)) ) {
            dev_err(&ivpci_dev->dev->dev, PFX "copy from user failed");
            return -1;
        }
        vector = value & 0xffff;
        ivposition = value & 0xffff0000 >> 16;
        dev_info(&ivpci_dev->dev->dev,
                PFX "ring doorbell: value: %u(0x%x), vector: %u, peer id: %u\n",
                value, value, vector, ivposition);
        for (i = 0; i < interrupts_1time; i++) {
            if (itr_delay)
                udelay(itr_delay);
            writel(value & 0xffffffff, ivpci_dev->regs_addr + DOORBELL_OFF);
            g_interrupts++;
        }
        break;

    case IOCTL_WAIT:
        dev_info(&ivpci_dev->dev->dev, PFX "wait for interrupt\n");
        ret = wait_event_interruptible(wait_queue, (event_toggle == 1));
        if (ret == 0) {
            dev_info(&ivpci_dev->dev->dev, PFX "wakeup\n");
            event_toggle = 0;
        } else if (ret == -ERESTARTSYS) {
            dev_err(&ivpci_dev->dev->dev, PFX "interrupted by signal\n");
            return ret;
        } else {
            dev_err(&ivpci_dev->dev->dev, PFX "unknown failed: %d\n", ret);
            return ret;
        }
        break;

    case IOCTL_IVPOSITION:
        dev_info(&ivpci_dev->dev->dev, PFX "get ivposition: %u\n",
                ivpci_dev->ivposition);
        if (copy_to_user((u32 *) arg, &ivpci_dev->ivposition, sizeof(u32))) {
            dev_err(&ivpci_dev->dev->dev, PFX "copy to user failed");
            return -1;
        }
        break;

    default:
        dev_err(&ivpci_dev->dev->dev, PFX "bad ioctl command: %d\n", cmd);
        return -1;
    }

    return 0;
}

static long ivpci_write(struct file *filp, const char *buffer, size_t len,
        loff_t *poffset)
{
    int bytes_written = 0;
    unsigned long offset;
    struct ivpci_private *ivpci_dev;

    ivpci_dev = (struct ivpci_private *)filp->private_data;

    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);

    dev_info(&ivpci_dev->dev->dev, PFX "write ivpci bar2\n");

    offset = *poffset;

    if (len > ivpci_dev->bar2_len - offset) {
        len = ivpci_dev->bar2_len - offset;
    }

    if (len == 0) {
        return 0;
    }

    bytes_written = copy_from_user(ivpci_dev->base_addr + offset, buffer, len);
    if (bytes_written > 0) {
        return -EFAULT;
    }

    *poffset += len;
    return len;
}

static loff_t ivpci_lseek(struct file *filp, loff_t offset, int origin)
{
    loff_t retval = -1;
    struct ivpci_private *ivpci_dev;

    ivpci_dev = (struct ivpci_private *)filp->private_data;

    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);

    dev_info(&ivpci_dev->dev->dev,
            PFX "lseek ivpci bar2, offset: %llu, origin: %d\n", offset, origin);

    switch (origin) {
    case 1:
        offset += filp->f_pos;
        /* fall through */
    case 0:
        retval = offset;
        if (offset > ivpci_dev->bar2_len) {
            offset = ivpci_dev->bar2_len;
        }
        filp->f_pos = offset;
    }
    return retval;
}

static int ivpci_release(struct inode *inode, struct file *filp)
{
    struct ivpci_private *ivpci_dev;
    ivpci_dev = (struct ivpci_private *)filp->private_data;

    BUG_ON(ivpci_dev == NULL);
    BUG_ON(ivpci_dev->base_addr == NULL);

    dev_info(&ivpci_dev->dev->dev, PFX "release ivpci\n");

    return 0;
}

static struct file_operations ivpci_ops = {
    .owner          = THIS_MODULE,
    .open           = ivpci_open,
    .mmap           = ivpci_mmap,
    .unlocked_ioctl = ivpci_ioctl,
    .read           = ivpci_read,
    .write          = ivpci_write,
    .llseek         = ivpci_lseek,
    .release        = ivpci_release,
};

static int ivpci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
{
    int ret;
    struct ivpci_private *ivpci_dev;
    dev_t devno;

    dev_info(&pdev->dev, PFX "probing for device: %s\n", pci_name(pdev));

    if (g_ivpci_count >= g_max_devices) {
        dev_err(&pdev->dev, PFX "reach the maxinum number of devices, " \
                "please adapt the `g_max_devices` value, reload the driver\n");
        ret = -1;
        goto out;
    }

    ret = pci_enable_device(pdev);
    if (ret < 0) {
        dev_err(&pdev->dev, PFX "unable to enable device: %d\n", ret);
        goto out;
    }

    /* Reserved PCI I/O and memory resources for this device */
    ret = pci_request_regions(pdev, DRV_NAME);
    if (ret < 0) {
        dev_err(&pdev->dev, PFX "unable to reserve resources: %d\n", ret);
        goto disable_device;
    }

    ivpci_dev = ivpci_get_private();
    BUG_ON(ivpci_dev == NULL);

    pci_read_config_byte(pdev, PCI_REVISION_ID, &ivpci_dev->revision);

    dev_info(&pdev->dev, PFX "device %d:%d, revision: %d\n", g_ivpci_major,
            ivpci_dev->minor, ivpci_dev->revision);

    /* Pysical address of BAR0, BAR1, BAR2 */
    ivpci_dev->bar0_addr = pci_resource_start(pdev, 0);
    ivpci_dev->bar0_len = pci_resource_len(pdev, 0);
    ivpci_dev->bar1_addr = pci_resource_start(pdev, 1);
    ivpci_dev->bar1_len = pci_resource_len(pdev, 1);
    ivpci_dev->bar2_addr = pci_resource_start(pdev, 2);
    ivpci_dev->bar2_len = pci_resource_len(pdev, 2);

    dev_info(&pdev->dev, PFX "BAR0: 0x%0x@0x%0x\n", ivpci_dev->bar0_addr,
            ivpci_dev->bar0_len);
    dev_info(&pdev->dev, PFX "BAR1: 0x%0x@0x%0x\n", ivpci_dev->bar1_addr,
            ivpci_dev->bar1_len);
    dev_info(&pdev->dev, PFX "BAR2: 0x%0x@0x%0x\n", ivpci_dev->bar2_addr,
            ivpci_dev->bar2_len);

    //ivpci_dev->regs_addr = ioremap(ivpci_dev->bar0_addr, ivpci_dev->bar0_len);
    ivpci_dev->regs_addr = pci_iomap(pdev, 0, 0x100);
    if (!ivpci_dev->regs_addr) {
        dev_err(&pdev->dev, PFX "unable to ioremap bar0, size: %d\n",
                ivpci_dev->bar0_len);
        goto release_regions;
    }

    //ivpci_dev->base_addr = ioremap(ivpci_dev->bar2_addr, ivpci_dev->bar2_len);
    ivpci_dev->base_addr = pci_iomap(pdev, 2, 0);
    if (!ivpci_dev->base_addr) {
        dev_err(&pdev->dev, PFX "unable to ioremap bar2, size: %d\n",
                ivpci_dev->bar2_len);
        goto iounmap_bar0;
    }
    dev_info(&pdev->dev, PFX "BAR2 map: %p\n", ivpci_dev->base_addr);

    /*
     * Create character device file.
     */
    cdev_init(&ivpci_dev->cdev, &ivpci_ops);
    ivpci_dev->cdev.owner = THIS_MODULE;

    devno = MKDEV(g_ivpci_major, ivpci_dev->minor);
    ret = cdev_add(&ivpci_dev->cdev, devno, 1);
    if (ret < 0) {
        dev_err(&pdev->dev, PFX "unable to add chrdev %d:%d to system: %d\n",
                g_ivpci_major, ivpci_dev->minor, ret);
        goto iounmap_bar2;
    }

    if (device_create(g_ivpci_class, NULL, devno, NULL, DRV_FILE_FMT,
                ivpci_dev->minor) == NULL)
    {
        dev_err(&pdev->dev, PFX "unable to create device file: %d:%d\n",
                g_ivpci_major, ivpci_dev->minor);
        goto delete_chrdev;
    }

    ivpci_dev->dev = pdev;
    pci_set_drvdata(pdev, ivpci_dev);

    if (ivpci_dev->revision == 1) {
        /* Only process the MSI-X interrupt. */
        ivpci_dev->ivposition = ioread32(ivpci_dev->regs_addr + IVPOSITION_OFF);

        dev_info(&pdev->dev, PFX "device ivposition: %u, MSI-X: %s\n",
                ivpci_dev->ivposition,
                (ivpci_dev->ivposition == 0) ? "no": "yes");

        if (ivpci_dev->ivposition != 0) {
            ret = ivpci_request_msix_vectors(ivpci_dev, 4);
            if (ret != 0) {
                goto destroy_device;
            }
        }
    }

    g_ivpci_count++;
    dev_info(&pdev->dev, PFX "device probed: %s\n", pci_name(pdev));
    return 0;

destroy_device:
    devno = MKDEV(g_ivpci_major, ivpci_dev->minor);
    device_destroy(g_ivpci_class, devno);
    ivpci_dev->dev = NULL;

delete_chrdev:
    cdev_del(&ivpci_dev->cdev);

iounmap_bar2:
    iounmap(ivpci_dev->base_addr);

iounmap_bar0:
    iounmap(ivpci_dev->regs_addr);

release_regions:
    pci_release_regions(pdev);

disable_device:
    pci_disable_device(pdev);

out:
    pci_set_drvdata(pdev, NULL);
    return ret;
}

static void ivpci_remove(struct pci_dev *pdev)
{
    int devno;
    struct ivpci_private *ivpci_dev;

    dev_info(&pdev->dev, PFX "removing ivshmem device: %s\n", pci_name(pdev));

    ivpci_dev = pci_get_drvdata(pdev);
    BUG_ON(ivpci_dev == NULL);

    ivpci_free_msix_vectors(ivpci_dev);

    ivpci_dev->dev = NULL;

    devno = MKDEV(g_ivpci_major, ivpci_dev->minor);
    device_destroy(g_ivpci_class, devno);

    cdev_del(&ivpci_dev->cdev);

    iounmap(ivpci_dev->base_addr);
    iounmap(ivpci_dev->regs_addr);

    pci_release_regions(pdev);
    pci_disable_device(pdev);
    pci_set_drvdata(pdev, NULL);
}

static struct pci_driver ivpci_driver = {
    .name       = DRV_NAME,
    .id_table   = ivpci_id_table,
    .probe      = ivpci_probe,
    .remove     = ivpci_remove,
};

static int __init ivpci_init(void)
{
    int ret, i, minor;

    pr_info(PFX "*********************************************************\n");
    pr_info(PFX "module loading\n");

    ret = alloc_chrdev_region(&g_ivpci_devno, 0, g_max_devices, DRV_NAME);
    if (ret < 0) {
        pr_err(PFX "unable to allocate major number: %d\n", ret);
        goto out;
    }

    g_ivpci_devs = kzalloc(sizeof(struct ivpci_private) * g_max_devices,
            GFP_KERNEL);
    if (g_ivpci_devs == NULL) {
        goto unregister_chrdev;
    }

    minor = MINOR(g_ivpci_devno);
    for (i = 0; i < g_max_devices; i++) {
        g_ivpci_devs[i].minor = minor++;
    }

    g_ivpci_class = class_create(THIS_MODULE, DRV_NAME);
    if (g_ivpci_class == NULL) {
        pr_err(PFX "unable to create the struct class\n");
        goto free_devs;
    }

    g_ivpci_major = MAJOR(g_ivpci_devno);
    pr_info(PFX "major: %d, minor: %d\n", g_ivpci_major, MINOR(g_ivpci_devno));

    ret = pci_register_driver(&ivpci_driver);
    if (ret < 0) {
        pr_err(PFX "unable to register driver: %d\n", ret);
        goto destroy_class;
    }

    pr_info(PFX "module loaded\n");
    return 0;

destroy_class:
    class_destroy(g_ivpci_class);

free_devs:
    kfree(g_ivpci_devs);

unregister_chrdev:
    unregister_chrdev_region(g_ivpci_devno, g_max_devices);

out:
    return -1;
}

static void __exit ivpci_exit(void)
{
    pci_unregister_driver(&ivpci_driver);

    class_destroy(g_ivpci_class);

    kfree(g_ivpci_devs);

    unregister_chrdev_region(g_ivpci_devno, g_max_devices);

    pr_info(PFX "module unloaded\n");
    pr_info(PFX "*********************************************************\n");
}

/************************************************
 * Just for eliminating the compiling warnings.
 ************************************************/
#define my_module_init(initfn)					\
	static inline initcall_t __inittest(void)		\
	{ return initfn; }					\
	int init_module(void) __cold __attribute__((alias(#initfn)));

#define my_module_exit(exitfn)					\
	static inline exitcall_t __exittest(void)		\
	{ return exitfn; }					\
	void cleanup_module(void) __cold __attribute__((alias(#exitfn)));

my_module_init(ivpci_init);
my_module_exit(ivpci_exit);

MODULE_AUTHOR("haiwei-li@outlook.com");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Demo PCI driver for ivshmem device");
MODULE_VERSION(DRV_VERSION);

