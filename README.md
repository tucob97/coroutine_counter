# Coroutine Example in GAS Assembly

This repository contains a minimal coroutine example implemented in **GAS assembly**.
- Inspired by [TsodingDaily’s video](https://www.youtube.com/watch?v=sYSP_elDdZw&ab_channel=TsodingDaily).

## What is a Coroutine?

A coroutine is a function that can pause and resume its execution, 
allowing cooperative multitasking without the overhead of threads or processes. 
This example shows a simple coroutine for a counter function
implemented in assembly language using low-level stack manipulation.


The coroutine implemented has this characteristic:
- Stackful coroutine with 4 KB stack space
- Use "yield" for scheduling between coroutines

## How to run example?
I personally use Taskfile, so if you have it installed

The default task is the coroutine implementation of counter function
```bash
task 
```

There is also a "seq" task for the sequential implementation (No coroutines)
```bash
task seq 
```
