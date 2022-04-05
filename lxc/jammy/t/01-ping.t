#!/usr/bin/env sh

echo "1..1"

ansible all -i inventory/hosts -m ping
if [ $? -eq 0 ]; then
  echo "ok"
else
  echo "not ok"
fi

