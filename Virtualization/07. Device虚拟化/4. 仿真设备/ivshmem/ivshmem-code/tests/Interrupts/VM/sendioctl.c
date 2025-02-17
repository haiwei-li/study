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
#include "ivshmem.h"

int main(int argc, char ** argv){

	int rv,fd;
	int * count;
	short rv_short;
	int i,x=0;
	void * map_region;
	char * file;
	int my_ioctl;
	long ioctl_arg;

	if (argc < 3) {
		fprintf(stderr, "USAGE: guestlock <file> <ioctl> <ioctl_arg>\n");
        ivshmem_print_opts();
        exit(-1);
	}

	file=strdup(argv[1]);

	my_ioctl = atol(argv[2]);
	if (argc == 4) {
		ioctl_arg = atol(argv[3]);
	} else {
		ioctl_arg = -1;
	}

	if ((fd=open(file, O_RDWR)) < 0) {
		fprintf(stderr, "ERROR: cannot open file\n");
		exit(-1);
	}

    ivshmem_send(fd, my_ioctl, ioctl_arg);

	close(fd);

	printf("exiting\n");
/*
	rv=pthread_spin_trylock(sl1);
	printf("retval is %d\n", rv);

	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv);
*/

/*	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv);

	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv);
*/
}
