class Arguments
{
    private native void setArgs (String[] javaArgs);
    public static void main (String args[]) 
    {
        Arguments A = new Arguments();
        newArgs[] = A.setArgs(args);
    }

    static 
    {
        System.loadLibrary("MyArgs");
    }
}


