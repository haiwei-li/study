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

int ivshmem_recv(int fd, int ivshmem_cmd) {
    int rv, buf;

    printf("[RECVIOCTL] %s\n", ivshmem_strings[ivshmem_cmd]);
    rv = ioctl(fd, ivshmem_cmd, &buf);

    return buf;
}

int ivshmem_send(int fd, int ivshmem_cmd, int destination_vm) {
    int rv;

#ifdef DEBUG
    switch (ivshmem_cmd) {
        case SET_SEMA:
            printf("[SENDIOCTL] set_sema\n");
            break;
        case DOWN_SEMA:
            printf("[SENDIOCTL] down_sema\n");
            break;
        case SEMA_IRQ:
            printf("[SENDIOCTL] sema_irq\n");
            break;
        case WAIT_EVENT:
            printf("[SENDIOCTL] wait_event\n");
            break;
        case WAIT_EVENT_IRQ:
            printf("[SENDIOCTL] wait_event_irq\n");
            break;
        case GET_IVPOSN:
            printf("[SENDIOCTL] wait_event_irq\n");
            break;
        case GET_LIVELIST:
            printf("[SENDIOCTL] wait_event_irq\n");
            break;
        default:
            printf("[SENDIOCTL] unknown ioctl\n");
    }
#endif

    printf("[SENDIOCTL] %s\n", ivshmem_strings[ivshmem_cmd]);
    rv = ioctl(fd, ivshmem_cmd, destination_vm);

#ifdef DEBUG
    printf("[SENDIOCTL] rv is %d\n", rv);
#endif
    
    return(rv);
}

int ivshmem_print_opts(void) {
    int i;
#ifdef DEBUG
    printf("ivshmem parameters: \n");
#endif
    for (i = 0; i < 7; i++) {
        printf ("%s: %d\n", ivshmem_strings[i], i);
    }

    return(0);
}
