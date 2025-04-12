CC=gcc
CFLAGS = -lrt

all: readpci trigger userctl
readpci: rwpci.c
	$(CC) -o rwpci rwpci.c $(CFLAGS)
trigger: trigger.c
	$(CC) -o trigger trigger.c $(CFLAGS)
userctl: userctl.c
	$(CC) -o userctl userctl.c
clean:
	rm -f rwpci trigger userctl
