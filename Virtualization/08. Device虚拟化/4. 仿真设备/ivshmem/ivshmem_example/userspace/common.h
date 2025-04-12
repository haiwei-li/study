#ifndef COMMON_H
#define COMMON_H

#define MAP_SIZE 4096UL
void print_error() {
  fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", \
  __LINE__, __FILE__, errno, strerror(errno));
   exit(1);
}

#endif
