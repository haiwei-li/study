/*
 * Performance test for IPI on SMP machines.
 *
 * Copyright (c) 2017 Cavium Networks.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of version 2 of the GNU General Public
 * License as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 */

#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/ktime.h>

#define NTIMES 100000

#define POKE_ANY	0
#define DRY_RUN		1
#define POKE_SELF	2
#define POKE_ALL	3
#define POKE_ALL_LOCK	4

static void __init handle_ipi_spinlock(void *t)
{
	spinlock_t *lock = (spinlock_t *) t;

	spin_lock(lock);
	spin_unlock(lock);
}

static void __init handle_ipi(void *t)
{
	ktime_t *time = (ktime_t *) t;

	if (time)
		*time = ktime_get() - *time;
}

static ktime_t __init send_ipi(int flags)
{
	ktime_t time = 0;
	DEFINE_SPINLOCK(lock);
	unsigned int cpu = get_cpu();

	switch (flags) {
	case DRY_RUN:
		/* Do everything except actually sending IPI. */
		break;
	case POKE_ALL:
		/* If broadcasting, don't force all CPUs to update time. */
		/*
 		 * 通过smp_call_function_many机制, 向其它核发送ipi, 使其执行指定的函数(handle_ipi), 
 		 * 最后一个入参表示是否wait, 此处传入1, 表示需要阻塞等待
 		 * 所有核都执行完成后才继续后面的流程. 
 		*/
		smp_call_function_many(cpu_online_mask, handle_ipi, NULL, 1);
		break;
	case POKE_ALL_LOCK:
		smp_call_function_many(cpu_online_mask,
				handle_ipi_spinlock, &lock, 1);
		break;
	case POKE_ANY:
		cpu = cpumask_any_but(cpu_online_mask, cpu);
		if (cpu >= nr_cpu_ids) {
			time = -ENOENT;
			break;
		}
		/* Fall thru */
	case POKE_SELF:
		time = ktime_get();
		smp_call_function_single(cpu, handle_ipi, &time, 1);
		break;
	default:
		time = -EINVAL;
	}

	put_cpu();
	return time;
}

static int __init __bench_ipi(unsigned long i, ktime_t *time, int flags)
{
	ktime_t t;

	*time = 0;
	while (i--) {
		t = send_ipi(flags);
		if ((int) t < 0)
			return (int) t;

		*time += t;
	}

	return 0;
}

static int __init bench_ipi(unsigned long times, int flags,
				ktime_t *ipi, ktime_t *total)
{
	int ret;

	*total = ktime_get();
	ret = __bench_ipi(times, ipi, flags);
	if (unlikely(ret))
		return ret;

	*total = ktime_get() - *total;

	return 0;
}

static int __init init_bench_ipi(void)
{
	ktime_t ipi, total;
	int ret;

	ret = bench_ipi(NTIMES, POKE_SELF, &ipi, &total);
	if (ret)
		pr_err("Self-IPI FAILED: %d\n", ret);
	else
		pr_err("Self-IPI:       %18llu, %18llu ns\n", ipi, total);

	/* Return error to avoid annoying rmmod. */
	return -EINVAL;
}
module_init(init_bench_ipi);

MODULE_LICENSE("GPL");