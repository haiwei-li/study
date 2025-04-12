#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <errno.h>

int main(int argc, char ** argv){

	int fd, length=4*1024;
	void * memptr;
	long * long_array;
	int i;
	SHA_CTX context;
	char md[20];

	if (argc != 3){
		printf("USAGE: test_shmem <filename> <size>\n");
		exit(-1);
	}

	printf("opening file %s\n", argv[1]);
	length=atoi(argv[2])*1024*1024;
//	length=atoi(argv[2]);
	printf("size is %d\n", length);

	fd=open(argv[1], O_RDWR);
	printf("fd = %d\n", fd);

	if ((memptr = mmap(NULL, length, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)) == (caddr_t)-1){
		printf("mmap failed (0x%x)\n", memptr);
		close (fd);
		exit (-1);
	}

	srand(time());
	long_array=(long *)memptr;
	for (i=0; i < length/sizeof(long); i++){
		long_array[i]=rand();	
	}

	memset(md,0,20);

	SHA1_Init(&context);
	SHA1_Update(&context,memptr,length);
	SHA1_Final(md,&context);

	printf("[DUMP] ");	
	for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
	{
    		unsigned char c = md[i];
	        printf("%2.2x",c);
  	}
	printf("\n");	

	printf("munmap is unmapping %x\n", memptr);
	munmap(memptr, length);

	printf("fd is %d\n", fd);
	close(fd);

}
