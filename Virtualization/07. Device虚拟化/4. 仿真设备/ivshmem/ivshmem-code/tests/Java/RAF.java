import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.security.MessageDigest;

class RAF {

    public static void main(String args[]){
  
        String fname="test";

        if (args.length == 1) {
            fname = args[0];
        } else {
            System.console().printf("USAGE: RAF <filename>\n");
        }

        try {

            RandomAccessFile raf = new RandomAccessFile(fname,"r");
            byte b[];

            b = new byte[8];

            // raf.seek(256*1024*1024);

            int i = raf.read(b, 0, 8);
            System.console().printf("Length is " + i +"\n");

            String str = new String(b); 
            System.console().printf("String is *" + str + "*\n");

            MessageDigest md = MessageDigest.getInstance("SHA-1");

            md.update(b);
            byte[] hash = md.digest();

            String sha1 = HexConversions.bytesToHex(hash);

            System.out.println("String is " + sha1);

        } catch (Exception e) {
            System.console().printf("error" + e);
        }
    }

}
