#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define FREQUENCY 1

void start(int szer, int wys, float *M, float C, float waga);
void place(int ile, int x[], int y[], float temp[]);
void step();

typedef struct matrix_cell {
    float *states;          // Current temperatures.
    float *difference;      // Difference between current and last state (valid for not fixed cells only).
    int *fixed_temperature; // Stores 1 for cells with cooler or heater.
} matrix_t;

typedef struct simulation_data {
    float proportionality_factor;
    int steps;
    int height;
    int width;
    float cooler_temperature;
    int heaters_count;
} simulation_data_t;

int get_int(char *str) {
    char *rest_of_string = "";
    int num = strtol(str, &rest_of_string, 10);

    if ((errno & (EINVAL | ERANGE)) || strcmp(rest_of_string, "") != 0)
        exit(1);

    return num;
}

float get_float(char *str) {
    char *rest_of_string = "";
    float num = strtof(str, &rest_of_string);

    if ((errno & ERANGE) || strcmp(rest_of_string, "") != 0)
        exit(1);

    return num;
}

void read_int(FILE *file, int *num) {
    char temp[40];
    if (fscanf(file,"%s", temp) != 1)
        exit(1);

    *num = get_int(temp);
}

void read_float(FILE *file, float *num) {
    char temp[40];
    if (fscanf(file,"%s", temp) != 1)
        exit(1);

    *num = get_float(temp);
}

void read_matrix(FILE *file, matrix_t *matrix, long width, long height) {
    long index = 0;
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            read_float(file, &matrix->states[index]);
            ++index;
        }
    }
}

void read_heaters(FILE *file, simulation_data_t sim_data, int x[], int y[], float temp[], int size) {
    for (int i = 0; i < size; ++i) {
        read_int(file, &x[i]);
        if (x[i] < 0 || x[i] >= sim_data.height)
            exit(1);
        read_int(file, &y[i]);
        if (y[i] < 0 || y[i] >= sim_data.width)
            exit(1);
        read_float(file, &temp[i]);
    }
}

void print_matrix(matrix_t *matrix, int width, int height) {
    int index = 0;
    for (int i = 0; i < height; ++i) {
        for (int j = 0; j < width; ++j) {
            printf("%f\t", matrix->states[index]);
            ++index;
        }
        printf("\n");
    }
    printf("\n");
    while (getchar() != '\n') {}
}

void start_simulation(simulation_data_t sim_data, matrix_t *matrix, int x[],
                      int y[], float temp[]) {
    start(sim_data.width, sim_data.height, (float *)matrix, sim_data.cooler_temperature,
          sim_data.proportionality_factor);
    place(sim_data.heaters_count, x, y, temp);

    for (int i = 0; i < sim_data.steps; ++i) {
        step();
        if (i % FREQUENCY == 0)
            print_matrix(matrix, sim_data.width, sim_data.height);
    }
}

int main(int argc, char **argv) {
    if (argc != 4)
        exit(1);

    simulation_data_t sim_data;
    char *filename = argv[1];
    sim_data.proportionality_factor = get_float(argv[2]);
    sim_data.steps = get_int(argv[3]);
    sim_data.heaters_count = 0;

    FILE *file = fopen(filename, "r");
    if (file == NULL)
        exit(1);

    read_int(file, &sim_data.width);
    read_int(file, &sim_data.height);
    if (sim_data.width < 3 || sim_data.height < 3) // Useless simulation (only coolers).
        exit(1);
    read_float(file, &sim_data.cooler_temperature);

    matrix_t *matrix = malloc(sizeof(matrix_t));
    matrix->states = calloc(sim_data.width * sim_data.height, sizeof(float));
    if (matrix->states == NULL)
        exit(1);
    matrix->difference = calloc(sim_data.width * sim_data.height, sizeof(float));
    if (matrix->difference == NULL)
        exit(1);
    matrix->fixed_temperature = calloc(sim_data.width * sim_data.height, sizeof(int));
    if (matrix->fixed_temperature == NULL)
        exit(1);

    read_matrix(file, matrix, sim_data.width, sim_data.height);
    read_int(file, &sim_data.heaters_count);

    int *x = malloc(sizeof(int) * sim_data.heaters_count);
    if (x == NULL)
        exit(1);
    int *y = malloc(sizeof(int) * sim_data.heaters_count);
    if (y == NULL)
        exit(1);
    float *temp = malloc(sizeof(float) * sim_data.heaters_count);
    if (temp == NULL)
        exit(1);

    read_heaters(file, sim_data, x, y, temp, sim_data.heaters_count);
    if (fclose(file) != 0)
        exit(1);

    start_simulation(sim_data, matrix, x, y, temp);
    free(x);
    free(y);
    free(temp);
    free(matrix->states);
    free(matrix->difference);
    free(matrix->fixed_temperature);
    free(matrix);
    return 0;
}
