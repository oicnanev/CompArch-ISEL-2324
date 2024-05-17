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
    .equ    PEDESTRIAN_BUTTON, 0x01     ; Mascara para botão de peão
    .equ    CONFIG_SW, 0x10             ; Mascara para switch de CONFIG
    .equ    TIME_SWS, 0xE0              ; Mascara para Time

    ; Definicoes do porto de saida      ----------------------------------------  
    .equ    OUTPORT_ADDRESS, 0xFFC0     ; Endereco do porto de saida
    .equ    TRAFFIC_YELLOW, 0x03        ; Mascara traffic light yellow
    .equ    CONFIG_MODE_YELLOW, 0x30    ; Mascara config mode yellow (red_0x10 + green_0x20)
    .equ    NORMAL_FIXED_LIGHTS, 0x24   ; Mascara PEDESTRIAN_RED 0x04 + NORMAL_MODE_GREEN 0x20
    .equ    CONFIG_BLIKING_LIGHTS, 0x0B ; Mascara TRAFFIC_YELLOW 0x03 + PEDESTRIAN_GREEN 0x08
    .equ    CONFIG_LIGHTS_TO_OFF, 0x24  ; Mascara NORMAL_MODE_GREE 0x20 + PEDESTRIAN_RED 0x04
    .equ    PEDESTRIAN_OFF_LIGHTS, 0x07 ; Mascara TRAFFIC_YELLOW 0x03 + PEDESTRAIN_RED 0x04
    .equ    PEDESTRIAN_ON_LIGHTS, 0x09  ; Mascara TRAFFIC_RED 0x01 + PEDESTRIAN_GREEN 0x08

    ; Definicoes do circuito pTC        ----------------------------------------
    .equ    PTC_ADDRESS,  0xFF40        ; Endereco do circuito pTC
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
                                        ; 1000Hz / 10Hz = 100Hz = 0x64

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
; R4 = BLINK_TIME, R5 = observed_ticks + BLINK_TIME, R6 = CONFIG_SW
main:
    mov     r0, #0                      ; todos os LEDs apagados
    bl      outport_init
    mov     r0, #SYSCLK_FREQ
    bl      sysclk_init
    mrs     r0, cpsr
    mov     r1, #CPSR_BIT_I
    orr     r0, r0, r1
    msr     cpsr, r0

operation_mode:
    mov     r0, #NORMAL_FIXED_LIGHTS    ; L3 green + L2 red
    bl      outport_set_bits

yellow_on:
    mov     r0, #TRAFFIC_YELLOW         ; L1 yellow
    bl      outport_set_bits
    bl      sysclk_get_ticks
    mov     r4, #BLINK_TIME
    add     r5, r0, r4                  ; sum observed ticks + BLINK_TIME 
loop_yellow_on:
    ; Check CONFIG -------------------------------------------
    bl      inport_read
    mov     r6, #CONFIG_SW              ; check CONFIG    
    and     r0, r6, r0
    cmp     r0, r6                      ; check CONFIG is 1
    beq     config_mode
    ; Check PEDESTRIAN ---------------------------------------
    bl      inport_read  
    mov     r1, #PEDESTRIAN_BUTTON
    bl      sw_is_pressed
    mov     r1, #1
    cmp     r0, r1
    beq     pededestrian_crossing       ; se sw_is_pressed == 1, houve transição ascendente
    ; Check if time is up ------------------------------------
    bl      sysclk_get_ticks
    cmp     r0, r5                      ; comparar o valor lido com o valor limite (r5)
    blo     traffic_yellow_on

yellow_off:
    mov     r0, #TRAFFIC_YELLOW         ; L1 yellow
    bl      outport_clear_bits
    bl      sysclk_get_ticks            ; start new count
    add     r5, r0, r4                  ; sum observed ticks + BLINK_TIME (R4)
loop_yellow_off:
    ; Check CONFIG -------------------------------------------
    bl      inport_read
    and     r0, r6, r0                  ; R6 = CONFIG_SW
    cmp     r0, r6                      ; check CONFIG is 1
    beq     config_mode
    ; Check PEDESTRIAN ---------------------------------------
    bl      inport_read                 ; ler porto de entrada
    mov     r1, #PEDESTRIAN_BUTTON
    bl      sw_is_pressed
    mov     r1, #1
    cmp     r0, r1
    beq     pededestrian_crossing       ; se sw_is_pressed == 1, houve transição ascendente

    bl      sysclk_get_ticks
    cmp     r0, r5                      ; comparar o valor lido com o valor limite (R5)
    blo     traffic_yellow_off
    b       yellow_on
    b       .

config_mode:
    mov     r0, #CONFIG_LIGHTS_TO_OFF   ; L3 green + L2 red
    bl      outport_clear_bits          ; clear L3 + L2
    mov     r0, #CONFIG_MODE_YELLOW     ; L3 yellow
    bl      outport_set_bits            ; set L3
config_lights_on:
    mov     r0, #CONFIG_BLIKING_LIGHTS  ; L2 green and L1 yellow
    bl      outport_set_bits            ; set L2 + L1
    bl      sysclk_get_ticks
    add     r5, r0, r4                  ; sum observed ticks + BLINK_TIME (R4)
config_lights_on_loop:
    ; Check CONFIG -------------------------------------------
    bl      inport_read   
    and     r0, r0, r6                  ; R6 = CONFIG_SW
    cmp     r0, r6                      ; check CONFIG is 1
    bne     off_bliking_lights
    ; Check if time is up ------------------------------------
    bl      sysclk_get_ticks
    cmp     r0, r5                      ; comparar o valor lido com o valor limite (R5)
    blo     config_lights_on_loop

config_lights_off:
    mov     r0, #CONFIG_BLIKING_LIGHTS  ; L2 green and L1 yellow
    bl      outport_clear_bits          ; set L2 + L1
    bl      sysclk_get_ticks
    add     r5, r0, r4                  ; sum observed ticks + BLINK_TIME (R4)
config_lights_off_loop:
    ; Check CONFIG -------------------------------------------
    bl      inport_read
    and     r0, r6, r0                  ; R6 = CONFIG_SW
    cmp     r0, r6                      ; check CONFIG is 1
    bne     end_config_mode
    ; Check if time is up ------------------------------------
    bl      sysclk_get_ticks
    cmp     r0, r5                      ; comparar o valor lido com o valor limite (R5)
    blo     config_lights_off_loop
    b       config_lights_on

off_bliking_lights:
    mov     r0, #CONFIG_BLIKING_LIGHTS  ; L2 green and L1 yellow
    bl      outport_clear_bits          ; clear L2 + L1
end_config_mode:
    bl      inport_read                 ; ver qual o crossing time configurado
    mov     r1, #TIME_SWS               ; aplicar mascara
    and     r1, r0, r1                  ; ficar com os bits que interessa
    lsr     r1, r1, #5                  ; shiftar bits para a parte baixa
    ldr     r0, crossing_times_array_addr 
    ldrb    r1, [r0, r1]                ; novo crossing time no index r1
    ldr     r0, crossing_time_addr      
    strb    r1, [r0, #0]                ; guardar novo crossing time
    mov     r0, #CONFIG_MODE_YELLOW     ; L3 yellow
    bl      outport_clear_bits          ; clear L3
    b       operation_mode

pedestrian_crossing:                    
    ; não faz sentido ver se há config mode devido ao delay bloqueante
    mov     r0, #PEDESTRIAN_OFF_LIGHTS  ; L1 yellow + L2 red
    bl      outport_clear_bits          ; clear L1 + L2
    mov     r0, #PEDESTRIAN_ON_LIGHTS   ; L1 red + L2 green
    bl      outport_set_bits            ; set L1 + L2
    ldr     r0, crossing_time_addr
    ldrb    r0, [r0, #0]                ; ler valor do crossing time
    delay                               ; delay bloqueante
    ; Check new PEDESTRIAN ---------------------------------------
    bl      inport_read
    mov     r1, #PEDESTRIAN_BUTTON
    bl      sw_is_pressed
    mov     r1, #1
    cmp     r0, r1
    beq     pededestrian_crossing
    b       operation_mode

crossing_times_array_addr:
    .word crossing_times_array

crossing_time_addr:
    .word crossing_time

; Rotina:    sw_is_pressed -----------------------------------------------------
; Descricao: Deteta se existiu uma transicao ascendente no bit identificado em 
;            IN_PEDESTRIAN_MASK.
; Entradas:  R0 - valor do porto de entrada
;            R1 - bit a analisar
; Saidas:    R0 - 1 se houve transicao ascendente, 0 caso contrario
; Efeitos:   -
sw_is_pressed:
    push    lr
    and     r0, r0, r1                  ; r0 = sw_new_state = inport_value & pin_mask
    ldr     r1, sw_state_addr
    ldrb    r2, [r1, #0]                ; r2 = sw_state
    cmp     r0, r2                      ; r0 = sw_new_state, r2 = sw_state
    beq     sw_is_pressed_0
    strb    r0, [r1, #0]                ; sw_state = sw_new_state
    sub     r0, r0, #0                  ; para testar a flag Z
    beq     sw_is_pressed_0             ; se Z = 1, então r0 = 0    
    mov     r0, #1
    b       sw_is_pressed_end
sw_is_pressed_0:
    mov     r0, #0
sw_is_pressed_end:
    pop     pc

sw_state_addr:
    .word sw_state

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

    ; incrementar sysclk
    ldr     r0, sysclk_addr
    ldrb    r1, [r0, #0]
    add     r1, r1, #1
    strb    r1, [r0, #0]

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

sw_state:
    .space  1

sysclk:
    .space  2

crossing_time:
    .byte 10
    .align


crossing_times_array:
    .byte  10, 20, 30, 40, 50, 60, 60
    ; hex: 00, 01, 02, 03, 04, 05, 06, 28


; ##############################################################################
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
    .space  STACK_SIZE
stack_top:
