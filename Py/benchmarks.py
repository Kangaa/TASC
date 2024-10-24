#!/usr/bin/env python3
import argparse
import numpy as np
import copy
import csv
import pyperf
import statistics
import cmd
from sandpile import SandPile, stabilise


def export_csv(file, bench):
    runs = bench.get_runs()
    runs_values = [run.values for run in runs if run.values]

    rows = []
    for run_values in zip(*runs_values):
        min_value = min(run_values)
        median_value = statistics.median(run_values)
        max_value = max(run_values)
        rows.append([min_value, median_value, max_value])

    with open(file, 'w', newline='', encoding='ascii') as fp:
        writer = csv.writer(fp)
        writer.writerows(rows)


def create_test_grids(size):
    grids = []
    grid = np.zeros((size, size), dtype=np.int8)
    center = size // 2
    square_sizes = range(3, size + 1, 2)
    half_square = np.array([s // 2 for s in square_sizes])
    
    start_ix = center - half_square
    end_ix = center + half_square + 1  # +1 because Python slicing is exclusive at the end
    
    for i in range(len(square_sizes)):
        grid[start_ix[i]:end_ix[i], start_ix[i]:end_ix[i]] = 3
        grid[center, center] = 4
        grids.append(grid.copy())
    
    return grids

def add_tracemalloc_flag(cmd):
    cmd.extend(('--tracemalloc'))

def main(size, malloc):
    size = 101
    grid = create_test_grids(size)
    runner = pyperf.Runner()
    for i, g in enumerate(grid):
        pile = SandPile(g)
        if malloc:
            runner.bench_func(f'stabilise_{i}', 'stabilise()',pile)
        else:
            runner.timeit(name=f'stabilise_{i}', stmt='stabilise(pile)',
                      setup='from sandpile import stabilise, SandPile; pile = SandPile(grid.copy())',
                      globals={'grid': g})

        


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--tracemalloc', type=bool, default=False, help='Enable tracemalloc')
    parser.add_argument('--size', type=int, default=101, help='Size of the grid')
    args = parser.parse_args()
    main(args.size, args.tracemalloc)