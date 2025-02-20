package org.ualberta.shm;

import java.io.FileInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.lang.Runnable;

public class ShmServer extends Shm implements Runnable {
    public static void main(String args[]) throws Exception {
        String devname = args[0];
        int msize = Integer.parseInt(args[1]);
        int nblocks = Integer.parseInt(args[2]);
        int nchunks = Integer.parseInt(args[3]);
        int nmachines = Integer.parseInt(args[4]);

        ShmServer s = new ShmServer(devname, msize, nblocks, nchunks, nmachines);
        s.run();
    }

    public ShmServer(String devname, int msize, int nblocks, int nchunks, int nmachines) throws IOException {
        super(devname, msize, nblocks, nchunks, nmachines);
    }

    public void run() {
        try {
            doRun();
        } catch(Exception e) {
            return;
        }
    }

    private void doRun() throws IOException {
        int me;
        int block;
        String sendfile;
        boolean quit = false;
        byte[] bytes = new byte[DATA_SZ];

        /* What is my VM number? */
        me = _mem.getPosition();
        _mem.writeInt(-1, SYNC(me) + BLK);
        System.out.println("[SHM] I am VM number " + String.valueOf(me));

        while(!quit) {

            /* Wait for a client */
            System.out.println("[SHM] Waiting for a client.");
            do {
                block = _mem.readInt(SYNC(me) + BLK);
            } while(block == -1);

            System.out.println("[SHM] Got a client with block " + String.valueOf(block));

            /* Read the filename */
            sendfile = _mem.readString(SYNC(me) + FNAME);
            System.out.println("[SHM] Client sent filename: " + sendfile);

            ShmOutputStream shmout = new ShmOutputStream(this, block);
            DataOutputStream dos = new DataOutputStream(shmout);

            FileInputStream file = new FileInputStream(sendfile);

            long rem = file.getChannel().size();
            int len = file.read(bytes, 0, (int)Math.min(rem, DATA_SZ));
            while (len >= 0) {
                rem -= len;
                if (len > 0) {
                    dos.write(bytes, 0, len);
                } else {
                    System.out.println("Skipping zero-length transfer");
                }
                if (rem == 0) {
                    break;
                }
                len = file.read(bytes, 0, (int)Math.min(rem, DATA_SZ));
            }

            _mem.writeInt(-1, SYNC(me) + BLK);
            dos.close();
            shmout.close();
            System.out.println("[SHM] Done sending map outputs.");
        }

        _mem.closeDevice();
    }
}
