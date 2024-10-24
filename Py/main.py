import argparse
import os
from sandpile import simulate_sandpile

def main():
	parser = argparse.ArgumentParser(description="Simulate a sandpile model.")
	parser.add_argument('--size', type=int, default=10, help='Size of the sandpile grid')
	parser.add_argument('--k', type=int, default=4, help='Threshold value for toppling')
	parser.add_argument('--t_max', type=int, default=100, help='Maximum number of iterations')
	parser.add_argument('--reps', type=int, default=1, help='Number of simulations')
	parser.add_argument('--save', default=True, action='store_true', help='Save the resulting DataFrame to a file')

	args = parser.parse_args()

	for rep in range(args.reps):
		result_df = simulate_sandpile(size=args.size, k=args.k, t_max=args.t_max)
		
		if args.save:
			os.makedirs('Py/data/sims', exist_ok=True)
			filename = f'Py/data/sims/sandpile_size{args.size}_rep{rep+1}.csv'
			result_df.to_csv(filename, index=False)
			print(f'Results saved to {filename}')

if __name__ == "__main__":
	main()