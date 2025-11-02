#!/bin/sh
# tst.sh

echo "FYI ./q_selftest $*"
if ./q_selftest $*; then echo "FYI q_selftest success"
else exit 1
fi

exit 0
