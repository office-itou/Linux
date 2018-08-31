## Process this file with automake to produce Makefile.in

AM_CPPFLAGS = -Wall -D_FILE_OFFSET_BITS=64 -pthread
noinst_PROGRAMS = t_cdrom
t_cdromdir = .
t_cdrom_SOURCES = t_cdrom.c my_file.c my_string.c my_cdrom.c
t_cdrom_HEADERS = my_common.h
LIBS = -lfuse

## autoreconf --INSTALL && autoheader && automake -a -c && ./configure ##
