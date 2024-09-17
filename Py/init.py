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

def simulate_abelian_sandpile(height, width, iterations):
    sandpile = np.zeros((height, width), dtype=int)

    for _ in range(iterations):
        sandpile = topple(sandpile)

    return sandpile