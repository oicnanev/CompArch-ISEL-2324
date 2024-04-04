# Answers - draft!!!

## 3.1 Microarchitecture analysis

### 1.

A afirmação "A microarquitectura do processador é do tipo von Neumann" está errada, uma vez que a microarquitetura apresentada, tem separação entre memória de dados e memória de instruções, usa barramentos independentes e funciona com ciclo único. A microarquitetura do processador é de Harvard.

### 2.

O módulo **Ext** é um extensor de sinal / *zero fill*, usado para ajustar o tamanho do operando imediato (instrução ldr rd, [#imm4]) para que este imm4 corresponda ao tamanho do *bus* de dados do processador. **Não sei se está bem**

### 3.

**b** e **bzc** utilizam modos de endereçamento imediato e condicional respetivamente. 

O modo imediato permite a codificação direta do endereço de  salto na instrução, através do valor guardado num registo, o que poderá melhorar a densidade do código mas limita a flexibilidade da localização em memória de instruções (só de -128 a +127).

O modo condicional permite saltos baseados no estado das flags do processador, como a flag Z do CPSR, o que suporta a implementação de rotinas de decisão.



## 3.2 Encoding of instructions

### 1.

| Intrução        | 8    | 7    | 6    | 5    | 4    | 3    | 2        | 1     | 0     |
| --------------- | ---- | ---- | ---- | ---- | ---- | ---- | -------- | ----- | ----- |
| b rn            | -    | -    | rn1  | rn0  | -    | -    |          |       |       |
| bzc #imm7       | imm6 | imm5 | imm4 | imm3 | imm2 | imm1 | imm0 ??? | **1** | **1** |
| ldr rd, [#imm4] | rd1  | rd0  | imm3 | imm2 | imm1 | imm0 |          |       |       |
| mov rd, rn      | rd1  | rd0  | rn1  | rn0  | -    | -    |          |       |       |
| sub rd, rn, rm  | rd1  | rd0  | rn1  | rn0  | rm1  | rm0  | **0**    | **0** | **1** |
| str rd, [rn]    | rd1  | rd0  | rn1  | rn0  | -    | -    |          |       |       |
| tst rn, rm      | -    | -    | rn1  | rn0  | rm1  | rm0  |          | **1** | **0** |
|                 | RD   | RD   | RN   | RN   | RM   | RM   | OP       | CO    | DE    |
|                 | imm7 | imm7 | imm7 | imm7 | imm7 | imm7 | imm7     |       |       |
|                 |      |      | imm4 | imm4 | imm4 | imm4 |          |       |       |

### 2.

### 3.

Vantagem da utilização de um código uniforme de comprimento fixo - Simplicidade na descodificação - cada instrução tendo o mesmo tamanho, pode ser facilmente identificada e processada pelo hardware sem necessidade de mecanismos adicionais para determinar os limites das instruções, o que levaria a gastar mais tempo de clock(s) só para intrepertar a instrução.

Desvantagem - Ineficiência na utilização do espaço da memória de intruções - Instruções que precisariam de usar menos bits para representar operações, acabam por usar mais espaço que o necessário. Por um lado pode levar ao desperdício de espaço de memória, especialmente no caso de existirem muitas instruções simples que não necessitem de toda a largura do código de intrução, por outro, faz aumentar o tamanho da memória necessária para as instruções.

## 3.3 Instructions Decoder project design

### 1.

| Instrução        | opcode | Z    | SI   | SC   | SD    | ER   | EP   | nRD  | nWR  |
| ---------------- | ------ | ---- | ---- | ---- | ----- | ---- | ---- | ---- | ---- |
| sub rd, rn, rm   | 001    | -    | 00   | 1    | 0     | 1    | 1    | 1    | 1    |
| b rn             | ???    | -    | 01   | -    | -     | 0    | 0    | 1    | 1    |
| bzc, #imm7 (Z=0) | ?11    | 0    | 00   | -    | - (?) | 0    | 0    | 1    | 1    |
| bzc, #imm7 (Z=1) | ?11    | 1    | 10   | -    | - (?) | 0    | 0    | 1    | 1    |
| ldr rd, [#imm4]  | ???    | -    | 00   | 0    | 1     | 1    | 0    | 0    | 1    |
| mov rd, rn       | ???    | -    | 00   | ?    | -     | 1    | 0    | 1    | 1    |
| str rd, [rn]     | ???    | -    | 00   | 1    | -     | 0    | 0    | 1    | 0    |
| tst rn, rm       | ?10    | -    | 00   | 1    | -     | 0    | 1    | 1    | 1    |

### 2.

Escolheria a Montagem 2, (b). Vamos precisar da flag Z para entrada, logo, ou 1 ou 2; A 1, não faz sentido porque tem uma saida de 2 bit com OP_ALU, OP_ALU já faz parte do OPCODE e já entra direto na ALU.

### 3.

8 linhas X 14 linhas = 112 -> 128

## 3.4

| Instrução         | Endereço | Código máquina |
| ----------------- | -------- | -------------- |
| ldr r0, [#0]      | 0x0000   |                |
| ldr r1, [#1]      | 0x0001   |                |
| tst r0, r1        | 0x0010   |                |
| bzc skip (0x1000) | 0x0011   |                |
| mov r0, r1        | 0x0100   |                |
| sub r2, r2, r2    | 0x0101   |                |
| str r0, [r2]      | 0x0111   |                |
| b r2 (0x0000)     | 0x1000   |                |

