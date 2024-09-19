import numpy as np

## create sandpile class
class Sandpile:
    def __init__(self, height, width):
        self.height = height
        self.width = width
        self.sandpile = np.zeros((height, width), dtype=int)

def topple(sandpile):
    height, width = sandpile.shape
    toppled = np.zeros_like(sandpile)

    for i in range(height):
        for j in range(width):
            if sandpile[i, j] >= 4:
                toppled[i, j] -= 4
                if i > 0:
                    toppled[i - 1, j] += 1
                if i < height - 1:
                    toppled[i + 1, j] += 1
                if j > 0:
                    toppled[i, j - 1] += 1
                if j < width - 1:
                    toppled[i, j + 1] += 1

    return sandpile + toppled

class PileStats:
    def __init__(self):
        self.age = 0
        self.mass = 0.0
        self.n_topples = 0
        self.edge_loss = 0

class SandPile:
    def __init__(self, n, m, k):
        self.grid = [[0 for _ in range(m)] for _ in range(n)]
        self.n = n
        self.m = m
        self.k = k
        self.topple_value = k % 4
        self.spread_value = k // 4
        self.stats = PileStats()

# Example usage
if __name__ == "__main__":
    sand_pile = SandPile(5, 5, 10)
    print(sand_pile.grid)
    print(sand_pile.stats.age)

def simulate(sandpile, n):
    
