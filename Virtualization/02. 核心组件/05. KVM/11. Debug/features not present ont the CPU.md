
This kernel requires the following features not present on the CPU:
la57

1. 查看 la57 对应的 feature

LA57    ⟷ 5-level page tables

arch/x86/include/asm/cpufeatures.h


2. 查找 cpu flag

3. 在 qemu 命令行减去这个 feature