#!/usr/bin/env python3

for i in range(1, 8) :
    print('CLIENT{0}_IMAGE=noble:latest'.format(i))
    print('CLIENT{0}_NAME=client{0}'.format(i))
    print('CLIENT{0}_IPV4=172.16.{0}.{1}'.format(i, 50 + i))
    print('CLIENT{0}_PARENT=lan{0}'.format(i))
    print('CLIENT{0}_SUBNET=172.16.{0}.0/24'.format(i))
    print('CLIENT{0}_GATEWAY=172.16.{0}.1'.format(i))
    print('CLIENT{0}_LPORT=10{0}22'.format(i))
    print('CLIENT{0}_MGMT_IPV4=172.31.0.{1}'.format(i, 50 + i))
    print('')

content = '''
LDAP_URI=ldaps://192.168.1.72
LDAP_BASE=dc=example,dc=com
LDAP_START_TLS=true
LDAP_TLS_REQCERT=never
LDAP_ALLOW_GROUPS=ldapusers
'''

print(content)

#CLIENT1_IMAGE=noble:latest
#CLIENT1_NAME=client1
#CLIENT1_IPV4=172.16.1.55
#CLIENT1_PARENT=lan1
#CLIENT1_SUBNET=172.16.1.0/24
#CLIENT1_GATEWAY=172.16.1.1
#CLIENT1_LPORT=10122

#CLIENT2_IMAGE=noble:latest
#CLIENT2_NAME=client2
#CLIENT2_IPV4=172.16.2.55
#CLIENT2_PARENT=lan2
#CLIENT2_SUBNET=172.16.2.0/24
#CLIENT2_GATEWAY=172.16.2.1
#CLIENT2_LPORT=10222


