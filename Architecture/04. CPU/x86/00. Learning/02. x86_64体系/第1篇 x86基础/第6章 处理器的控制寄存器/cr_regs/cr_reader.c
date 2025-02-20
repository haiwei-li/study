#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haiwei Li");
MODULE_DESCRIPTION("A module to read CR registers");
MODULE_VERSION("0.01");

static int __init cr_reader_init(void) {
    unsigned long cr0, cr2, cr3, cr4;

    // Read CR0
    asm ("mov %%cr0, %0" : "=r" (cr0));
    // Read CR2
    asm ("mov %%cr2, %0" : "=r" (cr2));
    // Read CR3
    asm ("mov %%cr3, %0" : "=r" (cr3));
    // Read CR4
    asm ("mov %%cr4, %0" : "=r" (cr4));

    printk(KERN_INFO "CR0: 0x%lx, CR2: 0x%lx, CR3: 0x%lx, CR4: 0x%lx\n", cr0, cr2, cr3, cr4);

    return 0; // Non-zero return means that the module couldn't be loaded.
}

static void __exit cr_reader_exit(void) {
    printk(KERN_INFO "Exiting CR Reader Module\n");
}

module_init(cr_reader_init);
module_exit(cr_reader_exit);
