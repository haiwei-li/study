// -----------------------------------------------------------------------------
// HexConversions.java
// -----------------------------------------------------------------------------

/*
 * =============================================================================
 * Copyright (c) 1998-2008 Jeffrey M. Hunter. All rights reserved.
 * 
 * All source code and material located at the Internet address of
 * http://www.idevelopment.info is the copyright of Jeffrey M. Hunter and
 * is protected under copyright laws of the United States. This source code may
 * not be hosted on any other site without my express, prior, written
 * permission. Application to host any of the material elsewhere can be made by
 * contacting me at jhunter@idevelopment.info.
 *
 * I have made every effort and taken great care in making sure that the source
 * code and other content included on my web site is technically accurate, but I
 * disclaim any and all responsibility for any loss, damage or destruction of
 * data or any other property which may arise from relying on it. I will in no
 * case be liable for any monetary damages arising from such loss, damage or
 * destruction.
 * 
 * As with any code, ensure to test this code in a development environment 
 * before attempting to run it in production.
 * =============================================================================
 */
 
import java.io.File;

/**
 * -----------------------------------------------------------------------------
 * This program provides several Convenience methods that can be used to convert
 * HEX values to/from Strings.
 * 
 * @version 1.0
 * @author  Jeffrey M. Hunter  (jhunter@idevelopment.info)
 * @author  http://www.idevelopment.info
 * -----------------------------------------------------------------------------
 */

public class HexConversions {

    /**
     *  Convenience method to convert a byte array to a hex string.
     *
     * @param  data  the byte[] to convert
     * @return String the converted byte[]
     */
    public static String bytesToHex(byte[] data) {
        StringBuffer buf = new StringBuffer();
        for (int i = 0; i < data.length; i++) {
            buf.append(byteToHex(data[i]).toUpperCase());
        }
        return (buf.toString());
    }


    /**
     *  method to convert a byte to a hex string.
     *
     * @param  data  the byte to convert
     * @return String the converted byte
     */
    public static String byteToHex(byte data) {
        StringBuffer buf = new StringBuffer();
        buf.append(toHexChar((data >>> 4) & 0x0F));
        buf.append(toHexChar(data & 0x0F));
        return buf.toString();
    }


    /**
     *  Convenience method to convert an int to a hex char.
     *
     * @param  i  the int to convert
     * @return char the converted char
     */
    public static char toHexChar(int i) {
        if ((0 <= i) && (i <= 9)) {
            return (char) ('0' + i);
        } else {
            return (char) ('a' + (i - 10));
        }
    }


    /**
     * Sole entry point to the class and application.
     * @param args Array of String arguments.
     */
    public static void main(String[] args) {

        // Create a String that will be stored in a byte[] array.
        // Consider this the "original" string.
        String str = "This is a test string.";
        System.out.println();
        System.out.println("Original String          : "  + str);
            
        byte[] bytes = str.getBytes();
        System.out.println("Created byte[] of length : " + bytes.length);

        System.out.println("Convert byte[] to String : " + bytesToHex(bytes));

        System.out.println();
        System.out.println("List individual entries of byte[]");
        System.out.println("---------------------------------");
        for (int i=0; i<bytes.length; i++) {
            System.out.println(
                    "bytes[" + i + "] " +
                    (i<=9 ? "  = " : " = ") +
                    ((int)bytes[i] < 9  ? "  " : "") +
                    ( ((int)bytes[i] > 9 && (int)bytes[i] <= 99) ? " " : "") +
                    bytes[i] + " : " +
                    " HEX=(0x" + byteToHex(bytes[i]) + ") : " +
                    " charValue=(" + (char)bytes[i] + ")"
            );
        }

    }

}
