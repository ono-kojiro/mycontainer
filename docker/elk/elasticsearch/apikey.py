#!/usr/bin/env python3

import ast
import getopt
import json
import sys
from netrc import netrc

from elasticsearch import Elasticsearch
from elasticsearch._sync.client import SecurityClient

def dump_response(res):
    data = ast.literal_eval(str(res))
    #print(json.dumps(data, indent=4, ensure_ascii=False))
    if not "api_keys" in data :
        print(json.dumps(data, indent=4, ensure_ascii=False))
    else :
        api_keys = data["api_keys"]
        for api_key in api_keys:
            invalidated = api_key["invalidated"]
            if invalidated != True :
                print(api_key)

def usage():

    print('usage : {0} CMD [OPTIONS] [ARGS]'.format(sys.argv[0]))

    msg = '''
CMD:
  list         show available API keys
  create       create API key for user
  delete       invalidate API key

OPTIONS:
  -u, --username          username
'''

    print(msg)

def main():
    ret = 0
  
    if len(sys.argv) < 2 :
        usage()
        sys.exit(1)

    subcmd = sys.argv[1]
    if subcmd is None :
        print('no subcommand')
        sys.exit(1)

    is_help = False
    url = None
    netrcfile = None
    username = None
    api_key_id = None

    try:
        opts, args = getopt.getopt(
            sys.argv[2:],
            "hvo:n:u:i:",
            [
                "help",
                "version",
                "output=",
                "netrc=",
                "username=",
                "url=",
                "id=",
            ],
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    for key, value in opts:
        if key in ("-u", "--username"):
            print('found username option')
            username = value
        elif key in ("-o", "--output"):
            print('get option -o, {0}'.format(value))
            pass
        elif key in ("-h", "--help"):
            is_help = True
        elif key in ("-n", "--netrc"):
            netrcfile = value
        elif key in ("--url"):
            print('found url option')
            url = value
        elif key in ("-i", "--id"):
            api_key_id = value
        else:
            assert False, "unknown option"

    if is_help :
        print('usage : aaa')
        sys.exit(1)

    if url is None:
        url = "https://192.168.0.98:9200"

    if netrcfile is None:
        netrcfile = "./netrc"

    if ret != 0:
        sys.exit(ret)

    host = "192.168.0.98"

    auths = netrc(netrcfile)

    # pprint(auths)

    auth = auths.authenticators(host)
    # pprint(auth)

    if auth is None:
        print(f"no authentication in {netrcfile}")
        sys.exit(1)

    adminuser = auth[0]
    adminpass = auth[2]

    es = Elasticsearch(
        url,
        basic_auth=(adminuser, adminpass),
        ca_certs="./mylocalca.pem",
        verify_certs=True,
    )

    ast.literal_eval(str(es.info()))

    # print(
    #  json.dumps(
    #    data_dict,
    #    indent=4,
    #    ensure_ascii=False
    #  )
    # )
    
    sc = SecurityClient(es)

    if subcmd == "create" :
        if username is None:
            print('no username option')
            sys.exit(1)

        res = sc.create_api_key(name="my-api-key for {0}".format(username))
        dump_response(res)
    elif subcmd == "delete" :
        if api_key_id is None :
            print('ERROR: no id option')
            sys.exit(1)
        res = sc.invalidate_api_key(id="{0}".format(api_key_id))
        pass
    elif subcmd in ("list", "show") :
        res = sc.get_api_key()
        dump_response(res)

    es.close()

if __name__ == "__main__":
    main()
