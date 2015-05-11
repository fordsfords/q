#!/bin/sh
# clean.sh
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.

rm -f `find . -name '*.tar' -print`
rm -f `find . -name '*.log' -print`
rm -f `find . -name '*_perf' -print`
rm -f `find . -name '*_selftest' -print`
rm -f `find . -name '*.[os]' -print`
rm -f `find . -name '*.FileListAbsolute.txt' -print`
rm -rf `find . -name '*.dSYM' -print`
rm -rf `find . -name '.DS_Store' -print`
