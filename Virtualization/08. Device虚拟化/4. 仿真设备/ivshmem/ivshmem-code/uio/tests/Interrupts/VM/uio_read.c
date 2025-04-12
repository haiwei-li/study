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

int main(int argc, char ** argv){

    int i, count, rv, fd , buf;

    if (argc != 3) {
        printf("USAGE: uio_read <filename> <count>\n");
        exit(-1);
    }

    fd = open(argv[1], O_RDWR);
    count = atoi(argv[2]);
    printf("[UIO] opening file %s\n", argv[1]);

    printf("[UIO] reading\n");

    for (i = 0; i < count; i++) {
        rv = read(fd, &buf, sizeof(buf));
        printf("[UIO] buf is %d\n", buf);
    }

    close(fd);

    printf("[UIO] Exiting...\n");
}
