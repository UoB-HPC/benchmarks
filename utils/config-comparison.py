import sys
from benchmarks import *

print 'ERROR: script needs to be updated for new results format'
exit(1)

if len(sys.argv) != 3:
    print 'Usage: python config-comparison.py BENCHMARK PLATFORM'
    exit(1)

platform = sys.argv[2]

benchmark = next((x for x in benchmarks if x.name == sys.argv[1]), None)
if not benchmark:
    print 'Benchmark "' + sys.argv[1] + '" not found'
    exit(1)

output = []
output.append(['Result', 'Config'])
output.append(['------', '------'])

results = gather_results([platform])
results = results[benchmark.name][platform]
results = sorted(results, cmp=lambda x,y: compare_results(benchmark, x, y))
for result in results:
    if result[1]:
        x = '%.3g %s' % (result[1],benchmark.units)
    else:
        x = 'FAILED'
    output.append([x, result[0]])

# Print results in a column-aligned format.
# Code shamelessly stolen from https://stackoverflow.com/a/12065663
widths = [max(map(len, col)) for col in zip(*output)]
for row in output:
    print '  '.join((val.ljust(width) for val, width in zip(row, widths)))
