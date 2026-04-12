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

def write_network(fp, name, attrs):
    fp.write('{0}_IPV4={1}\n'.format(name.upper(), attrs['ipv4']))
    fp.write('{0}_PARENT={1}\n'.format(name.upper(), attrs['parent']))
    fp.write('{0}_SUBNET={1}\n'.format(name.upper(), attrs['subnet']))
    if 'gateway' in attrs:
        fp.write('{0}_GATEWAY={1}\n'.format(name.upper(), attrs['gateway']))

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
        data = read_yaml(filepath)
        containers = data['containers']
        for name in containers:
            fp.write('{0}_IMAGE={1}\n'.format(name.upper(),
                                        containers[name]['image']))
            fp.write('{0}_NAME={1}\n'.format(name.upper(), name))
            #for attrs in containers[name]['networks']:
            #    write_network(fp, name, attrs)
            #    fp.write('\n')

        envs = data['environments']
        for name in envs:
            fp.write('{0}={1}\n'.format(name, envs[name]))

    if output is not None:
        fp.close()

if __name__ == '__main__':
    main()

