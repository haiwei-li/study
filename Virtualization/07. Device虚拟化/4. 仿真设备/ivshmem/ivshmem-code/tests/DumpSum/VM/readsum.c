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
	long randnum, half;

	if (argc != 3){
		printf("USAGE: sum <filename> <size>\n");
		exit(-1);
	}

	printf("[SUM] opening file %s\n", argv[1]);
	length=atoi(argv[2])*1024*1024;
//	length=atoi(argv[2]);
	printf("[SUM] size is %d\n", length);

	fd=open(argv[1], O_RDWR);

	srand(time());

    	memset(md,0,20);
	SHA1_Init(&context);
	for (i=0; i < length/sizeof(long); i++){
		int n;

        	n=read(fd, &randnum, sizeof(long));
		SHA1_Update(&context,&randnum,sizeof(long));
	        if (n<sizeof(long)){
        		printf("[ERROR] read %d bytes!\n", n);
	        }
	}
	SHA1_Final(md,&context);
	
    	close(fd);

	printf("[SUM] ");
	for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
	{
    		unsigned char c = md[i];
	        printf("%2.2x",c);
  	}
	printf("\n");

	printf("munmap is unmapping %x\n", memptr);


}
