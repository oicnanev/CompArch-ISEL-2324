# P16 Processor



## Overview

16-bit RISC-type processor with load/store architecture

16 general-purpose records;

43 instructions organized into three classes:

- Data Manipulation Instructions

- Jumping Instructions

- Data Transfer Instructions


Supports the implementation of subroutines;

Support for the implementation of data stack structure;

64 KB memory space, 16-bit or 8-bit accessible;

Support for processing external interrupts.



![image-20240303132619545](../../images/image-20240303132619545.png)



## Operating modes

The P16 processor supports two distinct operating modes:

- **Normal Mode (N)**, used for normal program execution;

- **Interrupt Mode (I)**, used to process external interrupt requests.

Both modes provide access to all system resources and allow you to switch mode of operation.
The change of operating mode can be done by software or result from an exception:
- Reset;
- Interrupt Request (IRQ)

## Registers

The P16 processor provides the programmer with a total of 19 registers, all 16-bit:
- 16 general-purpose records;
-  2 processor status records (CPSR and SPSR).

The records that can be accessed are defined by the Processor operating mode

### General use registers

The 16 general-purpose records are divided into two blocks of 8 records:
- The low block contains records R0 to R7;
- The high block contains records R8 through R15.

The low block registers are of generic use and accessible by any instruction that have a record as either a source or destination operand.
High block registers cannot be used as the first source operand of the Instructions.
Some registers of the high block are in generic use - R9 to R12, but three are committed tospecific functionalities: R13, R14, R15

### Special use register

- **R15** - maps the **Program Counter (PC)**, saving, at all times, the address of memory where the code of the next instruction to be executed is
- **R14** - is used as a **Link Register (LR)** to store the return address in calls to subroutines or on the input in Break mode.
- **R13** -  is used as a **Stack Pointer (SP)** for stack manipulation instructions.

### Processor state registers

The P16 processor has two status records:
- **Current Processor Status Register (CPSR)**, which stores the current state of the processor;
- **Saved Processor Status Register (SPSR)**, to save the CPSR value at the moment 
immediately prior to entering Interrupt mode.

**CPSR** and **SPSR** are accessible in both operating modes, but using its own instructions.

Both are 16-bit registers, where only bits 0 through 5 have meaning:

|      |      |      |      |      |      |      |      |      |      | M    | I    | N    | V    | C    | Z    |
| ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| 15   |      |      |      |      |      |      |      |      | 6    | 5    | 4    | 3    | 2    | 1    | 0    |

Meaning of CPSR/SPSR bits:

- **Z** - takes the value ```one``` when the value resulting from performing a logical operation or arithmetic is zero;
- **C** - takes the value ```one``` when performing an arithmetic operation results transport to the most significant digit, or in the operations of displacement o last bit shifted is 1;
- **V** - takes the value ```one``` when, when performing a subtraction or a sum, the result exceeds the domain, understood as integers with a code sign of the add-ons for two;
- **N** - takes the logical value of the highest weight bit of the result after performing a arithmetic or logical operation;
- **I** - enables the handling of external interruptions;
- **M** - sets the operating mode of the processor

## Instruction set

The P16 processor instruction set comprises 43 distinct instructions.

The instructions are organized into 3 classes:

- Data processing instructions;

- Control instructions;

- Data transfer instructions.

The data processing instructions adopt a format with three operands.
All instructions are encoded with 16 bits.



### Data processing instructions

The data processing instructions perform operations involving the registers of general and constant use.
There are six subclasses of data processing instructions:

- Arithmetic instructions (add, sub, adc, sbc);
- Comparison instructions (cmp);
- Constant loading instructions (mov, movt);
- Instructions for copying data between registers (mov, movn);
- Logical instructions (and, orr, eor);
- Shifting instructions(lsl, lsr, asr, ror, rol, rrx, rlx).

Most data processing instructions also update the bits of status in the CPSR, depending on the calculated result.

```assembly
; ARITMETHIC INSTRUCTIONS ------------------
ADD R3, R5, #1 		;R3 = R5 + 1
ADD R5, R4, R3 		;R5 = R4 + R3
SUB R3, R5, #1 		;R3 = R5 - 1
SUB R5, R4, R3 		;R5 = R4 - R3
ADC R5, R5, R2 		;R5 = R5 + R2 + C
SBC R5, R4, R3 		;R5 = R4 – R3 - C

; COMPARISON INSTRUCTION -------------------
CMP R4, R5 			;CPSR = R4 - R5

; CONSTANT LOADING INSTRUCTIONS ------------
MOV R0, #255		;R3 = 0x00FF 
MOVT R0, #255		;R3 = OxFFFF

; INSTRUCTIONS FOR COPYING BETWEEN REGISTERS
MOV R0, R1			;R3 = R1
MOVN R0, R1			;R3 = ~R1

; LOGICAL INSTRUCTIONS ---------------------
AND R3, R5, R1 		;R3 = R5 & R1
ORR R5, R4, R3 		;R5 = R4 | R3
EOR R3, R5, R1 		;R3 = R5 ^ R1

; SHIFTING INSTRUCTIONS --------------------
LSL R5, R2, #5 		; R5 = R2 << 5
LSR R5, R4, #4 		; R5 = R4 >> 4
ASR R4, R2, #10 	; 
ROR R6, R4, #5 		; R6 = R4 RIGHT ROTATE 4, 0208 -> 8020
ROR R6, R4, #16-4 	; R6 = R4 LEFT ROTATE 4, 8020 -> 0208
RRX R5, R4 			; R5(15)=Cy, R5(14..0)=R4(15..1), Cy=R4(0)
```



