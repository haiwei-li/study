#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <fcntl.h>

#define FILE_NAME "huge/hugepagefile"
#define LENGTH (256UL*1024*1024)
#define PROTECTION (PROT_READ | PROT_WRITE)

/* Only ia64 requires this */
#ifdef __ia64__
#define ADDR (void *)(0x8000000000000000UL)
#define FLAGS (MAP_SHARED | MAP_FIXED)
#else
#define ADDR (void *)(0x0UL)
#define FLAGS (MAP_SHARED)
#endif

static void check_bytes(char *addr)
{
    printf("First hex is %x\n", *((unsigned int *)addr));
}

static void write_bytes(char *addr)
{
    unsigned long i;

    for (i = 0; i < LENGTH; i++)
        *(addr + i) = (char)i;
}

static int read_bytes(char *addr)
{
    unsigned long i;

    check_bytes(addr);
    for (i = 0; i < LENGTH; i++)
        if (*(addr + i) != (char)i) {
            printf("Mismatch at %lu\n", i);
            return 1;
        }
    return 0;
}

int main(void)
{
    void *addr;
    int fd, ret;

    fd = open(FILE_NAME, O_CREAT | O_RDWR, 0755);
    if (fd < 0) {
        perror("Open failed");
        exit(1);
    }

    addr = mmap(ADDR, LENGTH, PROTECTION, FLAGS, fd, 0);
    if (addr == MAP_FAILED) {
        perror("mmap");
        unlink(FILE_NAME);
        exit(1);
    }

    printf("Returned address is %p\n", addr);
    check_bytes(addr);
    write_bytes(addr);
    ret = read_bytes(addr);

    sleep(10);

    munmap(addr, LENGTH);
    close(fd);
    unlink(FILE_NAME);

    return ret;
}