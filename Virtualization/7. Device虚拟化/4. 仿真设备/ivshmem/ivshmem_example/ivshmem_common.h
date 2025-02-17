#ifndef IVSHMEM_COMMON_H
#define IVSHMEM_COMMON_H

#define CMD_READ_SHMEM _IOR('i', 1, int)
#define CMD_READ_VMID _IOR('i', 2, int)
#define CMD_INTERRUPT _IOW('i', 3, int)

typedef struct{
  int dest_id;
  int msg;
} irq_arg;

#endif
