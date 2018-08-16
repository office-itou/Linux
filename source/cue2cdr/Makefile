PROGRAM		=	cue2cdr
OBJS		=	cue2cdr.o
CFLAGS		=	-Os -Wall

all			:	$(PROGRAM)

clean		:;	rm -f *.o *~ $(PROGRAM)

$(PROGRAM)	:	$(OBJS)
				$(CC) $(OBJS) $(LDFLAGS) $(LIBS) -o $(PROGRAM)
