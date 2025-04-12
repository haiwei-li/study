package org.ualberta.shm;

import java.io.OutputStream;
import java.io.IOException;

public class ShmOutputStream extends OutputStream {
    private Shm _shm;
    private MemAccess _mem;
    private int _block;
    private int _idx;

    public ShmOutputStream(Shm shm, int block) {
        super();
        _shm = shm;
        _mem = _shm._mem;
        _block = block;
        _idx = 0;
    }

    public void write(byte[] b) throws IOException {
        write(b, 0, b.length);
    }

    public void write(byte[] b, int offset, int len) throws IOException {
        int written = 0;
        int pos = offset;
        int cur;
        int full, empty = 0;
        int havelock = -1;

        while(written < len) {
            if(len - written < _shm.DATA_SZ) {
                cur = len - written;
            } else {
                cur = _shm.DATA_SZ;
            }

            do {
                Thread.yield();
                havelock = _mem.spinTrylock(_shm.BASE(_block) + _shm.ELOCK);
                if(havelock == 0) {
                    empty = _mem.readInt(_shm.BASE(_block) + _shm.EMPTY);
                    if(empty == 0) {
                        _mem.spinUnlock(_shm.BASE(_block) + _shm.ELOCK);
                    }
                }
            } while(empty == 0 || havelock != 0);

            empty = empty - 1;
            _mem.writeInt(empty, _shm.BASE(_block) + _shm.EMPTY);
            _mem.spinUnlock(_shm.BASE(_block) + _shm.ELOCK);
            
            _mem.writeBytes(b, pos, _shm.OFFSET(_block, _idx) + _shm.DATA, cur);
            _mem.writeInt(cur, _shm.OFFSET(_block, _idx) + _shm.SIZE);

            _mem.spinLock(_shm.BASE(_block) + _shm.FLOCK);
            full = _mem.readInt(_shm.BASE(_block) + _shm.FULL);
            full = full + 1;
            _mem.writeInt(full, _shm.BASE(_block) + _shm.FULL);
            _mem.spinUnlock(_shm.BASE(_block) + _shm.FLOCK);

            _idx = _shm.NEXT(_idx);

            pos += cur;
            written += cur;
        }
    }

    public void write(int b) throws IOException {
        int full, empty;

        byte[] t = new byte[1];
        t[0] = (byte)b;

        do {
            Thread.yield();
            empty = _mem.readInt(_shm.BASE(_block) + _shm.EMPTY);
        } while(empty == 0);

        _mem.spinLock(_shm.BASE(_block) + _shm.ELOCK);
        empty = empty - 1;
        _mem.writeInt(empty, _shm.BASE(_block) + _shm.EMPTY);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.ELOCK);

        _mem.writeBytes(t, 0, _shm.OFFSET(_block, _idx) + _shm.DATA, 1);
        _mem.writeInt(1, _shm.OFFSET(_block, _idx) + _shm.SIZE);

        _mem.spinLock(_shm.BASE(_block) + _shm.FLOCK);
        full = _mem.readInt(_shm.BASE(_block) + _shm.FULL);
        full = full + 1;
        _mem.writeInt(full, _shm.BASE(_block) + _shm.FULL);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.FLOCK);

        _idx = _shm.NEXT(_idx);
    }

    public void close() throws IOException {
        int full, empty;

        do {
            Thread.yield();
            empty = _mem.readInt(_shm.BASE(_block) + _shm.EMPTY);
        } while(empty == 0);

        _mem.spinLock(_shm.BASE(_block) + _shm.ELOCK);
        empty = empty - 1;
        _mem.writeInt(empty, _shm.BASE(_block) + _shm.EMPTY);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.ELOCK);

        _mem.writeInt(0, _shm.OFFSET(_block, _idx) + _shm.SIZE);

        _mem.spinLock(_shm.BASE(_block) + _shm.FLOCK);
        full = _mem.readInt(_shm.BASE(_block) + _shm.FULL);
        full = full + 1;
        _mem.writeInt(full, _shm.BASE(_block) + _shm.FULL);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.FLOCK);

        _idx = _shm.NEXT(_idx);
    }
}
