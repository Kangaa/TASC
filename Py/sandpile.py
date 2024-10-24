import numpy as np
from math import sqrt
import pandas as pd
class PileStats:
    def __init__(self, grid):
        self.age = 0
        self.mass = np.sum(grid)
        self.topple_count = np.zeros_like(grid, dtype=np.int64)

class SandPile:
    def __init__(self, grid):
        self.grid = grid
        self.n = grid.shape[0]
        self.m = grid.shape[1]
        self.k = 2 * grid.ndim
        self.topple_value = self.k % 4
        self.spread_value = self.k // 4
        self.stats = PileStats(self.grid)


def get_neighbours(pile, site):
    neighbours = []
    if site[0] != 0:
        neighbours.append((site[0] - 1, site[1]))
    if site[0] != pile.n - 1:
        neighbours.append((site[0] + 1, site[1]))
    if site[1] != 0:
        neighbours.append((site[0], site[1] - 1))
    if site[1] != pile.m - 1:
        neighbours.append((site[0], site[1] + 1))
    return neighbours 

def topple(pile, site):
    pile.grid[site] -= pile.k
    pile.stats.topple_count[site] += 1
    spread_locations = get_neighbours(pile, site)
    for loc in spread_locations:
        pile.grid[loc] += 1
    return spread_locations

def stabilise(pile):
    while np.any(pile.grid >= pile.k):
        for site in np.ndindex(pile.grid.shape):
            if pile.grid[site] >= pile.k:
                topple(pile, site)

def euclidean_distance(p1, p2):
    return sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

def manhattan_distance(p1, p2):
    return abs(p1[0] - p2[0]) + abs(p1[1] - p2[1])

def simulate_sandpile(size=10, k=4, t_max=None):
    if t_max is None:
        t_max = (size ** 2) * 4

    pile = SandPile(size, size, k)
    pile.grid = np.random.randint(0, 4, (size, size))

    stats_log = pd.DataFrame({
        't': range(1, t_max + 1),
        'topples_at_t': np.zeros(t_max, dtype=int),
        'unique_topples_at_t': np.zeros(t_max, dtype=int),
        'mass': np.zeros(t_max, dtype=int),
        'max_dist_euc': np.zeros(t_max, dtype=float),
        'max_dist_man': np.zeros(t_max, dtype=float)
    })

    for i in range(t_max):
        pile.stats.age += 1

        drop_loc = (np.random.randint(0, size), np.random.randint(0, size))

        pile.grid[drop_loc] += 1

        topples_at_last_t = np.copy(pile.stats.topple_count)

        stabilise(pile)

        pile.stats.mass = np.sum(pile.grid)

        topples_at_t = pile.stats.topple_count - topples_at_last_t
        n_topples = np.sum(topples_at_t)
        unique_topples = np.argwhere(topples_at_t > 0)

        if n_topples == 0:
            stats_log.at[i, 'max_dist_euc'] = stats_log.at[i, 'max_dist_man'] = 0
        elif n_topples == 1:
            stats_log.at[i, 'max_dist_euc'] = stats_log.at[i, 'max_dist_man'] = 1
        else:
            stats_log.at[i, 'max_dist_euc'] = max(euclidean_distance(drop_loc, site) for site in unique_topples)
            stats_log.at[i, 'max_dist_man'] = max(manhattan_distance(drop_loc, site) for site in unique_topples)

        stats_log.at[i, 'topples_at_t'] = n_topples
        stats_log.at[i, 'unique_topples_at_t'] = len(unique_topples)
        stats_log.at[i, 'mass'] = pile.stats.mass

        assert np.max(pile.grid) < k, f"{pile.grid}"

    return stats_log