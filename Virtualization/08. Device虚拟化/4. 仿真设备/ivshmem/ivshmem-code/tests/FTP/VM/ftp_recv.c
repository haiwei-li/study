#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h>
#include <pthread.h>
#include "ftp.h"
#include "ivshmem.h"

int main(int argc, char ** argv){

    int ivfd, ffd;
    int sender;
    void * memptr;
    char * copyfrom;
    int idx;
    unsigned int total, recvd;

    int *full, *empty;
    pthread_spinlock_t *flock, *elock;

    if (argc != 4){
        printf("USAGE: ftp_recv <ivshmem_device> <file> <sender>\n");
        exit(-1);
    }

    sender = atoi(argv[3]);

    if((ffd = open(argv[2], O_WRONLY|O_CREAT, 0644)) == -1) {
        printf("could not open file\n");
        exit(-1);
    }

    ivfd = open(argv[1], O_RDWR);

    if ((memptr = mmap(NULL, 16*CHUNK_SZ, PROT_READ|PROT_WRITE, MAP_SHARED, ivfd, 0)) == MAP_FAILED){
        printf("mmap failed (0x%p)\n", memptr);
        close(ivfd);
        close(ffd);
        exit (-1);
    }

    copyfrom = (char *)BUF_LOC;

    /* Get the filesize */
    printf("[RECV] waiting for size from %d\n", sender);
    ivshmem_send(ivfd, WAIT_EVENT, sender);
    memcpy((void*)&total, (void*)copyfrom, sizeof(unsigned int));
    /* We got the size! */
    printf("[RECV] got size %u, notifying\n", total);
    ivshmem_send(ivfd, WAIT_EVENT_IRQ, sender);

    /* My "semaphores" */
    flock = (pthread_spinlock_t *)FLOCK_LOC;
    full = (int *)FULL_LOC;
    elock = (pthread_spinlock_t *)ELOCK_LOC;
    empty = (int *)EMPTY_LOC;

    for(idx = recvd = 0; recvd < total; idx = NEXT(idx)) {
        printf("[RECV] waiting for block notification\n");
        while(*full == 0) {
            usleep(50);
        }
        while(pthread_spin_lock(flock) != 0);
        *full = *full - 1;
        pthread_spin_unlock(flock);

        printf("[RECV] recieving bytes in block %d\n", idx);
        write(ffd, copyfrom + OFFSET(idx), CHUNK_SZ);
        recvd += CHUNK_SZ;
        printf("[RECV] block received, notifying sender. recvd size now %u\n", recvd);

        while(pthread_spin_lock(elock) != 0);
        *empty = *empty + 1;
        pthread_spin_unlock(elock);
    }

    ftruncate(ffd, total);

    munmap(memptr, 16*CHUNK_SZ);
    close(ffd);
    close(ivfd);
}
