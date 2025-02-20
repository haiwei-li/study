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

int main(int argc, char ** argv){

    long size;
    char * file;
    void * map_region;
    long * long_array;
    int i,fd;
    SHA_CTX context;
    unsigned char md[20];
    struct test * myptr;

    if (argc!=3){
        fprintf(stderr, "USAGE: sum <file> <size in MB>\n");
        exit(-1);
    }

    size=atol(argv[2])*1024*1024;
    file=strdup(argv[1]);

    printf("[SUM] reading %d bytes from %s\n", size, file);

    if ((fd=open(file, O_RDWR)) < 0){
        fprintf(stderr, "ERROR: cannot open file\n");
        exit(-1);
    }

    /* With UIO drivers, the offset selects the memory region beginning at 0 and counting by page offsets */
    if ((map_region=mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 1 * getpagesize())) < 0){
        fprintf(stderr, "ERROR: cannot mmap file\n");
    } else {
        printf("[SUM] mapped to %p\n", map_region);
    }

    memset(md,0,20);

    SHA1_Init(&context);
    SHA1_Update(&context,map_region,size);
    SHA1_Final(md,&context);

    printf("[SUM] ");
    for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
    {
        unsigned char c = md[i];
        printf("%2.2x",c);
    }
    printf("\n");

//    printf("md is *%20s*\n", md);

    munmap(map_region,size);
    close(fd);

    printf("[SUM] Exiting...\n");
}
