#!/usr/bin/env python3

import sys
import re
import os

import json

STATE_INIT = 0
STATE_LAYER = 1

def main() :
    layers = [
        '${TOPDIR}/../../meta-openembedded/meta-oe',
        '${TOPDIR}/../../meta-openembedded/meta-networking',
        '${TOPDIR}/../../meta-openembedded/meta-filesystems',
        '${TOPDIR}/../../meta-openembedded/meta-python',
        '${TOPDIR}/../../meta-virtualization',
    ]
    state = STATE_INIT

    while 1:
        line = sys.stdin.readline()
        if not line:
            break

        line = re.sub(r'\r?\n?$', '', line)

        if state == STATE_INIT :
            if re.search(r'^BBLAYERS \?= "', line) :
                state = STATE_LAYER
        elif state == STATE_LAYER :
            if re.search(r'^\s*"$', line) :
                for layer in layers :
                    print('  ' + layer + ' \\')
                state = STATE_INIT

        print(line)

if __name__ == "__main__" :
    main()

