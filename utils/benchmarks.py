import os
from collections import namedtuple

class stream:
    name = 'stream'
    fullname = 'STREAM'
    units = 'GB/s'
    higher_better = True
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            line = get_last_line(file.readlines(), 'Triad')
            return float(line.split()[1]) / 1000

class cloverleaf:
    name = 'cloverleaf'
    fullname = 'CloverLeaf'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            line = get_last_line(file.readlines(), 'Wall clock')
            return float(line.split()[2])

class tealeaf:
    name = 'tealeaf'
    fullname = 'TeaLeaf'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            line = get_last_line(file.readlines(), 'Wall clock')
            return float(line.split()[2])

class snap:
    name = 'snap'
    fullname = 'SNAP'
    units = 'grind time'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            line = get_last_line(file.readlines(), 'Grind Time')
            return float(line.split()[3])

class neutral:
    name = 'neutral'
    fullname = 'Neutral'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            line = get_last_line(file.readlines(), 'Final Wallclock')
            return float(line.split()[2][:-1])

class cp2k:
    name = 'cp2k'
    fullname = 'CP2K'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            if not get_last_line(lines, 'DBCSR STATISTICS'):
                return None
            line = get_last_line(lines, 'CP2K')
            return float(line.split()[5])

class gromacs:
    name = 'gromacs'
    fullname = 'GROMACS'
    units = 'ns/day'
    higher_better = True
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'Performance')
            return float(line.split()[1])

class namd:
    name = 'namd'
    fullname = 'NAMD'
    units = 'days/ns'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'Benchmark time:')
            return float(line.split()[7])

class nemo:
    name = 'nemo'
    fullname = 'NEMO'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'Average')
            return float(line.split()[2])

class openfoam:
    name = 'openfoam'
    fullname = 'OpenFOAM'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines           = file.readlines()
            final_time      = float(get_last_line(lines, 'ExecutionTime').split()[2])
            first_step_time = float(get_first_line(lines, 'ExecutionTime').split()[2])
            return final_time - first_step_time

class opensbli:
    name = 'opensbli'
    fullname = 'OpenSBLI'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'Total Wall time')
            return float(line.split()[11])

class um:
    name = 'um'
    fullname = 'Unified Model'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'Elapsed Wallclock Time')

            return float(line.split()[4])

class vasp:
    name = 'vasp'
    fullname = 'VASP'
    units = 'seconds'
    higher_better = False
    def get_runtime(self, filename):
        with open(filename, 'r') as file:
            lines = file.readlines()
            line = get_last_line(lines, 'LOOP+')
            return float(line.split()[6])

# Returns the first line in a list which contains a string.
def get_first_line(lines, pattern):
    for line in lines:
        if pattern in line:
            return line

# Returns the last line in a list which contains a string.
def get_last_line(lines, pattern):
    for line in reversed(lines):
        if pattern in line:
            return line

# Compares two benchmark results, returns -1 if a is better than b, otherwise 1.
def compare_results(benchmark, a, b):
    if not b or not b.result:
        return -1
    if not a or not a.result:
        return 1
    if a.result > b.result if benchmark.higher_better else a.result < b.result:
        return -1
    else:
        return 1

# Returns the best result in a list of results for a specific benchmark.
def get_best(benchmark, results):
    return reduce(lambda x,y: x if compare_results(benchmark,x,y) < 0 else y, \
                  results, None)

# Gather all available benchmark results for each platform in `platforms`.
def gather_results(platforms):
    Result = namedtuple('Result', ['jobsize', 'config', 'result'])
    results = dict()
    for benchmark in benchmarks:
        results[benchmark.name] = dict()
        for platform in platforms:
            results[benchmark.name][platform] = []

            # Get list of files in results subdirectory for benchmark/platform.
            result_dir = benchmark.name + '/' + platform + '/results'
            try:
                files = os.listdir(result_dir)
            except:
                continue

            # Loop over result files and attempt to extract results.
            for file in files:
                path = result_dir + '/' + file

                # Extract jobsize
                underscore = file.find('_')
                if underscore < 0:
                    continue
                jobsize = file[0:underscore]
                if not (jobsize.startswith('scale-') or jobsize == 'node'):
                    continue

                # Extract config
                config = file[underscore+1:-4]
                config = config[:-4] if config[-4:] == '.out' else config

                result = Result(jobsize,config,None)
                try:
                    result = Result(jobsize,config,benchmark.get_runtime(path))
                except:
                    pass
                results[benchmark.name][platform].append(result)

    return results


miniapps = []
miniapps.append(stream())
miniapps.append(cloverleaf())
miniapps.append(tealeaf())
miniapps.append(snap())
miniapps.append(neutral())

applications = []
applications.append(cp2k())
applications.append(gromacs())
applications.append(namd())
applications.append(nemo())
applications.append(openfoam())
applications.append(opensbli())
applications.append(um())
applications.append(vasp())

benchmarks = miniapps + applications
