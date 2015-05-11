#!/bin/sh
# bld.sh
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.

OS=`uname`
Q="$1"

CACHE_LINE_SIZE=64 # x86, sparc
# CACHE_LINE_SIZE=128 # Itanium, PowerPC

COPTS="-g -O3 -DCACHE_LINE_SIZE=$CACHE_LINE_SIZE -pthread"; LIBS=""

rm -f *.o ${Q}_selftest

# Compile module
echo "FYI gcc $COPTS -c -o ${Q}.o ${Q}.c"
if gcc $COPTS -I.. -c -o ${Q}.o ${Q}.c; then :
else echo "fail"; exit 1
fi

# Build performance measurement tool
echo "FYI gcc $COPTS -o ${Q}_perf ${Q}.o ../q_perf.c"
if gcc $COPTS -I.. -o ${Q}_perf ${Q}.o ../q_perf.c; then :
else echo "fail"; exit 1
fi

exit 0
