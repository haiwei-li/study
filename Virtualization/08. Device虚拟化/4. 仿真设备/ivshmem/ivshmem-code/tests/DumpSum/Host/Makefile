CC=gcc
CFLAGS= -g -lcrypto -lrt

all: sum dump unlink_mem

sum:	sum.c
	$(CC) $^ -o $@ $(CFLAGS)

dump:	dump.c
	$(CC) $^ -o $@ $(CFLAGS)

unlink_mem:	unlink_mem.c
	$(CC) $^ -o $@ $(CFLAGS)

clean:
	rm -f sum dump unlink_mem
