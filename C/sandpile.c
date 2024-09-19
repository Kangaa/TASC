#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct {
    int age;
    int mass;
} PileStats;

typedef struct {
    int **grid;
    int n;
    int m;
    int k;
    int topple_value;
    int spread_value;
    PileStats stats;
} SandPile;

typedef struct {
    int x;
    int y;
} ToppleSite;

SandPile* initialize_sandpile(int n, int m, int k) {
    SandPile *pile = (SandPile*)malloc(sizeof(SandPile));
    pile->n = n;
    pile->m = m;
    pile->k = k;
    pile->topple_value = k % 4;
    pile->spread_value = k / 4;
    pile->stats.age = 0;
    pile->stats.mass = 0;

    pile->grid = (int**)malloc(n * sizeof(int*));
    for (int i = 0; i < n; i++) {
        pile->grid[i] = (int*)calloc(m, sizeof(int));
    }

    return pile;
}

void topple(SandPile *pile, ToppleSite site, ToppleSite *spread_locations, int *spread_count) {
    pile->grid[site.x][site.y] -= 4;
    *spread_count = 0;

    if (site.x != 0) spread_locations[(*spread_count)++] = (ToppleSite){site.x - 1, site.y};
    if (site.x != pile->n - 1) spread_locations[(*spread_count)++] = (ToppleSite){site.x + 1, site.y};
    if (site.y != 0) spread_locations[(*spread_count)++] = (ToppleSite){site.x, site.y - 1};
    if (site.y != pile->m - 1) spread_locations[(*spread_count)++] = (ToppleSite){site.x, site.y + 1};

    for (int i = 0; i < *spread_count; i++) {
        pile->grid[spread_locations[i].x][spread_locations[i].y] += pile->spread_value;
    }
}

void stabilize(SandPile *pile, ToppleSite *sites, int site_count) {
    ToppleSite spread_locations[4];
    int spread_count;

    while (site_count > 0) {
        ToppleSite site = sites[--site_count];
        if (pile->grid[site.x][site.y] >= pile->k) {
            topple(pile, site, spread_locations, &spread_count);
            for (int i = 0; i < spread_count; i++) {
                sites[site_count++] = spread_locations[i];
            }
        }
    }
}

void simulate_sandpile(int size, int k, int t_max, const char *drop_placement, const char *filename) {
    if (t_max == 0) {
        t_max = size * size * 4;
    }

    SandPile *pile = initialize_sandpile(size, size, k);
    FILE *file = fopen(filename, "w");
    if (file == NULL) {
        perror("Error opening file");
        exit(EXIT_FAILURE);
    }
    fprintf(file, "t,topples_at_t,unique_topples_at_t,mass\n");

    ToppleSite *sites = (ToppleSite*)malloc(size * size * sizeof(ToppleSite));
    int site_count;

    for (int i = 0; i < t_max; i++) {
        pile->stats.age += 1;

        ToppleSite drop_loc;
        if (strcmp(drop_placement, "random") == 0) {
            drop_loc.x = rand() % size;
            drop_loc.y = rand() % size;
        } else if (strcmp(drop_placement, "center") == 0) {
            drop_loc.x = size / 2;
            drop_loc.y = size / 2;
        }

        pile->grid[drop_loc.x][drop_loc.y] += 1;
        sites[0] = drop_loc;
        site_count = 1;
        stabilize(pile, sites, site_count);
        pile->stats.mass = 0;
        for (int x = 0; x < size; x++) {
            for (int y = 0; y < size; y++) {
                pile->stats.mass += pile->grid[x][y];
            }
        }

        fprintf(file, "%d,%d,%d,%d\n", i + 1, site_count, site_count, pile->stats.mass);
    }

    fclose(file);
    free(sites);
    for (int i = 0; i < size; i++) {
        free(pile->grid[i]);
    }
    free(pile->grid);
    free(pile);
}

int main(int argc, char *argv[]) {
    srand(time(NULL));

    int size = 10;
    int k = 4;
    int t_max = 100;
    const char *drop_placement = "center";
    const char *filename = "./data/sandpile.csv";

    simulate_sandpile(size, k, t_max, drop_placement, filename);

    return 0;
}