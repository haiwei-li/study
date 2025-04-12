/* https://blog.csdn.net/fuyuande/article/details/82193600 */
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/hrtimer.h>
#include <linux/jiffies.h>
 
static struct hrtimer timer;
ktime_t kt;
 
/* 定时器回调函数 */
static enum hrtimer_restart  hrtimer_hander(struct hrtimer *timer)
{
    printk("hrtimer up\r\n");
 
    /* 设置下次过期时间 */
    kt = ktime_set(3,0);    
    hrtimer_forward_now(timer, kt);
 
    /* 该参数将重新启动定时器 */    
    return HRTIMER_RESTART;  
}
 
static int __init hrtimer_demo_init(void)
{
    printk("hello hrtimer \r\n");
 
    kt = ktime_set(1,10);
 
    /* hrtimer初始化 */
    hrtimer_init(&timer,CLOCK_MONOTONIC,HRTIMER_MODE_REL);
 
    /* hrtimer启动 */
    hrtimer_start(&timer,kt,HRTIMER_MODE_REL);
 
    /* 设置回调函数 */
    timer.function = hrtimer_hander;
 
    return 0;
}
 
static void __exit hrtimer_demo_exit(void)
{
    /* hrtimer注销 */
    hrtimer_cancel(&timer);
    printk("bye hrtimer\r\n");
}
 
 
module_init(hrtimer_demo_init);
module_exit(hrtimer_demo_exit);
MODULE_LICENSE("GPL");