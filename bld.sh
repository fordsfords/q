#!/bin/sh
# bld.sh
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.

OS=`uname`

CACHE_LINE_SIZE=64 # x86, sparc
# CACHE_LINE_SIZE=128 # Itanium, PowerPC

COPTS="-g -O3 -DCACHE_LINE_SIZE=$CACHE_LINE_SIZE -pthread"; LIBS=""

rm -f *.o q_selftest

# Only build the semlit doc if the semlit.sh tool is available
# Note that THIS WILL DELETE AND REPLACE THE .c AND .h FILES!
if which semlit.sh >/dev/null 2>&1; then :
	./bld_semlit.sh
fi

# Compile module
echo "FYI gcc $COPTS -c -o q.o q.c"
if gcc $COPTS -c -o q.o q.c; then :
else echo "fail"; exit 1
fi

# Build unit test program
echo "FYI gcc $COPTS -DSELFTEST $LIBS -o q_selftest q.c"
if gcc $COPTS -DSELFTEST $LIBS -o q_selftest q.c; then :
else echo "fail"; exit 1
fi

# Build performance measurement tool
echo "FYI gcc $COPTS -o q_perf q.o q_perf.c"
if gcc $COPTS -o q_perf q.o q_perf.c; then :
else echo "fail"; exit 1
fi

# Generate assem language
# echo "FYI gcc -g -O3 -DSELFTEST -S -o q_selftest.s q.c"
# if gcc -g -O3 -DSELFTEST -S -o q_selftest.s q.c; then :
# else echo "fail"; exit 1
# fi

exit 0
