# Akeno

## Overview

Akeno is a very basic legacy bootloader and operating system hello world.

It is not designed to actually do anything, it just prints a message when it enters the dummy kernel.

It was written for educational purposes and is likely not very efficient.

## Emulating

Using QEMU run the following command from within the project directory:
- `qemu-system-x86_64 -drive file=bin/akeno_os.img,format=raw,index=0,media=disk`

Alternatively, use the makefile:
- `make run`

## Building

This project uses Make. You are required to be on Linux or use the Windows Subsystem for Linux in order
to build this project.

### Dependencies

The following dependencies are required to build the project:
- `nasm`
- `gcc`
- `binutils`
- `make`
- `gcc-multilib`

### Compilation

Assuming you have the required dependencies, you can run the makefile as following:
- `make` 

This will build the operating system as a image file and and place it inside `./bin/`.
