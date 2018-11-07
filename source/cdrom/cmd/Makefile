targets		:= sr_mount
sources		:= sr_mount.c          \
			   ../lib/my_library.c \
			   ../lib/my_cdrom.c
objects 	:= $(sources:.c=.o)
headers		:= ../knl/sr_module.h  \
			   ../lib/my_library.h \
			   ../lib/my_cdrom.h
cflags		:= -Wall -O3 \
			   -I../knl/ \
			   -I../lib/

$(targets)	: $(sources)
	gcc $(cflags) -o $@ $^

.PHONY		: all
all			: $(objects)

.PHONY		: clean
clean		:
	rm -f $(targets) $(objects)
