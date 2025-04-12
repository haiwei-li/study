CC=gcc
JAVA_HOME=/usr/lib/jvm/jdk1.6.0_14
CFLAGS=-I${JAVA_HOME}/include -I${JAVA_HOME}/include/linux -fPIC -shared -Wall -D_GNU_SOURCE

all: libMemAccess.so org/ualberta/shm/Handler.class org/ualberta/shm/ShmServer.class org/ualberta/shm/ShmPrep.class Getter.class

libMemAccess.so: org_ualberta_shm_MemAccess.h
	$(CC) $(CFLAGS) -o libMemAccess.so MemAccess.c ivshmem.c

org_ualberta_shm_MemAccess.h: org/ualberta/shm/MemAccess.class
	javah -jni org.ualberta.shm.MemAccess

%.class: %.java
	javac $<

clean:
	find . -name '*.class' -exec rm {} \;
	-rm -f *.so org_ualberta_shm_MemAccess.h
