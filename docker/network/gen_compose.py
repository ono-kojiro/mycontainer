#!/usr/bin/env python3



print('---')
print('services:')

for i in range(1, 9) :
    print('  client{0}:'.format(i))
    print('    image: ${{CLIENT{0}_IMAGE}}'.format(i))
    print('    container_name: ${{CLIENT{0}_NAME}}'.format(i))
    print('    hostname: ${{CLIENT{0}_NAME}}'.format(i))
    print('    restart:  always')
    print('    stdin_open: true   # docker run -i')
    print('    tty:        true   # docker run -t')
    print('    environment:')
    print('      TZ: Asia/Tokyo')
    print('    ports:')
    print('      - "${{CLIENT{0}_LPORT}}:22"'.format(i))
    print('    networks:')
    print('      lan{0}_bridge:'.format(i))
    print('        ipv4_address: ${{CLIENT{0}_IPV4}}'.format(i))
    print('      docker_bridge: {}')
    print('')

print('networks:')
for i in range(1, 9) :
    print('  lan{0}_bridge:'.format(i))
    print('    name: lan{0}_bridge'.format(i))
    print('    driver: bridge')
    print('    driver_opts:')
    print('      parent: ${{CLIENT{0}_PARENT}}'.format(i))
    print('    ipam:')
    print('      config:')
    print('        - subnet:  ${{CLIENT{0}_SUBNET}}'.format(i))
    print('          gateway: ${{CLIENT{0}_GATEWAY}}'.format(i))
    print('')

print('  docker_bridge:')
print('    driver: bridge')

'''
---
services:
  client1:
    image: ${CLIENT1_IMAGE}
    container_name: ${CLIENT1_NAME}
    hostname: ${CLIENT1_NAME}
    restart:  always
    stdin_open: true   # docker run -i
    tty:        true   # docker run -t
    environment:
      TZ: Asia/Tokyo
    ports:
      - "${CLIENT1_LPORT}:22"
    networks:
      lan1_bridge:
        ipv4_address: ${CLIENT1_IPV4}
      docker_bridge: {}
  
  client2:
    image: ${CLIENT2_IMAGE}
    container_name: ${CLIENT2_NAME}
    hostname: ${CLIENT2_NAME}
    restart:  always
    stdin_open: true   # docker run -i
    tty:        true   # docker run -t
    environment:
      TZ: Asia/Tokyo
    ports:
      - "${CLIENT2_LPORT}:22"
    networks:
      lan2_bridge:
        ipv4_address: ${CLIENT2_IPV4}
      docker_bridge: {}


networks:
  lan1_bridge:
    name: lan1_bridge
    driver: bridge
    driver_opts:
      parent: ${CLIENT1_PARENT}
    ipam:
      config:
        - subnet:  ${CLIENT1_SUBNET}
          gateway: ${CLIENT1_GATEWAY}

  lan2_bridge:
    name: lan2_bridge
    driver: bridge
    driver_opts:
      parent: ${CLIENT2_PARENT}
    ipam:
      config:
        - subnet:  ${CLIENT2_SUBNET}
          gateway: ${CLIENT2_GATEWAY}

  docker_bridge:
    driver: bridge
'''

