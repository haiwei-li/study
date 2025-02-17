#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

#include <sys/ipc.h>
#include <sys/shm.h>

/* ---------------------------------- */
/*         hugepage defination        */
/* ---------------------------------- */
#define HUGEPAGE_SIZE(count)    ((count)*2UL*1024UL*1024UL)

struct hugepage {
        key_t key;
        int id;
        size_t size;
        void *address;
};

int hugepage_open(struct hugepage *hugepage, key_t key, size_t size);
void hugepage_close(struct hugepage *hugepage);
void hugepage_dump(struct hugepage *hugepage);

/* ---------------------------------- */
/*             main                   */
/* ---------------------------------- */
#define DEFAULT_KEY             (0x11111)
#define DEFAULT_COUNT   (1)

int main(int argc, char *argv[])
{
        struct hugepage hugepage;
        int error_code;
        int count;
        size_t hugepage_count = DEFAULT_COUNT;

        if (argc > 1) {
                count = atoi(argv[1]);
                if (count <= 0) {
                        printf("usage: %s <hugepage_count>\n", argv[0]);
                        goto fail_user_input;
                }
                hugepage_count = (size_t)count;
        }

        error_code = hugepage_open(&hugepage
                , DEFAULT_KEY
                , HUGEPAGE_SIZE(hugepage_count));

        if (0 != error_code) {
                goto fail_open;
        }

        printf("hugepage allocated: \n");
        hugepage_dump(&hugepage);

        printf("Press any key to access hugepage!\n");
        getchar();
        memset(hugepage.address, 0, hugepage.size);

        printf("Press any key to free hugepage and exit!\n");
        getchar();
        hugepage_close(&hugepage);

        return 0;

fail_open:
        perror("hugepage open fail");
fail_user_input:
        return -1;
}

/* ---------------------------------- */
/*         hugepage implement         */
/* ---------------------------------- */

int hugepage_open(struct hugepage *hugepage, key_t key, size_t size)
{
        int id;
        void *address;

        if (NULL == hugepage) {
                return -EINVAL;
        }

        /* create */
        /* 创建了一个共享内存区域 */
        /* 在特殊文件系统shm中, 创建并打开一个同名文件 */
        id = shmget(key
                        , size
                        , SHM_HUGETLB | IPC_CREAT | SHM_R | SHM_W
                        );

        if (id < 0) {
                goto fail_create;
        }

        /* get address */
        /* 将共享内存区域映射到进程地址空间 */
        address = shmat(id, NULL, 0);
        if ((void *)-1 == address) {
                goto fail_get_address;
        }

        hugepage->key = key;
        hugepage->id = id;
        hugepage->size = size;
        hugepage->address = address;

        return 0;

        /* error handle */
fail_get_address:
        shmctl(id, IPC_RMID, NULL);
fail_create:
        return -EAGAIN;
}


void hugepage_close(struct hugepage *hugepage)
{
        if (NULL == hugepage
        ||  0 == hugepage->id) {
                return ;
        }

        shmctl(hugepage->id, IPC_RMID, NULL);
}


void hugepage_dump(struct hugepage *hugepage)
{

        if (NULL == hugepage) {
                return ;
        }

        printf(
                "hugepage(%p) = {\n"
                "  key = 0x%x\n"
                "  id = %u\n"
                "  size = %llu\n"
                "  address = %p\n"
                "}\n"
                , hugepage
                , hugepage->key
                , hugepage->id
                , hugepage->size
                , hugepage->address
                );
}
