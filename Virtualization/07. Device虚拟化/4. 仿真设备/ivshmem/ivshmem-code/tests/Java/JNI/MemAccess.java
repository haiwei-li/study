// MemAccess.java:
import java.nio.ByteBuffer;
import java.nio.LongBuffer;
import java.nio.ByteOrder;
import java.security.MessageDigest;
import java.util.Random;
 
public class MemAccess {
    static {
        System.loadLibrary("MemAccess");
    }
    
    public static void main(String[] args) throws Exception {

        MemAccess ma = new MemAccess();
            
    //    ma.readGeneratedMem();
        ma.writeSum();

    }

    void writeSum() throws Exception {
   
        int fd = openDevice("bonzo");
        long size = 16;
        Random myrand = new Random(); 
        MessageDigest md = MessageDigest.getInstance("SHA-1");

        ByteBuffer bytebuffer = getGeneratedMem(fd, size);
        LongBuffer lb = bytebuffer.asLongBuffer();

        for (int i = 0; i < size; i++) {
            lb.put(myrand.nextLong());
        }

        byte[] bytes = md.digest();
        md.update(bytebuffer);
        bytes = md.digest();
         
        System.out.println(HexConversions.bytesToHex(bytes).toLowerCase());
        
    }

    void readGeneratedMem() throws Exception {

        // get a reference to the object that holds a pointer to the c++ buffer
        long size=64;
        
        int fd = openDevice("bonzo");

        ByteBuffer buffer = getGeneratedMem(fd, size);
        buffer.order(ByteOrder.nativeOrder()); 

        // walk through the c++ buffer to display the values
        System.out.println("size is " + size);   
        int my_id = getShmemId(fd);
        System.out.println("my_id is " + my_id);   

        setSemaphore(fd, 0);
        downSemaphore(fd);
         
        closeGeneratedMem(fd);

        MessageDigest md = MessageDigest.getInstance("SHA-1");

        md.update(buffer);
        byte[] bytes = md.digest();
        System.out.println(HexConversions.bytesToHex(bytes).toLowerCase());

        buffer.position(0);
        md.reset();
        md.update(buffer);
        bytes = md.digest();

        System.out.println(HexConversions.bytesToHex(bytes).toLowerCase());

    }
    
    native ByteBuffer getGeneratedMem(int fd, long size);
    native void closeGeneratedMem(int fd);
    native int getShmemId(int fd);
    native int openDevice(String str);
    native void downSemaphore(int fd);
    native void upSemaphore(int fd, int dest);
    native void setSemaphore(int fd, int value);
 
}
