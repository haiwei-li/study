package org.ualberta.shm;

import java.io.IOException;

/* This class contains constants and "macros" for the FTP apps. */

public class Shm {
    /* Memory device */
    protected MemAccess _mem;

    /* Chunks per block */
    protected final long MSIZE;
    protected final int NBLOCKS;
    protected final int NCHUNKS;
    protected final int CHUNK_SZ;
    protected final int DATA_SZ;
    protected final int BLOCK_SZ;
    protected final int NMACHINES;
 
    /* Offsets for the synchronization memory */
    protected final int SLOCK = 0;
    protected final int BLK = 4;
    protected final int FNAME = 8;

    /* Offsets for the block memory */
    protected final int LOCK = 0;
    protected final int FLOCK = 4;
    protected final int FULL = 8;
    protected final int ELOCK = 12;
    protected final int EMPTY = 16;

    /* Offsets in the chunk */
    protected final int SIZE = 0;
    protected final int DATA = 4;

    public Shm(String devname, long msize, int nblocks, int nchunks, int nmachines) throws IOException {
        _mem = new MemAccess(devname);

        MSIZE = msize;
        NBLOCKS = nblocks;
        NCHUNKS = nchunks;
        NMACHINES = nmachines;

        /* Convert mem size to MB */
        msize *= 1024*1024;
        /* Reserve space for sync data */
        msize -= nmachines * 1024;
        /* Calculate sizes */
        BLOCK_SZ = (int)(msize / nblocks);
        CHUNK_SZ = BLOCK_SZ / (nchunks + 1);
        DATA_SZ = CHUNK_SZ - 4;

        System.out.println("[SHM] Initialized.");
        System.out.println("\tMemory: " + String.valueOf(MSIZE) + "MB");
        System.out.println("\tBlocks: " + String.valueOf(NBLOCKS) + " x " + String.valueOf(BLOCK_SZ) + "B");
        System.out.println("\tChunks: " + String.valueOf(NCHUNKS) + " x " + String.valueOf(CHUNK_SZ) + "B per block");
    }

    public void prep() throws IOException {
        /* Initialize the sync memory for the senders */
        for(int i = 1; i <= NMACHINES; i++) {
            _mem.initLock(SYNC(i) + SLOCK);
            _mem.writeInt(-1, SYNC(i) + BLK);
        }

        /* Initialize the block locks */
        for(int i = 0; i < NBLOCKS; i++) {
            _mem.initLock(BASE(i) + LOCK);
        }

        /* Initialize the free blocks semaphore */
        System.out.println("[SHM] Setting semaphore to " + String.valueOf(NBLOCKS));
        //_mem.setSema(NBLOCKS);
    }

    protected int NEXT(int i) {
        return (i + 1) % NCHUNKS;
    }

    /* The base address of block blk */
    protected int BASE(int blk) {
        return CHUNK_SZ + BLOCK_SZ * blk;
    }

    /* Offset based on the block and chunk numbers */
    protected int OFFSET(int blk, int i) {
        return CHUNK_SZ + BLOCK_SZ * blk + CHUNK_SZ * (i + 1);
    }

    /* The syncronization block for sender i */
    protected int SYNC(int i) {
        return 1024*(i-1);
    }
}
