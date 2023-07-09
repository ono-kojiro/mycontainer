#!/bin/sh

echo "check named.conf"
named-checkconf /etc/bind/named.conf

echo "check db.example.com"
named-checkzone example.com /etc/bind/db.sub.example.com

echo "check db.10.0.3"
named-checkzone 3.0.10.in-addr.arpa /etc/bind/db.10.0.3

