import java.io.FileOutputStream;
import java.io.File;

import org.ualberta.shm.MemAccess;

public class FTPRecv extends FTP {
    public static void main(String args[]) throws Exception {
        String devname = args[0];
        int msize = Integer.parseInt(args[1]);
        int nblocks = Integer.parseInt(args[2]);
        int nchunks = Integer.parseInt(args[3]);
        String recvfile = args[4];
        int sender = Integer.parseInt(args[5]);

        FTPRecv r = new FTPRecv(devname, msize, nblocks, nchunks, recvfile, sender);
    }

    public FTPRecv(String devname, int msize, int nblocks, int nchunks, String recvfile, int sender) throws Exception {
        super(devname, msize, nblocks, nchunks);

        int block;
        int me;
        int full, empty;
        byte bytes[] = new byte[CHUNK_SZ];
        int idx;
        long total, recvd;

        //System.out.println("[RECV] Opening device " + devname);
        FileOutputStream file = new FileOutputStream((new File(recvfile)).getName());

        /* Indicate our interest */
        me = mem.getPosition();
        //System.out.println("[RECV] I am VM number " + String.valueOf(me) + " receiving from VM number " + String.valueOf(sender));
        while(mem.spinLock(SYNC(sender) + SLOCK) != 0);
        mem.writeInt(me, SYNC(sender) + CLIENT);
        mem.waitEventIrq(sender);
        //System.out.println("[RECV] Waiting for the server to write a block number.");
        mem.waitEvent();

        /* Read the block number and write the filename */
        block = mem.readInt(SYNC(sender) + BLK);
        //System.out.println("[RECV] Will be using block " + String.valueOf(block));
        mem.writeString(recvfile, BASE(block) + FNAME);
        mem.waitEventIrq(sender);
        //System.out.println("[RECV] Waiting for size from sender.");
        mem.waitEvent();
        
        /* Read the size */
        total = mem.readLong(BASE(block) + SIZE);
        //System.out.println("[RECV] Got size from sender: " + String.valueOf(total));
        mem.waitEventIrq(sender);

        recvd = 0;
        for(idx = 0; recvd < total; idx = NEXT(idx)) {
            //System.out.println("[RECV] Waiting for full slot.");
            do {
                Thread.sleep(50);
                full = mem.readInt(BASE(block) + FULL);
            } while(full == 0);

            while(mem.spinLock(BASE(block) + FLOCK) != 0);
            full = full - 1;
            mem.writeInt(full, BASE(block) + FULL);
            mem.spinUnlock(BASE(block) + FLOCK);
            //System.out.println("[RECV] Decremented full to " + String.valueOf(full));

            mem.readBytes(bytes, OFFSET(block, idx), CHUNK_SZ);
            file.write(bytes, 0, CHUNK_SZ);
            recvd += CHUNK_SZ;
            //System.out.println("[RECV] Read bytes in slot " + String.valueOf(idx) + " recvd =  " + String.valueOf(recvd));
            System.out.println("[RECV] " + String.valueOf(recvd) + "B / " + String.valueOf(total) + "B = " + String.valueOf((float)recvd / (float)total * 100.0) + "%");

            while(mem.spinLock(BASE(block) + ELOCK) != 0);
            empty = mem.readInt(BASE(block) + EMPTY);
            empty = empty + 1;
            mem.writeInt(empty, BASE(block) + EMPTY);
            mem.spinUnlock(BASE(block) + ELOCK);
            //System.out.println("[RECV] Incremented empty to " + String.valueOf(empty));
        }
       
        //System.out.println("[RECV] Done, closing file and device.");
        file.getChannel().truncate(total);
        file.close();

        mem.spinUnlock(SYNC(sender) + SLOCK);

        mem.closeDevice();
    }
}
