#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "common.h"


#define BYTE_TO_PRINT 32
#define BYTE_PER_LINE 8


void print_bytes(char *base_addr) {
  for (int i = 0; i < BYTE_TO_PRINT; i++){
    printf("0x%02hhx ", base_addr[i]);
    if ((i+1) % BYTE_PER_LINE == 0) {
      printf("\n");
    }
  }
}

int main(int argc, char **argv) {
  int fd;
  char *filename;
  char *map_base;

  if (argc < 2) {
    fprintf(stderr, "need specify file path to read");
    exit(1);
  }

  filename = argv[1];
  if ((fd = open(filename, O_RDWR | O_SYNC)) == -1) print_error();
  printf("%s opened.\n", filename);

  map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if(map_base == (void *) -1) print_error();

  printf("Memory mapped to address 0x%08lx.\n", (unsigned long) map_base);
  printf("Current content in hex: \n");

  print_bytes(map_base);

  if (argc == 3) {
    printf("\nwrite %s to dev, only write 32 bytes for testing", argv[2]);
    int i = 0;
    for (i; argv[2][i] != '\0' && i < BYTE_TO_PRINT; i++) {
      map_base[i] = argv[2][i];
    }

    // overwrite left bytes
    for (i; i < BYTE_TO_PRINT; i++) {
      map_base[i] = 0x00;
    }
    printf("After writing: \n");
    print_bytes(map_base);
  }



  close(fd);
  return 0;

}
