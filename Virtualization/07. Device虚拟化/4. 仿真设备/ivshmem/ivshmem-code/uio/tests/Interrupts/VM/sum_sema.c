#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <errno.h>
#include "ivshmem.h"

#define CHUNK_SZ (1024l*1024l*4l)
#define MSI_VECTOR 0 /* the default vector */


int do_select(int fd);

int main(int argc, char ** argv){

    long num_chunks, length;
    void * memptr, *regptr;
    int i,fd,j, k;
    int other, count;

    if (argc != 4){
        printf("USAGE: sum <filename> <num chunks> <other vm>\n");
        exit(-1);
    }

    fd=open(argv[1], O_RDWR);
    printf("[SUM] opening file %s\n", argv[1]);
    num_chunks=atol(argv[2]);
    other = atoi(argv[3]);

    length=num_chunks*CHUNK_SZ;
    printf("[SUM] length is %ld\n", length);

    if ((regptr = mmap(NULL, 256, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0 * getpagesize())) == (void *) -1){
        printf("mmap failed (0x%p)\n", regptr);
        close (fd);
        exit (-1);
    }

    if ((memptr = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 1 * getpagesize())) == (void *) -1){
        printf("mmap failed (0x%p)\n", memptr);
        close (fd);
        exit (-1);
    }

    printf("[SUM] reading %ld chunks\n", num_chunks);

    count = 0;
    for (k = 0; k < 2; k++){
        int oldrv = -1;

        for (j = 0; j < num_chunks; j++) {

            int rv;
            SHA_CTX context;
            unsigned char md[20];

            memset(md,0,20);

            SHA1_Init(&context);

            if (count <= 0) {
                do_select(fd);
                rv = ivshmem_recv(fd);

                if (rv > 0)  {
                    if (oldrv == -1)
                        oldrv = rv - 1; // read returns the total # of interrupts
                                    // ever which would lead to overflow
                    count += rv - oldrv;
                    printf("rv = %d\n", rv);
                    oldrv = rv;
                }
            }

            SHA1_Update(&context,memptr + CHUNK_SZ*j, CHUNK_SZ);
            count--;
            ivshmem_send(regptr, MSI_VECTOR, other);

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
    munmap(regptr, 256);
    close(fd);

    printf("[SUM] Exiting...\n");
}

int do_select (int fd) {

    fd_set readset;

    FD_ZERO(&readset);
    /* conn socket is in Live_vms at posn 0 */
    FD_SET(fd, &readset);

    select(fd + 1, &readset, NULL, NULL, NULL);

    return 1;

}
