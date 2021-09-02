#!/bin/sh

echo "1..2"

which docker > /dev/null 2>&1
res=$?
if [ "$res" = "0" ]; then
  echo "ok - docker exists"
else
  echo "Bail out! no docker"
  exit $res
fi

# remove comma and compare the version number
got=`docker --version | sed 's/,/ /g' | awk '{ print $3 }'`
expected="20.10.7"
if [ "x$got" = "x$expected" ]; then
  echo "ok - expected version, $got"
else
  echo "not ok - NOT expected version, $got != $expected"
fi



