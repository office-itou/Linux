targets		:= srdev
sources		:= ../dev/sr_device.c  \
			   ../dev/sr_gpcmd.c   \
			   ../lib/my_cdrom.c
objects 	:= $(sources:.c=.o)
headers		:= ../dev/sr_device.h  \
			   ../lib/my_library.h \
			   ../lib/my_cdrom.h
cflags		:= -Wall -O3 \
			   -I../dev/ \
			   -I../lib/
obj-m		:= $(targets).o
$(targets)-y:= $(objects)

.PHONY		: all
all			:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules

.PHONY		: clean
clean		:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
