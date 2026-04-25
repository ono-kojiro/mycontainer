#!/bin/sh

N="$1"
E="$2"

python3 <<EOF
import base64
import sys
from struct import pack

def b64url_to_long(b64url):
    padded = b64url + "=" * (-len(b64url) % 4)
    return int.from_bytes(base64.urlsafe_b64decode(padded), "big")

n = b64url_to_long("$N")
e = b64url_to_long("$E")

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
pem += b"-----END PUBLIC KEY-----\n"

sys.stdout.buffer.write(pem)
EOF

