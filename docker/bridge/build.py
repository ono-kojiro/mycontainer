#!/usr/bin/env python3

import sys

import getopt
import json
import yaml

import copy
import subprocess

from pprint import pprint

def read_json(filepath) :
    fp = open(filepath, mode='r', encoding='utf-8')
    data = json.loads(fp.read())
    fp.close()
    return data

def read_yaml_list(filepath):
    fp = open(filepath, mode="r", encoding="utf-8")
    docs = yaml.load_all(fp, Loader=yaml.loader.SafeLoader)

    data = []
    for items in docs:
        for item in items:
            data.append(item)

    fp.close()
    return data

def read_yaml_list(filepath):
    fp = open(filepath, mode="r", encoding="utf-8")
    docs = yaml.load_all(fp, Loader=yaml.loader.SafeLoader)

    data = []
    for items in docs:
        for item in items:
            data.append(item)

    fp.close()
    return data

def read_yaml_dict(filepath):
    fp = open(filepath, mode="r", encoding="utf-8")
    docs = yaml.load_all(fp, Loader=yaml.loader.SafeLoader)
    
    data = {}
    for doc in docs:
        data = data | copy.deepcopy(doc)

    fp.close()
    return data

def usage():
    print("Usage : {0}".format(sys.argv[0]))

def all(configs):
    print('DEBUG: all')

def get_cmd_results(cmd):
    try :
        proc = subprocess.Popen(
                cmd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
            )

        while True:
            line = proc.stdout.readline()
            if line:
                yield line.decode('utf-8', errors='replace')

            if not line and proc.poll() is not None:
                break

    except Exception as e:
        print("ERROR: subprocess.Popen failed", file=sys.stderr)
        print("ERROR: {0}".format(e), file=sys.stderr)
        sys.exit(1)

    
def data(configs):
    cmd = 'sh mkdata.sh'
    for line in get_cmd_results(cmd):
        print(line, end='')

def create_bridge(configs):

    for item in configs['bridges']:
        name = item['name']
        conn_id = name
        ifname  = name
        ipv4_method = item['ipv4.method']
        ipv4_addresses = item['ipv4.addresses']
        ipv6_method = item['ipv6.method']

        cmd =  'sudo nmcli con add type bridge'
        cmd += ' conn.id {0}'.format(conn_id)
        cmd += ' ifname {0}'.format(ifname)
        cmd += ' ipv4.method {0}'.format(ipv4_method)
        cmd += ' ipv4.addresses {0}'.format(ipv4_addresses)
        cmd += ' ipv6.method {0}'.format(ipv6_method)
   
    print('INFO: create bridge, {0}'.format(name))
    print('DEBUG: cmd is "{0}"'.format(cmd))

    for line in get_cmd_results(cmd):
        print(line, end='')

def remove_bridge(configs):
    for item in configs['bridges']:
        name = item['name']

        cmd =  'sudo nmcli con del {0}'.format(name)
        print('INFO: remove bridge, {0}'.format(name))

        for line in get_cmd_results(cmd):
            print(line, end='')

def create_network(configs):
    parent = 'admin'
    #driver = 'macvlan'
    driver = 'bridge'
    subnet = '172.31.0.0/24'
    gateway = '172.31.0.1'
    name = '{0}_{1}'.format(parent, driver)

    cmd =  'docker network create'
    cmd += ' --driver={0}'.format(driver)
    cmd += ' --subnet={0}'.format(subnet)
    cmd += ' --gateway={0}'.format(gateway)
    cmd += ' -o parent={0}'.format(parent)
    cmd += ' {0}'.format(name)

    for line in get_cmd_results(cmd):
        print(line, end='')

def remove_network(configs):
    parent = 'admin'
    #driver = 'macvlan'
    driver = 'bridge'
    name = '{0}_{1}'.format(parent, driver)

    cmd =  'docker network remove {0}'.format(name)

    for line in get_cmd_results(cmd):
        print(line, end='')

def list_networks(configs):
    cmd =  'docker network ls'
    for line in get_cmd_results(cmd):
        print(line, end='')

def list_bridges(configs):
    for item in configs['bridges']:
        name = item['name']
        cmd = 'ip a show {0}'.format(name)
        for line in get_cmd_results(cmd):
            print(line, end='')


def main():
    ret = 0

    try:
        opts, args = getopt.getopt(
            sys.argv[1:],
            "hvo:c:",
            [
                "help",
                "version",
                "output=",
                "config=",
            ]
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)
	
    output = None
    config_yml = None
	
    for o, a in opts:
        if o == "-v":
            usage()
            sys.exit(0)
        elif o in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif o in ("-o", "--output"):
            output = a
        elif o in ("-c", "--config"):
            config_yml = a
        else:
            assert False, "unknown option"
	
    if output is not None :
        fp = open(output, mode='w', encoding='utf-8')
    else :
        fp = sys.stdout
	
    if ret != 0:
        sys.exit(1)
 
    configs = {}

    if config_yml is not None :
        configs = read_yaml_dict(config_yml)


    #pprint(configs)

    for target in args:
        if target in globals():
            func = globals()[target]
            res = func(configs)
        else :
            print('ERROR: no such function, {0}'.format(target),
                file=sys.stderr)
            sys.exit(1)
            #usage()

    if output is not None :
        fp.close()
	
if __name__ == "__main__":
	main()
