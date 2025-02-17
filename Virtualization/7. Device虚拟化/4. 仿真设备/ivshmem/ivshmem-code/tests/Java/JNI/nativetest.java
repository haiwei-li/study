public class nativetest
{
    static {
        System.loadLibrary("nativetest");
    }
    public native String sayHello(String s);
	public static void main(String[] argv)
	{
		String retval = null;
		nativetest nt = new nativetest();
		retval = nt.sayHello("Beavis");
		System.out.println("Invocation returned " + retval);
	}
}

