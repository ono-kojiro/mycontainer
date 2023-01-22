#!/bin/sh

server="10.0.3.204"

echo "1..2"
echo "check http"
curl -k http://${server}/ > /dev/null 2>&1

if [ "$?" -eq 0 ]; then
  echo "ok - http connection"
else
  echo "not ok - http connection"
fi

echo "check https"
curl -k https://${server}/ > /dev/null 2>&1

if [ "$?" -eq 0 ]; then
  echo "ok - https connection"
else
  echo "not ok - https connection"
fi

