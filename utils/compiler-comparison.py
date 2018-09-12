import csv
import sys
from benchmarks import *

if len(sys.argv) < 2 or len(sys.argv) > 3:
    print 'Usage: python compiler-comparison.py PLATFORM [COMPILER_PREFIXES]'
    exit(1)

platform = sys.argv[1]

compilers = ['gcc', 'arm', 'cce']
if len(sys.argv) > 2:
    compilers = sys.argv[2].split()

output = csv.DictWriter(sys.stdout, ['benchmark', 'units'] + compilers)
output.writeheader()

results = gather_results([platform])
for benchmark in benchmarks:
    entry = dict()
    entry['benchmark'] = benchmark.fullname
    entry['units'] = benchmark.units

    for compiler in compilers:
        best = None
        for result in results[benchmark.name][platform]:
            if result[0].startswith(compiler):
                if best:
                    best = get_best(benchmark, [best, result])
                else:
                    best = result

        if best:
            entry[compiler] = ('%.3g' % best[1]) if best[1] else 'X'
        else:
            entry[compiler] = '-'

    output.writerow(entry)
