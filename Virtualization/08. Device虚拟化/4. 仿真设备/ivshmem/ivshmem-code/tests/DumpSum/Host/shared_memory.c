#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>
#include <errno.h>

struct cams_test {

	int x;

};

int main(void){

	int fd;
	void * addr;
	char fname[]="/kvmci";
	int ret,first=0;
	struct cams_test * conf;
	
	conf=(struct cams_test *)valloc(sizeof(struct cams_test));	
	printf("conf is %p\n", conf);	
	
//	ret=shm_unlink(fname);
	printf("ret is %d\n", ret);	

	/* file will be created in /dev/shm */
	if ((fd=shm_open(fname, O_CREAT|O_RDWR|O_EXCL, S_IREAD | S_IWRITE)) > 0) {
		printf("I'm first\n");
		first=1;
	} else if ((fd=shm_open(fname, O_CREAT|O_RDWR, S_IREAD | S_IWRITE)) > 0) {
		printf("I'm second\n");	
	} else {
		printf("Could not allocate space %s\n", strerror(errno));
		return errno;
	}
	
	if (fd<0)
		printf("shm_open failed with %d\n", fd);	
	else printf("fd is %d\n", fd);

	ftruncate(fd, sizeof(struct cams_test));
	addr=mmap(conf, sizeof(conf), PROT_READ|PROT_WRITE, MAP_SHARED|MAP_FIXED, fd, 0);

	printf("addr is %p\n", addr);	

	conf=addr;
	if (first) 
		conf->x=5	;
	else {
		printf("conf is %d\n", conf->x);
	}

#if 0
	if (first){
		sleep(60);
		munmap(addr, sizeof(conf));
		shm_unlink(fname);
	}
#endif	
}
