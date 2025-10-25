import sys
import re
import tempfile
import subprocess

import os

inputs = ''
while True:
    line = sys.stdin.readline()
    if not line:
        break

    if re.search(r'BEGIN CERT', line) :
        inputs = ''

    inputs += line

    if re.search(r'END CERT', line) :
        #print('START')
        #print(lines)
        #print('END')
        fp = tempfile.NamedTemporaryFile(mode='w', delete=False)
        fp.write(inputs)
        fp.close()
        cmd = 'openssl x509 -in {0} -text -noout'.format(fp.name)
        #print(cmd)
        outputs = subprocess.check_output(cmd, shell=True, text=True)
        for line in outputs.split('\n'):
            print('{0}'.format(line))
        os.remove(fp.name)

