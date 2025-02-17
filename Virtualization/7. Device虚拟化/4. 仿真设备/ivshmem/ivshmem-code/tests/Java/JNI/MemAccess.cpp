// MemAccess.cpp:
#include "MemAccess.h"
#include "ivshmem.h"
#include <stdlib.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <errno.h>

JNIEXPORT jobject JNICALL Java_MemAccess_getGeneratedMem(JNIEnv * env, jobject obj, jint fd, jlong mysize) {
    int sz = mysize * 1024 * 1024;
    int i, nbr;

    mysize = 13;
    nbr = sz / sizeof(long);
    long * buffer = new long[nbr]; // c++ buffer

   printf("mysize is %ld\n", mysize);

    if ((buffer = (long *)mmap(NULL, sz, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)) == (long *)(caddr_t)-1){ 
        printf("mmap failed (0x%x)\n", buffer);
        close (fd);
        exit (-1);
    }

/*
    for (i = 0; i < size; i++)
        printf("%ld\n", buffer[i]);
    printf("%ld\n", buffer[nbr-1]);
    printf("**************\n");
*/
    // return a reference of a (Java) object that holds a pointer to the c++ buffer
    return env->NewDirectByteBuffer(buffer, nbr * sizeof(long));
}

JNIEXPORT void JNICALL Java_MemAccess_closeGeneratedMem(JNIEnv * env, jobject obj, jint fd) {

    close(fd);

}

JNIEXPORT jint JNICALL Java_MemAccess_getShmemId (JNIEnv *, jobject, jint fd) {

	return ivshmem_recv(fd, GET_POSN);
}

JNIEXPORT void JNICALL Java_MemAccess_downSemaphore (JNIEnv *, jobject, jint fd) {

	ivshmem_send(fd, DOWN_SEMA, 0);
}

JNIEXPORT void JNICALL Java_MemAccess_upSemaphore (JNIEnv *, jobject jobj, jint fd, jint dest) {

	ivshmem_send(fd, SEMA_IRQ, dest);
}

JNIEXPORT void JNICALL Java_MemAccess_setSemaphore (JNIEnv *, jobject jobj, jint fd, jint value) {

	ivshmem_send(fd, SET_SEMA, value);
}

JNIEXPORT jint JNICALL Java_MemAccess_openDevice (JNIEnv *env, jobject, jstring dev_name) {

	const char *str;
	int fd;

	jboolean * iscopy;
	str = env->GetStringUTFChars(dev_name, NULL);
	if (str == NULL) {
		return -1;
	}
	
	fd=open("/dev/ivshmem", O_RDWR);
    	printf("fd is %d\n", fd);
 
	printf("String is %s\n", str);
	env->ReleaseStringUTFChars(dev_name, str);

	return fd;
}
