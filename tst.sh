#!/bin/sh
# tst.sh
# This code and its documentation is Copyright 2014 Steven Ford, sford@geeky-boy.com
# and licensed under Creative Commons "CC0": http://creativecommons.org/publicdomain/zero/1.0/
# To the extent possible under law, Steve Ford has waived all copyright and related or
# neighboring rights to this work.  This work is published from: United States.

echo "FYI ./q_selftest $*"
if ./q_selftest $*; then echo "FYI q_selftest success"
else exit 1
fi

exit 0
