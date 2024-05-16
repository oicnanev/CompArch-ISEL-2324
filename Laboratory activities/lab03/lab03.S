; Ficheiro:  lab03.S
; Descricao: Programa para a realização da 3a atividade laboratorial de
;            Arquitetura de Computadores.
; Autor:     Tiago M Dias (tiago.dias@isel.pt)
; Data:      18-04-2024

; Definicao dos valores dos simbolos utilizados no programa
;
	.equ	STACK_SIZE, 64                ; Dimensao do stack

; *** Início de zona para completar ***
;	.equ	INPORT_ADDRESS, 0xFF80        ; de FF80 a FFBF
;	.equ	OUTPORT_ADDRESS, 0xFFC0       ; de FFC0 a FFFF
; *** Final de zona para completar  ***

; Seccao:    startup
; Descricao: Guarda o código de arranque do sistema
;
	.section startup
	ldr	sp, stack_top_addr
    mov r0, pc
    add lr, r0, #4
	ldr	pc, main_addr
    b   .

stack_top_addr:
	.word	stack_top
main_addr:
	.word	main

; Seccao:    text
; Descricao: Guarda o código do programa
;
	.text

; Rotina:    main
; Descricao: Reads from the input port and writes to the output port
; Entradas:  Input port
; Saidas:    Output port
; Efeitos:   Put in the output port the value readed in the input port
main:
	push	lr
	mov	r0, #0xFF
	bl	outport_write
	mov	r0, #0x00
	bl	outport_write
loop:
	bl	inport_read
	bl	outport_write
	b	loop
	pop	pc

; Rotina:    inport_read
; Descricao: Reads a value from the input port 
; Entradas:  -
; Saidas:    r0 - value readed from the input port
; Efeitos:   r1 - input port address
inport_read:
	mov	r1, #INPORT_ADDRESS & 0xFF
	movt	r1, #INPORT_ADDRESS >> 8 & 0xFF
	ldrb	r0, [r1, #0]
	mov	pc, lr

; Rotina:    outport_write
; Descricao: Writes a value to the output port
; Entradas:  r0 - Value to write to the port
; Saidas:    -
; Efeitos:   r1 - output port address
outport_write:
	mov	r1, #OUTPORT_ADDRESS & 0xFF
	movt	r1, #OUTPORT_ADDRESS >> 8 & 0xFF
	strb	r0, [r1, #0]
	mov	pc, lr

; Rotina:    sleep
; Descricao: Keeps the execution in a loop by a time defined in R0
; Entradas:  R0 - time to be sleep
; Saidas:    -
; Efeitos:   Keeps the execution in a loop according to the time passed in R0 x 0.1 second (830 in R1)
sleep:
	and	r0, r0, r0
	beq	sleep_end
sleep_outer_loop:
	mov	r1, #0x3E
	movt	r1, #0x03 		; 830
sleep_inner_loop:
	; 2 (instructions) x 830 x 3 (clocks by instruction) = 4980 
	; 4980 / 50000 (processor's clock rate) = 0.0996 ≃ 0.1 seconds
	sub	r1, r1, #1
	bne	sleep_inner_loop
	sub	r0, r0, #1
	bne	sleep_outer_loop
sleep_end:
	mov	pc, lr

; Seccao:    data
; Descricao: Guarda as variáveis globais
;
;	.data

; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
	.stack
	.space	STACK_SIZE
stack_top:
