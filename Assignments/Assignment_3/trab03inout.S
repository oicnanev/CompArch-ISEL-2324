;---------------------------------------------------------------------------------
; Ficheiro:  trab03inout.S
; Descricao: Programa desenvolvido para no ambito da questão 6 do trabalho prático 3
; Autores: Grupo 02 da turma 21N (45824 Nuno Venancio, 48070 Daniel Cabaça)     
; Data:      01-05-2024
; 
; IMPORTANTE:
; No assembler p16as.exe defenir o "address" da secção data para evitar conflitos
; p16as.exe -s .data=0x6000 trab03inout.S 
;
; No simulador, p16sim.exe
; p16sim.exe -c trab3.txt
;---------------------------------------------------------------------------------

; ================================================================================
; Definicao dos valores dos simbolos utilizados no programa

.equ	STACK_SIZE, 64		; Dimensao do stack
.equ 	IDX_MASK, 0x38		; InPort são apenas 8 bits
.equ 	OUT_MASK, 0xFF00
.equ 	IN_ADDR, 0xD000
.equ 	OUT_ADDR, 0xD000

; ================================================================================
; Seccao:    startup
; Descricao: Guarda o código de arranque do sistema

	.section startup
	b		_start
	b		.

_start:
	ldr		SP, stack_top_addr
	mov		R0, PC
	add 	LR, R0, #4							; LR = PC + 4
	ldr 	PC, main_addr
	b		.

stack_top_addr:
	.word	stack_top
main_addr:
	.word	main

; ================================================================================
; Seccao:    text
; Descricao: Guarda o código do programa

	.text
;---------------------------------------------------------------------------------
; Rotina: main
; Descricao: Lê, continuamente, o estado do dispositivo INPORT e utiliza os bits 3 a 5
;            obtidos para definir a posição da variável 'array' que contém o valor a
; 			 afixar nos 8 bits de maior peso do dispositivo OUTPORT, mantendo inalterados
;            os valores dos 8 bits de menos peso.
; Entradas: 
; Saidas:
; Efeitos: 
;---------------------------------------------------------------------------------
main:
	push	LR
	push 	R4
	mov		R0, #0
	bl		outport_init
loop:
	bl		inport_read				
	mov		R1, #IDX_MASK & 0xFF
	and		R0, R0, R1
	lsr		R0, R0, #3
	ldr		R1, array_addr
	ldrb	R1, [R1, R0]
	lsl 	R0, R1, #8
	mov		R4, R0  			; save the value of R0
	mov		R0, #OUT_MASK & 0xFF
	movt 	R0, #OUT_MASK>>8 & 0xFF
	bl		outport_clear_bits
	mov 	R0, R4				; restore R0
	bl 		outport_set_bits
	b 		loop
	pop 	R4
	pop		PC

array_addr:
	.word array

;---------------------------------------------------------------------------------
; Rotina: outport_init
; Descricao: Faz a iniciacao do sistema, atribuindo o valor value aos pinos do
; porto de saida .
; Entradas: Valor a escrever no porto
; Saidas:
; Efeitos: 
;---------------------------------------------------------------------------------
outport_init:
	push lr
	bl outport_write
	pop pc

;---------------------------------------------------------------------------------	
; Rotina:    outport_write
; Descricao: Atribui aos pinos do porto de saida o valor dos bits correspondentes de value.
; Entradas:  Valor a escrever no porto
; Saidas:    
; Efeitos:   Atualiza o valor da variavel imagem do porto
;---------------------------------------------------------------------------------	
outport_write:
	ldr		r1, outport_img_addr
	str 	r0, [r1, #0]						; nosso porto é de 16 bit
	mov		r1, #OUT_ADDR & 0xFF
	movt	r1, #OUT_ADDR >>8 & 0xFF
	str 	r0, [r1, #0]
	mov		pc, lr

outport_img_addr:
	.word	outport_img

;---------------------------------------------------------------------------------	
; Rotina:    inport_read
; Descricao: Devolve o valor corrente do estado dos pinos do porto de entrada.
; Entradas:  
; Saidas:    Valor corrente do porto
; Efeitos:   
;---------------------------------------------------------------------------------	
inport_read:
	mov		r0, #IN_ADDR & 0xFF
	movt	r0, #IN_ADDR>>8 & 0xFF
	ldrb	r0, [r0, #0]					; nosso porto é de 8 bit
	mov		pc, lr

;---------------------------------------------------------------------------------	
; Rotina:    outport_set_bits
; Descricao: Atribui o valor logico '1' aos pinos do porto de saida identificados 
;			 com o valor 1 no argumento passado a rotina. O estado dos restantes 
;			 bits nao e alterado.
; Entradas:  Mascara com os bits a alterar
; Saidas:    
; Efeitos:   Atualiza o valor da variavel imagem do porto
;---------------------------------------------------------------------------------	
outport_set_bits:
	push	lr
	ldr		r1, outport_img_address
	ldr 	r2, [r1, #0]
	orr		r0, r2, r0
	str 	r0, [r1, #0]
	bl		outport_write
	pop		pc

;---------------------------------------------------------------------------------	
; Rotina:    outport_clear_bits
; Descricao: Atribui o valor logico '0' aos pinos do porto de saida identificados 
;			 com o valor 1 no argumento passado a rotina. O estado dos restantes 
;			 bits nao e alterado.
; Entradas:  Mascara com os bits a alterar
; Saidas:    
; Efeitos:   Atualiza o valor da variavel imagem do porto
;---------------------------------------------------------------------------------	
outport_clear_bits:
	push	lr
	ldr		r1, outport_img_address
	ldr 	r2, [r1, #0]
	mvn		r0, r0
	and		r0, r2, r0
	str 	r0, [r1, #0]
	bl		outport_write
	pop		pc

outport_img_address:
	.word	outport_img

; ================================================================================
; Seccao:    data
; Descricao: Guarda as variáveis globais

	.data
outport_img:
	.space 2
array:
	.byte 1, 2, 4, 8, 16, 32, 64, 128

; ================================================================================
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE

	.stack
	.space	STACK_SIZE
stack_top:
