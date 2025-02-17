public class IrqTest {
    public static void main(String args[]) throws Exception {
        MemAccess mem = new MemAccess("/dev/kvm_ivshmem");

        if(Integer.parseInt(args[0]) == 0) {
            mem.waitEvent();
        } else {
            mem.waitEventIrq(Integer.parseInt(args[0]));
        }

        mem.closeDevice();
    }
}
