#ifndef SEND_SCM
#define SEND_SCM

struct vm_guest_conn {
    int posn;
    int sockfd;
    int * efd;
    int alive;
};

typedef struct vm_guest_conn vmguest_t;

int readRights(int fd, long count, size_t count_len, int **fds, int msi_vectors);
int sendRights(int fd, long const count, size_t count_len, vmguest_t *Live_vms, long msi_vectors);
int readUpdate(int fd, long * posn, int * newfd);
int sendUpdate(int fd, long const posn, size_t posn_len, int sendfd);
int sendPosition(int fd, long const posn);
int sendKill(int fd, long const posn, size_t posn_len);
#endif
