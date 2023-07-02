#!/bin/sh

suffix=`cat /etc/ldap/ldap.conf | grep -e '^BASE' | awk '{ print $2 }'`
masterdn="cn=Manager,${suffix}"

stty -echo
printf "Password for masterdn: "
read PASSWORD
stty echo
printf "\n"

cat - << EOF | ldapmodify -D $masterdn -w $PASSWORD
dn: cn=config
changetype: modify
delete: olcDisallows
olcDisallows: bind_anon
EOF

if [ $? -eq 0 ]; then
  echo "ldapmodify passed"
else
  echo "ldapmodify failed"
fi


cat - << EOF | ldapmodify -D $masterdn -w $PASSWORD
dn: cn=config
changetype: modify
delete: olcRequires
olcRequires: authc
EOF

if [ $? -eq 0 ]; then
  echo "ldapmodify passed"
else
  echo "ldapmodify failed"
fi

cat - << EOF | ldapmodify -D $masterdn -w $PASSWORD
dn: olcDatabase={-1}frontend,cn=config
changetype: modify
delete: olcRequires
olcRequires: authc
EOF

if [ $? -eq 0 ]; then
  echo "ldapmodify passed"
else
  echo "ldapmodify failed"
fi

#sudo systemctl restart slapd

