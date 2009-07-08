/*
 * Shuffle the lines in a file. See shuffle.1 for manual.
 * (Original: http://www.w3.org/People/Bos/Shuffle)
 *
 * Reads all lines into memory, then writes them out in arbitrary order.
 * Tries to use mmap() first, but if that fails, uses read().
 * The idea is that mmap() should be faster than read() + realloc()...
 *
 * Author: Bert Bos <bert@w3.org>
 * Created: 12 April 1999
 * Version: $Id: shuffle.c,v 1.5 2005/05/30 16:43:30 bbos Exp $
 *
 * This is Open Source software, see http://www.w3.org/Consortium/Legal/
 *
 * Copyright © 1995-2005 World Wide Web Consortium, (Massachusetts
 * Institute of Technology, ERCIM, Keio University). All Rights Reserved.
 */

#include <sys/mman.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

#ifndef MAP_FAILED
#define	MAP_FAILED ((void *) -1)
#endif

#define BUFINC 8096


/* fatal -- print message and exit */
static void fatal(char *msg1, char *msg2)
{
  (void) write(2, msg1, strlen(msg1));
  (void) write(2, ": ", 2);
  (void) write(2, msg2, strlen(msg2));
  exit(1);
}

/* syserr -- print system error and exit */
static void syserr(char *msg)
{
  fatal(msg, strerror(errno));
}

/* swap -- swap two integers */
static void swap(int *a, int *b)
{
  int h;
  h = *a;
  *a = *b;
  *b = h;
}

/* main -- read lines, shuffle and write them */
int main(int argc, char *argv[])
{
  int in = 0, out = 1;
  int nlines, i, j, ismmap;
  off_t len;
  char *buf;
  int *lines, *shuffle;

  /* Open input and output */
  if (argc > 3) fatal("Usage", "shuffle [infile [outfile]]\n");
  if (argc > 2 && strcmp(argv[2], "-") != 0
      && (out = open(argv[2], O_WRONLY|O_CREAT)) < 0) syserr(argv[2]);
  if (argc > 1 && strcmp(argv[1], "-") != 0
      && (in = open(argv[1], O_RDONLY)) < 0) syserr(argv[1]);

  /* Map file into memory, either via mmap or read */
  ismmap = (len = lseek(in, 0, SEEK_END)) >= 0;
  if (ismmap) {					/* Real file, so try mmap */
    buf = mmap(NULL, len, PROT_READ, MAP_PRIVATE, in, 0);
    if (buf == MAP_FAILED) syserr(argv[0]);
  } else {					/* Cannot seek, try read */
    if (! (buf = malloc(BUFINC))) syserr(argv[0]);
    for (len = 0; (i = read(in, buf + len, BUFINC)) > 0; len += i)
      if (! (buf = realloc(buf, len + i + BUFINC))) syserr(argv[0]);
    if (i < 0) syserr(argv[0]);
  }

  /* Find the # of lines */
  for (i = 0, nlines = 0; i < len; i++) if (buf[i] == '\n') nlines++;
  if (len > 0 && buf[len-1] != '\n') fatal(argv[0],"Missing newline at eof\n");

  /* Allocate arrays of indexes into buf and indexes into index */
  if (! (lines = malloc((nlines + 1) * sizeof(lines[0])))) syserr(argv[0]);
  if (! (shuffle = malloc((nlines + 1) * sizeof(shuffle[0])))) syserr(argv[0]);

  /* Find the start & end of each line again */
  lines[0] = 0;
  for (i = 0, j = 1; i < len; i++) if (buf[i] == '\n') lines[j++] = i + 1;

  /* Shuffle the shuffle array */
  for (i = 0; i < nlines; i++) shuffle[i] = i;
  srandom(time(NULL));
  for (i = 0; i < nlines; i++)
    swap(&shuffle[i], &shuffle[i + random() % (nlines - i)]);

  /* Write out the shuffled lines */
  for (i = 0; i < nlines; i++) {
    j = shuffle[i];
    if (write(out, buf + lines[j], lines[j+1] - lines[j]) < 0) syserr(argv[0]);
  }

  /* Let's be good and explicitly unmap, free, close, etc. everything */
  if (ismmap && munmap(buf, len) < 0) syserr(argv[0]);
  if (!ismmap) free(buf);
  if (close(in) < 0) syserr(argv[0]);
  if (close(out) < 0) syserr(argv[0]);
  free(shuffle);
  free(lines);

  return 0;
}
