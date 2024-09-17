class SandPile:
	def __init__(self, size, spread_value, k):
		self.size = size
		self.spread_value = spread_value
		self.k = k
		self.grid = [[0 for _ in range(size)] for _ in range(size)]
		self.m = size  # Assuming m is the size of the grid

	def cascade(self, cell, cascade_stats):
		i, j = cell
		if self.grid[i][j] == self.k:
			self.topple(cell, cascade_stats)
			cascade_stats[0]['total_topples_at_t'] += 1
			if cell not in cascade_stats[1]:
				cascade_stats[1].append(cell)

	def topple(self, cell, cascade_stats):
		i, j = cell
		if j != 0:
			self.grid[i][j-1] += self.spread_value
			self.cascade((i, j-1), cascade_stats)
		elif j == 0:
			cascade_stats[0]['edge_loss'] += 1

		if j != self.m - 1:
			self.grid[i][j+1] += self.spread_value
			self.cascade((i, j+1), cascade_stats)
		elif j == self.m - 1:
			cascade_stats[0]['edge_loss'] += 1

# Example usage
sand_pile = SandPile(size=5, spread_value=1, k=4)
cascade_stats = [{'edge_loss': 0, 'total_topples_at_t': 0}, []]
sand_pile.topple((2, 2), cascade_stats)
print(sand_pile.grid)
print(cascade_stats)