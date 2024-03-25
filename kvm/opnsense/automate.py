#!/usr/bin/python3

#from __future__ import unicode_literals

import pexpect
import time
import sys

def main():
    try:
        raw_input
    except NameError:
        raw_input = input

    cmd = "virsh console opnsense-base"
    child = pexpect.spawn(cmd)
    child.logfile = sys.stderr.buffer
    time.sleep(1)

    child.sendline('')
    child.expect('login: ')
    child.sendline('root')
    time.sleep(1)
    child.expect('Password:')
    child.sendline('opnsense')
    time.sleep(1)
    child.expect('Enter an option:')

    # logoff
    child.sendline('0')
    child.expect('login: ')

    # exit virsh console
    child.sendcontrol(']') # Ctrl+]

    print('')


if __name__ == '__main__':
    main()

