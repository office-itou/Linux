targets		:= sremu
sources		:= sr_module.c         \
			   sr_gpcmd.c          \
			   ../lib/my_library.c \
			   ../lib/my_cdrom.c
objects		:= $(sources:.c=.o)
headers		:= sr_module.h         \
			   ../lib/my_library.h \
			   ../lib/my_cdrom.h
cflags		:= -Wall -O3 \
			   -I../lib/
obj-m		:= $(targets).o
$(targets)-y:= $(objects)

.PHONY		: all
all			:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules

.PHONY		: clean
clean		:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
