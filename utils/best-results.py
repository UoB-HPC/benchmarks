import csv
import sys
from benchmarks import *

if len(sys.argv) != 1:
    print 'Usage: python best-results.py'
    exit(1)

platforms = ['tx2-foxconn', 'bdw-swan', 'skl-swan']
output = csv.DictWriter(sys.stdout, ['benchmark', 'units'] + platforms)
output.writeheader()

results = gather_results(platforms)
for benchmark in benchmarks:
    entry = dict()
    entry['benchmark'] = benchmark.fullname
    entry['units'] = benchmark.units
    for platform in platforms:
        best = get_best(benchmark, results[benchmark.name][platform])
        entry[platform] = ('%.3g' % best[1]) if best else 'X'
    output.writerow(entry)
