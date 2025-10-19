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
        
    print('id, name, value')

    for i in range(0, num):
        dt = datetime.now()
        dt_str = dt.isoformat()
    
        val1 = gen_random_string()
        val2 = gen_random_string()
        print('{0}, csv:{1}, csv:{2}'.format(i, val1, val2))

if __name__ == '__main__' :
    main()

