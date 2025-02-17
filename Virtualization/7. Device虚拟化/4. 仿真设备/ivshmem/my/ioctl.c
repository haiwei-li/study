#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <assert.h>


#define IOCTL_MAGIC         ('f')
#define IOCTL_RING          _IOW(IOCTL_MAGIC, 1, __u32)
#define IOCTL_WAIT          _IO(IOCTL_MAGIC, 2)
#define IOCTL_IVPOSITION    _IOR(IOCTL_MAGIC, 3, __u32)

static void usage(void)
{
    printf("Usage: \n"  \
           "  ioctl <devfile> ivposition\n"    \
           "  ioctl <devfile> wait\n"          \
           "  ioctl <devfile> ring <peer_id> <vector_id>\n");
}


int main(int argc, char **argv)
{
    int fd, arg, ret, vector, peer;

    if (argc < 3) {
        usage();
        return -1;
    }

    fd = open(argv[1], O_RDWR);
    assert(fd != -1);

    ret = ioctl(fd, IOCTL_IVPOSITION, &peer);
    printf("IVPOSITION: %d\n", peer);

    if (strcmp(argv[2], "ivposition") == 0) {
        return 0;

    } if (strcmp(argv[2], "wait") == 0) {
        if (argc != 3) {
            usage();
            return -1;
        }
        printf("wait:\n");
        ret = ioctl(fd, IOCTL_WAIT, &arg);

    } else if (strcmp(argv[2], "ring") == 0) {
        if (argc != 5) {
            usage();
            return -1;
        }
        printf("ring:\n");
        peer = atoi(argv[3]);
        vector = atoi(argv[4]);

        arg = ((peer & 0xffff) << 16) | (vector & 0xffff);
        printf("arg: 0x%x\n", arg);

        ret = ioctl(fd, IOCTL_RING, &arg);

    } else {
        printf("Invalid command: %s\n", argv[2]);
        usage();
        return -1;
    }

    printf("ioctl finished, returned value: %d\n", ret);

    close(fd);

    return 0;
}