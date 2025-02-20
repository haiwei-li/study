// : c12:MappedFile.java
// Mapping an entire file into memory for reading.
// {Args: MappedFile.java}
// From 'Thinking in Java, 3rd ed.' (c) Bruce Eckel 2002
// www.BruceEckel.com. See copyright notice in CopyRight.txt.

import java.io.File;
import java.io.FileInputStream;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.security.MessageDigest;

public class MappedFile {
  public static void main(String[] args) throws Exception {
    if (args.length != 1) {
      System.out.println("argument: sourcefile");
      System.exit(1);
    }
    long length = new File(args[0]).length();
    MappedByteBuffer buf = new RandomAccessFile(args[0],"rw").getChannel().map(
        FileChannel.MapMode.READ_WRITE, 0, length);  

    int i = 0;
    
    while (i < length) {
      buf.put(i,(byte) 'x'); 
      i += 2;
    }

    i = 0;

    MessageDigest md = MessageDigest.getInstance("SHA-1");

    md.update(buf);
    byte[] bytes = md.digest();

    System.out.println(HexConversions.bytesToHex(bytes).toLowerCase());
  }
} ///:~
