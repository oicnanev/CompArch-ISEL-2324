# Answers

## 3.1 Microarchitecture analysis

### 1.

A afirmação *"A microarquitectura do processador é do tipo von Neumann"* está errada, uma vez que a microarquitetura apresentada, tem separação entre memória de dados e memória de instruções, usa barramentos independentes e funciona com ciclo único. A microarquitetura do processador é do tipo Harvard.

### 2.

O módulo **Ext** é um *zero fill*, usado para ajustar o tamanho do operando imediato (instrução ldr rd, [#imm4]) para que este imm4 corresponda ao tamanho do *bus* de dados do processador (de 4 para 8 bits).

### 3.

**b** e **bzc** utilizam modos de endereçamento imediato e condicional respetivamente. 

O modo imediato permite a codificação direta do endereço de  salto na instrução, através do valor guardado num registo, o que poderá melhorar a densidade do código mas limita a flexibilidade da localização em memória de instruções (só de -128 a +127).

O modo condicional permite saltos baseados no estado das flags do processador, como a flag Z do CPSR, o que suporta a implementação de rotinas de decisão.



## 3.2 Encoding of instructions

### 1.

| Instrução | 8        | 7        | 6        | 5        | 4        | 3        | 2            | 1    | 0    |
| --------- | -------- | -------- | -------- | -------- | -------- | -------- | ------------ | ---- | ---- |
| sub       | rd       | rd       | rn       | rn       | rm       | rm       | op 0         | op 0 | op 1 |
| b         |          |          | rn       | rn       |          |          | op           | op   | op   |
| bzc       | imm7 - 6 | imm7 - 5 | imm7 - 4 | imm7 - 3 | imm7 - 2 | imm7 - 1 | imm7 - 0 /op | op   | op   |
| ldr       | rd       | rd       | imm4 -3  | imm4 -2  | imm4 -1  | imm4 -0  | op           | op   | op   |
| mov       | rd       | rd       | rn       | rn       |          |          | op           | op   | op   |
| str       | rd       | rd       | rn       | rn       |          |          | op           | op   | op   |
| tst       |          |          | rn       | rn       | rm       | rm       | op           | op   | op   |
|           |          |          |          |          |          |          |              |      |      |



### 2.



| Instrução       | 8     | 7    | 6     | 5    | 4    | 3     | 2          | 1     | 0     |
| --------------- | ----- | ---- | ----- | ---- | ---- | ----- | ---------- | ----- | ----- |
| b rn            | -     | -    | rn1   | rn0  | -    | -     | 0          | 0     | 0     |
| bzc #imm7       | imm6  | imm5 | imm4  | imm3 | imm2 | imm1  | imm0 **0** | **1** | **1** |
| bzc #imm7       | imm6  | imm5 | imm4  | imm3 | imm2 | imm1  | imm0 **1** | **1** | **1** |
| ldr rd, [#imm4] | rd1   | rd0  | imm3  | imm2 | imm1 | imm0  | 1          | 0     | 0     |
| mov rd, rn      | rd1   | rd0  | rn1   | rn0  | -    | -     | 1          | 0     | 1     |
| sub rd, rn, rm  | rd1   | rd0  | rn1   | rn0  | rm1  | rm0   | **0**      | **0** | **1** |
| str rd, [rn]    | rd1   | rd0  | rn1   | rn0  | -    | -     | 1          | 1     | 0     |
| tst rn, rm      | -     | -    | rn1   | rn0  | rm1  | rm0   | 0          | **1** | **0** |
|                 | [RD   | RD]  | [RN   | RN]  | [RM  | RM]   | [OP        | CO    | DE]   |
|                 | [imm7 | imm7 | imm7  | imm7 | imm7 | imm7  | imm7]      |       |       |
|                 |       |      | [imm4 | imm4 | imm4 | imm4] |            |       |       |

Para definir os "opcodes" é necessário que os mesmos sejam distintos uns dos outros por instrução. Sendo o "opcode" da instrução "sub" dado, escolhemos códigos distintos deste para as restantes instruções:
- 000 - b
- 001 - sub
- 010 - tst
- 011 - bzc com imm7-bit0 a 0
- 100 - ldr
- 101 - mov
- 110 - str
- 111 - bzc com imm7-bit0 a 1

A instrução "bzc" irá ocupar 2 "opcode" pois o bit 0 do seu imm7, ocupa o espaço do "opcode"

### 3.

Vantagem da utilização de um código uniforme de comprimento fixo - **Simplicidade na descodificação** - cada instrução tendo o mesmo tamanho, pode ser facilmente identificada e processada pelo hardware sem necessidade de mecanismos adicionais para determinar os limites das instruções, o que levaria a gastar mais tempo de clock(s) só para intrepertar a instrução.

Desvantagem - **Ineficiência na utilização do espaço da memória de instruções** - Instruções que precisariam de usar menos bits para representar operações, acabam por usar mais espaço que o necessário. Por um lado pode levar ao desperdício de espaço de memória, especialmente no caso de existirem muitas instruções simples que não necessitem de toda a largura do código de intrução, por outro, faz aumentar o tamanho da memória necessária para as instruções. Por exemplo **bzc** ocupa 2 vezes 9 bits, enquanto que **b** só necessita de 5 bits e estamos a usar 9 bits.

## 3.3 Instructions Decoder project design

### 1.

| Instrução        | opcode | Z    | SI   | SC   | SD   | ER   | EP   | nRD  | nWR  |
| ---------------- | ------ | ---- | ---- | ---- | ---- | ---- | ---- | ---- | ---- |
| sub rd, rn, rm   | 001    | -    | 00   | 1    | 0    | 1    | 1    | 1    | 1    |
| b rn             | 000    | -    | 01   | -    | -    | 0    | 0    | 1    | 1    |
| bzc, #imm7 (Z=0) | 011    | 0    | 10   | -    | -    | 0    | 0    | 1    | 1    |
| bzc, #imm7 (Z=1) | 111    | 1    | 00   | -    | -    | 0    | 0    | 1    | 1    |
| ldr rd, [#imm4]  | 100    | -    | 00   | 0    | 1    | 1    | 0    | 0    | 1    |
| mov rd, rn       | 101    | -    | 00   | 1    | 0    | 1    | 0    | 1    | 1    |
| str rd, [rn]     | 110    | -    | 00   | 1    | -    | 0    | 0    | 1    | 0    |
| tst rn, rm       | 010    | -    | 00   | 1    | -    | 0    | 1    | 1    | 1    |

### 2.

Escolheria a Montagem 2, (b). 

A nossa escolha recaí sobre a montagem 2, porque vamos necessitar da "flag" Z como entrada para efetuar a descodificação (instrução bzc) e, não necessitamos de 2 bits de saída para "OP_ALU" uma vez que os bits "OP_ALU" já fazem parte do "opcode" e entram diretamente para na "ALU".

## 3.4 Machine code encoding

| Instrução       | Endereço | bin            | hex   |
| --------------- | -------- | -------------- | ----- |
| ldr r0, [#0]    | 0x00     | 00 0000 100    | 0x004 |
| ldr r1, [#1]    | 0x01     | 01 0001 100    | 0x08C |
| tst r0, r1      | 0x02     | - - 00 01 010  | 0x00A |
| bzc skip (0x06) | 0x03     | 000110 011     | 0x033 |
| mov r0, r1      | 0x04     | 00 01 - - 101  | 0x025 |
| sub r2, r2, r2  | 0x05     | 10 10 10 001   | 0x151 |
| str r0, [r2]    | 0x06     | 00 10 - - 110  | 0x046 | 
| b r2 (0x00)     | 0x07     | - - 10 - - 000 | 0x040 |
