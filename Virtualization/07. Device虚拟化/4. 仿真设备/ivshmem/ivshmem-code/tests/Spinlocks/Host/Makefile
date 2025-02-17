CC=gcc
CFLAGS= -g -lcrypto -lrt -lpthread

all:	grablock 	testlock 

testlock:	testlock.c
	$(CC) $^ -o $@ $(CFLAGS)

grablock:	grablock.c
	$(CC) $^ -o $@ $(CFLAGS)

clean:
	rm -f testlock grablock 
