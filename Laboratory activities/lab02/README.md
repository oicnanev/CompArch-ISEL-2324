# Laboratorial Activity 02

## 1. Objectives

This work of Computer Architecture aims to study the processes of translation of programs written in *P16 assembly* language into machine code and their loading into memory, as well as the operation of the *P16 processor bus*. The experimental component of the work is carried out on the SDP16 board.

## 2. Requirements

- SDP16 board with USB cable
- Personal computer with a native or virtual machine installation of the Microsoft Windows 10 operating system, or a higher version
- Assembler *p16as* for the P16 processor
- *Visual Studio Code* IDE with P16 plugin or *Notepadd++* editor

## 3.  Preparatory work for laboratory activity

The tasks indicated in this section constitute the preparatory work for this laboratory activity, so they should be carried out in advance of the laboratory session.

### 3.1 Work environment preparation

1. On your personal computer, access the board created to store the work carried out in AC in the current academic semester when preparing [Laboratory Activity 01](../lab01)
2. Create a board of directors named lab02 within that board.
3. Copy the *"P16 Instructions Coding Guide"* to the docs directory, which contains the description of the P16 instruction coding map.

### 3.2 Analysis of programs and their coding in machine language of P16

```assembly
	.text
	ldr		r0, var2_addr
loop:
	ldrb	r1, [r0, #0]
	add 	r1, r1, #1
	strb	r1, [r0, #0]
	b		loop
var2_addr:
	.word	var2
	
	.data
var1:
	.byte	0xAC
var2:
	.byte	126
var3:
	.word	0x2022
```



1. Analyze the program presented, written in the assembly language of the P16 processor, and indicate its functionality.

   **Answer** 

   A funcionalidade deste programa é demonstrar um loop infinito que incrementa o valor de uma variável. Começa por carregar o endereço da *var2* no registo *R0*, depois, entra em loop infinito onde:

   - Carrega o valor de 8 bits (byte) no endereço apontado por *R0* (var2) no registo *R1*
   - Incrementa o valor de *R1* por 1
   - Armazena o valor de *R1* de volta no endereço apontado por *R0* (var2)

   Como não existe condição de saída do *loop*, o programa continuará infinitamente a incrementar o valor da variável *var2*. De notar que quando o valor da *var2* atingir 255, irá 'dar a volta' e voltar a 0, pois o seu tamanho é *byte* (8 bits),

2.  Indicate, justifying, the number of clock cycles spent running each iteration of the loop cycle implemented in the program (lines 3 through 7).

   **Answer**

   Nas linhas 3 a 7, estão as instruções:

   - **ldrb** - 6 clocks
   - **add** - 3 clocks
   - **strb** - 6 clocks
   - **b** - 3 clocks

   No P16 as instruções que não fazem uso da memória, gastam 3 clocks (fetch, decode, execute). Para além destes 3 clocks, as instruções que fazem uso da memória (neste caso ldrb e strb) gastam adicionalmente outros 3 clocks. Em conclusão, cada interação do ciclo de *loop* do programa vai gastar 18 clocks no total. 

3. Knowing that the program will be located in memory from the 0x0000 address, indicate the values that should be associated with the symbols var2_addr, var1, var2 and var3. Justify your answer.

   **Answer**

   - **var2_addr** 0x000A - value 0x00D
   - **var1** 0x000C - value 0xAC
   - **var2** 0x000D - value 0x7E
   - **var3** 0x000E - value 0x2022

   Como o programa começa em 0x0000 e cada intrução ocupa uma *word* (16 bits), temos até ao **var2_addr**, 5 instruções (ldr, ldrb, add, strb e b), 5x2 = 10 -> 0xA -> 0x000A. Como esta varíavél é um endereço, ocupa 16 bits, logo, a próxima variável, **var1** vai estar em 0x000A + 2 = 0x000C. **var1** é de apenas 8 bits, logo, **var2** vai estar no proximo endereço, 0x000D. Como **var2** também é apenas *byte*, **var3**, vai estar no endereço seguinte 0x000E.

4. Manually translate the program to P16 machine code. Use a table to record the result of this encoding, assuming that each row of the table should correspond to only one instruction in the program. Represent in hexadecimal notation, using four digits, the values of memory addresses and program instructions.

   **Answer**

   | Instrução              | Endereço | 15   | 14   | 13   | 12   | 11   | 10   | 9    | 8    | 7    | 6    | 5    | 4    | 3    | 2    | 1    | 0    | Código Máquina |
   | ---------------------- | -------- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- | -------------- |
   | ldr r0, var2_addr      | 0x0000   | 0    | 0    | 0    | 0    | 1    | 1    | 0    | 0    | 0    | 1    | 0    | 0    | 0    | 0    | 0    | 0    | 0x0C40         |
   | loop:                  |          |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |                |
   | ldrb r1, [r0, #0]      | 0x0002   | 0    | 0    | 0    | 0    | 1    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 1    | 0x0801         |
   | add, r1, r1, #1        | 0x0004   | 1    | 0    | 1    | 0    | 0    | 0    | 0    | 0    | 1    | 0    | 0    | 1    | 0    | 0    | 0    | 1    | 0xA091         |
   | strb r1, [r0, #0]      | 0x0006   | 0    | 0    | 1    | 0    | 1    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 0    | 1    | 0x2801         |
   | b loop                 | 0x0008   | 0    | 1    | 0    | 1    | 1    | 0    | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 1    | 0    | 0    | 0x5BFC         |
   | var_2 addr: .word var2 | 0x000A   |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      | 0x000D         |
   | var1: .byte 0xAC       | 0x000C   |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      | 0xAC           |
   | var2: .byte 126        | 0x000D   |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      | 0x7E           |
   | var3: word 0x2022      | 0x000E   |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      |      | 0x2022         |

   