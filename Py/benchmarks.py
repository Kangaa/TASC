import numpy as np
import pyperf
from sandpile import SandPile  # Assuming sandpile.py is in the same directory

def create_test_grids(size):
    grids = []
    grid = np.zeros((size, size), dtype=int)
    center = size // 2
    square_sizes = range(3, size + 1, 2)
    half_square = [s // 2 for s in square_sizes]

    start_ix = [center - hs for hs in half_square]
    end_ix = [center + hs for hs in half_square]

    for i in range(len(square_sizes)):
        grid[start_ix[i]:end_ix[i]+1, start_ix[i]:end_ix[i]+1] = 3
        grid[center, center] = 4
        grids.append(grid.copy())

    return grids

test_grids = create_test_grids(21)

def benchmark_topple(grid):
    pile = SandPile.from_grid(grid)
    site = (10, 10)
    runner = pyperf.Runner()
    runner.bench_func('topple', pile.topple, site)

def benchmark_stabilize(grid):
    pile = SandPile.from_grid(grid)
    site = (10, 10)
    runner = pyperf.Runner()
    runner.bench_func('stabilize', pile.stabilize, [site])


benchmark_stabilize(test_grids[4])