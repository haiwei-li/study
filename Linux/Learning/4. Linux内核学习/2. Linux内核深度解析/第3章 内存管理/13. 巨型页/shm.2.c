#include <stdlib.h>
#include <stdio.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/mman.h>

#ifndef SHM_HUGETLB
#define SHM_HUGETLB 04000
#endif

#define LENGTH (256UL*1024*1024)

#define dprintf(x)  printf(x)

/* Only ia64 requires this */
#ifdef __ia64__
#define ADDR (void *)(0x8000000000000000UL)
#define SHMAT_FLAGS (SHM_RND)
#else
#define ADDR (void *)(0x0UL)
#define SHMAT_FLAGS (0)
#endif

int main(void)
{
    int shmid;
    unsigned long i;
    char *shmaddr;

    shmid = shmget(0x12345678, LENGTH, SHM_HUGETLB | IPC_CREAT | SHM_R | SHM_W);
    if (shmid < 0) {
        perror("shmget");
        exit(1);
    }
    printf("shmid: %d\n", shmid);

    shmaddr = shmat(shmid, ADDR, SHMAT_FLAGS);
    if (shmaddr == (char *)-1) {
        perror("Shared memory attach failure");
        shmctl(shmid, IPC_RMID, NULL);
        exit(2);
    }
    printf("shmaddr: %p\n", shmaddr);

    dprintf("Starting the writes:\n");
    for (i = 0; i < LENGTH; i++) {
        shmaddr[i] = (char)(i);
        if (!(i % (1024 * 1024)))
            dprintf(".");
    }
    dprintf("\n");

    dprintf("Starting the Check...");
    for (i = 0; i < LENGTH; i++)
        if (shmaddr[i] != (char)i) {
            printf("\nIndex %lu mismatched\n", i);
            exit(3);
        }
    dprintf("Done.\n");
    sleep(10);

    if (shmdt((const void *)shmaddr) != 0) {
        perror("Detach failure");
        shmctl(shmid, IPC_RMID, NULL);
        exit(4);
    }

    shmctl(shmid, IPC_RMID, NULL);

    return 0;
}