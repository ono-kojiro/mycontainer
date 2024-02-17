#!/usr/bin/env python3

import sys
import re

import getopt
from pprint import pprint

def usage():
    print(f"Usage : {sys.argv[0]} -o <output> <input>...")

def main():
    ret = 0

    try:
        options, args = getopt.getopt(
            sys.argv[1:],
            "hvo:",
            [
                "help",
                "version",
                "output=",
            ],
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(1)

    output = None

    for option, optarg in options:
        if option == "-v":
            usage()
            sys.exit(1)
        elif option in ("-h", "--help"):
            usage()
            sys.exit(1)
        elif option in ("-o", "--output"):
            output = optarg
        else:
            assert False, "unknown option"

    if output is not None :
        fp = open(output, mode="w", encoding="utf-8")
    else :
        fp = sys.stdout

    if ret != 0:
        sys.exit(ret)
            
    pat_src = r'(\d+\.\d+\.\d+\.\d+:\d+)'
    pat_dst = r'(\d+/\w+)'
    reg_frd = re.compile(pat_src + '->' + pat_dst)

    for filepath in args:
        fp_in = open(filepath, mode="r", encoding="utf-8")
        while 1 :
            line = fp_in.readline()
            if not line :
                break

            line = re.sub(r'\r?\n?$', '', line)

            if re.search(r'^CONTAINER ID', line):
                continue

            #print('DEBUG: "{0}"'.format(line))
            m = re.search(r'^(\w+)\s+(\w+)\s+(.+)', line)
            if not m :
                print('invalid line, {0}'.format(line))
                sys.exit(1)

            cont_id = m.group(1)
            name    = m.group(2)
            port_maps_str   = m.group(3)

            port_maps = re.split(r',\s*', port_maps_str)
            for port_map in port_maps :
                if re.search(r'^\s*$', port_map):
                    continue
                pprint(port_map)

        fp_in.close()
    if output is not None:
        fp.close()

if __name__ == "__main__":
    main()

