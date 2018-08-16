CFILES = brd.c

obj-m := brd.o

ccflags-y += -Os -Wall

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
