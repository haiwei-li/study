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
    long num_chunks;
    int other;
    int i, j, k;
    int count;

    if (argc != 4){
        printf("USAGE: dump_sema <filename> <num chunks> <other vm>\n");
        exit(-1);
    }

    fd=open(argv[1], O_RDWR|O_NONBLOCK);
    printf("[DUMP] opening file %s\n", argv[1]);

    num_chunks=atol(argv[2]);
    other = atoi(argv[3]);

    length=num_chunks*CHUNK_SZ;
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
    long_array=(long *)memptr;

    count = num_chunks;
    for (k = 0; k < 2; k++){
        int oldrv = -1;

        for (j = 0; j < num_chunks; j++){
            int rv;
            SHA_CTX context;
            unsigned char md[20];
            long offset = j*(CHUNK_SZ/sizeof(long));

            memset(md,0,20);

            SHA1_Init(&context);

            do {
                rv = ivshmem_recv(fd);

                if (rv > 0) {
                    if (oldrv == -1)
                        oldrv = rv - 1;
                    count += rv - oldrv;
                    printf("rv = %d\n", rv);
                }

                oldrv = rv;
            } while (count <= 0);

            for (i = 0; i < CHUNK_SZ/sizeof(long); i++){
                long_array[offset + i]=rand();
            }

            SHA1_Update(&context, memptr + CHUNK_SZ*j, CHUNK_SZ);
            count--;
            ivshmem_send(regptr, MSI_VECTOR, other);

            SHA1_Final(md, &context);

            printf("[CHUNK %d] ", j);
            for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
            {
                unsigned char c = md[i];
                printf("%2.2x",c);
            }
            printf("\n");
        }
    }

    printf("[DUMP] munmap is unmapping %p\n", memptr);
    munmap(memptr, length);
    munmap(regptr, 256);

    close(fd);

}
