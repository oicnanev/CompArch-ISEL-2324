# Laboratory activity 01

```assembly
; -----------------------------------------------------------------------------
; Ficheiro:  lab01.S
; Descricao: Codigo de suporte a realizacao da 1a atividade laboratorial de AC.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      11-03-2022
; -----------------------------------------------------------------------------

	; r0 guarda o valor da variavel M
	; r1 guarda o valor da variavel m
	; r2 guarda o valor da variavel p
	; r3 e utilizado para guardar valores temporariamente

	mov	r2, #0
while:
	mov	r3, #0
	cmp	r3, r1
	bhs	while_end
	add	r2, r2, r0
	sub	r1, r1, #1
	b	while
while_end:
	b	.
```



**Question 1** -  Give the reason for using the **bhs** statement in the implementation of the *while* cycle test condition, rather than using the **bge** statement.

**Response** - The **bhs** statement is used because it evaluates the **C (carry) flag**, which is used for operations with natural numbers. Instead, the **bge** statement **XOR's the N (MSB) and V (overflow) flags** is used for operations with signed integers.



**Question 2** - Given the above code, file lab01.S change it so that the piece of code contained in it starts to perform the functionality specified in the C code bellow, which multiplies two encoded natural numbers - M and m -, coded with 8 bits, using the algorithm of successive additions.

```c
uint16_t p = 0;

if ( M != 0 ) {
    while ( m > 0 ) {
        p = p + M ;
        m - -;
    }
}
```

**Response** :

```assembly
 ; r0 guarda o valor da variavel M
 ; r1 guarda o valor da variavel m
 ; r2 guarda o valor da variavel p
 ; r3 e utilizado para guardar valores temporariamente

 mov r2, #0
if:
 mov r3, #0
 cmp r0, r3
 beq if_end
while:
 mov r3, #0
 cmp r3, r1
 bhs while_end
 add r2, r2, r0
 sub r1, r1, #1
 b while
while_end:
if_end:
 b .
```



**Question 3** - .lst file after assembled 

**Response**:

```
P16 assembler v1.5 (Feb  9 2024)	lab01.lst	Wed Mar 06 22:11:48 2024

Sections
Index   Name            Address   Size
0       .text           0000      0014 20

Symbols
Name                    Type      Value       Section
line#24                 LABEL     0012 18     .text
while                   LABEL     0006 6      .text
while_end               LABEL     0012 18     .text

Code listing
   1           	; ---------------------------------------------------------------------------
   2           	; Ficheiro:  lab01.S
   3           	; Descricao: Codigo de suporte a realizacao da 1a atividade laboratorial de AC.
   4           	; Autor:     Tiago M Dias (tiago.dias@isel.pt)
   5           	; Data:      11-03-2022
   6           	; ---------------------------------------------------------------------------
   7           	
   8           		; r0 guarda o valor da variavel M
   9           		; r1 guarda o valor da variavel m
  10           		; r2 guarda o valor da variavel p
  11           		; r3 e utilizado para guardar valores temporariamente
  12           		
  13 0000 02 60		mov r2, #0		; p = 0
  14 0002 24 88		sub r4, r2, r0 	; r0 is M
  15 0004 06 40		beq while_end  ; if (M == 0) terminate
  16           	while:
  17 0006 03 60		mov r3, #0		; to use a temp 0 in the next comparisson
  18 0008 B0 B8		cmp r3, r1		; r1 is m
  19 000A 03 48		bhs while_end  ; while (0 > m)
  20 000C 22 80		add r2, r2, r0	; p = p + M
  21 000E 91 A8		sub r1, r1, #1	; m--
  22 0010 FA 5B		b   while		; jump to while
  23           	while_end:
  24 0012 FF 5B		b   .			; stay here
  25           	
```



**Question 4** - Associate each application with a step in the process of developing an assembly language program for the P16 processor.

**Response**:

- Source code edition - ```Visual Studio Code```
- Machine code translation - ```p16as```
- Program execution - ```p16sim```
- Program test and debug - ```p16dbg```



**Question 5** - To optimize the multiplication calculation, we want to minimize the number of iterations of the *while* cycle by associating the operand (multiplying or multiplier) with the smallest value to the variable **m**.

**Response**:

```assembly
; -----------------------------------------------------------------------------
; Ficheiro:  lab01_opt2.S
; Descricao: Codigo de suporte a realizacao da 1a atividade laboratorial de AC.
; Autor:     Grupo 2
; Data:      07-03-2024
; -----------------------------------------------------------------------------

	; r0 guarda o valor da variavel M
	; r1 guarda o valor da variavel m
	; r2 guarda o valor da variavel p
	; r3 e utilizado para guardar valores temporariamente
	
	; if m > M, R0 = m, r1 = M
	cmp R0, R1		; check whats higher
	bhs main		; if M is higher or same than m, do nothing 
	mov R3, R0		; else, change positions
	mov R0, r1
	mov r1, r3	
main:	
	mov r2, #0		; p = 0
	sub r3, r2, r0 	; r0 is M
	beq while_end  ; if (M == 0) terminate
while:
	mov r3, #0		; to use a temp 0 in the next comparisson
	cmp r3, r1		; r1 is m
	bhs while_end  ; while (0 > m)
	add r2, r2, r0	; p = p + M
	sub r1, r1, #1	; m--
	b   while		; jump to while
while_end:
	b   .			; stay here
```

