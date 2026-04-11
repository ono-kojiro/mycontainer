#!/usr/bin/env python3

import sys

import getopt
import yaml


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

    for filepath in args :
        fp.write('---\n')
        fp.write('services:\n')
        data = read_yaml(filepath)
        containers = data['containers']
        envs = data['environments']
        for name in containers:
            attrs = containers[name]
            fp.write('  {0}:\n'.format(name))
            fp.write('    image: ${{{0}_IMAGE}}\n'.format(name.upper()))
            fp.write('    container_name: ${{{0}_NAME}}\n'.format(name.upper()))
            fp.write('    hostname: ${{{0}_NAME}}\n'.format(name.upper()))
            fp.write('    restart:  always\n')
            fp.write('    stdin_open: true   # docker run -i\n')
            fp.write('    tty:        true   # docker run -t\n')
            fp.write('    environment:\n')
            fp.write('      TZ: Asia/Tokyo\n')
            for env in envs:
                fp.write('      {0}: ${{{0}}}\n'.format(env))
            fp.write('    networks:\n')
            fp.write('      {0}_macvlan:\n'.format(attrs['parent']))
            fp.write('        ipv4_address: ${{{0}_IPV4}}\n'.format(name.upper()))
            fp.write('\n')

        fp.write('networks:\n')
        for name in containers:
            attrs = containers[name]
            fp.write('  {0}_macvlan:\n'.format(attrs['parent']))
            fp.write('    external: true\n')

    if output is not None:
        fp.close()

if __name__ == '__main__':
    main()

