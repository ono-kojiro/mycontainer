#!/usr/bin/env python3
import ast
import getopt
import json
import re
import sys
from netrc import netrc
from urllib.parse import urlparse

from elasticsearch import Elasticsearch


def dump_response(res):
    data = ast.literal_eval(str(res))

    print(json.dumps(data, indent=4, ensure_ascii=False))


def main():
    ret = 0

    try:
        options, args = getopt.getopt(
            sys.argv[1:],
            "hvo:u:n:",
            [
                "help",
                "version",
                "output=",
                "netrc=",
            ],
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    url = None
    netrcfile = None

    for key, value in options:
        if key in ("-o", "--output"):
            pass
        elif key in ("-n", "--netrc"):
            netrcfile = value
        else:
            assert False, "unknown option"

    if url is None:
        url = "https://192.168.0.98:9200"

    if netrcfile is None:
        netrcfile = "./.netrc"

    if ret != 0:
        sys.exit(ret)

    netloc = re.sub(r":.+", "", urlparse(url)[1])

    auths = netrc(netrcfile)

    auth = auths.authenticators(netloc)

    if auth is None:
        print(f"no authentication in {netrcfile}")
        sys.exit(1)

    username = auth[0]
    password = auth[2]

    es = Elasticsearch(
        url,
        basic_auth=(username, password),
        verify_certs=False,
    )

    data_dict = ast.literal_eval(str(es.info()))

    print(json.dumps(data_dict, indent=4, ensure_ascii=False))

    es.close()


if __name__ == "__main__":
    main()
