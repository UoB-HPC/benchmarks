import sys
from benchmarks import *

print 'ERROR: script needs to be updated for new results format'
exit(1)

if len(sys.argv) != 2:
    print 'Usage: python best-for-platform.py PLATFORM'
    exit(1)

platform = sys.argv[1]

output = []
output.append(['Benchmark', 'Result', 'Config'])
output.append(['---------', '------', '------'])

results = gather_results([platform])
for benchmark in benchmarks:
        best_result = get_best(benchmark, results[benchmark.name][platform])
        if not best_result:
            continue

        output.append([benchmark.fullname, \
                       '%.3g %s' % (best_result[1],benchmark.units),
                       best_result[0]])

# Print results in a column-aligned format.
# Code shamelessly stolen from https://stackoverflow.com/a/12065663
widths = [max(map(len, col)) for col in zip(*output)]
for row in output:
    print '  '.join((val.ljust(width) for val, width in zip(row, widths)))
