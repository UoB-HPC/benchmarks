import sys
from benchmarks import *

print 'ERROR: script needs to be updated for new results format'
exit(1)

if len(sys.argv) != 2:
    print 'Usage: python valid-configs.py PLATFORM'
    exit(1)

platform = sys.argv[1]

results = gather_results([platform])
for benchmark in benchmarks:
    print benchmark.fullname
    for result in results[benchmark.name][platform]:
        if result[1]:
            print '-',result[0]
    print
