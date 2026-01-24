#!/bin/sh
      
provider="ldaps://192.168.1.72"
tls_cacert="/etc/ssl/certs/ca-certificates.crt"
tls_reqcert="try"
binddn="cn=Manager,dc=example,dc=com"
credentials="xxxxxxxx"
searchbase="dc=example,dc=com"

ldapmodify -Q -Y EXTERNAL -H ldapi:/// << EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcSyncrepl
olcSyncRepl: rid=123
  provider=$provider
  tls_cacert="$tls_cacert"
  tls_reqcert="$tls_reqcert"
  bindmethod=simple
  binddn=$binddn
  credentials=$credentials
  searchbase=$searchbase
  scope=sub
  schemachecking=on
  type=refreshAndPersist
  retry="30 5 300 3"
  interval=00:00:05:00
EOF

