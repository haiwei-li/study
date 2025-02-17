#include "protocol.h"
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>

int main() {
    int i, fd, *data;

    fd = shm_open(NAME, O_RDONLY, 0600);
    if (fd < 0) {
        perror ("shm_open()");
        return EXIT_FAILURE;
    }

    ftruncate(fd, SIZE);
    data = (int *) mmap(0, SIZE, PROT_READ, MAP_SHARED, fd, 0);
    printf("receiver mapped address: %p\n", data);

    for (i = 0; i < NUM; ++i) {
        printf("%d\n", data[i]);
    }

    munmap(data, SIZE);
    close(fd);
    shm_unlink(NAME);

    return EXIT_SUCCESS;
}
