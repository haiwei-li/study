import org.ualberta.shm.MemAccess;

public class FTPPrep extends FTP {
    public FTPPrep(String devname, long msize, int nblocks, int nchunks) throws Exception {
        super(devname, msize, nblocks, nchunks);

        for(int i = 1; i <= NBLOCKS; i++) {
            mem.initLock(SYNC(i) + SLOCK);
            mem.initLock(BASE(i - 1) + LOCK);
        }
    }
    
    public static void main(String args[]) throws Exception {
        int msize = Integer.parseInt(args[1]);
        int nblocks = Integer.parseInt(args[2]);
        int nchunks = Integer.parseInt(args[3]);

        FTPPrep p = new FTPPrep(args[0], msize, nblocks, nchunks);
    }
}
