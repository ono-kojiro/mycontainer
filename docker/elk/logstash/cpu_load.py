#!/usr/bin/env python3

import sys
import getopt

import json
import psutil

from datetime import datetime, timedelta, timezone

def usage():
    print(f"Usage : {sys.argv[0]}")

def main():
    ret = 0

    try:
        opts, args = getopt.getopt(
            sys.argv[1:],
            "hvo:i:n:f:",
            [
                "help",
                "version",
                "output=",
                "index=",
                "number=",
                "format=",
            ]
        )
    except getopt.GetoptError as err:
        print(str(err))
        sys.exit(2)

    output = None
    index  = None
    num    = 1
    fmt    = None

    for o, a in opts:
        if o == "-v":
            usage()
            sys.exit(0)
        elif o in ("-h", "--help"):
            usage()
            sys.exit(0)
        elif o in ("-o", "--output"):
            output = a
        elif o in ("-i", "--index"):
            index = a
        elif o in ("-f", "--format"):
            fmt = a
        elif o in ("-n", "--num"):
            num = int(a)
        else:
            assert False, "unknown option"
    
    tz = timezone(timedelta(hours=+0), 'UTC')
    now = datetime.now(tz)
    
    if index is None:
        #print('ERROR : no index option', file=sys.stderr)
        #ret += 1
        index = now.strftime('mymetrics-%Y.%m.%d')
        
    if fmt is None or fmt == 'json' :
        ext = '.json'
    elif fmt == 'csv' :
        ext = '.csv'
    else:
       print('unknown format, {0}'.format(fmt))
       sys.exit(1)
    
    if ret != 0:
        sys.exit(1)

    if output is not None:
        if output == "-" :
          fp = sys.stdout
        else :
          fp = open(output, mode="w", encoding="utf-8")

    for i in range(num) :
        now = datetime.now(tz)
        #ts = now.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
        ts = now.strftime('%Y-%m-%d %H:%M:%S')
        
        
        if output is None:
            outfile = now.strftime('%Y%m%d-%H%M%S-%f')[:-3] + ext
            fp = open(outfile, mode="w", encoding="utf-8")
            
        cpu = psutil.cpu_percent(interval=1)
        vm  = psutil.virtual_memory()
        mem = round(vm.used * 100 / vm.total, 2)  # ex. 34.56
         
        if fmt is None or fmt == 'json' :
            data = { "index" : { "_index" : index } }
            fp.write(json.dumps(data) + '\n')

            data = {
                "key" : i,
                "val" : i,
                "@timestamp" : ts,
                "cpu" : cpu,
                "mem" : mem,
            }
            fp.write(json.dumps(data) + '\n')
        elif fmt == 'csv' :
            fp.write('Timestamp,CPU\n')
            fp.write('{0},{1}\n'.format(ts, cpu))
        
        if output is None:
            fp.close()

    if output is not None:
        fp.close()

if __name__ == "__main__":
    main()
