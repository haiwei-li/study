
import java.net.Socket;
import java.net.InetSocketAddress;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.net.ConnectException;

import java.io.IOException;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FilterInputStream;
import java.io.InputStream;

import java.util.Hashtable;
import java.util.Iterator;
import java.util.Map.Entry;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;

import javax.net.SocketFactory;

class SocketTest {

    private SocketFactory socketFactory;
    private Socket socket;
            
    SocketTest(){
        socketFactory = SocketFactory.getDefault();
    }

    public void setupIOstreams() {

      InetSocketAddress iSA = new InetSocketAddress("localhost.localdomain", 50060);  
      short ioFailures = 0;
      short timeoutFailures = 0;
      try {
        System.out.println("Connecting to " + iSA.getAddress());
          try {
            this.socket = socketFactory.createSocket();
            //this.socket.setTcpNoDelay(tcpNoDelay);
            // connection time out is 20s
            this.socket.connect(iSA, 20000);
            this.socket.setSoTimeout(10000);
            this.socket.close();
          } catch (Exception toe) {
            /* The max number of retries is 45,
             * which amounts to 20s*45 = 15 minutes retries.
             */
            System.out.println("Error1 " + toe);
          } 
      } catch (Exception e) {
      
          System.out.println("Error2 " + e);
      
      }
      

    }
    
    public static void main(String args[]) {

        SocketTest st = new SocketTest();
        st.setupIOstreams();

    }

}
