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
#include <linux/slab.h>
#include <linux/init.h>
#include <linux/ktime.h>

#define NTIMES 100000

#define POKE_ANY	0
#define DRY_RUN		1
#define POKE_SELF	2
#define POKE_ALL	3
#define POKE_ALL_LOCK	4
#define POKE_NUM        5

typedef struct ipitype {
	int type;
	char name[20];
}ipitype;

ipitype poke_any = {POKE_ANY, "Normal IPI"};
ipitype dry_run = {DRY_RUN, "Dry run"};
ipitype poke_self = {POKE_SELF, "Self IPI"};
ipitype poke_all = {POKE_ALL, "Broadcast IPI"};
ipitype poke_all_lock= {POKE_ALL_LOCK, "Broadcast lock"};

static int times = 10;
static int ipi_index[5] = {0,3};
static int n_para=5;
module_param(times, int, S_IRUSR);
module_param_array(ipi_index, int, &n_para, S_IRUSR);

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
	int i,j = 0;
	int i_case;
	char *name;
	char *result = kvalloc(times*12, GFP_KERNEL);
	unsigned long long sum;
	unsigned long long offset;
	unsigned long long max;
	unsigned long long min;
	unsigned long long sum_output;
	unsigned long long avg_output;
	ipitype benchmark[5] = {poke_any, dry_run, poke_self, poke_all, poke_all_lock};
	ipitype benchmark_tests[n_para];
	for (i=0; i < n_para; i++) {
		benchmark_tests[i] = benchmark[ipi_index[i]];
	}

	for (j=0; j<n_para; j++) {
		sum = 0;
		offset = 0;
		max=0;
		min=0;
		memset(result, 0, times*12);
		/* strcpy(result, ""); */
		name = benchmark_tests[j].name;
		i_case = benchmark_tests[j].type;
		for (i=0; i<times; i++) {
			ret = bench_ipi(NTIMES, i_case, &ipi, &total);
			if (ret) {
				pr_err("Type: %s, FAILED: %d\n", name, ret);
				break;
			}
			/* pr_err("tootal: %llu ", total); */
			max = max>total? max:total;
			if (min==0) {
				min = total;
			} else {
				min = min<total? min:total;
			}
			offset += sprintf(result+offset, "%llu+", total);
			/* pr_err("offset: %llu ", offset); */
			sum += total;
		}
		result[offset -1] = '\0';
		pr_err("Type: %s, result: %s\n",
		       name, result);
		pr_err("max: %llu, min: %llu\n",
		       max, min);
		sum_output = sum;
		avg_output = sum/times;
		if (times>2){
			sum_output = sum-max-min;
			avg_output = sum_output/(times - 2);
		}
		pr_err("Type: %s, times: %d, total: %llu, sum: %llu, avg: %llu\n\n",
		       name, times, sum, sum_output, avg_output);

	}
	kfree(result);

	/*
	ret = bench_ipi(NTIMES, DRY_RUN, &ipi, &total);
	if (ret)
		pr_err("Dry-run FAILED: %d\n", ret);
	else
		pr_err("Dry-run:        %18llu, %18llu ns\n", ipi, total);

	ret = bench_ipi(NTIMES, POKE_SELF, &ipi, &total);
	if (ret)
		pr_err("Self-IPI FAILED: %d\n", ret);
	else
		pr_err("Self-IPI:       %18llu, %18llu ns\n", ipi, total);

	ret = bench_ipi(NTIMES, POKE_ANY, &ipi, &total);
	if (ret)
		pr_err("Normal IPI FAILED: %d\n", ret);
	else
		pr_err("Normal IPI:     %18llu, %18llu ns\n", ipi, total);

	ret = bench_ipi(NTIMES, POKE_ALL, &ipi, &total);
	if (ret)
		pr_err("Broadcast IPI FAILED: %d\n", ret);
	else
		pr_err("Broadcast IPI:  %18llu, %18llu ns\n", ipi, total);

	ret = bench_ipi(NTIMES, POKE_ALL_LOCK, &ipi, &total);
	if (ret)
		pr_err("Broadcast lock FAILED: %d\n", ret);
	else
		pr_err("Broadcast lock: %18llu, %18llu ns\n", ipi, total);
	*/

	/* Return error to avoid annoying rmmod. */
	return -EINVAL;
}
module_init(init_bench_ipi);

MODULE_LICENSE("GPL");
