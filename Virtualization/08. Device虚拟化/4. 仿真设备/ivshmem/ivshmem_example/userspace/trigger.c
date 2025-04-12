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

#define DOORBELL_OFFSET 12

int main(int argc, char **argv) {
  int fd;
  char *filename;
  void *map_base, *dest;

  // peer_id = 0, vector = 0;
  unsigned long msg = 0;

  if (argc < 2) {
    fprintf(stderr, "Usage: ./trigger <path_to_pci_resource1>");
    exit(1);
  }

  filename = argv[1];
  if ((fd = open(filename, O_RDWR | O_SYNC)) == -1) print_error();
  printf("%s opened.\n", filename);

  map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
  if(map_base == (void *) -1) print_error();

  printf("Memory mapped to address 0x%08lx.\n", (unsigned long) map_base);

  dest = map_base + DOORBELL_OFFSET;
  // write message to dest
  *((unsigned long *) dest) = msg;

  close(fd);

  return 0;
}
