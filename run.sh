#!/bin/sh

set -eu

nasm -f elf64 ./fizzbuzz.asm -o fizzbuzz.o
ld fizzbuzz.o -o fizzbuzz
./fizzbuzz $@

