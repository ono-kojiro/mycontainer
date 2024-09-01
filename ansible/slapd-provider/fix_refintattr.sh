#!/bin/sh

# Supplying multiple names in a single olcRefintAttribute value is unsupported and will be disallowed in a future version
#olcRefintAttribute: memberof member manager owner

#dn: olcOverlay={2}refint,olcDatabase={1}mdb,cn=config
#objectClass: olcConfig
#objectClass: olcOverlayConfig
#objectClass: olcRefintConfig
#objectClass: top
#olcRefintAttribute: memberof member manager owner

ldapmodify -H ldaps://localhost -D cn=Manager,dc=example,dc=com -W << EOF
dn: olcOverlay={2}refint,olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcRefintAttribute
olcRefintAttribute: memberof
-
add: olcRefintAttribute
olcRefintAttribute: member
-
add: olcRefintAttribute
olcRefintAttribute: manager
-
add: olcRefintAttribute
olcRefintAttribute: owner
EOF

#ldapmodify -H ldaps://localhost -D cn=Manager,dc=example,dc=com -W << EOF
#dn: olcOverlay={2}refint,olcDatabase={1}mdb,cn=config
#changetype: modify
#EOF

