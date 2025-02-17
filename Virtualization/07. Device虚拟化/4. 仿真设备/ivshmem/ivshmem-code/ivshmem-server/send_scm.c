#include <stdint.h>
#include <stdlib.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <poll.h>
#include "send_scm.h"

#ifndef POLLRDHUP
#define POLLRDHUP 0x2000
#endif

int readUpdate(int fd, long * posn, int * newfd)
{
    struct msghdr msg;
    struct iovec iov[1];
    struct cmsghdr *cmptr;
    size_t len;
    size_t msg_size = sizeof(int);
    char control[CMSG_SPACE(msg_size)];

    msg.msg_name = 0;
    msg.msg_namelen = 0;
    msg.msg_control = control;
    msg.msg_controllen = sizeof(control);
    msg.msg_flags = 0;
    msg.msg_iov = iov;
    msg.msg_iovlen = 1;

    iov[0].iov_base = &posn;
    iov[0].iov_len = sizeof(posn);

    do {
        len = recvmsg(fd, &msg, 0);
    } while (len == (size_t) (-1) && (errno == EINTR || errno == EAGAIN));

    printf("iov[0].buf is %ld\n", *((long *)iov[0].iov_base));
    printf("len is %ld\n", len);
    // TODO: Logging
    if (len == (size_t) (-1)) {
        perror("recvmsg()");
        return -1;
    }

    if (msg.msg_controllen < sizeof(struct cmsghdr))
        return *posn;

    for (cmptr = CMSG_FIRSTHDR(&msg); cmptr != NULL;
        cmptr = CMSG_NXTHDR(&msg, cmptr)) {
        if (cmptr->cmsg_level != SOL_SOCKET ||
            cmptr->cmsg_type != SCM_RIGHTS){
                printf("continuing %ld\n", sizeof(size_t));
                printf("read msg_size = %ld\n", msg_size);
                if (cmptr->cmsg_len != sizeof(control))
                    printf("not equal (%ld != %ld)\n",cmptr->cmsg_len,sizeof(control));
                continue;
        }

        memcpy(newfd, CMSG_DATA(cmptr), sizeof(int));
        printf("posn is %ld (fd = %d)\n", *posn, *newfd);
        return 0;
    }

    fprintf(stderr, "bad data in packet\n");
    return -1;
}

int readRights(int fd, long count, size_t count_len, int **fds, int msi_vectors)
{
    int j, newfd;

    for (; ;){
        long posn = 0;

        readUpdate(fd, &posn, &newfd);
        printf("reading posn %ld ", posn);
        fds[posn] = (int *)malloc (msi_vectors * sizeof(int));
        fds[posn][0] = newfd;
        for (j = 1; j < msi_vectors; j++) {
            readUpdate(fd, &posn, &newfd);
            fds[posn][j] = newfd;
            printf("%d.", fds[posn][j]);
        }
        printf("\n");

        /* stop reading once i've read my own eventfds */
        if (posn == count)
            break;
    }

    return 0;
}

int sendKill(int fd, long const posn, size_t posn_len) {

    struct cmsghdr *cmsg;
    size_t msg_size = sizeof(int);
    char control[CMSG_SPACE(msg_size)];
    struct iovec iov[1];
    size_t len;
    struct msghdr msg = { 0, 0, iov, 1, control, sizeof control, 0 };

    struct pollfd mypollfd;
    int rv;

    iov[0].iov_base = (void *) &posn;
    iov[0].iov_len = posn_len;

    // from cmsg(3)
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_len = 0;
    msg.msg_controllen = cmsg->cmsg_len;

    printf("Killing posn %ld\n", posn);

    // check if the fd is dead or not
    mypollfd.fd = fd;
    mypollfd.events = POLLRDHUP;
    mypollfd.revents = 0;

    rv = poll(&mypollfd, 1, 0);

    printf("rv is %d\n", rv);

    if (rv == 0) {
        len = sendmsg(fd, &msg, 0);
        if (len == (size_t) (-1)) {
            perror("sendmsg()");
            return -1;
        }
        return (len == posn_len);
    } else {
        printf("already dead\n");
        return 0;
    }
}

int sendUpdate(int fd, long posn, size_t posn_len, int sendfd)
{

    struct cmsghdr *cmsg;
    size_t msg_size = sizeof(int);
    char control[CMSG_SPACE(msg_size)];
    struct iovec iov[1];
    size_t len;
    struct msghdr msg = { 0, 0, iov, 1, control, sizeof control, 0 };

    iov[0].iov_base = (void *) (&posn);
    iov[0].iov_len = posn_len;

    // from cmsg(3)
    cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(msg_size);
    msg.msg_controllen = cmsg->cmsg_len;

    memcpy((CMSG_DATA(cmsg)), &sendfd, msg_size);

    len = sendmsg(fd, &msg, 0);
    if (len == (size_t) (-1)) {
        perror("sendmsg()");
        return -1;
    }

    return (len == posn_len);

}

int sendPosition(int fd, long const posn)
{
    int rv;

    rv = send(fd, &posn, sizeof(long), 0);
    if (rv != sizeof(long)) {
        fprintf(stderr, "error sending posn\n");
        return -1;
    }

    return 0;
}

int sendRights(int fd, long const count, size_t count_len, vmguest_t * Live_vms,
                                                            long msi_vectors)
{
    /* updates about new guests are sent one at a time */

    long i, j;

    for (i = 0; i <= count; i++) {
        if (Live_vms[i].alive) {
            for (j = 0; j < msi_vectors; j++) {
                sendUpdate(Live_vms[count].sockfd, i, sizeof(long),
                                                        Live_vms[i].efd[j]);
            }
        }
    }

    return 0;

}
