#ifndef _FTP_H
#define _FTP_H

#include <pthread.h>

#define CHUNK_SZ  (16*1024*1024)
#define NEXT(i)   ((i + 1) % 15)
#define OFFSET(i) (i * CHUNK_SZ)

#define FLOCK_LOC memptr
#define FULL_LOC  FLOCK_LOC + sizeof(pthread_spinlock_t)
#define ELOCK_LOC FULL_LOC + sizeof(int)
#define EMPTY_LOC ELOCK_LOC + sizeof(pthread_spinlock_t)
#define BUF_LOC   (memptr + CHUNK_SZ)

#endif /* _FTP_H */
