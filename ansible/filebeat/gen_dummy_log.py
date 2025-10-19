#!/usr/bin/env python3

import random
import string

from datetime import datetime

num = 100

for i in range(0, num):
    dt = datetime.now()
    random_string = ''.join(
        random.choices(
            string.ascii_letters + string.digits,
            k=8
        )
    )
    dt_str = dt.isoformat()
    print('{0} example: {1}'.format(dt_str, random_string))


