# ARMv8 Startup Example Makefile
#
# Copyright (C) ARM Limited, 2013. All rights reserved.
#
# This makefile is intended for use with GNU make
# This example is intended to be built with ARM Compiler 6

EXECUTABLE=image.axf

ASFLAGS= -gdwarf-3 -c --target=aarch64-arm-none-eabi
CFLAGS=  -gdwarf-3 -c --target=aarch64-arm-none-eabi -I"./headers"

CC=armclang
AS=armclang
LD=armlink

# Select build rules based on Windows or Unix
ifdef WINDIR
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(WINDIR)\system32\cmd.exe
else
ifdef windir
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(windir)\system32\cmd.exe
else
DONE=@if [ -f $(1) ]; then if [ -f $(2) ]; then echo Build completed.; fi; fi
RM=rm -f $(1)
endif
endif

all: $(EXECUTABLE)
	$(call DONE,$(EXECUTABLE))

rebuild: clean all

clean:
	$(call RM,*.o)
	$(call RM,$(EXECUTABLE))

main.o: ./src/main.c
	$(CC) ${CFLAGS} ./src/main.c

gicv3_basic.o: ./src/gicv3_basic.c
	$(CC) ${CFLAGS} ./src/gicv3_basic.c

system_counter.o: ./src/system_counter.c
	$(CC) ${CFLAGS} ./src/system_counter.c

startup.o: ./src/startup.s
	$(AS) ${ASFLAGS} ./src/startup.s

el3_vectors.o: ./src/el3_vectors.s
	$(AS) ${ASFLAGS} ./src/el3_vectors.s

generic_timer.o: ./src/generic_timer.s
	$(AS) ${ASFLAGS} ./src/generic_timer.s

gicv3_cpuif.o: ./src/gicv3_cpuif.S
	$(AS) ${ASFLAGS} ./src/gicv3_cpuif.S

$(EXECUTABLE): main.o generic_timer.o system_counter.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter.txt main.o generic_timer.o system_counter.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o -o $@ --entry=start64

