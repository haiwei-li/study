

```
/*
 * May add pads for 16B alignment.
 * EPT table pointer can be got from MSRs
 */
struct pcm_cpu_states {                      
    struct pcm_cpu_user_regs uregs;
    struct pcm_cpu_non_reg_states nregs;
    struct pcm_cpu_seg_regs sregs;
    struct pcm_cpu_cr_regs  crs;
    struct pcm_cpu_dr_regs  drs;
    struct pcm_cpu_msrs msrs;
    struct pcm_fpu_states fpu;
    pcm_addr apic;  /* 'struct pcm_lapic_regs   *' */
    pcm_addr pmu;   // 'struct pcm_cpu_pmu_regs *'
    /*  
     * Fixed information of the platform, such as the CPU model, CPUID leaves etc.
     * TODO for details
     */
    pcm_addr platform_info; // 'void   *'
    uint64_t eptp;
};
```

从PCM和RCP重放产生的cpu file获取sizeof(struct pcm_cpu_states)个字节

```
fread(&rcp_cpu_info, 1, sizeof(struct pcm_cpu_states), fp_rcp);                    

fread(&pcm_cpu_info, 1, sizeof(struct pcm_cpu_states), fp_pcm);
```

对比寄存器数值

```
err += compare_cpu_state_user_reg   (&rcp_cpu_info, &pcm_cpu_info, NULL);
err += compare_cpu_state_none_reg   (&rcp_cpu_info, &pcm_cpu_info);
err += compare_cpu_state_seg_reg    (&rcp_cpu_info, &pcm_cpu_info);
err += compare_cpu_state_cr_reg     (&rcp_cpu_info, &pcm_cpu_info);
err += compare_cpu_state_dr_reg     (&rcp_cpu_info, &pcm_cpu_info);

err += compare_cpu_state_flag_reg   (&rcp_cpu_info, &pcm_cpu_info, NULL);
err += compare_cpu_state_msrs_reg   (&rcp_cpu_info, &pcm_cpu_info);
err += compare_cpu_state_fpu_reg    (&rcp_cpu_info, &pcm_cpu_info);
```