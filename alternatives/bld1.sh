#!/bin/sh
# bld.sh

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
