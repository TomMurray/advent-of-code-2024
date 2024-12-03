# Advent of Code 2024

This year I'm trying out zig for advent of code. I always find it's a nice way to try and get some practical use of a new language. Please excuse any poor zig practice as I get used to it!

Solutions for a day are built with `zig build-exe day<N>.zig` e.g.:
```bash
zig build-exe day1.zig
```

Binaries usually are run with a single argument, the path to a file containing the input data for the day e.g.:
```
./day1 inputs/day1.txt
```
However, some solutions use command line parameters for part 1 & 2 solutions.
