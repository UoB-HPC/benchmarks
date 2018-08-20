import sys
from benchmarks import *

if len(sys.argv) != 2:
    print 'Usage: python failed-configs.py PLATFORM'
    exit(1)

platform = sys.argv[1]

results = gather_results([platform])
for benchmark in benchmarks:
    print benchmark.fullname
    for result in results[benchmark.name][platform]:
        if not result[1]:
            print '-',result[0]
    print
