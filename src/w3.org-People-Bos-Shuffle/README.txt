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
 * Copyright � 1995-2005 World Wide Web Consortium, (Massachusetts
 * Institute of Technology, ERCIM, Keio University). All Rights Reserved.
 */
