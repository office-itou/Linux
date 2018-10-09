obj-m		:= sremu.o
sremu-y		:= sr_emu.o sr_common.o
cflags-y	+= -Wall -I../knl/

.PHONY		: all
all			:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules

.PHONY		: clean
clean		:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
