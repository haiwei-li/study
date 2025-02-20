CC=gcc
CFLAGS= -g -lcrypto -lrt

all: sum dump

sum:	sum.c
	$(CC) $^ -o $@ $(CFLAGS)

dump:	dump.c
	$(CC) $^ -o $@ $(CFLAGS)

clean:
	rm -f sum dump
