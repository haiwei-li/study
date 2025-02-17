import java.util.*;

class ReadFile {
//Native method declaration
  native byte[] loadFile(String name);
//Load the library
  static {
    System.loadLibrary("nativelib");
  }

  public static void main(String args[]) {
    byte buf[];
//Create class instance
    ReadFile mappedFile=new ReadFile();
//Call native method to load ReadFile.java
    buf=mappedFile.loadFile("ReadFile.java");
//Print contents of ReadFile.java
    for(int i=0;i<buf.length;i++) {
      System.out.print((char)buf[i]);
    }
  }
}
