CC=gcc
CFLAGS= -g -lcrypto -lrt -lpthread

all:	trylock	guestlock 

guestlock:	guestlock.c
	$(CC) $^ -o $@ $(CFLAGS)

trylock:	trylock.c
	$(CC) $^ -o $@ $(CFLAGS)

clean:
	rm -f guestlock trylock
