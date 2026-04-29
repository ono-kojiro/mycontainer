#!/usr/bin/env python3

import sys

import getopt
import json

import base64
from struct import pack

def read_json(jsonfile):
    fp = open(jsonfile, mode='r', encoding='utf-8')
    data = json.load(fp)
    fp.close()
    return data

def b64url_to_long(b64url):
    padded = b64url + "=" * (-len(b64url) % 4)
    return int.from_bytes(base64.urlsafe_b64decode(padded), "big")

# ASN.1 DER encoding for RSA public key
def encode_length(length):
    if length < 0x80:
        return bytes([length])
    s = hex(length)[2:]
    if len(s) % 2:
        s = "0" + s
    l = bytes.fromhex(s)
    return bytes([0x80 | len(l)]) + l

def encode_integer(x):
    b = x.to_bytes((x.bit_length() + 7) // 8, "big")
    if b[0] & 0x80:
        b = b"\x00" + b
    return b"\x02" + encode_length(len(b)) + b

def main():
    ret = 0

    try:
        opts, args = getopt.getopt(
            sys.argv[1:],
            "hvo:",
            [
                "help",
                "version",
                "output=",
                "oneline",
            ]
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    output = None
    oneline = False

    for o, a in opts:
        if o == "-v":
            usage()
            sys.exit(0)
        elif o in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif o in ("-o", "--output"):
            output = a
        elif o in ("--oneline"):
            oneline = True
        else:
            assert False, "unknown option"

    if output is not None :
        fp = open(output, mode='w', encoding='utf-8')
    else:
        fp = sys.stdout

    if ret != 0:
        sys.exit(1)

    for jsonfile in args:
        #print('DEBUG: read {0}'.format(jsonfile))
        data = read_json(jsonfile)
        
        #print(
        #    json.dumps(
        #        data,
        #        indent=2,
        #        ensure_ascii=False,
        #    )
        #)

        key = data['keys'][0]

        kid = key.get('kid', None)
        n   = key.get('n', None)
        e   = key.get('e', None)

        if kid is None:
            print('ERROR: "kid" not found in {0}'.format(jsonfile))
            ret += 1

        if n is None:
            print('ERROR: "n" not found in {0}'.format(jsonfile))
            ret += 1

        if e is None:
            print('ERROR: "e" not found in {0}'.format(jsonfile))
            ret += 1

        if ret :
            sys.exit(3)

        n = b64url_to_long(n)
        e = b64url_to_long(e)

        #print(n)
        #print(e)

        seq = encode_integer(n) + encode_integer(e)
        seq = b"\x30" + encode_length(len(seq)) + seq

        # Wrap in SubjectPublicKeyInfo
        algo = b"\x30\x0d\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x01\x05\x00"
        bitstr = b"\x03" + encode_length(len(seq) + 1) + b"\x00" + seq
        spki = b"\x30" + encode_length(len(algo) + len(bitstr)) + algo + bitstr

        pem = b"-----BEGIN PUBLIC KEY-----\n"
        b64 = base64.encodebytes(spki).replace(b"\n", b"")
        for i in range(0, len(b64), 64):
            pem += b64[i:i+64] + b"\n"
        pem += b"-----END PUBLIC KEY-----"

        for line in pem.decode('utf-8').split('\n') :
            fp.write('{0}'.format(line))
            if oneline :
                fp.write('\\n')
            else :
                fp.write('\n')

    if oneline:
        fp.write('\n')

    if output is not None :
        fp.close()

if __name__ == "__main__" :
    main()
    sys.exit(0)

