#!/usr/bin/env python3

print('---')
print('services:')

num_vm = 7

use_macvlan = 1
use_mgmt = 0

for i in range(1, num_vm + 1) :
    print('  client{0}:'.format(i))
    print('    image: ${{CLIENT{0}_IMAGE}}'.format(i))
    print('    container_name: ${{CLIENT{0}_NAME}}'.format(i))
    print('    hostname: ${{CLIENT{0}_NAME}}'.format(i))
    print('    restart:  always')
    print('    stdin_open: true   # docker run -i')
    print('    tty:        true   # docker run -t')
    print('    environment:')
    print('      TZ: Asia/Tokyo')
    print('      LDAP_URI: ${LDAP_URI}')
    print('      LDAP_BASE: ${LDAP_BASE}')
    print('      LDAP_START_TLS: ${LDAP_START_TLS}')
    print('      LDAP_TLS_REQCERT: ${LDAP_TLS_REQCERT}')
    print('      LDAP_ALLOW_GROUPS: ${LDAP_ALLOW_GROUPS}')
    print('    ports:')
    print('      - "${{CLIENT{0}_LPORT}}:22"'.format(i))
    print('    networks:')
    if use_macvlan :
      print('      lan{0}_macvlan:'.format(i))
    else:
      print('      lan{0}_bridge:'.format(i))
    print('        ipv4_address: ${{CLIENT{0}_IPV4}}'.format(i))
    if use_mgmt:
      print('      mgmt_bridge:')
      print('        ipv4_address: ${{CLIENT{0}_MGMT_IPV4}}'.format(i))
    
    print('')

print('networks:')
for i in range(1, num_vm + 1) :
    if use_macvlan :
      print('  lan{0}_macvlan:'.format(i))
    else :
      print('  lan{0}_bridge:'.format(i))
    print('    name: lan{0}_bridge'.format(i))
    if use_macvlan :
      print('    driver: macvlan')
    else :
      print('    driver: bridge')

    print('    driver_opts:')
    print('      parent: ${{CLIENT{0}_PARENT}}'.format(i))
    print('    ipam:')
    print('      config:')
    print('        - subnet:  ${{CLIENT{0}_SUBNET}}'.format(i))
    print('          gateway: ${{CLIENT{0}_GATEWAY}}'.format(i))
    print('')

if use_mgmt :
  print('  mgmt_bridge:')
  print('    driver: bridge')
  print('    ipam:')
  print('      config:')
  print('        - subnet: 172.31.0.0/24')

