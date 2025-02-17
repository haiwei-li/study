https://www.vpsman.net/18758.html

http://www.luo666.com/?p=55

https://patchwork.kernel.org/project/kvm/patch/1408637291-18533-5-git-send-email-rkrcmar@redhat.com/

```cpp
static inline bool kvm_pause_in_guest(struct kvm *kvm)
{
    return kvm->arch.pause_in_guest;
}
```


可以试下 pause 透传和不透传两种情况下的性能

通过修改 `arch/x86/kvm/x86.h`, 不要改启动参数
* hlt/pause/mwait 全部return false
* hlt/mwait return false, pause return true

```diff
diff --git a/arch/x86/kvm/x86.h b/arch/x86/kvm/x86.h
index 0f727b50bd3d..858f918ccef2 100644
--- a/arch/x86/kvm/x86.h
+++ b/arch/x86/kvm/x86.h
@@ -318,17 +318,20 @@ static inline u64 nsec_to_cycles(struct kvm_vcpu *vcpu, u64 nsec)

 static inline bool kvm_mwait_in_guest(struct kvm *kvm)
 {
-       return kvm->arch.mwait_in_guest;
+       return false;
+       //return kvm->arch.mwait_in_guest;
 }

 static inline bool kvm_hlt_in_guest(struct kvm *kvm)
 {
-       return kvm->arch.hlt_in_guest;
+       return false;
+       //return kvm->arch.hlt_in_guest;
 }

 static inline bool kvm_pause_in_guest(struct kvm *kvm)
 {
-       return kvm->arch.pause_in_guest;
+       return false;
+       //return kvm->arch.pause_in_guest;
 }

 static inline bool kvm_cstate_in_guest(struct kvm *kvm)
```
