#!/bin/sh

echo "check named.conf"
named-checkconf /etc/bind/named.conf

echo "check db.main.example.com"
named-checkzone main.example.com /etc/bind/db.main.example.com

echo "check db.3.0.10"
named-checkzone 3.0.10.in-addr.arpa /etc/bind/db.10.0.3

