import numpy as np

import pandas as pd

class PileStats:
    def __init__(self, age=0, mass=0):
        self.age = age
        self.mass = mass

class SandPile:
    def __init__(self, grid, n, m, k, topple_value, spread_value, stats):
        self.grid = grid
        self.n = n
        self.m = m
        self.k = k
        self.topple_value = topple_value
        self.spread_value = spread_value
        self.stats = stats

    @classmethod
    def from_dimensions(cls, n, m, k):
        grid = np.zeros((n, m), dtype=int)
        topple_value = k % 4
        spread_value = k // 4
        stats = PileStats()
        return cls(grid, n, m, k, topple_value, spread_value, stats)

    @classmethod
    def from_grid(cls, grid):
        n, m = grid.shape
        k = 4
        topple_value = 0
        spread_value = 1
        stats = PileStats(0, np.sum(grid))
        return cls(grid, n, m, k, topple_value, spread_value, stats)

    def topple(self, site):
        spread_locations = []
        self.grid[site] -= 4

        if site[0] != 0:
            spread_locations.append((site[0] - 1, site[1]))
        if site[0] != self.n-1:
            spread_locations.append((site[0] + 1, site[1]))
        if site[1] != 0:
            spread_locations.append((site[0], site[1] - 1))
        if site[1] != self.m-1:
            spread_locations.append((site[0], site[1] + 1))

        for loc in spread_locations:
            self.grid[loc] += self.spread_value

        return spread_locations

    def stabilize(self, sites):
        topple_sites = []
        while sites:
            site = sites.pop(0)
            if self.grid[site] >= self.k:
                new_sites = self.topple(site)
                sites.extend(new_sites)
                topple_sites.append(site)
        return topple_sites

def simulate_sandpile(size=10, k=4, t_max=None, drop_placement="center", plot="none"):
    if t_max is None:
        t_max = size * size * 4

    pile = SandPile.from_dimensions(size, size, k)
    stats_log = []

    for i in range(t_max):
        pile.stats.age += 1

        if drop_placement == "random":
            drop_loc = (np.random.randint(size), np.random.randint(size))
        elif drop_placement == "center":
            drop_loc = ((size // 2) + 1, (size // 2) + 1)

        pile.grid[drop_loc] += 1
        topple_sites = pile.stabilize([drop_loc])
        pile.stats.mass = np.sum(pile.grid)

        stats_log.append({
                    't': i + 1,
                    'topples_at_t': len(topple_sites),
                    'unique_topples_at_t': len(set(topple_sites)),
                    'mass': pile.stats.mass
                })

    stats_log_df = pd.DataFrame(stats_log, columns=['t', 'topples_at_t', 'unique_topples_at_t', 'mass'])
    return stats_log_df