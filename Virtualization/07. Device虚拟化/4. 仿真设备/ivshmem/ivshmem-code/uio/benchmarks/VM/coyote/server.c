#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/ioctl.h>
#include "ivshmem.h"

#define CHUNK_SZ (4*1024*1024)
#define MSI_VECTOR 0 /* the default MSI vector */

int main(int argc, char ** argv){

    int fd, length=4*1024;
    void * memptr, *regptr;
    long * long_array;
    long param;
    int other;
    int i, j, k;
    int count;

    if (argc != 4){
        printf("USAGE: server <filename> <param> <other vm>\n");
        exit(-1);
    }

    fd = open(argv[1], O_RDWR|O_NONBLOCK);
    printf("[DUMP] opening file %s\n", argv[1]);

    param = atol(argv[2]);
    other = atoi(argv[3]);

    length = CHUNK_SZ;
    printf("[DUMP] size is %d\n", length);

    if ((regptr = mmap(NULL, 256, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0 * getpagesize())) == (void *) -1)
    {
        printf("mmap failed (0x%p)\n", regptr);
        close (fd);
        exit (-1);
    }

    if ((memptr = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 1 * getpagesize())) == (void *) -1)
    {
        printf("mmap failed (0x%p)\n", memptr);
        close (fd);
        exit (-1);
    }

    srand(time(NULL));

    /* wake client */
    ivshmem_send(regptr, MSI_VECTOR, other);
    /*
    printf("waiting\n");
    rv = ivshmem_recv(fd);
    printf("rv = %d\n", rv);
    */

    printf("[DUMP] munmap is unmapping %p\n", memptr);
    munmap(memptr, length);
    munmap(regptr, 256);

    close(fd);

}
