#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    int age;
    int mass;
    int **topple_count;
} PileStats;

typedef struct {
    int **grid;
    int n;
    int m;
    int k;
    PileStats stats;
} SandPile;

typedef struct {
    int x;
    int y;
} Site;

SandPile* initialize_sandpile(int **grid, int n, int m, int k);
void get_neighbours(SandPile *pile, Site site, Site *neighbours, int *count);
void topple(SandPile *pile, Site site);
void stabilize(SandPile *pile);

int** create_grid(int n, int m);
void free_grid(int **grid, int n);
void create_test_grids(int size, int *  ***grids, int *num_grids);
void benchmark_stabilize(int ***grids, int num_grids, int k, const char *filename);

int main(int argc, char *argv[]) {
    srand(time(NULL));

    int size = 101; // Adjust the size as needed
    int k = 4;
    const char *filename = "benchmark_results.csv";

    int ***grids = NULL;
    int num_grids = 0;
    create_test_grids(size, grids, &num_grids);

    benchmark_stabilize(&grids, num_grids, k, filename);

    // Free test grids
    for (int i = 0; i < num_grids; i++) {
        free_grid(grids[i], size);
    }
    free(grids);

    return 0;
}

// Initializes a new sandpile with the given grid
SandPile* initialize_sandpile(int **grid, int n, int m, int k) {
    SandPile *pile = (SandPile*)malloc(sizeof(SandPile));
    pile->n = n;
    pile->m = m;
    pile->k = k;

    // Allocate and copy the grid
    pile->grid = (int**)malloc(n * sizeof(int*));
    pile->stats.topple_count = (int**)malloc(n * sizeof(int*));
    pile->stats.mass = 0;
    for (int i = 0; i < n; i++) {
        pile->grid[i] = (int*)malloc(m * sizeof(int));
        pile->stats.topple_count[i] = (int*)calloc(m, sizeof(int));
        for (int j = 0; j < m; j++) {
            pile->grid[i][j] = grid[i][j];
            pile->stats.mass += grid[i][j];
        }
    }
    pile->stats.age = 0;

    return pile;
}

// Frees the memory allocated for a sandpile
void free_sandpile(SandPile *pile) {
    for (int i = 0; i < pile->n; i++) {
        free(pile->grid[i]);
        free(pile->stats.topple_count[i]);
    }
    free(pile->grid);
    free(pile->stats.topple_count);
    free(pile);
}

// Returns the neighboring sites of a given site
void get_neighbours(SandPile *pile, Site site, Site *neighbours, int *count) {
    *count = 0;
    if (site.x > 0) neighbours[(*count)++] = (Site){site.x - 1, site.y};
    if (site.x < pile->n - 1) neighbours[(*count)++] = (Site){site.x + 1, site.y};
    if (site.y > 0) neighbours[(*count)++] = (Site){site.x, site.y - 1};
    if (site.y < pile->m - 1) neighbours[(*count)++] = (Site){site.x, site.y + 1};
}

// Performs a topple operation at a given site
void topple(SandPile *pile, Site site) {
    pile->grid[site.x][site.y] -= pile->k;
    pile->stats.topple_count[site.x][site.y] += 1;

    Site neighbours[4];
    int count;
    get_neighbours(pile, site, neighbours, &count);

    for (int i = 0; i < count; i++) {
        pile->grid[neighbours[i].x][neighbours[i].y] += 1;
    }
}

// Stabilizes the sandpile using the naive method
void stabilize(SandPile *pile) {
    int unstable = 1;
    while (unstable) {
        unstable = 0;
        for (int i = 0; i < pile->n; i++) {
            for (int j = 0; j < pile->m; j++) {
                if (pile->grid[i][j] >= pile->k) {
                    topple(pile, (Site){i, j});
                    unstable = 1;
                }
            }
        }
    }
}

// Creates a new grid of size n x m
int** create_grid(int n, int m) {
    int **grid = (int**)malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++) {
        grid[i] = (int*)calloc(m, sizeof(int));
    }
    return grid;
}

// Frees the memory allocated for a grid
void free_grid(int **grid, int n) {
    for (int i = 0; i < n; i++) {
        free(grid[i]);
    }
    free(grid);
}

// Generates test grids of increasing square sizes
void create_test_grids(int size, int ***grids, int *num_grids) {
    int center = size / 2;
    int start_size = 3;
    int step = 2;
    int max_square_size = size;

    *num_grids = ((max_square_size - start_size) / step) + 1;
    *grids = (int**)malloc(*num_grids * sizeof(int*));

    for (int idx = 0, square_size = start_size; square_size <= max_square_size; square_size += step, idx++) {
        int **grid = create_grid(size, size);
        int half_square = square_size / 2;

        int start_ix = center - half_square;
        int end_ix = center + half_square;

        for (int i = start_ix; i <= end_ix; i++) {
            for (int j = start_ix; j <= end_ix; j++) {
                grid[i][j] = 3;
            }
        }
        grid[center][center] = 4; // Set the center cell to 4
        (*grids)[idx] = grid;
    }
}

// Benchmarks the stabilize function on each test grid
void benchmark_stabilize(int ***grids, int num_grids, int k, const char *filename) {
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Error opening CSV file");
        exit(EXIT_FAILURE);
    }
    fprintf(file, "grid_size,total_topples,time_ms\n");

    for (int idx = 0; idx < num_grids; idx++) {
        int **grid = (*grids)[idx];
        int n = 0;
        while (grid[n] != NULL) n++; // Assuming square grids
        SandPile *pile = initialize_sandpile(grid, n, n, k);

        clock_t start_time = clock();
        stabilize(pile);
        clock_t end_time = clock();

        double time_ms = ((double)(end_time - start_time)) / CLOCKS_PER_SEC * 1000.0;

        // Calculate total topples
        int total_topples = 0;
        for (int i = 0; i < pile->n; i++) {
            for (int j = 0; j < pile->m; j++) {
                total_topples += pile->stats.topple_count[i][j];
            }
        }

        fprintf(file, "%d,%d,%.3f\n", n, total_topples, time_ms);

        free_sandpile(pile);
    }

    fclose(file);
}