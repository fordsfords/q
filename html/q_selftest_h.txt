/* q_selftest.h - unit test for q module.  See http://geeky-boy.com/q/ */
/* Only included when q.c is built with "-DSELFTEST" */
/*
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.
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
