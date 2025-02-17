
amd:

```
 144)               |  vcpu_enter_guest [kvm]() {
 144)   0.080 us    |    svm_prepare_guest_switch [kvm_amd]();
 144)   0.091 us    |    __srcu_read_unlock();
 144)   0.090 us    |    kvm_vcpu_exit_request [kvm]();
 144)               |    rcu_note_context_switch() {
 144)   0.080 us    |      rcu_qs();
 144)   0.241 us    |    }
 144)   0.080 us    |    fpregs_assert_state_consistent();
 144)               |    svm_vcpu_run [kvm_amd]() {
 144)               |      kvm_get_cr8 [kvm]() {
 144)   0.080 us    |        kvm_lapic_get_cr8 [kvm]();
 144)   0.231 us    |      }
 144)   0.080 us    |      kvm_load_guest_xsave_state [kvm]();
 144)   0.080 us    |      kvm_wait_lapic_expire [kvm]();
 144)   0.141 us    |      x86_virt_spec_ctrl();
 144)   0.110 us    |      get_cpu_entry_area();
 144)   0.100 us    |      get_cpu_entry_area();
 144)   0.160 us    |      x86_virt_spec_ctrl();
 144)   0.080 us    |      kvm_load_host_xsave_state [kvm]();
 144)               |      kvm_set_cr8 [kvm]() {
 144)               |        kvm_set_cr8.part.119 [kvm]() {
 144)               |          kvm_lapic_set_tpr [kvm]() {
 144)               |            apic_update_ppr [kvm]() {
 144)   0.080 us    |              __apic_update_ppr [kvm]();
 144)   0.240 us    |            }
 144)   0.401 us    |          }
 144)   0.561 us    |        }
 144)   0.722 us    |      }
 144)   3.206 us    |    }
 144)   0.090 us    |    svm_handle_exit_irqoff [kvm_amd]();
 144)   0.091 us    |    __srcu_read_lock();
 144)               |    handle_exit [kvm_amd]() {
 144)   0.090 us    |      svm_complete_interrupts [kvm_amd]();
 144)               |      io_interception [kvm_amd]() {
 144)               |        kvm_fast_pio [kvm]() {
 144)               |          emulator_pio_out [kvm]() {
 144)               |            kernel_pio [kvm]() {
 144)               |              kvm_io_bus_write [kvm]() {
 144)               |                __kvm_io_bus_write [kvm]() {
 144)               |                  kvm_io_bus_get_first_dev [kvm]() {
 144)   0.081 us    |                    kvm_io_bus_sort_cmp [kvm]();
 144)   0.080 us    |                    kvm_io_bus_sort_cmp [kvm]();
 144)   0.090 us    |                    kvm_io_bus_sort_cmp [kvm]();
 144)   0.581 us    |                  }
 144)               |                  ioeventfd_write [kvm]() {
 144)               |                    eventfd_signal() {
 144)   0.080 us    |                      _raw_spin_lock_irqsave();
 144)   0.080 us    |                      _raw_spin_unlock_irqrestore();
 144)   0.420 us    |                    }
 144)   0.591 us    |                  }
 144)   1.413 us    |                }
 144)   1.583 us    |              }
 144)   1.753 us    |            }
 144)   1.923 us    |          }
 144)               |          kvm_skip_emulated_instruction [kvm]() {
 144)   0.080 us    |            svm_get_rflags [kvm_amd]();
 144)   0.080 us    |            skip_emulated_instruction [kvm_amd]();
 144)   0.421 us    |          }
 144)   2.594 us    |        }
 144)   2.735 us    |      }
 144)   3.116 us    |    }
 144)   7.915 us    |  }
 144)               |  vcpu_enter_guest [kvm]() {
 144)   0.080 us    |    svm_prepare_guest_switch [kvm_amd]();
 144)   0.090 us    |    __srcu_read_unlock();
 144)   0.090 us    |    kvm_vcpu_exit_request [kvm]();
 144)               |    rcu_note_context_switch() {
 144)   0.080 us    |      rcu_qs();
 144)   0.241 us    |    }
 144)   0.080 us    |    fpregs_assert_state_consistent();
 144)               |    svm_vcpu_run [kvm_amd]() {
 144)               |      kvm_get_cr8 [kvm]() {
 144)   0.081 us    |        kvm_lapic_get_cr8 [kvm]();
 144)   0.241 us    |      }
 144)   0.080 us    |      kvm_load_guest_xsave_state [kvm]();
 144)   0.080 us    |      kvm_wait_lapic_expire [kvm]();
 144)   0.130 us    |      x86_virt_spec_ctrl();
 144)   0.110 us    |      get_cpu_entry_area();
 144)   0.101 us    |      get_cpu_entry_area();
 144)   0.160 us    |      x86_virt_spec_ctrl();
 144)   0.080 us    |      kvm_load_host_xsave_state [kvm]();
 144)               |      kvm_set_cr8 [kvm]() {
 144)               |        kvm_set_cr8.part.119 [kvm]() {
 144)               |          kvm_lapic_set_tpr [kvm]() {
 144)               |            apic_update_ppr [kvm]() {
 144)   0.090 us    |              __apic_update_ppr [kvm]();
 144)   0.250 us    |            }
 144)   0.401 us    |          }
 144)   0.571 us    |        }
 144)   0.731 us    |      }
 144)   3.206 us    |    }
 144)   0.090 us    |    svm_handle_exit_irqoff [kvm_amd]();
 144)   0.090 us    |    __srcu_read_lock();
 144)               |    handle_exit [kvm_amd]() {
```

intel:

```
 49)               |  vcpu_enter_guest [kvm]() {
 49)   0.107 us    |    vmx_prepare_switch_to_guest [kvm_intel]();
 49)               |    vmx_sync_pir_to_irr [kvm_intel]() {
 49)   0.111 us    |      kvm_lapic_find_highest_irr [kvm]();
 49)   0.103 us    |      vmx_set_rvi [kvm_intel]();
 49)   0.551 us    |    }
 49)   0.106 us    |    kvm_vcpu_exit_request [kvm]();
 49)               |    vmx_vcpu_run [kvm_intel]() {
 49)   0.106 us    |      kvm_load_guest_xsave_state [kvm]();
 49)               |      clear_atomic_switch_msr [kvm_intel]() {
 49)   0.107 us    |        clear_atomic_switch_msr_special [kvm_intel]();
 49)   0.308 us    |      }
 49)   0.105 us    |      clear_atomic_switch_msr [kvm_intel]();
 49)   0.105 us    |      kvm_wait_lapic_expire [kvm]();
 49)   0.111 us    |      vmx_update_host_rsp [kvm_intel]();
 49)   0.111 us    |      kvm_load_host_xsave_state [kvm]();
 49)   0.112 us    |      __vmx_complete_interrupts [kvm_intel]();
 49)   2.200 us    |    }
 49)   0.110 us    |    vmx_handle_exit_irqoff [kvm_intel]();
 49)               |    vmx_handle_exit [kvm_intel]() {
 49)               |      handle_io [kvm_intel]() {
 49)               |        kvm_fast_pio [kvm]() {
 49)               |          emulator_pio_out [kvm]() {
 49)               |            kernel_pio [kvm]() {
 49)               |              kvm_io_bus_write [kvm]() {
 49)               |                __kvm_io_bus_write [kvm]() {
 49)               |                  kvm_io_bus_get_first_dev [kvm]() {
 49)   0.134 us    |                    kvm_io_bus_sort_cmp [kvm]();
 49)   0.108 us    |                    kvm_io_bus_sort_cmp [kvm]();
 49)   0.103 us    |                    kvm_io_bus_sort_cmp [kvm]();
 49)   0.770 us    |                  }
 49)   0.126 us    |                  ioeventfd_write [kvm]();
 49)   1.240 us    |                }
 49)   1.449 us    |              }
 49)   1.659 us    |            }
 49)   1.881 us    |          }
 49)               |          kvm_skip_emulated_instruction [kvm]() {
 49)   0.108 us    |            vmx_get_rflags [kvm_intel]();
 49)               |            vmx_skip_emulated_instruction [kvm_intel]() {
 49)               |              skip_emulated_instruction [kvm_intel]() {
 49)   0.105 us    |                vmx_cache_reg [kvm_intel]();
 49)   0.106 us    |                vmx_set_interrupt_shadow [kvm_intel]();
 49)   0.599 us    |              }
 49)   0.796 us    |            }
 49)   1.204 us    |          }
 49)   3.401 us    |        }
 49)   3.599 us    |      }
 49)   3.816 us    |    }
 49)   7.717 us    |  }
 49)               |  vcpu_enter_guest [kvm]() {
 49)   0.106 us    |    vmx_prepare_switch_to_guest [kvm_intel]();
 49)               |    vmx_sync_pir_to_irr [kvm_intel]() {
 49)   0.110 us    |      kvm_lapic_find_highest_irr [kvm]();
 49)   0.106 us    |      vmx_set_rvi [kvm_intel]();
 49)   0.530 us    |    }
 49)   0.103 us    |    kvm_vcpu_exit_request [kvm]();
 49)               |    vmx_vcpu_run [kvm_intel]() {
 49)   0.105 us    |      kvm_load_guest_xsave_state [kvm]();
 49)               |      clear_atomic_switch_msr [kvm_intel]() {
 49)   0.125 us    |        clear_atomic_switch_msr_special [kvm_intel]();
 49)   0.323 us    |      }
 49)   0.109 us    |      clear_atomic_switch_msr [kvm_intel]();
 49)   0.104 us    |      kvm_wait_lapic_expire [kvm]();
 49)   0.108 us    |      vmx_update_host_rsp [kvm_intel]();
 49)   0.112 us    |      kvm_load_host_xsave_state [kvm]();
 49)   0.112 us    |      __vmx_complete_interrupts [kvm_intel]();
 49)   2.216 us    |    }
 49)   0.109 us    |    vmx_handle_exit_irqoff [kvm_intel]();
 49)               |    vmx_handle_exit [kvm_intel]() {
```