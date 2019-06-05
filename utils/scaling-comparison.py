import argparse
import csv
import matplotlib
import matplotlib.pyplot as plt
import sys
from collections import namedtuple

from benchmarks import *

# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument('-b', '--benchmark', type=str, required=True,
                    help='name of benchmark')
parser.add_argument('--config-map', type=str,
                    help='CSV list of config=name mappings')
parser.add_argument('-e','--efficiency', action='store_true',
                    help='generate efficiency graph instead of relative')
parser.add_argument('--legend-pos', type=str, default='upper right',
                    help='position of legend')
parser.add_argument('-n', '--nodecounts', type=str, required=True,
                    help='CSV separated list of node counts')
parser.add_argument('-o', '--output', type=str, default='scaling.png',
                    help='output filename')
parser.add_argument('--platform-map', type=str,
                    help='CSV list of platform=name mappings')
parser.add_argument('-t', '--targets', type=str, required=True,
                    help='CSV list of platform:config pairs')
parser.add_argument('--title', type=str,
                    help='title of graph')
parser.add_argument('--wide', action='store_true',
                    help='generate widescreen graph')
parser.add_argument('--ymax', type=float,
                    help='y-axis maximum value')
args = parser.parse_args()

# Build platform name map
platform_map = dict()
if args.platform_map:
    for platform in args.platform_map.split(','):
        tokens = platform.split('=')
        if len(tokens) != 2:
            print('Invalid platform mapping "%s" (expected "platform=name")'
                  % platform)
            exit(1)
        platform_map[tokens[0]] = tokens[1]

# Build config name map
config_map = dict()
if args.config_map:
    for config in args.config_map.split(','):
        tokens = config.split('=')
        if len(tokens) != 2:
            print('Invalid config mapping "%s" (expected "config=name")'
                  % config)
            exit(1)
        config_map[tokens[0]] = tokens[1]

# Build list of targets
Target = namedtuple('Target', ['key', 'platform', 'config', 'prettyname'])
targets = []
for target in args.targets.split(','):
    tokens = target.split(':')
    if len(tokens) != 2:
        print('Invalid target "%s" (expected "target:config")' % target)
        exit(1)

    # Build prettyname
    platform = tokens[0]
    config = tokens[1]
    if tokens[0] in platform_map:
        platform = platform_map[tokens[0]]
    if tokens[1] in config_map:
        config = config_map[tokens[1]]
    prettyname = platform + ' ' + config

    targets.append(Target(target, tokens[0], tokens[1], prettyname))

# Find benchmark
benchmark = next((x for x in benchmarks if x.name == args.benchmark), None)
if not benchmark:
    print('Benchmark "' + args.benchmark + '" not found')
    exit(1)

# Get results
results = gather_results([t.platform for t in targets])

# Prepare CSV output
output = csv.DictWriter(sys.stdout, ['nodes'] + [t.key for t in targets])
output.writeheader()

# Split node counts into integer list
nodecounts = [int(x) for x in args.nodecounts.split(',')]

# Gather results for each target and output as CSV
scaling_results = dict()
for target in targets:
    scaling_results[target] = []
for n in nodecounts:
    entry = dict()
    entry['nodes'] = n
    for target in targets:
        found = False
        for result in results[benchmark.name][target.platform]:
            if result.jobsize == 'scale-'+str(n) and \
               result.config == target.config:
                r = '%.3g' % result.result
                entry[target.key] = r
                scaling_results[target].append(float(r))
                found = True
        if not found:
            print('Missing result for %s at %s nodes' % (target.key, n))
            exit(1)
    output.writerow(entry)


# Utils for processing results
baseline = scaling_results[targets[0]]
def gen_normalised(input):
    output = []
    for x,b in zip(input,baseline):
        if benchmark.higher_better:
            output.append(x / b)
        else:
            output.append(b / x)
    return output
def gen_efficiencies(input):
    output = []
    base = input[0] / nodecounts[0]
    for i in range(len(nodecounts)):
        if benchmark.higher_better:
            speedup = input[i] / input[0]
        else:
            speedup = input[0] / input[i]
        output.append(100.0 * (speedup / (nodecounts[i] / nodecounts[0])))
    return output

# Generate normalised results and scaling efficiencies
norm_results = []
eff_results = []
for t in range(len(targets)):
    target = targets[t]
    norm_results.append(gen_normalised(scaling_results[target]))
    eff_results.append(gen_efficiencies(scaling_results[target]))


# Plot results
fig, ax = plt.subplots()
bar_width = 1/(len(targets)+1)
base_offset = bar_width * ((len(targets) - 1) / 2)
bar_offsets = [x - base_offset for x in range(len(norm_results[t]))]
for t in range(len(targets)):
    target = targets[t]
    if args.efficiency:
        ax.plot(eff_results[t], marker='.', zorder=3, label=target.prettyname)
    else:
        ax.bar(bar_offsets, norm_results[t], width=bar_width, zorder=3,
               label=target.prettyname)
        bar_offsets = [x + bar_width for x in bar_offsets]

# Configure axes and legend
plt.legend(loc=args.legend_pos, framealpha=1.0, prop={'size': 10})
plt.xticks(range(len(nodecounts)), nodecounts)
ax.yaxis.grid(zorder=0)
ax.tick_params(labelright=True)
ax.set_ylim([0, args.ymax])

# Add axis and graph titles
ax.set(xlabel='Nodes')
if args.efficiency:
    ax.set(ylabel='Scaling efficiency (%)')
else:
    ax.set(ylabel='Performance (rel. to %s)' % targets[0].prettyname)
if args.title:
    ax.set(title=args.title)

# Save graph to file
if args.wide:
    fig.set_size_inches(10, 5)
fig.savefig(args.output)
