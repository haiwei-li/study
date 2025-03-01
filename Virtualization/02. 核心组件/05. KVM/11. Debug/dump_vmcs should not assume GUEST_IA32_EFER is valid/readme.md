


v1: https://patchwork.kernel.org/project/kvm/patch/20210218100450.2157308-1-david.edmondson@oracle.com/

David Edmondson: dump VMCS 时, 如果未设置`VM_EXIT_SAVE_IA32_EFER` 或`VM_ENTRY_LOAD_IA32_EFER`都未设置, 则从`kvm_vcpu`结构中检索当前 guest 的 EFER 值. 如果处理器不支持相关的 VM-entry/exit control, 则可能会发生这种情况.

paolo: 打印`kvm_vcpu`中的值不可取, 可否打印整个 MSR load/store area

David: 可以打印, 但是解决不了最初的问题: 如果虚拟机设置了 `EFER_LMA`, 但是 host 没有使用 entry/exit control

If the guest has EFER_LMA set but we aren't using the entry/exit
controls, vm_read64(GUEST_IA32_EFER) returns 0, causing dump_vmcs() to
erroneously dump the PDPTRs.


v2: https://patchwork.kernel.org/project/kvm/cover/20210219144632.2288189-1-david.edmondson@oracle.com/

