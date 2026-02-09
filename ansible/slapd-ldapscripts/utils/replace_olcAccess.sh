#!/bin/sh

ldap_conf=""

if [ -e "/etc/ldap/ldap.conf" ]; then
  ldap_conf="/etc/ldap/ldap.conf"
fi

ldap_base=`cat $ldap_conf | grep -e '^BASE ' | awk '{ print $2 }'`
ldap_uri=`cat $ldap_conf | grep -e '^URI ' | awk '{ print $2 }'`

echo $ldap_uri

cat - << EOF > _sample.ldif
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: to attrs=sshPublicKey
  by self write
  by dn.base=cn=Manager,dc=example,dc=com write
  by * read
olcAccess: to attrs=givenName,cn,sn,photo
  by self write
  by dn.base=cn=Manager,dc=example,dc=com write
  by * read
olcAccess: to attrs=userPassword
  by self write
  by anonymous auth
  by * none
olcAccess: to attrs=shadowLastChange
  by self write
  by * read
olcAccess: to *
  by * read
EOF

sudo ldapmodify \
  -Q -Y EXTERNAL -H ldapi:/// -D cn=Manager,$ldap_base -f _sample.ldif

