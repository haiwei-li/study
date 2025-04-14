.PHONY: all

all: sender receiver

sender: sender.c
	gcc -o sender sender.c -lrt

receiver: receiver.c
	gcc -o receiver receiver.c -lrt

clean:
	rm -f sender receiver
