; -----------------------------------------------------------------------------
; File:         g02_tp1.S
; Description:  Support program for the realization of the 1st practical 
;               assignment of Computer Architecture.
; Authors:      45824 Nuno Venâncio
;               48070 Daniel Cabaça
; Date:         2024-03-15
; -----------------------------------------------------------------------------

; Setting the values for symbols (constants) used in the program ==============

.equ    STACK_SIZE, 64
.equ    RED_SCALE, 2            ; unsigned 8 bit
.equ    AMBAR_SCALE, 1          ; unsigned 8 bit
.equ    GREEN_SCALE, 0          ; unsigned 8 bit
.equ    WARNING_TIME, 300       ; signed 16 bit
.equ    CRITICAL_TIME, 150      ; signed 16 bit

; =============================================================================



; Section:    .startup ========================================================
; Description: Exception / Interrupt vector table

    .section .startup

    b       _start              ; Reset handler
    b       .                   ; Interrupt handler

_start:
    ldr     SP, stack_top_addr  ; Initialize the stack pointer
    mov     R0, PC              ; Jump to user code....
    add     LR, R0, #4          ; Set LR to after the call to main
    ldr     PC, main_addr       ; Set PC to begining of main address
    b       .

stack_top_addr:
    .word   stack_top

main_addr:
    .word   main

; =============================================================================



; Section:    .text ===========================================================
; Description: Program code

    .text

; Routine:      main ----------------------------------------------------------
; Description:
; Inputs:       none
; Outputs:      value 0
; Efects:

main:
    ; save used registers in stack 
    push    LR

    mov     R0, #0 & 0xFF       ; i = 0 (uint16_t) - lsb
    movt    R0, #(0>>8) & 0xFF  ; i = 0 - msb

    ldrb    R1, color_hist_addr ; get color_histogram mem address
    mov     R2, #0              ; color_histogram index value, 8bit
    mov     R3, #3              ; temp value for while_main
    
while_main:
    ; while ( i < 3 )
    cmp     R0, R3              ; check if i >= 3
    bhs     end_while_main
    str     R2, [R1, R0]        ; set 0 (8 bit R2) in color_histogram mem addr R1, idx R0
    add     R0, R0, #1          ; i++
    b       while_main

end_while_main:
    ; call to test_color_scale( times(R0), color_histogram(R1), 10(R2) )
    ldr     R0, times_addr      ; R0 = times mem address
    mov R2, #10                 ; R2 = 10
    bl      test_color_scale    ; R1 already has color_hist_addr

    mov R0, #0                  ; return 0
    pop PC                      ; put LR in PC


color_hist_addr:
    .byte color_histogram

times_addr:
    .word times



; Routine:      test_color_scale ----------------------------------------------
; Description:  
; Inputs:       times (uint16_t array address in R0)
;               color_histogram (uint8_t array address in R1)
;               size (int16_t in R2)   
; Outputs:      None
; Efects:       Fills the color_histogram array

test_color_scale:
    push    LR
    push    R4
    push    R5

    mov     R3, #0 & 0xFF       ; i = 0 (uint16_t) - lsb
    movt    R3, #0 >> 8 & 0xFF  ; i = 0 - msb
    mov     R4, R0
    mov     R5, R1

for:
    cmp     R3, R2
    bhs     end_for
    ldr     R0, [R4, R3]        ; array_t[i] (times) value
    bl      color_scale         ; call to color_scale, result comes in R0
    ldrb    R1, [R5, R0]        ; array_c[color_scale(array_t)] value
    add     R1, #1              ; array_c[color_scale(array_t)] value ++
    strb    R1, [R5, R0]        ; save the new value
    b       for

end_for:
    pop     R5
    pop     R4
    pop     PC



; Routine:      color_scale ---------------------------------------------------
; Description:  returns a color value (0, 1, 2) according the t value
; Inputs:       t (uint16_t in R0)
; outputs:      t (uint8_t in R0 )
; Efects:

color_scale:    
    push    R4                  ; save used registers in stack

    mov     R4, R0              ; preserve t
    movt    R4, R0

    mov     R0, GREEN_SCALE
    mov     R1, CRITICAL_TIME & 0xFF
    movt    R1, CRITICAL_TIME >> 8 & 0xFF
    mov     R2, WARNING_TIME & 0xFF
    movt    R2, WARNING_TIME >> 8 & 0xFF

    ; t >= CRITICAL_TIME && t <= WARNING_TIME
    cmp     R4, R1
    blo     red_scale           ; t is < CRITICAL_TIME
    cmp     R2, R4              ; WARNING_TIME > t
    blo     amber_scale         ; t is >= CRITICAL_TIME and <= WARNING_TIME
    b       color_scale_end     ; t is > WARNING_TIME

red_scale:
    mov     R0, RED_SCALE
    b       color_scale_end

amber_scale:
    mov     R0, AMBER_SCALE

color_scale_end:
    pop     R4
    mov     PC, LR

; =============================================================================



; Seccao:    .data ============================================================
; Descricao: Guarda as variáveis globais com um valor inicial definido
    .data

times:
    .word 65535, 500, 301, 300, 299, 151, 150, 149, 1, 0

color_histogram:
    .byte color_histogram

; =============================================================================



; Seccao:    .stack ===========================================================
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
stack_bottom:
    .space  STACK_SIZE
stack_top:
