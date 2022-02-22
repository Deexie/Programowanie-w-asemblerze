#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

typedef int fixed;

void start(int width, int height, fixed *M, fixed weight);
void step(fixed T[]);

int get_int(char *str) {
    char *rest_of_string = "";
    int num = strtol(str, &rest_of_string, 10);

    if ((errno & (EINVAL | ERANGE)) || strcmp(rest_of_string, "") != 0)
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
    if (fscanf(file, "%f", num) != 1)
        exit(1);
}

float to_float(fixed v) {
    return (float)v / 1000;
}

fixed to_fixed(float v) {
    return (fixed)(v * 1000);
}

void read_matrix(FILE *file, fixed *matrix, long width, long height) {
    long index = 0;
    float value;
    int i, j;

    for (i = 0; i < height; ++i) {
        for (j = 0; j < width; ++j) {
            read_float(file, &value);
            matrix[index] = to_fixed(value);
            ++index;
        }
    }
}

void read_polutions(FILE *file, long height, fixed *T) {
    float value;
    int i;

    for (i = 0; i < height; ++i) {
        read_float(file, &value);
        T[i] = to_fixed(value);
    }
}

void print_matrix(fixed *matrix, int width, int height) {
    int index = 0;
    int i, j;
    for (i = 0; i < height; ++i) {
        for (j = 0; j < width; ++j) {
            if (j != 0)
                matrix[index] /= 1000;
            printf("%f\t", to_float(matrix[index]));
            ++index;
        }
        printf("\n");
    }
    printf("\n");
}

int main(int argc, char **argv) {
    if (argc != 2)
        exit(1);

    char *filename = argv[1];

    FILE *file = fopen(filename, "r");
    if (file == NULL)
        exit(1);

    int width, height, steps;
    float weight;
    read_int(file, &width);
    read_int(file, &height);
    read_float(file, &weight);

    fixed *matrix = calloc(height * width, sizeof(fixed));
    if (matrix == NULL)
        exit(1);

    read_matrix(file, matrix, width, height);
    start(width, height, matrix, to_fixed(weight));

    read_int(file, &steps);
    fixed *T = calloc(height, sizeof(fixed));
    if (T == NULL)
        exit(1);

    int i;
    for (i = 0; i < steps; ++i) {
        read_polutions(file, height, T);
        step(T);
        print_matrix(matrix, width, height);
    }

    if (fclose(file) != 0)
        exit(1);

    free(matrix);
    return 0;
}

