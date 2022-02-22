.PHONY: all clean

all: main

main: step.o main.o
	gcc -std=c99 step.o main.o -lpthread -o main -lm

step.o:
	as -o step.o step.s

main.o: main.c
	gcc -c -Wall -Wextra -O2 -o main.o main.c

clean:
	rm -f *.o main