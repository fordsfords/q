#!/bin/sh
# clean.sh
# This code and its documentation is Copyright 2014, 2015 Steven Ford, http://geeky-boy.com
# and licensed "public domain" style under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, the contributors to this project have
# waived all copyright and related or neighboring rights to this work. 
# In other words, you can use this code for any purpose without any
# restrictions.  This work is published from: United States.  The project home
# is https://github.com/fordsfords/q/tree/gh-pages

rm -f `find . -name '*.tar' -print`
rm -f `find . -name '*.log' -print`
rm -f `find . -name '*_perf' -print`
rm -f `find . -name '*_selftest' -print`
rm -f `find . -name '*.[os]' -print`
rm -f `find . -name '*.FileListAbsolute.txt' -print`
rm -rf `find . -name '*.dSYM' -print`
rm -rf `find . -name '.DS_Store' -print`
