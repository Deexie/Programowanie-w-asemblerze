.PHONY: all clean

all: main

main: func.o main.o
	gcc func.o main.o -lpthread -o main

func.o:
	nasm -f elf64 -w+all -w+error -o func.o func.asm

main.o:
	gcc -c -Wall -Wextra -O2 -std=c11 -o main.o main.c

clean:
	rm -f *.o main