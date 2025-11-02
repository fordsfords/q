/* q_selftest.h - unit test for q module.  See https://github.com/fordsfords/q/tree/gh-pages */
/* Only included when q.c is built with "-DSELFTEST" */

/* This work is dedicated to the public domain under CC0 1.0 Universal:
 * http://creativecommons.org/publicdomain/zero/1.0/
 * 
 * To the extent possible under law, Steven Ford has waived all copyright
 * and related or neighboring rights to this work. In other words, you can 
 * use this code for any purpose without any restrictions.
 * This work is published from: United States.
 * Project home: https://github.com/fordsfords/q
 */

#include <unistd.h>
#include <pthread.h>
#include <string.h>
#include <errno.h>
#include <sys/time.h>
#include <stdio.h>

/* some platforms require the program to declare these external */
extern char *optarg;
extern int optind;
extern int optopt;
extern int opterr;
extern int optreset;
