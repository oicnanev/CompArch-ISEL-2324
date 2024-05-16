; -----------------------------------------------------------------------------
; Ficheiro:  lab01.S
; Descricao: Codigo de suporte a realizacao da 1a atividade laboratorial de AC.
; Autor:     Grupo 2
; Data:      07-03-2024
; -----------------------------------------------------------------------------

	; r0 guarda o valor da variavel M
	; r1 guarda o valor da variavel m
	; r2 guarda o valor da variavel p
	; r3 e utilizado para guardar valores temporariamente
	
	; if m > M, R0 = m, r1 = M
	cmp R0, R1
	bhs main
	mov R3, R0
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
