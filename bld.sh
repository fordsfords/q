#!/bin/sh
# bld.sh
# This code and its documentation is Copyright 2014, 2015 Steven Ford, http://geeky-boy.com
# and licensed "public domain" style under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work.
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/q/tree/gh-pages


OS=`uname`

CACHE_LINE_SIZE=128 # x86, sparc use 64, but X86 pre-fetches 2 at a time.
# CACHE_LINE_SIZE=128 # Itanium, PowerPC

COPTS="-g -O3 -DCACHE_LINE_SIZE=$CACHE_LINE_SIZE -pthread"; LIBS=""

rm -f *.o q_selftest

# Update doc table of contents (see https://github.com/fordsfords/mdtoc).
if which mdtoc.pl >/dev/null; then mdtoc.pl -b "" README.md;
elif [ -x ../mdtoc/mdtoc.pl ]; then ../mdtoc/mdtoc.pl -b "" README.md;
else echo "FYI: mdtoc.pl not found; see https://github.com/fordsfords/mdtoc"
fi

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
