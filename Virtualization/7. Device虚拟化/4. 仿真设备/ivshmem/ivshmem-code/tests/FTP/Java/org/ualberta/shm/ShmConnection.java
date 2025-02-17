package org.ualberta.shm;

import java.net.URLConnection;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;
import java.io.InputStream;
import java.io.IOException;
import java.net.URL;

public class ShmConnection extends URLConnection {
    private static Map<String, Integer> _shmHosts;
    private static Shm _shm;

    private ShmInputStream _inputStream;

    public ShmConnection(URL u) {
        super(u);
    }

    public void connect() throws IOException {
        URL u = this.getURL();
        
        if(_shm == null) {
            /* TODO: Parmaeterize the device name */
            try {
                _shm = new Shm("/dev/kvm_ivshmem", 256, 5, 5, 3);
            } catch (Exception e) {
                throw new IOException("Error creating memory device.");
            }
        }

        if(_shmHosts == null) {
            _shmHosts = new HashMap<String, Integer>();
            /* TODO: Read or compute these mappings */
            _shmHosts.put("10.111.111.165", 1);
            _shmHosts.put("10.111.111.188", 2);
            _shmHosts.put("10.111.111.140", 3);
            _shmHosts.put("f11a", 1);
            _shmHosts.put("f11b", 2);
            _shmHosts.put("f11c", 3);
        }

        if(!_shmHosts.containsKey(u.getHost())) {
            throw new IOException("Host not found in SHM mapping.");
        }

        int sender = _shmHosts.get(u.getHost()).intValue();

        _inputStream = new ShmInputStream(_shm, u.getFile(), sender);
    }

    public InputStream getInputStream() throws IOException {
        connect();
        return _inputStream;
    }
}
