# Snake Game - Assembly 8086

A classic Snake Game developed in **8086 Assembly Language** for DOS environments. The project demonstrates low-level programming concepts such as memory management, keyboard interrupt handling, screen buffer manipulation, and real-time game logic implementation.

## Features

* Interactive main menu
* Easy Mode and Hard Mode
* Dynamic score system
* Multiple food types with different point values
* Obstacles in Hard Mode
* Increasing game speed based on score
* Colored snake and food rendering
* Keyboard controls using arrow keys
* Game Over screen and replay support

## Controls

| Key   | Action             |
| ----- | ------------------ |
| ↑     | Move Up            |
| ↓     | Move Down          |
| ←     | Move Left          |
| →     | Move Right         |
| Enter | Select Menu Option |
| ESC   | Exit Game          |

## Technologies

* 8086 Assembly Language
* NASM Assembler
* DOS Interrupts (INT 10h, INT 16h, INT 21h, INT 1Ah)
* Text Mode Video Memory (0xB800)

## How to Run

### Assemble

```bash
nasm -f bin snake.asm -o snake.com
```

### Execute

Run the generated `snake.com` file in:

* DOSBox
* EMU8086
* DOS Emulator supporting COM programs

## Learning Objectives

This project was created to practice:

* Assembly language programming
* Direct memory access
* Keyboard input handling
* Game loop implementation
* Buffer-based screen rendering
* Data structures in low-level programming

