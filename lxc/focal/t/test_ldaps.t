#!/bin/sh

echo "1..1"
echo "check ldaps"
ldapsearch -H ldaps://10.0.3.204 -D cn=Manager,dc=zeon,dc=org \
      -w secret -LLL -b "olcDatabase={1}mdb,cn=config" olcSuffix

if [ "$?" -eq 0 ]; then
  echo "ok - ldaps connection"
else
  echo "not ok - ldaps connection"
fi

