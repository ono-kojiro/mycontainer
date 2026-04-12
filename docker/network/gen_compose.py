#!/usr/bin/env python3

import sys

import getopt
import yaml

from pprint import pprint

def read_yaml(filepath):
    fp = open(filepath, mode="r", encoding="utf-8")
    docs = yaml.load_all(fp, Loader=yaml.loader.SafeLoader)
    data = {}
    for doc in docs:
        data = data | doc
    fp.close()
    return data

def main() :
    ret = 0

    try:
        options, args = getopt.getopt(
            sys.argv[1:],
            "hvo:",
            [
              "help",
              "version",
              "output="
            ]
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    output = None

    for option, arg in options:
        if option in ("-v", "-h", "--help"):
            usage()
            sys.exit(0)
        elif option in ("-o", "--output"):
            output = arg
        else:
            assert False, "unknown option"

    if output is not None:
        fp = open(output, mode="w", encoding="utf-8")
    else :
        fp = sys.stdout

    if ret != 0:
        sys.exit(1)

    network_list = {}

    for filepath in args :
        fp.write('---\n')
        fp.write('services:\n')
        data = read_yaml(filepath)
        containers = data['containers']
        envs = data['environments']
        for name in containers:
            attrs = containers[name]
            fp.write('  {0}:\n'.format(name))
            fp.write('    image: {0}\n'.format(attrs['image']))
            fp.write('    container_name: {0}\n'.format(name))
            fp.write('    hostname: {0}\n'.format(name))
            fp.write('    restart:  always\n')
            fp.write('    stdin_open: true   # docker run -i\n')
            fp.write('    tty:        true   # docker run -t\n')
            fp.write('    cap_add:\n')
            fp.write('      - NET_ADMIN\n')
            nws = containers[name]['networks']

            main_ip = None
            gateway = None
            fp.write('    networks:\n')
            for attrs in nws:
                fp.write('      nw_{0}:\n'.format(attrs['parent']))
                fp.write('        ipv4_address: {0}\n'.format(attrs['ipv4']))
                if 'gateway' in attrs:
                    main_ip = attrs['ipv4']
                    gateway = attrs['gateway']

            fp.write('    environment:\n')
            for env in envs:
                fp.write('      {0}: {1}\n'.format(env, envs[env]))

            if main_ip :
                fp.write('      MAIN_IP: {0}\n'.format(main_ip))
                fp.write('      GATEWAY: {0}\n'.format(gateway))
            fp.write('\n')

        fp.write('networks:\n')
        for container_name in containers:
            nws = containers[container_name]['networks']
            for attrs in nws:
                parent = attrs['parent']
                driver = attrs['driver']
                name = 'nw_{0}'.format(parent)
                network_list[name] = 1

        for name in sorted(network_list.keys()):
            fp.write('  {0}:\n'.format(name))
            fp.write('    external: true\n')

    if output is not None:
        fp.close()

if __name__ == '__main__':
    main()

