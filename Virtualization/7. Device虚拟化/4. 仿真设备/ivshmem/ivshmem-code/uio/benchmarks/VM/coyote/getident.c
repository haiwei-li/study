#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include "ivshmem.h"

enum ivshmem_registers {
    IntrMask = 0,
    IntrStatus = 4,
    IVPosition = 8,
    Doorbell = 12
};

int main(int argc, char ** argv){

	int fd;
	int * regptr;

	if (argc != 2) {
		fprintf(stderr, "USAGE: getident <file>\n");
        exit(-1);
	}

	if ((fd = open(argv[1], O_RDWR)) < 0) {
		fprintf(stderr, "ERROR: cannot open file\n");
		exit(-1);
	}

    if ((regptr = (int *)mmap(NULL, 256, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0 * getpagesize())) == (void *) -1){
        printf("mmap failed\n");
        close (fd);
        exit (-1);
    }

    printf("ID is %d\n", regptr[IVPosition/sizeof(int)]);

	close(fd);

	printf("exiting\n");
}
