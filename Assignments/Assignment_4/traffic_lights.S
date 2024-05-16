; Ficheiro:  traffic_lights.S
; Descricao: Programa de suporte ao protótipo de um sistema embebido baseado no 
;            processador P16 que implementa o controlador de um sistema de 
;            semáforos para uma passadeira.
; Autores:   Grupo 02 da turma 21N (45824 Nuno Venancio e 48070 Daniel Cabaça) 
; Data:      15-05-2024

; ##############################################################################
; Definicao dos valores dos simbolos utilizados no programa
    .equ    CPSR_BIT_I, 0b010000        ; Mascara para o bit I do registo CPSR
    .equ    STACK_SIZE, 64              ; Dimensao do stack - 64 B

    ; Definicoes do porto de entrada    ----------------------------------------
    .equ    INPORT_ADDRESS, 0xFF80      ; Endereco do porto de entrada
    .equ    IN_PEDESTRIAN_MASK, 0x01    ; Mascara para botão de peão
    .equ    IN_MODE_MASK, 0x10          ; Mascara para switch de CONFIG
    .equ    IN_TIME_MASK, 0xE0          ; Mascara para Time

    ; Definicoes do porto de saida      ----------------------------------------  
    .equ    OUTPORT_ADDRESS, 0xFFC0     ; Endereco do porto de saida
    .equ    OUT_TRAFFIC_RED, 0x01       ; Mascara traffic light red
    .equ    OUT_TRAFFIC_GREEN, 0x02     ; Mascara traffic light green
    .equ    OUT_TRAFFIC_YELLOW, 0x03    ; Mascara traffic light yellow
    .equ    OUT_PEDESTR_RED, 0x04       ; Mascara pedestrian light red
    .equ    OUT_PEDESTR_GREEN, 0x08     ; Mascara pedestrian light green
    .equ    OUT_MODE_RED, 0x10          ; Mascara mode red
    .equ    OUT_MODE_GREEN, 0x20        ; Mascara mode green

    ; Definicoes do circuito pTC        ----------------------------------------
    .equ    PTC_ADDRESS,  0xFF78        ; Endereco do circuito pTC
    .equ    PTC_TCR, 0                  ; Deslocamento do registo TCR do pTC
    .equ    PTC_TMR, 2                  ; Deslocamento do registo TMR do pTC
    .equ    PTC_TC,  4                  ; Deslocamento do registo TC do pTC
    .equ    PTC_TIR, 6                  ; Deslocamento do registo TIR do pTC
    .equ    PTC_CMD_START, 0            ; Comando para iniciar a contagem no pTC
    .equ    PTC_CMD_STOP, 1             ; Comando para parar a contagem no pTC
    .equ    SYSCLK_FREQ, 0x64           ; Intervalo de contagem do circuito pTC
                                        ; que suporta a implementação do sysclk
                                        ; T = 1 / f  
                                        ; 0.001s = 1 / 1000Hz
                                        ; 0.1s   = 1 / f ( f = 10Hz ) 

    ; Outras definicoes                 ----------------------------------------
    .equ    BLINK_TIME, 0x05            ; Tempo dos LEDs intermitentes 
 

; ##############################################################################
; Seccao:    startup
; Descricao: Guarda o código de arranque do sistema
;
    .section startup
    b       _start
    ldr     pc, isr_addr
_start:
    ldr     sp, stack_top_addr
    mov     r0, pc
    add     lr, r0, #4
    ldr     pc, main_addr
    b       .

stack_top_addr:
    .word   stack_top
main_addr:
    .word   main
isr_addr:
    .word   isr

; ##############################################################################
; Seccao:    text
; Descricao: Guarda o código do programa
;
    .text

; Rotina:    main --------------------------------------------------------------
; Descricao: *** TODO ***
; Entradas:  -
; Saidas:    -
; Efeitos:   *** TODO ***
;
main:
    ; TODO
    mov     r0, #0                      ; todos os LEDs apagados
    bl      outport_init
    mov     r0, #SYSCLK_FREQ
    bl      sysclk_init
    mrs     r0, cpsr
    mov     r1, #CPSR_BIT_I
    orr     r0, r0, r1
    msr     cpsr, r0

    bl      operation_mode
    b.

; Rotina:    operation_mode ----------------------------------------------------
; Descricao: *** TODO ***
; Entradas:  -
; Saidas:    -
; Efeitos:   *** TODO ***
;
operation_mode:
    push    lr
    push    r4
    push    r5
    mov     r0, #OUT_MODE_GREEN         ; L3 green
    bl      outport_set_bits
    mov     r0, #OUT_PEDESTR_RED        ; L2 red
    bl      outport_set_bits
yellow_on:
    mov     r0, #OUT_TRAFFIC_YELLOW     ; L1 yellow
    bl      outport_set_bits
    bl      sysclk_get_ticks
    mov     r1, #BLINK_TIME
    add     r4, r0, r1                  ; sum observed ticks plus BLINK_TIME 
loop_yellow_on:
    bl      inport_read
    mov     r5, r0                      ; preserve inport data
    mov     r1, #IN_MODE_MASK           ; check CONFIG    
    and     r0, r1, r5
    cmp     r0, r1                      ; check CONFIG is 1
    beq     config_mode
    ; TODO: ver se aconteceu transição de 0 para 1 em PEDESTRIAN
    bl      sysclk_get_ticks
    cmp     r0, r4                      ; comparar o valor lido com o valor limite
    blo     traffic_yellow_on
yellow_off:
    mov     r0, #OUT_TRAFFIC_YELLOW     ; L1 yellow
    bl      outport_clear_bits
    bl      sysclk_get_ticks            ; start new count
    mov     r1, #BLINK_TIME
    add     r4, r0, r1                  ; sum observed ticks plus BLINK_TIME 
loop_yellow_off:
    bl      inport_read
    mov     r5, r0                      ; preserve inport data
    mov     r1, #IN_MODE_MASK           ; check CONFIG    
    and     r0, r1, r5
    cmp     r0, r1                      ; check CONFIG is 1
    beq     config_mode
    ; TODO: ver se aconteceu transição de 0 para 1 em PEDESTRIAN
    bl      sysclk_get_ticks
    cmp     r0, r4                      ; comparar o valor lido com o valor limite
    blo     traffic_yellow_off
    b       yellow_on
    pop     r5
    pop     r4
    pop     pc

; Rotina:    config_mode -------------------------------------------------------
; Descricao: *** TODO ***
; Entradas:  -
; Saidas:    -
; Efeitos:   *** TODO ***
;
config_mode:
    push    lr
    ; LED 01 - amarelo a piscar ao ritmo de 0.5s
    ; LED 02 - verde a piscar ao ritmo de 0.5s
    ; LED 03 - amarelo
config_mode_loop:
    ; ler crossing_time_arr
    ; guardar crossing_time
    ; verificar se CONFIG se mantém a 1
    ; se sim, b config_mode_loop
    pop     pc


; Rotina:    delay -------------------------------------------------------------
; Descricao: Rotina bloqueante que realiza uma espera por teste sucessivo
;            do valor da variável global sysclk. O tempo a esperar, em
;            centenas de milissegundos, e passado em R0.
;            Interface exemplo: void delay( uint16_t hms );
; Entradas:  R0 - o tempo a esperar em centenas de milisegundos
; Saidas:    -
; Efeitos:   -
delay:
    push    lr
    push    r4
    mov     r4, r0              ; preservar o tempo a esperar em cent. ms.
    bl      sysclk_get_ticks    ; valor atual do sysclk
    add     r4, r4, r0          ; somar o valor observado com o tempo a esperar
while:
    bl      sysclk_get_ticks    ; reler o valor atual do sysclk
    cmp     r0, r4              ; comparar o valor lido com o valor limite
    blo     while               ; voltar ao while
    pop     r4
    pop     pc


; Rotina:    isr ---------------------------------------------------------------
; Descricao: Incrementa o valor da variável global sysclk.
; Entradas:  -
; Saidas:    -
; Efeitos:   Incrementa o valor da variável global sysclk
isr:
    push    r0
    push    r1

    ; "limpar" a interrupção no pTC
    ldr     r0, ptc_addr
    strb    r1, [r0, #PTC_TIR]
    ; ---------------------------------

    ; incrementar sysclk --------------
    ldr     r0, sysclk_addr
    ldrb    r1, [r0, #0]
    add     r1, r1, #1
    strb    r1, [r0, #0]
    ; ----------------------------------

    pop     r1
    pop     r0
    movs    pc, lr

ptc_addr:
    .word PTC_ADDRESS

; Rotina:    sysclk_init -------------------------------------------------------
; Descricao: Inicia uma nova contagem no periferico pTC com o intervalo de
;            contagem recebido em R0, em ticks, limpando eventuais pedidos de
;            interrupcao pendentes e iniciando com o valor zero a variavel
;            global sysclk.
;            Interface exemplo: void sysclk_init( uint8_t interval );
; Entradas:  R0 - Valor do novo intervalo de contagem, em ticks.
; Saidas:    -
; Efeitos:   Inicia a contagem no periferico a partir do valor zero, limpando
;            eventuais pedidos de interrupcao pendentes e iniciando com o
;            valor zero a variavel global sysclk
sysclk_init:
    push    lr
    push    r0              ; preservar valor dos ticks 
    bl      ptc_stop        ; parar o ptc
    bl      ptc_clr_irq     ; limpar eventuais interrupts   

    ; iniciar a varável sysclk a 0 -------------------------
    mov     r0, #0 && 0xFF
    movt    r0, #0 >> 8 & 0xFF
    ldr     r1, sysclk_addr
    str     r0, [r1, #0]
    ; ------------------------------------------------------
    
    pop     r0              ; repor os ticks
    bl      ptc_init
    pop     pc

; Rotina:    sysclk_get_ticks --------------------------------------------------
; Descricao: Devolve o valor corrente da variável global sysclk.
;            Interface exemplo: uint16_t sysclk_get_ticks ( );
; Entradas:  -
; Saidas:    R0 - valor da variável global sysclk
; Efeitos:   -
sysclk_get_ticks:
    ldr     r1, sysclk_addr
    ldr     r0, [r1, #0]
    mov     pc, lr

sysclk_addr:
    .word sysclk

; Gestor de periférico para o porto de entrada %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;

; Rotina:    inport_read -------------------------------------------------------
; Descricao: Adquire e devolve o valor corrente do porto de entrada.
;            Interface exemplo: uint8_t inport_read( );
; Entradas:  -
; Saidas:    R0 - valor adquirido do porto de entrada
; Efeitos:   -
;
inport_read:
    ldr     r1, inport_addr
    ldrb    r0, [r1, #0]
    mov     pc, lr

inport_addr:
    .word   INPORT_ADDRESS

; Gestor de periférico para o porto de saída %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;

; Rotina:    outport_set_bits --------------------------------------------------
; Descricao: Atribui o valor logico 1 aos bits do porto de saida identificados
;            com o valor 1 em R0. O valor dos outros bits nao e alterado.
;            Interface exemplo: void outport_set_bits( uint8_t pins_mask );
; Entradas:  R0 - Mascara com a especificacao do indice dos bits a alterar.
; Saidas:    -
; Efeitos:   Altera o valor da variavel global outport_img.
;
outport_set_bits:
    push    lr
    ldr     r1, outport_img_addr
    ldrb    r2, [r1, #0]
    orr     r0, r2, r0
    strb    r0, [r1, #0]
    bl      outport_write
    pop     pc

; Rotina:    outport_clear_bits ------------------------------------------------
; Descricao: Atribui o valor logico 0 aos bits do porto de saida identificados
;            com o valor 1 em R0. O valor dos outros bits nao e alterado.
;            Interface exemplo: void outport_clear_bits( uint8_t pins_mask );
; Entradas:  R0 - Mascara com a especificacao do indice dos bits a alterar.
; Saidas:    -
; Efeitos:   Altera o valor da variavel global outport_img.
;
outport_clear_bits:
    push    lr
    ldr     r1, outport_img_addr
    ldrb    r2, [r1, #0]
    mvn     r0, r0
    and     r0, r2, r0
    strb    r0, [r1]
    bl      outport_write
    pop     pc

; Rotina:    outport_init ------------------------------------------------------
; Descricao: Faz a iniciacao do porto de saida, nele estabelecendo o valor
;            recebido em R0.
;            Interface exemplo: void outport_init( uint8_t value );
; Entradas:  R0 - Valor a atribuir ao porto de saida.
; Saidas:    -
; Efeitos:   Altera o valor da variavel global outport_img.
;
outport_init:
    push    lr
    ldr     r1, outport_img_addr
    strb    r0, [r1]
    bl      outport_write
    pop     pc

outport_img_addr:
    .word   outport_img

; Rotina:    outport_write -----------------------------------------------------
; Descricao: Escreve no porto de saida o valor recebido em R0.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  R0 - valor a atribuir ao porto de saida.
; Saidas:    -
; Efeitos:   -
;
outport_write:
    ldr     r1, outport_addr
    strb    r0, [r1, #0]
    mov     pc, lr

outport_addr:
    .word   OUTPORT_ADDRESS

; Gestor de periférico para o Pico Timer/Counter (pTC) %%%%%%%%%%%%%%%%%%%%%%%%%
;

; Rotina:    ptc_init ----------------------------------------------------------
; Descricao: Faz a iniciacao do periférico pTC, habilitando o seu funcionamento
;            em modo continuo e com o intervalo de contagem recebido em R0, em
;            ticks.
;            Interface exemplo: void ptc_init( uint8_t interval );
; Entradas:  R0 - Valor do novo intervalo de contagem, em ticks.
; Saidas:    -
; Efeitos:   Inicia a contagem no periferico a partir do valor zero, limpando
;            o pedido de interrupcao eventualmente pendente.
;
ptc_init:
    push    lr
    ldr     r1, PTC_ADDR
    mov     r2, #PTC_CMD_STOP
    strb    r2, [r1, #PTC_TCR]
    strb    r0, [r1, #PTC_TMR]
    bl      ptc_clr_irq
    ldr     r1, PTC_ADDR
    mov     r2, #PTC_CMD_START
    strb    r2, [r1, #PTC_TCR]
    pop     pc

; Rotina:    ptc_start ---------------------------------------------------------
; Descricao: Habilita a contagem no periferico pTC.
;            Interface exemplo: void ptc_start( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
;
ptc_start:
    ldr     r0, PTC_ADDR
    mov     r1, #PTC_CMD_START
    strb    r1, [r0, #PTC_TCR]
    mov     pc, lr

; Rotina:    ptc_stop ----------------------------------------------------------
; Descricao: Para a contagem no periferico pTC.
;            Interface exemplo: void ptc_stop( );
; Entradas:  -
; Saidas:    -
; Efeitos:   O valor do registo TC do periferico e colocado a zero.
;
ptc_stop:
    ldr     r0, PTC_ADDR
    mov     r1, #PTC_CMD_STOP
    strb    r1, [r0, #PTC_TCR]
    mov     pc, lr

; Rotina:    ptc_get_value -----------------------------------------------------
; Descricao: Devolve o valor corrente da contagem do periferico pTC.
;            Interface exemplo: uint8_t ptc_get_value( );
; Entradas:  -
; Saidas:    R0 - O valor corrente do registo TC do periferico.
; Efeitos:   -
;
ptc_get_value:
    ldr     r1, PTC_ADDR
    ldrb    r0, [r1, #PTC_TC]
    mov     pc, lr

; Rotina:    ptc_clr_irq -------------------------------------------------------
; Descricao: Sinaliza o periferico pTC que foi atendido um pedido de
;            interrupção.
;            Interface exemplo: void ptc_clr_irq( );
; Entradas:  -
; Saidas:    -
; Efeitos:   -
;
ptc_clr_irq:
    ldr     r0, PTC_ADDR
    strb    r1, [r0, #PTC_TIR]
    mov     pc, lr

PTC_ADDR:
    .word   PTC_ADDRESS

; ##############################################################################
; Seccao:    data
; Descricao: Guarda as variáveis globais
;
    .data
outport_img:
    .space  1

    .align
sysclk:
    .space  2

crossing_time:
    .byte  10, 20, 30, 40, 50, 60, 60
    ; hex: 00, 01, 02, 03, 04, 05, 06, 28


; ##############################################################################
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
    .space  STACK_SIZE
stack_top:
