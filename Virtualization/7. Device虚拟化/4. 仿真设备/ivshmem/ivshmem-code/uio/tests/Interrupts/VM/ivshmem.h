#ifndef IVSHMEM_HDR
#define IVSHMEM_HDR

int ivshmem_send(void *, int ivshmem_cmd, int destination_vm);
int ivshmem_recv(int fd);
void ivshmem_print_opts(void);

#endif
