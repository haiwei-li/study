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

int main(int argc, char ** argv){

    int fd, length=4*1024;
    void * memptr;
    long * long_array;
    long num_chunks;
    int other;
    int i, j, k;

    if (argc != 4){
        printf("USAGE: dump_sema <filename> <num chunks> <other vm>\n");
        exit(-1);
    }

    fd=open(argv[1], O_RDWR);
    printf("[DUMP] opening file %s\n", argv[1]);

    num_chunks=atol(argv[2]);
    other = atoi(argv[3]);

    length=num_chunks*CHUNK_SZ;
    printf("[DUMP] size is %d\n", length);


    if ((memptr = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)) == -1)
    {
        printf("mmap failed (0x%x)\n", memptr);
        close (fd);
        exit (-1);
    }

    ivshmem_send(fd, SET_SEMA, 8);

    srand(time(NULL));
    long_array=(long *)memptr;

    for (k = 0; k < 2; k++){
        for (j = 0; j < num_chunks; j++){

            SHA_CTX context;
            char md[20];
            long offset = j*(CHUNK_SZ/sizeof(long));

            memset(md,0,20);

            SHA1_Init(&context);

            ivshmem_send(fd, DOWN_SEMA, 0);
            for (i = 0; i < CHUNK_SZ/sizeof(long); i++){
	            long_array[offset + i]=rand();
            }
            SHA1_Update(&context,memptr + CHUNK_SZ*j, CHUNK_SZ);
            ivshmem_send(fd, SEMA_IRQ, other); // we are interacting with VM 2

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

    printf("[DUMP] munmap is unmapping %x\n", memptr);
    munmap(memptr, length);

    close(fd);

}
