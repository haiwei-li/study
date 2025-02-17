#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <fcntl.h>
#include <string.h>
#include <openssl/sha.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <errno.h>

int main(int argc, char ** argv){

	pthread_spinlock_t * sl1;
	int rv,fd;
	int * count;
	short rv_short;
	int i,x=0;
	void * map_region;
	char * file;

	if (argc!=2){
		fprintf(stderr, "USAGE: guestlock <file>\n");
		exit(-1);	
	}
	
	file=strdup(argv[1]);	
	

	if ((fd=open(file, O_RDWR)) < 0){
		fprintf(stderr, "ERROR: cannot open file\n");
		exit(-1);
	}

	printf("[SENDIOCTL] sending ioctl to %s\n", file);
	rv = ioctl(fd,2,NULL);
	printf("[SENDIOCTL] rv is %d\n", rv);
	close(fd);

	printf("[SENDIOCTL] exiting\n");
/*	
	rv=pthread_spin_trylock(sl1);
	printf("retval is %d\n", rv);

	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv); 
*/

/*	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv);

	rv=pthread_spin_lock(sl1);
	printf("retval is %d\n", rv);
*/
}
