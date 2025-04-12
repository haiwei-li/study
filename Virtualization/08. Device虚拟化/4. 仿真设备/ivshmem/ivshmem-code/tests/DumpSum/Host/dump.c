#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

int main(int argc, char ** argv){

	long size;
	char file[1024];
	void * map_region;
	long * long_array;
	int i,fd;
	SHA_CTX context;
	unsigned char md[20];
	struct test * myptr;

	if (argc!=3){
		fprintf(stderr, "USAGE: dump <file> <size in MB>\n");
		exit(-1);	
	}

	size=atol(argv[2])*1024*1024;
	memset(file,0,1024);
	snprintf(file, 1024, "/%s",argv[1]);	
	
	printf("[DUMP] filling %d bytes into %s with random numbers\n", size, file);

	if ((fd=shm_open(file, O_CREAT|O_RDWR|O_EXCL, S_IREAD | S_IWRITE)) > 0){
		printf("[DUMP] first\n");
	}
	else if ((fd=shm_open(file, O_CREAT|O_RDWR, S_IREAD | S_IWRITE)) > 0){
		printf("[DUMP] second\n");
	} else {
		fprintf(stderr, "ERROR: cannot open file\n");
		exit(-1);
	}

	if ((map_region=mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0))<0){
		fprintf(stderr, "ERROR: cannot mmap file\n");
	} else {
		printf("[DUMP] mapped to %p\n", map_region);
	}

	srand(time());
	long_array=(long *)map_region;
	for (i=0; i < size/sizeof(long); i++){
		long_array[i]=rand();	
	}

	memset(md,0,20);

	SHA1_Init(&context);
	SHA1_Update(&context,map_region,size);
	SHA1_Final(md,&context);

	printf("[DUMP] ");	
	for(i = 0; i < SHA_DIGEST_LENGTH; ++i )
	{
    		unsigned char c = md[i];
	        printf("%2.2x",c);
  	}
	printf("\n");	

//	printf("md is *%20s*\n", md);

	munmap(map_region,size);
	close(fd);
//	shm_unlink(file);
		
	printf("[DUMP] Exiting...\n");
}
