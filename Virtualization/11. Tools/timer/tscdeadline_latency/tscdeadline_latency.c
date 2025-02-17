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
#define pr_fmt(fmt) "%s: " fmt, __func__
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/ktime.h>
#include <linux/slab.h>
#include <linux/random.h>
#include <linux/hrtimer.h>

#define DELAY_TIME_100US 	(100000)
#define DELAY_TIME_200US 	(200000)
#define DELAY_TIME_500US 	(500000)
#define DELAY_TIME_1MS 		(1000000)
#define DELAY_TIME_5MS 		(5000000)

struct statistics_block {
	long count, last_timestamp;
	long min, max, sum;
	long of_100us, of_200us, of_500us, of_1ms, of_5ms;
	int done;
};

struct {
	struct hrtimer __percpu *period_hrtimer;
	struct statistics_block __percpu *statistics_block;
	struct work_struct work;
} timing_ctl_block;

struct work_struct __percpu *percpu_thread_work;

/* the max timing times of hrtimer */
static long max_times = 3600000;
/* the unit of the time is nanosecond */
static int timing_delta = 999000;

static void calculate_latency_work(struct work_struct *work)
{
	struct statistics_block *stb_data;
	int cpu;

	for_each_online_cpu(cpu) {
		stb_data = per_cpu_ptr(timing_ctl_block.statistics_block, cpu);
		pr_info("cpu%03d: timer latency: max=%12ld min=%8ld avg=%8ld of_100=%8ld of_200=%8ld of_500=%8ld of_1m=%8ld of_5m=%8ld count=%8ld\n",
			cpu, stb_data->max, stb_data->min,
			stb_data->sum / stb_data->count,
			stb_data->of_100us, stb_data->of_200us, 
			stb_data->of_500us, stb_data->of_1ms, 
			stb_data->of_5ms, stb_data->count);
	}
}

static enum hrtimer_restart period_timer_handler(struct hrtimer *timer)
{
	struct statistics_block *stb_data;
	long now, delta;
	int cpu;

	stb_data = this_cpu_ptr(timing_ctl_block.statistics_block);
	if (stb_data->count < max_times) {
		now = ktime_to_ns(ktime_get());
		delta = now - stb_data->last_timestamp - timing_delta;

		if (likely(stb_data->count != 0)) {
			if (stb_data->max < delta)
				stb_data->max = delta;

			if (stb_data->min > delta)
				stb_data->min = delta;
		} else {
			stb_data->min = stb_data->max = delta;
		}

		stb_data->last_timestamp = now;
		stb_data->sum += delta;
		stb_data->count++;

		if (delta > DELAY_TIME_100US) ++stb_data->of_100us;
		if (delta > DELAY_TIME_200US) ++stb_data->of_200us;
		if (delta > DELAY_TIME_500US) ++stb_data->of_500us;
		if (delta > DELAY_TIME_1MS) ++stb_data->of_1ms;
		if (delta > DELAY_TIME_5MS) ++stb_data->of_5ms;

		hrtimer_start(timer, ns_to_ktime(stb_data->last_timestamp + timing_delta),
			      HRTIMER_MODE_ABS_PINNED);

		return HRTIMER_NORESTART;
	}

	stb_data->done = 1;
for_each_online_cpu(cpu) {
		stb_data = per_cpu_ptr(timing_ctl_block.statistics_block, cpu);
		if (stb_data->done != 1) {
			goto out;
		}
	}

	schedule_work(&timing_ctl_block.work);
out:
	return HRTIMER_NORESTART;
}

static void start_timer_handler(struct work_struct *work)
{
	struct hrtimer *timer;
	struct statistics_block *stb_data;

	timer = this_cpu_ptr(timing_ctl_block.period_hrtimer);
	stb_data = this_cpu_ptr(timing_ctl_block.statistics_block);
	hrtimer_init(timer, CLOCK_MONOTONIC, HRTIMER_MODE_ABS_PINNED);
	timer->function = period_timer_handler;
	stb_data->last_timestamp = ktime_to_ns(ktime_get());
	hrtimer_start(timer, ns_to_ktime(stb_data->last_timestamp + timing_delta),
		      HRTIMER_MODE_ABS_PINNED);

	//pr_debug("start cpu%d timer sucessful!\n", smp_processor_id());
}

static int __init init_hrtimer_test(void)
{
	int cpu;

	timing_ctl_block.period_hrtimer = alloc_percpu(struct hrtimer);
	if (!timing_ctl_block.period_hrtimer)
		goto out;

	timing_ctl_block.statistics_block = alloc_percpu(struct statistics_block);
	if (!timing_ctl_block.statistics_block)
		goto err_statistics_block;

	percpu_thread_work = alloc_percpu(struct work_struct);
	if (!percpu_thread_work)
		goto err_alloc_work_struct;

	INIT_WORK(&timing_ctl_block.work, calculate_latency_work);

	for_each_online_cpu(cpu) {
		INIT_WORK(per_cpu_ptr(percpu_thread_work, cpu), start_timer_handler);
		queue_work_on(cpu, system_highpri_wq,
			      per_cpu_ptr(percpu_thread_work, cpu));
	}

	//pr_debug("period hrtimer test module probe sucessfule!\n");

	return 0;

err_alloc_work_struct:
	free_percpu(timing_ctl_block.statistics_block);
err_statistics_block:
	free_percpu(timing_ctl_block.period_hrtimer);
out:
	return -1;
}

static void exit_hrtimer_test(void)
{
	struct hrtimer *timer;
	int cpu;

	for_each_online_cpu(cpu) {
		timer = per_cpu_ptr(timing_ctl_block.period_hrtimer, cpu);
		hrtimer_cancel(timer);
	}

	cancel_work_sync(&timing_ctl_block.work);

	free_percpu(timing_ctl_block.period_hrtimer);
	free_percpu(timing_ctl_block.statistics_block);
	free_percpu(percpu_thread_work);

	//pr_debug("remove module sucessfule!\n");
}

module_init(init_hrtimer_test);
module_exit(exit_hrtimer_test);

MODULE_LICENSE("GPL");
