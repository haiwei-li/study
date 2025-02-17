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
#include "ivshmem.h"

#define CHUNK_SZ (1024l*1024l*4l)

int main(int argc, char ** argv){

    long num_chunks, length;
    void * memptr;
    long * long_array;
    int i,fd,j, k;
    struct test * myptr;
    int other;

    if (argc != 4){
        printf("USAGE: sum <filename> <num chunks> <other vm>\n");
        exit(-1);
    }

    fd=open(argv[1], O_RDWR);
    printf("[SUM] opening file %s\n", argv[1]);
    num_chunks=atol(argv[2]);
    other = atoi(argv[3]);

    length=num_chunks*CHUNK_SZ;
    printf("[SUM] length is %d\n", length);


    if ((memptr = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)) == -1){
        printf("mmap failed (0x%x)\n", memptr);
        close (fd);
        exit (-1);
    }

    ioctl(fd, SET_SEMA, (void*)0);

    printf("[SUM] reading %d chunks\n", num_chunks);

    for (k = 0; k < 2; k++){
        for (j = 0; j < num_chunks; j++){

            SHA_CTX context;
            unsigned char md[20];
            long offset = j*(CHUNK_SZ/sizeof(long));

            memset(md,0,20);

            SHA1_Init(&context);

            ioctl(fd, DOWN_SEMA, NULL);
            SHA1_Update(&context,memptr + CHUNK_SZ*j, CHUNK_SZ);
            ioctl(fd, SEMA_IRQ, (void *)other);

            SHA1_Final(md,&context);

            printf("[CHUNK %d] ", j);
            for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
            {
                unsigned char c = md[i];
                printf("%2.2x",c);
            }
            printf("\n");
        }
    }

//    printf("md is *%20s*\n", md);

    munmap(memptr, length);
    close(fd);

    printf("[SUM] Exiting...\n");
}
