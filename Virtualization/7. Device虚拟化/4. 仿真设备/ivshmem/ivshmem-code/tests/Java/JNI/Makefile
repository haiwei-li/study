CC=gcc
JAVA_HOME=/usr/lib/jvm/jdk1.6.0_14/

#gcc -G -I/usr/local/java/include -I/usr/local/java/include/solaris 
#	nativetest.c -o nativetest.so

all:	MemAccess memlib	

MemAccess:
	javac MemAccess.java
	javah -jni MemAccess

memlib:
	g++ -fPIC -I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux -shared -o libMemAccess.so MemAccess.cpp ivshmem.c
	

#	$(CC) -fPIC -o libnativelib.so -shared -Wl,-soname,libnative.so \
     -I$(JAVA_HOME)/include \
     -I$(JAVA_HOME)/include/linux nativelib.c  \
     -static -lc


