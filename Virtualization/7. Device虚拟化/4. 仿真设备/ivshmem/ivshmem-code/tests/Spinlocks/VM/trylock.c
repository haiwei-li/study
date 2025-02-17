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
	
	printf("[GUESTLOCK] locking on file %s\n", file);

	if ((fd=open(file, O_RDWR)) < 0){
		fprintf(stderr, "ERROR: cannot open file\n");
		exit(-1);
	}

	if ((map_region=mmap(NULL, 1024, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0))<0){
		fprintf(stderr, "ERROR: cannot mmap file\n");
	} else {
		printf("[GRABLOCK] mapped to %p\n", map_region);
	}

	sl1=map_region;
	count=map_region + sizeof(pthread_spinlock_t);

	printf("[GRABLOCK] init locking (0x%x)\n", sl1);
//	pthread_spin_init(sl1, PTHREAD_PROCESS_SHARED);

	/* this would lock the lock */

	rv=pthread_spin_trylock(sl1);

	printf("rv=%d\n",rv);
	sleep(1);

	/* close the file and unmap the region */
	pthread_spin_destroy(sl1);
	munmap(map_region,1024);
	close(fd);

	printf("[GRABLOCK] exiting\n");
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
