#!/bin/sh

binddn="cn=Manager,dc=example,dc=com"
bindpw="xxxxxxxx"

# BEFORE
#dn: olcDatabase={1}mdb,cn=config
#objectClass: olcDatabaseConfig
#objectClass: olcMdbConfig
#olcDatabase: {1}mdb
#olcDbDirectory: /var/lib/ldap
#olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
#olcAccess: {1}to attrs=shadowLastChange by self write by * read
#olcAccess: {2}to * by * read

cat - << EOF | ldapmodify -H ldaps://localhost -D $binddn -w $bindpw
dn: olcDatabase={1}mdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {2}to attrs=sshPublicKey by self write by * read
EOF

# AFTER
#dn: olcDatabase={1}mdb,cn=config
#objectClass: olcDatabaseConfig
#objectClass: olcMdbConfig
#olcDatabase: {1}mdb
#olcDbDirectory: /var/lib/ldap
#olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
#olcAccess: {1}to attrs=shadowLastChange by self write by * read
#olcAccess: {2}to attrs=sshPublicKey by self write by * read
#olcAccess: {3}to * by * read 

