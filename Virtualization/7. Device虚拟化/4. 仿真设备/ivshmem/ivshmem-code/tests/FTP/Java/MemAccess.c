#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <pthread.h>

#include <jni.h>

#include "org_ualberta_shm_MemAccess.h"
#include "ivshmem.h"

#define CHUNK_SZ (16*1024*1024)

static int fd;
char *mem;

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_openDevice (JNIEnv *env, jobject obj, jstring devname) {
    const char *fname = (*env)->GetStringUTFChars(env, devname, NULL);
    fd = open(fname, O_RDWR);
    (*env)->ReleaseStringUTFChars(env, devname, fname);

    if((mem = (char *)mmap(NULL, 16 * CHUNK_SZ, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)) == MAP_FAILED) {
        close(fd);
        return(-1);
    }

    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_closeDevice (JNIEnv *env, jobject obj) {
    munmap(mem, 16*CHUNK_SZ);
    close(fd);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_writeBytes (JNIEnv *env, jobject obj, jbyteArray bytes, jint foff, jint offset, jint cnt) {
    char *to = mem + offset;
    (*env)->GetByteArrayRegion(env, bytes, foff, cnt, (jbyte *)to);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_readBytes (JNIEnv *env, jobject obj, jbyteArray bytes, jint offset, jint cnt) {
    char *from = mem + offset;
    (*env)->SetByteArrayRegion(env, bytes, 0, cnt, (jbyte *)from);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_writeString (JNIEnv *env, jobject obj, jstring towrite, jint offset) {
    char *to = mem + offset;
    const char *from = (*env)->GetStringUTFChars(env, towrite, NULL);
    int len = (*env)->GetStringLength(env, towrite);
    memcpy(to, from, len);
    to[len] = '\0';
    (*env)->ReleaseStringUTFChars(env, towrite, from);
    return(0);
}

JNIEXPORT jstring JNICALL Java_org_ualberta_shm_MemAccess_readString (JNIEnv *env, jobject obj, jint offset) {
    const char *from = mem + offset;
    return (*env)->NewStringUTF(env, from);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_writeInt (JNIEnv *env, jobject obj, jint towrite, jint offset) {
    *((jint *)(mem + offset)) = towrite;
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_writeLong (JNIEnv *env, jobject obj, jlong towrite, jint offset) {
    *((jlong *)(mem + offset)) = towrite;
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_readInt (JNIEnv *env, jobject obj, jint offset) {
    return(*((jint *)(mem + offset)));
}

JNIEXPORT jlong JNICALL Java_org_ualberta_shm_MemAccess_readLong (JNIEnv *env, jobject obj, jint offset) {
    return(*((jlong *)(mem + offset)));
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_initLock (JNIEnv *env, jobject obj, jint offset) {
    pthread_spinlock_t *sl = (pthread_spinlock_t *)(mem + offset);
    pthread_spin_init(sl, 1);

    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_spinLock (JNIEnv *env, jobject obj, jint offset) {
    pthread_spinlock_t *sl = (pthread_spinlock_t *)(mem + offset);
    while(pthread_spin_lock(sl) != 0);

    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_spinTrylock (JNIEnv *env, jobject obj, jint offset) {
    pthread_spinlock_t *sl = (pthread_spinlock_t *)(mem + offset);
    return(pthread_spin_trylock(sl));
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_spinUnlock (JNIEnv *env, jobject obj, jint offset) {
    pthread_spinlock_t *sl = (pthread_spinlock_t *)(mem + offset);
    pthread_spin_unlock(sl);

    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_waitEvent (JNIEnv *env, jobject obj) {
    ivshmem_send(fd, WAIT_EVENT, 0);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_waitEventIrq (JNIEnv *env, jobject obj, jint machine) {
    ivshmem_send(fd, WAIT_EVENT_IRQ, machine);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_upSema (JNIEnv *env, jobject obj) {
    ivshmem_send(fd, SEMA_IRQ, 0);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_downSema (JNIEnv *env, jobject obj) {
    ivshmem_send(fd, DOWN_SEMA, 0);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_setSema (JNIEnv *env, jobject obj, jint val) {
    ivshmem_send(fd, SET_SEMA, val);
    return(0);
}

JNIEXPORT jint JNICALL Java_org_ualberta_shm_MemAccess_getPosition (JNIEnv *env, jobject obj) {
    return(ivshmem_recv(fd, GET_POSN));
}
