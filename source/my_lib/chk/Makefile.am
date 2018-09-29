# -----------------------------------------------------------------------------
AUTOMAKE_OPTIONS = subdir-objects
noinst_PROGRAMS = t_cdrom t_cdrom_read_toc t_copy
# -----------------------------------------------------------------------------
t_cdrom_SOURCES = t_cdrom.c
t_cdrom_LDADD = ../lib/libmy.a
t_cdrom_CFLAGS = -Wall -I../lib/
t_cdromdir = .
# -----------------------------------------------------------------------------
t_cdrom_read_toc_SOURCES = t_cdrom_read_toc.c
t_cdrom_read_toc_LDADD = ../lib/libmy.a
t_cdrom_read_toc_CFLAGS = -Wall -I../lib/
t_cdrom_read_tocdir = .
# -----------------------------------------------------------------------------
t_copy_SOURCES = t_copy.c
t_copy_LDADD = ../lib/libmy.a
t_copy_CFLAGS = -Wall -I../lib/
t_copydir = .
# -----------------------------------------------------------------------------
## autoreconf --INSTALL && autoheader && automake -a -c && ./configure ##
