package org.ualberta.shm;

import java.net.URLStreamHandler;
import java.net.URLConnection;
import java.net.URL;

public class Handler extends URLStreamHandler {
    public URLConnection openConnection(URL u) {
        return new ShmConnection(u);
    }
}
