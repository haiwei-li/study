guest中

```
[root@lihaiwei-vm tracing]# cat set_graph_function
kvm_vcpu_yield_to [kvm]
kvm_emulate_hypercall [kvm]
kvm_sched_yield [kvm]
smp_call_function_many_cond

[root@lihaiwei-vm tracing]# cat current_tracer
function_graph

[root@lihaiwei-vm tracing]# head -150 trace
# tracer: function_graph
#
# CPU  DURATION                  FUNCTION CALLS
# |     |   |                     |   |   |   |
 15)   3.036 us    |  smp_call_function_many_cond();
 15)               |  smp_call_function_many_cond() {
 15)   0.318 us    |    tlb_is_not_lazy();
 15)   1.421 us    |  }
  0) + 14.536 us   |                  } /* task_tick_fair */
  0)   0.181 us    |                  calc_global_load_tick();
  0)               |                  trigger_load_balance() {
  0)   0.307 us    |                    nohz_balance_exit_idle();
  0)   0.781 us    |                  }
  0) + 17.853 us   |                } /* scheduler_tick */
  0)   0.178 us    |                run_posix_cpu_timers();
  0) + 23.317 us   |              } /* update_process_times */
  0)   0.178 us    |              profile_tick();
  0) + 24.007 us   |            } /* tick_sched_handle */
  0)   0.261 us    |            hrtimer_forward();
  0) + 33.337 us   |          } /* tick_sched_timer */
  0)   0.178 us    |          _raw_spin_lock_irq();
  0)   0.207 us    |          enqueue_hrtimer();
  0) + 35.239 us   |        } /* __hrtimer_run_queues */
  0)               |        __hrtimer_get_next_event() {
  0)   0.170 us    |          __hrtimer_next_event_base();
  0)   0.191 us    |          __hrtimer_next_event_base();
  0)   0.880 us    |        }
  0)   0.218 us    |        _raw_spin_unlock_irqrestore();
  0)               |        tick_program_event() {
  0)               |          clockevents_program_event() {
  0)   0.223 us    |            ktime_get();
  0)   1.357 us    |            lapic_next_deadline();
  0)   2.172 us    |          }
  0)   2.571 us    |        }
  0) + 40.698 us   |      } /* hrtimer_interrupt */
  0)               |      irq_exit() {
  0)   0.202 us    |        ksoftirqd_running();
  0)               |        __do_softirq() {
  0)               |          run_timer_softirq() {
  0)   0.183 us    |            _raw_spin_lock_irq();
  0)   0.180 us    |            _raw_spin_lock_irq();
  0)   0.954 us    |          }
  0)   0.176 us    |          __local_bh_enable();
  0)   1.792 us    |        }
  0)   0.208 us    |        idle_cpu();
  0)               |        rcu_irq_exit() {
  0)   0.182 us    |          rcu_dynticks_curr_cpu_in_eqs();
  0)   0.539 us    |        }
  0)   3.610 us    |      }
  0) + 46.228 us   |    } /* smp_apic_timer_interrupt */
  0)   <========== |
  0) + 57.636 us   |  } /* smp_call_function_many_cond */
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.860 us    |          __x2apic_send_IPI_shorthand();
  0)   4.262 us    |        }
  0)   4.631 us    |      }
  0)   5.247 us    |    }
  0) + 11.055 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.965 us    |          __x2apic_send_IPI_shorthand();
  0)   4.329 us    |        }
  0)   4.699 us    |      }
  0)   5.282 us    |    }
  0)   9.847 us    |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.982 us    |          __x2apic_send_IPI_shorthand();
  0)   4.342 us    |        }
  0)   4.710 us    |      }
  0)   5.292 us    |    }
  0)   9.654 us    |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.547 us    |          __x2apic_send_IPI_shorthand();
  0)   3.899 us    |        }
  0)   4.318 us    |      }
  0)   4.873 us    |    }
  0)   8.774 us    |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.463 us    |          __x2apic_send_IPI_shorthand();
  0)   3.824 us    |        }
  0)   4.242 us    |      }
  0)   4.808 us    |    }
  0) + 10.695 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   4.047 us    |          __x2apic_send_IPI_shorthand();
  0)   4.400 us    |        }
  0)   4.776 us    |      }
  0)   5.349 us    |    }
  0) + 10.166 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.530 us    |          __x2apic_send_IPI_shorthand();
  0)   3.885 us    |        }
  0)   4.253 us    |      }
  0)   4.934 us    |    }
  0) + 10.237 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   3.885 us    |          __x2apic_send_IPI_shorthand();
  0)   4.243 us    |        }
  0)   4.610 us    |      }
  0)   5.182 us    |    }
  0) + 10.258 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   4.009 us    |          __x2apic_send_IPI_shorthand();
  0)   4.364 us    |        }
  0)   4.736 us    |      }
  0)   5.307 us    |    }
  0) + 10.284 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   4.431 us    |          __x2apic_send_IPI_shorthand();
  0)   4.799 us    |        }
  0)   5.172 us    |      }
  0)   5.733 us    |    }
  0) + 10.809 us   |  }
  0)               |  smp_call_function_many_cond() {
  0)               |    kvm_smp_send_call_func_ipi() {
  0)               |      native_send_call_func_ipi() {
  0)               |        x2apic_send_IPI_allbutself() {
  0)   4.036 us    |          __x2apic_send_IPI_shorthand();
  0)   4.390 us    |        }
  0)   4.759 us    |      }
  0)   5.359 us    |    }
```


host:

```
[root@TENCENT64 /sys/kernel/debug/tracing]# cat set_graph_function
kvm_sched_yield [kvm]
kvm_vcpu_yield_to [kvm]
kvm_emulate_hypercall [kvm]


```