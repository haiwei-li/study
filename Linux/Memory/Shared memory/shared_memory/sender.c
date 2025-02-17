#include "protocol.h"
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <signal.h>
int fd, *data;

void sigterm_handler (int signo)
{
    printf("do cleanup\n");
    munmap(data, SIZE);
    close(fd);

    exit(EXIT_SUCCESS);
}


int main() {
    int i;

    signal(SIGTERM, sigterm_handler);

    fd = shm_open(NAME, O_CREAT | O_EXCL | O_RDWR, 0600);
    if (fd < 0) {
        perror ("shm_open()");
        return EXIT_FAILURE;
    }

    ftruncate(fd, SIZE);
    data = (int *) mmap(0, SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    printf("sender mapped address: %p\n", data);

    for (i = 0; i < NUM; ++i) {
        data[i] = i;
    }

    for(;;);
}
