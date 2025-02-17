
intel:

```
  4)               |  handle_ept_misconfig [kvm_intel]() {
  4)               |    kvm_io_bus_write [kvm]() {
  4)               |      __kvm_io_bus_write [kvm]() {
  4)               |        kvm_io_bus_get_first_dev [kvm]() {
  4)   0.269 us    |          kvm_io_bus_sort_cmp [kvm]();
  4)   1.134 us    |        }
  4)               |        ioeventfd_write [kvm]() {
  4)               |          eventfd_signal() {
  4)   0.322 us    |            _raw_spin_lock_irqsave();
  4)               |            __wake_up_locked_key() {
  4)               |              __wake_up_common() {
  4)               |                pollwake() {
  4)               |                  default_wake_function() {
  4)               |                    try_to_wake_up() {
  4)   0.276 us    |                      _raw_spin_lock_irqsave();
  4)               |                      select_task_rq_fair() {
  4)   0.340 us    |                        available_idle_cpu();
  4)   0.667 us    |                      }
  4)               |                      ttwu_queue_wakelist() {
  4)               |                        __smp_call_single_queue() {
  4)   0.538 us    |                          send_call_function_single_ipi();
  4)   0.927 us    |                        }
  4)   1.274 us    |                      }
  4)   0.111 us    |                      _raw_spin_unlock_irqrestore();
  4)   3.466 us    |                    }
  4)   3.876 us    |                  }
  4)   4.087 us    |                }
  4)   4.885 us    |              }
  4)   5.155 us    |            }
  4)   0.283 us    |            _raw_spin_unlock_irqrestore();
  4)   6.175 us    |          }
  4)   6.528 us    |        }
  4)   8.876 us    |      }
  4)   9.626 us    |    }
  4)               |    kvm_skip_emulated_instruction [kvm]() {
  4)   0.126 us    |      vmx_get_rflags [kvm_intel]();
  4)               |      vmx_skip_emulated_instruction [kvm_intel]() {
  4)               |        skip_emulated_instruction [kvm_intel]() {
  4)   0.107 us    |          vmx_cache_reg [kvm_intel]();
  4)   0.105 us    |          vmx_set_interrupt_shadow [kvm_intel]();
  4)   0.583 us    |        }
  4)   0.782 us    |      }
  4)   1.396 us    |    }
  4) + 12.841 us   |  }
```

amd:

```
 178)               |  npf_interception [kvm_amd]() {
 178)               |    kvm_mmu_page_fault [kvm]() {
 178)   0.351 us    |      mmio_info_in_cache [kvm]();
 178)               |      x86_emulate_instruction [kvm]() {
 178)               |        init_emulate_ctxt [kvm]() {
 178)               |          kvm_get_cs_db_l_bits [kvm]() {
 178)               |            svm_get_segment [kvm_amd]() {
 178)   0.301 us    |              svm_seg [kvm_amd]();
 178)   0.782 us    |            }
 178)   1.202 us    |          }
 178)   0.091 us    |          svm_get_rflags [kvm_amd]();
 178)   0.091 us    |          init_decode_cache [kvm]();
 178)   2.515 us    |        }
 178)               |        x86_decode_insn [kvm]() {
 178)   0.100 us    |          emulator_read_gpr [kvm]();
 178)               |          decode_operand [kvm]() {
 178)               |            decode_register [kvm]() {
 178)   0.080 us    |              emulator_read_gpr [kvm]();
 178)   0.260 us    |            }
 178)   0.090 us    |            fetch_register_operand [kvm]();
 178)   1.122 us    |          }
 178)   0.101 us    |          decode_operand [kvm]();
 178)   0.110 us    |          decode_operand [kvm]();
 178)   3.626 us    |        }
 178)               |        x86_emulate_insn [kvm]() {
 178)   0.090 us    |          emulator_get_hflags [kvm]();
 178)   0.090 us    |          em_mov [kvm]();
 178)               |          writeback [kvm]() {
 178)               |            segmented_write [kvm]() {
 178)               |              linearize [kvm]() {
 178)   0.180 us    |                emulator_get_cr [kvm]();
 178)   0.841 us    |              }
 178)               |              emulator_write_emulated [kvm]() {
 178)               |                emulator_read_write.isra.137 [kvm]() {
 178)               |                  emulator_read_write_onepage [kvm]() {
 178)   0.200 us    |                    emulator_can_use_gpa [kvm]();
 178)   0.100 us    |                    vcpu_is_mmio_gpa [kvm]();
 178)               |                    write_mmio [kvm]() {
 178)   0.190 us    |                      apic_mmio_write [kvm]();
 178)               |                      kvm_io_bus_write [kvm]() {
 178)               |                        __kvm_io_bus_write [kvm]() {
 178)               |                          kvm_io_bus_get_first_dev [kvm]() {
 178)   0.341 us    |                            kvm_io_bus_sort_cmp [kvm]();
 178)   1.012 us    |                          }
 178)               |                          ioeventfd_write [kvm]() {
 178)               |                            eventfd_signal() {
 178)   0.191 us    |                              _raw_spin_lock_irqsave();
 178)               |                              __wake_up_locked_key() {
 178)               |                                __wake_up_common() {
 178)               |                                  pollwake() {
 178)               |                                    default_wake_function() {
 178)               |                                      try_to_wake_up() {
 178)   0.200 us    |                                        _raw_spin_lock_irqsave();
 178)               |                                        select_task_rq_fair() {
 178)   0.411 us    |                                          available_idle_cpu();
 178)   0.771 us    |                                        }
 178)               |                                        ttwu_queue_wakelist() {
 178)               |                                          __smp_call_single_queue() {
 178)               |                                            send_call_function_single_ipi() {
 178)               |                                              native_send_call_func_single_ipi() {
 178)               |                                                default_send_IPI_single_phys() {
 178)   0.300 us    |                                                  __default_send_IPI_dest_field();
 178)   0.761 us    |                                                }
 178)   1.162 us    |                                              }
 178)   1.603 us    |                                            }
 178)   2.384 us    |                                          }
 178)   2.796 us    |                                        }
 178)   0.080 us    |                                        _raw_spin_unlock_irqrestore();
 178)   5.069 us    |                                      }
 178)   5.520 us    |                                    }
 178)   5.820 us    |                                  }
 178)   6.823 us    |                                }
 178)   7.204 us    |                              }
 178)   0.090 us    |                              _raw_spin_unlock_irqrestore();
 178)   8.165 us    |                            }
 178)   8.586 us    |                          }
 178) + 10.731 us   |                        }
 178) + 11.141 us   |                      }
 178) + 11.912 us   |                    }
 178) + 13.074 us   |                  }
 178) + 13.605 us   |                }
 178) + 14.136 us   |              }
 178) + 15.469 us   |            }
 178) + 15.810 us   |          }
 178)               |          writeback_registers [kvm]() {
 178)   0.090 us    |            emulator_write_gpr [kvm]();
 178)   0.341 us    |          }
 178) + 17.412 us   |        }
 178)   0.090 us    |        svm_get_rflags [kvm_amd]();
 178)   0.180 us    |        svm_get_interrupt_shadow [kvm_amd]();
 178)               |        __kvm_set_rflags [kvm]() {
 178)   0.090 us    |          svm_set_rflags [kvm_amd]();
 178)   0.291 us    |        }
 178) + 25.939 us   |      }
 178) + 27.070 us   |    }
 178) + 29.475 us   |  }
```