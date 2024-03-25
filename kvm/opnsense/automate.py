#!/usr/bin/python3

import pexpect
import time
import sys

import getopt
import yaml
from yaml.loader import SafeLoader

def read_yaml(filepath):
   fp = open(filepath, mode="r", encoding="utf-8")
   data = yaml.load(fp, Loader=SafeLoader)
   fp.close()

   return data


def assign_interfaces(child, config):
    child.sendline('1')
    time.sleep(1)
    
    child.expect('Do you want to configure LAGGs now\? \[y/N\]: ')
    child.sendline('N')
    time.sleep(1)
    
    child.expect('Do you want to configure VLANs now\? \[y/N\]: ')
    child.sendline('N')
    time.sleep(1)

    child.expect("Enter the WAN interface name or 'a' for auto-detection: ")
    child.sendline(config['wan_interface'])

    # Enter the LAN interface name or 'a' for auto-detection
    # NOTE: this enables full Firewalling/NAT mode.
    child.expect("\(or nothing if finished\): ")
    child.sendline(config['lan_interface'])

    # Enter the Optional interface 1 name or 'a' for auto-detection
    child.expect("\(or nothing if finished\): ")
    child.sendline('')

    #The interfaces will be assigned as follows:
    #
    #   WAN  -> vtnet1
    #   LAN  -> vtnet0

    child.expect("Do you want to proceed\? \[y/N\]: ")
    child.sendline('y')
    
    child.expect("Enter an option: ")

def set_interface_ip_address(child, config):
    child.sendline('2') # 2) set interface IP address
    
    child.expect('Enter the number of the interface to configure: ')
    child.sendline('1') # LAN

    set_lan_address(child, config)
    
    child.sendline('2') # 2) set interface IP address
    
    child.expect('Enter the number of the interface to configure: ')
    child.sendline('2') # WAN

    set_wan_address(child, config)

def set_lan_address(child, config):
    child.expect('Configure IPv4 address LAN interface via DHCP\? \[y/N\] ')
    child.sendline('N')

    # Enter the new LAN IPv4 address. Press <ENTER> for none:
    child.expect("> ")
    child.sendline(config['lan_addr'])

    #Subnet masks are entered as bit counts (like CIDR notation).
    #e.g. 255.255.255.0 = 24
    #     255.255.0.0   = 16
    #     255.0.0.0     = 8
    # Enter the new LAN IPv4 subnet bit count (1 to 32):
    child.expect("> ")
    child.sendline('24')

    # For a WAN, enter the new LAN IPv4 upstream gateway address.
    # For a LAN, press <ENTER> for none:
    child.expect("> ")
    child.sendline('') # no gateway

    child.expect('Configure IPv6 address LAN interface via WAN tracking\? \[Y/n\] ')
    child.sendline('n')

    child.expect('Configure IPv6 address LAN interface via DHCP6\? \[y/N\] ')
    child.sendline('N')

    # Enter the new LAN IPv6 address. Press <ENTER> for none:
    child.expect("> ")
    child.sendline('') # no ipv6 address

    child.expect('Do you want to enable the DHCP server on LAN\? \[y/N\] ')
    child.sendline('y')

    child.expect('Enter the start address of the IPv4 client address range: ')
    child.sendline(config['dhcp_start'])

    child.expect('Enter the end address of the IPv4 client address range: ')
    child.sendline(config['dhcp_end'])

    child.expect('Do you want to change the web GUI protocol from HTTPS to HTTP\? \[y/N\] ')
    child.sendline('N')

    child.expect('Do you want to generate a new self-signed web GUI certificate\? \[y/N\] ')
    child.sendline('N')

    child.expect('Restore web GUI access defaults\? \[y/N\] ')
    child.sendline('N')

    child.expect("Enter an option: ")

def set_wan_address(child, config):
    child.expect('Configure IPv4 address WAN interface via DHCP\? \[Y/n\] ')
    child.sendline('n')

    child.expect('Enter the new WAN IPv4 address. Press <ENTER> for none:')
    child.expect("> ")
    child.sendline(config['wan_addr'])

    #Subnet masks are entered as bit counts (like CIDR notation).
    #e.g. 255.255.255.0 = 24
    #     255.255.0.0   = 16
    #     255.0.0.0     = 8
    child.expect('Enter the new WAN IPv4 subnet bit count \(1 to 32\):')
    child.expect("> ")
    child.sendline('24')

    # For a WAN, enter the new LAN IPv4 upstream gateway address.
    child.expect('For a LAN, press <ENTER> for none:')
    child.expect("> ")
    child.sendline(config['wan_gateway']) # virbr0

    # (WAN Only)
    child.expect('Do you want to use the gateway as the IPv4 name server, too\? \[Y/n\] ')
    child.sendline('Y')

    child.expect('Configure IPv6 address WAN interface via DHCP6\? \[Y/n\] ')
    child.sendline('N')

    child.expect('Enter the new WAN IPv6 address. Press <ENTER> for none:')
    child.expect("> ")
    child.sendline('') # no ipv6 address

    child.expect('Do you want to change the web GUI protocol from HTTPS to HTTP\? \[y/N\] ')
    child.sendline('N')

    child.expect('Do you want to generate a new self-signed web GUI certificate\? \[y/N\] ')
    child.sendline('N')

    child.expect('Restore web GUI access defaults\? \[y/N\] ')
    child.sendline('N')

    child.expect("Enter an option: ")


def main():
    ret = 0

    try:
        options, args = getopt.getopt(
            sys.argv[1:],
            "hvo:n:c:",
            [
                "help",
                "version",
                "output=",
                "name=",
                "config=",
            ],
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(1)

    output = None
    name   = None
    config_yml = None

    for option, optarg in options:
        if option == "-v":
            usage()
            sys.exit(1)
        elif option in ("-h", "--help"):
            usage()
            sys.exit(1)
        elif option in ("-o", "--output"):
            output = optarg
        elif option in ("-n", "--name"):
            name = optarg
        elif option in ("-c", "--config"):
            config_yml = optarg
        else:
            assert False, "unknown option"

    if output is not None :
        fp = open(output, mode="w", encoding="utf-8")
    else :
        fp = sys.stdout

    if name is None:
        print('no name option')
        ret += 1

    if ret != 0:
        sys.exit(ret)

    
    if config_yml is not None:
        config = read_yaml(config_yml)

    try:
        raw_input
    except NameError:
        raw_input = input

    cmd = "virsh console {0}".format(name)
    child = pexpect.spawn(cmd)
    child.logfile = sys.stderr.buffer
    time.sleep(1)

    child.sendline('')
    child.expect('login: ')
    child.sendline(config['username'])
    child.expect('Password:')
    child.sendline(config['password'])
    child.expect('Enter an option:')

    #assign_interfaces(child, config)
    #set_interface_ip_address(child, config)

    # logoff
    child.sendline('0')
    child.expect('login: ')

    # exit virsh console
    child.sendcontrol(']') # Ctrl+]

    print('')


if __name__ == '__main__':
    main()

