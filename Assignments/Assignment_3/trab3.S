.section startup ; --------------------------------------
	; Exception / Interrupt vector table
	b	_start		; Reset handler
	b	.			; interrupt handler
_start:
	; Initialize the SP (Stack Pointer)
	ldr	SP, stack_top_addr
	; Jump to user code (main function)
	mov R0, PC
	add LR, R0, #4
	ldr PC, main_addr
	b .
	
stack_top_addr:
	.word stack_top
main_addr:
	.word main
	.text
main:
	push r1
	ldr r1, [ r2, # 2 ]
	add r0, r2, # 1
	strb r3, [ r2, # 5 ]
	ldr r4, value
	ldrb r5, [ r6, # 0 ]
	b .

value:
	.word value1
	.data

value1:
	.word value2
	;...

value2:
	.word 0x1342

.section stack ; ----------------------------------------
stack_bottom:
	.word 0x4000
stack_top: