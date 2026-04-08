#!/usr/bin/env python3

print('---')
print('services:')

num_vm = 7

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
    print('      lan{0}_bridge:'.format(i))
    print('        ipv4_address: ${{CLIENT{0}_IPV4}}'.format(i))
    print('      bridge-admin:')
    print('')

print('networks:')
for i in range(1, num_vm + 1) :
    print('  lan{0}_bridge:'.format(i))
    print('    name: lan{0}_bridge'.format(i))
    print('    driver: bridge')
    #print('    driver: macvlan')
    print('    driver_opts:')
    print('      parent: ${{CLIENT{0}_PARENT}}'.format(i))
    print('    ipam:')
    print('      config:')
    print('        - subnet:  ${{CLIENT{0}_SUBNET}}'.format(i))
    print('          gateway: ${{CLIENT{0}_GATEWAY}}'.format(i))
    print('')

print('  bridge-admin:')
print('    driver: bridge')
#print('    driver: macvlan')

