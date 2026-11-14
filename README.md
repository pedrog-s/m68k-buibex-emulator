# BUIBEX Emulator in 68000 Assembly

An emulator, written in Motorola 68000 assembly for the EASy68K simulator, for BUIBEX (*Basic UIB Emulation eXperience*): a small 16-bit machine designed for teaching.

Built for the Computer Structure I course (*Estructura de Computadors I*) of the Computer Engineering degree at the University of the Balearic Islands (UIB), 2024-25. Comments are in Spanish.

## How it works

Everything about the emulated machine lives in the 68K's memory: its memory, its registers `T0`, `T1` and `R2`–`R5`, the program counter, the instruction register and the status flags `Z`, `N` and `C`.

- **Fetch, decode, execute loop:** each 16-bit instruction is fetched from the emulated memory, decoded and then executed.
- **Decoder as a subroutine:** it receives the instruction word through the stack and identifies the instruction by testing its bits, following the encoding table.
- **Execution through a jump table**, with one routine per instruction.
- **Shared subroutines** to read and write any register by its index and to update the flags.

## Instruction set

| Group | Instructions |
|---|---|
| Control | `HLT`, `JMI M` (jump), `JMZ M` (jump if zero), `JMN M` (jump if negative) |
| Memory | `STO Tj, M`, `LOA M, Tj` |
| Registers and ALU | `TRA Xa, Xb`, `ADD Ra, Rb`, `SUB Ra, Rb`, `CMP Ra, Rb`, `NAN Ra, Rb` (nand) |
| Constants | `SET #c, Rb`, `INC #c, Rb`, with 8-bit constants sign-extended to 16 bits |

Memory addresses are 8 bits wide. Programs and data share the same memory, as in a Von Neumann machine.

## Sample program

The program loaded at the top of the file, in the `EMEM` vector, multiplies 4 by 3 with repeated additions and stores the result, 12, in memory:

```text
 0: LOA 14,T0     ; T0 ← A (4)
 1: JMZ 11        ; if A = 0, the result is 0
 2: TRA T0,R2
 3: LOA 15,T1     ; T1 ← B (3)
 4: JMZ 11
 5: TRA T1,R3     ; R3 counts down from B
 6: SET #0,R4     ; R4 accumulates the result
 7: ADD R2,R4     ; R4 ← R4 + A
 8: INC #-1,R3
 9: JMZ 11
10: JMI 7
11: TRA R4,T0
12: STO T0,16     ; result → address 16
13: HLT
14: 4             ; A
15: 3             ; B
16: 0             ; result
```

To emulate another program, encode it and replace the words in `EMEM`.

## Run it

1. Install [EASy68K](http://www.easy68k.com/) (Windows).
2. Open `buibex_emulator.X68` and assemble it with **F9**.
3. Run it in the simulator and inspect the emulated memory when it stops.
