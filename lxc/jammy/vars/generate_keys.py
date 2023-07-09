#!/usr/bin/env python3

import sys

import getopt

import yaml
from yaml.loader import SafeLoader

import subprocess
import shlex

def read_text(filepath):
   fp = open(filepath, mode="r", encoding="utf-8")
   lines = fp.readall()
   fp.close()

   return lines

def read_yaml(filepath):
   fp = open(filepath, mode="r", encoding="utf-8")
   data = yaml.load(fp, Loader=SafeLoader)
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
        items = read_yaml(filepath)['newusers']
        for item in items:
            mail = item['mail']
            name = item['name']
            #print(mail)
            cmd = "ssh-keygen -t ed25519 -N ''"
            cmd += " -f id_ed25519_{0}".format(name)
            cmd += " -C {0}".format(mail)
            print(cmd)
            subprocess.call(shlex.split(cmd))


    if output is not None:
        fp.close()

if __name__ == "__main__":
    main()
