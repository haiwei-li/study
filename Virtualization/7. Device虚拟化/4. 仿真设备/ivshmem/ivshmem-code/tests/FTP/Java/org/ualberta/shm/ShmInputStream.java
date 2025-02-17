package org.ualberta.shm;

import java.io.InputStream;
import java.io.IOException;

public class ShmInputStream extends InputStream {
    private Shm _shm;
    private MemAccess _mem;
    
    private String _fname;
    private int _total;
    private int _idx;
    private byte[] _buf;
    private int _mark;
    private int _block;
    private int _sender;


    public ShmInputStream(Shm m, String fname, int sender) {
        super();

        _shm = m;
        _mem = _shm._mem;
        _fname = fname;
        _sender = sender;
        _buf = new byte[_shm.DATA_SZ];

        /* Find a free block */
        //_mem.downSema();
        do {
            for(_block = 0; _block < _shm.NBLOCKS; _block++) {
                System.out.println("[SHM] Trying block " + String.valueOf(_block));
                if(_mem.spinTrylock(_shm.BASE(_block) + _shm.LOCK) == 0) {
                    break;
                }
            }
        } while(_block == _shm.NBLOCKS);

        System.out.println("[SHM] Using block " + String.valueOf(_block) + " to fetch file " + _fname);

        /* Initiate connection */
        _mem.spinLock(_shm.SYNC(sender) + _shm.SLOCK);
        _mem.writeString(_fname, _shm.SYNC(sender) + _shm.FNAME);
        _mem.writeInt(_block, _shm.SYNC(sender) + _shm.BLK);

        /* Initialize semaphores */
        _mem.initLock(_shm.BASE(_block) + _shm.FLOCK);
        _mem.writeInt(0, _shm.BASE(_block) + _shm.FULL);
        _mem.initLock(_shm.BASE(_block) + _shm.ELOCK);
        _mem.writeInt(_shm.NCHUNKS, _shm.BASE(_block) + _shm.EMPTY);

        _idx = 0;
        _total = 0;
        _mark = 0;
    }

    public void close() throws IOException {
        System.out.println("[SHM] Cleaning up...");
        _mem.writeInt(-1, _shm.SYNC(_sender) + _shm.BLK);
        _mem.spinUnlock(_shm.SYNC(_sender) + _shm.SLOCK);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.LOCK);
        //_mem.upSema();
        _mem.closeDevice();
    }

    private int fillBuffer() throws Exception {
        int full = 0;
        int empty;
        int havelock = -1;

        do {
            Thread.sleep(50);
            havelock = _mem.spinTrylock(_shm.BASE(_block) + _shm.FLOCK);
            if(havelock == 0) {
                full = _mem.readInt(_shm.BASE(_block) + _shm.FULL);
                if(full == 0) {
                    _mem.spinUnlock(_shm.BASE(_block) + _shm.FLOCK);
                }
            }
        } while(full == 0 || havelock != 0);

        full = full - 1;
        _mem.writeInt(full, _shm.BASE(_block) + _shm.FULL);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.FLOCK);

        _total = _mem.readInt(_shm.OFFSET(_block, _idx) + _shm.SIZE);
        _mem.readBytes(_buf, _shm.OFFSET(_block, _idx) + _shm.DATA, _total);

        _mem.spinLock(_shm.BASE(_block) + _shm.ELOCK);
        empty = _mem.readInt(_shm.BASE(_block) + _shm.EMPTY);
        empty = empty + 1;
        _mem.writeInt(empty, _shm.BASE(_block) + _shm.EMPTY);
        _mem.spinUnlock(_shm.BASE(_block) + _shm.ELOCK);

        _mark = 0;
        _idx = _shm.NEXT(_idx);

        return _total;
    }

    public int read() throws IOException {
        if(_mark == _total) {
            try {
                if(fillBuffer() == 0) {
                    return -1;
                }
            } catch(Exception e) {
                throw new IOException("Error filling buffer.");
            }
        }

        return _buf[_mark++];
    }

    public int read(byte[] b) throws IOException {
        return read(b, 0, b.length);
    }
    
    public int read(byte[] b, int off, int len) throws IOException {
        int tocopy;

        if(len < 0 || len > b.length - off) {
            throw new IndexOutOfBoundsException();
        }

        if(len == 0) {
            return 0;
        }

        if(_mark == _total) {
            try {
                if(fillBuffer() == 0) {
                    return -1;
                }
            } catch(Exception e) {
                throw new IOException("Error filling buffer.");
            }
        }

        if(_total - _mark < len) {
            tocopy = _total - _mark;
        } else {
            tocopy = len;
        }

        System.arraycopy(_buf, _mark, b, 0, tocopy);
        _mark += tocopy;

        return tocopy;
    }

    public long skip(long s) throws IOException {
        long ret;

        if(s <= 0) {
            return 0;
        }

        if(_total - _mark < s) {
            ret = _total - _mark;
        } else {
            ret = s;
        }

        _mark += ret;
        
        return ret;
    }

    public int available() throws IOException {
        return _total - _mark;
    }

    public boolean markSupported() {
        return false;
    }

    public void reset() throws IOException {
        throw new IOException("Mark/reset not supported.");
    }
}
