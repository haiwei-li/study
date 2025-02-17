#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

int main(int argc, char ** argv){

	int ret;
		
	ret=shm_unlink(argv[1]);
	printf("unlinking %s\nret is %d\n", argv[1], ret);	

}
