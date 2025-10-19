#!/usr/bin/env python3

import random
import string

from datetime import datetime

def gen_random_string():
    res = ''.join(
        random.choices(
            string.ascii_letters + string.digits,
            k=8
        )
    )
    return res

def main():
    num = 100


    for i in range(0, num):
        dt = datetime.now()
        dt_str = dt.isoformat()
    
        line1 = gen_random_string()
        line2 = gen_random_string()
        print('[{0}] multiline'.format(dt_str))
        print('  {0}'.format(line1))
        print('  {0}'.format(line2))

if __name__ == '__main__' :
    main()

