#!/bin/sh

server_crt="/etc/ssl/certs/server.crt"
server_key="/etc/ssl/private/server.key"

replace_crt()
{
  cat - << EOF | sudo ldapmodify -Q -Y EXTERNAL -H ldapi:///
dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: ${server_crt}
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: ${server_key}
EOF
}

check()
{
  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
    -LLL -b "cn=config" olcTLSCertificateFile | grep TL
  ldapsearch -Q -Y EXTERNAL -H ldapi:/// \
    -LLL -b "cn=config" olcTLSCertificateKeyFile | grep TL
}

replace_crt
check

