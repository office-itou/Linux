targets		:= sr_test
sources		:= sr_test.c
objects 	:= $(sources:.c=.o)
headers		:= 
cflags		:= -Wall -O3

$(targets)	: $(sources)
	gcc $(cflags) -o $@ $^

.PHONY		: all
all			: $(objects)

.PHONY		: clean
clean		:
	rm -f $(targets) $(objects)
