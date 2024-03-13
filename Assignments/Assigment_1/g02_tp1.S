; -----------------------------------------------------------------------------
; Ficheiro:  g02_tp1.S
; Descricao: Programa de suporte a realização do 1o trabalho prático de
             Arquitectura de Computadores.
; Autor:     45824 Nuno Venancio
             48070 Daniel Cabaça
; Data:      15-03-2024
; -----------------------------------------------------------------------------

; Definicao dos valores dos simbolos utilizados no programa ===================

.equ    STACK_SIZE, 64
.equ    RED_SCALE, 2
.equ    AMBAR_SCALE, 1
.equ    GREEN_SCALE, 0
.equ    WARNING_TIME, 300
.equ    CRITICAL_TIME, 150
; =============================================================================


; Section:    .startup ========================================================
; Descricao: Guarda o código de arranque do sistema

    .section .startup
    b       _start

_start:
    ldr     SP, tos_addr        ; set SP (stack pointer) to begining of stack addr
    ldr     PC, main_addr       ; set PC (prog counter) to begining of main addr

tos_addr:
    .word   tos

main_addr:
    .word   main

; =============================================================================

; Section:    .text ===========================================================
; Descricao: Guarda o código do programa

    .section .text

; Rotina:    main -------------------------------------------------------------
; Descricao:
; Entradas:  none
; Saidas:    0 in R0
; Efeitos:

main:
    ; save used registers in stack 
    push    LR
    push    R4

    mov     R0, #0              ; i = 0
    mov     R1, #3              ; temp value for while_main
    mov     R2, #0              ; value to put in color_history indexes
    ldr     R3, color_hist_addr ; get color_history mem address
    mov     R4, #10
while_main:
    ; while ( i < 3 )  
    cmp     R0, R1
    bhs     end_while_main
    str     R3, [R2, R0]        ; set the value 0 in color_history mem address R2, index R0
    add     R0, R0, #1          ; i++
    b       while_main
end_while_main:
    ; call to test_color_scale( times(R0), color_histogram(R1), 10(R2) )
    ldr     R0, times_addr      ; R0 = times mem address
    mov R1, R3                  ; R1 = color_histogram mem address
    mov R2, #10                 ; R2 = 10
    bl      test_color_scale

    mov R0, #0                  ; return 0
    pop R4
    pop PC                      ; or b . to terminate program


color_hist_addr:
    .byte color_histogram

times_addr:
    .word times

; Rotina:    test_color_scale --------------------------------------------------
; Descricao:
; Entradas:  times (array address in R0)
;            color_histogram (array address in R1)
;            size (R2)   
; Saidas:    R0 (RED / AMBAR or GREEN SCALE)
; Efeitos:


; Rotina:    color_scale -------------------------------------------------------
; Descricao:
; Entradas:  t (R0)
; Saidas:    t in R0 (8 bits)
; Efeitos:

; =============================================================================


; Seccao:    .data ============================================================
; Descricao: Guarda as variáveis globais com um valor inicial definido
    .section .data

times:
    .word 65535, 500, 301, 300, 299, 151, 150, 149, 1, 0
; =============================================================================


; Seccao:    .bss =============================================================
; Descricao: Guarda as variáveis globais sem valor inicial definido
    .section .bss

color_histogram:
    .byte color_histogram
; =============================================================================


; Seccao:    .stack ===========================================================
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .section .stack
    .space  STACK_SIZE
tos: