#!/bin/sh
# clean.sh

rm -f `find . -name '*.tar' -print`
rm -f `find . -name '*.log' -print`
rm -f `find . -name '*_perf' -print`
rm -f `find . -name '*_selftest' -print`
rm -f `find . -name '*.[os]' -print`
rm -f `find . -name '*.FileListAbsolute.txt' -print`
rm -rf `find . -name '*.dSYM' -print`
rm -rf `find . -name '.DS_Store' -print`
