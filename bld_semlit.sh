#!/bin/sh
# bld_semlit.sh
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed "public domain" style under Creative Commons
# "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.

rm -rf html
mkdir html

echo "FYI cd html"
cd html

echo "FYI cp ../doc/*.png ."
cp ../doc/*.png .

echo "FYI semlit.sh -I../doc ../doc/q.sldoc"
if semlit.sh -I../doc ../doc/q.sldoc; then :
else echo "fail"
fi

# Remove execute permission so web servers don't refuse to serve it.
chmod -x *.txt

# We've generated fresh .c and .h files.  Copy them into the project dir.
for F in *_c.txt; do f=`basename $F _c.txt`;
	echo "FYI rm -f ../$f.c; cp $F ../$f.c; chmod -w ../$f.c"
	rm -f ../$f.c; cp $F ../$f.c; chmod -w ../$f.c
done
for F in *_h.txt; do f=`basename $F _h.txt`;
	echo "FYI rm -f ../$f.h; cp $F ../$f.h; chmod -w ../$f.h"
	rm -f ../$f.h; cp $F ../$f.h; chmod -w ../$f.h
done

echo "FYI cd .."
cd ..
