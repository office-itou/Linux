targets		:= sr_test
sources		:= sr_test.c ../knl/sr_common.c
objects 	:= $(sources:.c=.o)
headers		:= ../knl/sr_emu.h
cflags		:= -Wall -I../knl/

$(targets)	: $(sources)
	gcc -O $(cflags) -o $@ $^

.PHONY		: all
all			: $(objects)

.PHONY		: clean
clean		:
	rm -f $(targets) $(objects)
