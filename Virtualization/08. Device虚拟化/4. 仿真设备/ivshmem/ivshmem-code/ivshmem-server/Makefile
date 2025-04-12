CC = gcc
CFLAGS = -O3 -Wall -Werror
LIBS = -lrt

# a very simple makefile to build the inter-VM shared memory server

all: ivshmem_server

.c.o:
	$(CC) $(CFLAGS) -c $^ -o $@

ivshmem_server: ivshmem_server.o send_scm.o
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -f *.o ivshmem_server
