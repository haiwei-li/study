#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <time.h>
#include <pthread.h>
#include "ftp.h"
#include "ivshmem.h"

int main(int argc, char ** argv){

    int ivfd, ffd;
    int receiver;
    void * memptr;
    char * copyto;
    int idx;
    unsigned int total, sent;
    struct stat st;

    int *full, *empty;
    pthread_spinlock_t *flock, *elock;

    if (argc != 4){
        printf("USAGE: ftp_send <ivshmem_device> <file> <receiver>\n");
        exit(-1);
    }

    if(stat(argv[2], &st) != 0) {
        printf("file does not exist\n");
        exit(-1);
    }
    total = st.st_size;

    if((ffd = open(argv[2], O_RDONLY)) == -1) {
        printf("could not open file\n");
        exit(-1);
    }

    ivfd = open(argv[1], O_RDWR);

    receiver = atoi(argv[3]);

    if ((memptr = mmap(NULL, 16 * CHUNK_SZ, PROT_READ|PROT_WRITE, MAP_SHARED, ivfd, 0)) == MAP_FAILED) {
        printf("mmap failed (0x%p)\n", memptr);
        close(ivfd);
        close(ffd);
        exit(-1);
    }

    copyto = (char *)BUF_LOC;

    /* Initialize the "semaphores" */
    flock = (pthread_spinlock_t *)FLOCK_LOC;
    full = (int *)FULL_LOC;
    elock = (pthread_spinlock_t *)ELOCK_LOC;
    empty = (int *)EMPTY_LOC;

    pthread_spin_init(flock, 1);
    pthread_spin_init(elock, 1);
    *full = 0;
    *empty = 15;

    /* Send the file size */
    printf("[SEND] sending size %u to receiver %d\n", total, receiver);
    memcpy((void*)copyto, (void*)&total, sizeof(unsigned int));
    ivshmem_send(ivfd, WAIT_EVENT_IRQ, receiver);
    /* Wait to know the reciever got the size */
    printf("[SEND] waiting for receiver to ack size\n");
    ivshmem_send(ivfd, WAIT_EVENT, receiver);
    printf("[SEND] ack!\n");

    for(idx = sent = 0; sent < total; idx = NEXT(idx)) {
        printf("[SEND] waiting for available block\n");
        while(*empty == 0) {
            usleep(50);
        }
        while(pthread_spin_lock(elock) != 0);
        *empty = *empty - 1;
        pthread_spin_unlock(elock);

        printf("[SEND] sending bytes in block %d\n", idx);
        read(ffd, copyto + OFFSET(idx), CHUNK_SZ);
        sent += CHUNK_SZ;
        printf("[SEND] notifying, sent size now %u\n", sent);

        while(pthread_spin_lock(flock) != 0);
        *full = *full + 1;
        pthread_spin_unlock(flock);
    }

    munmap(memptr, 16*CHUNK_SZ);
    close(ffd);
    close(ivfd);
}
