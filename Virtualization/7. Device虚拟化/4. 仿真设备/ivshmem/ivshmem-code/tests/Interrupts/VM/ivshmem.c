#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
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

char * ivshmem_strings[32] = { "SET_SEMA", "DOWN_SEMA", "EMPTY", "WAIT_EVENT", "WAIT_EVENT_IRQ", "GET_POSN", "GET_LIVELIST", "SEMA_IRQ" };

int ivshmem_recv(int fd, int ivshmem_cmd)
{

    int rv, buf;

    buf = 0;

#ifdef DEBUG
    printf("[RECVIOCTL] %s\n", ivshmem_strings[ivshmem_cmd]);
#endif
    rv = ioctl(fd, ivshmem_cmd, &buf);

    if (rv < 0) {
        fprintf(stderr, "error on ioctl call\n");
        return rv;
    }

    return buf;

}

int ivshmem_send(int fd, int ivshmem_cmd, int destination_vm)
{

    int rv;

#ifdef DEBUG
    printf("[SENDIOCTL] %s\n", ivshmem_strings[ivshmem_cmd]);
#endif

    rv = ioctl(fd, ivshmem_cmd, destination_vm);

#ifdef DEBUG
    printf("[SENDIOCTL] rv is %d\n", rv);
#endif
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

int ivshmem_print_opts(void)
{
#ifdef DEBUG
    printf("ivshmem parameters: \n");
#endif
    for (int i = 0; i < 7; i++) {
        printf ("%s: %d\n", ivshmem_strings[i], i);
    }

}
