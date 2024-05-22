; Ficheiro:  traffic_lightsv2.S
; Descricao: Programa de suporte ao protótipo de um sistema embebido baseado no 
;            processador P16 que implementa o controlador de um sistema de 
;            semáforos para uma passadeira.
; Autores:   Grupo 02 da turma 21N (45824 Nuno Venancio e 48070 Daniel Cabaça) 
; Data:      15-05-2024
;
; -----------------------------------------------------------------------------
; |                               APLICAÇÂO                                   |
; |                              main    isr                                  |
; | is_pedestrian_crossing start_pedestrian_timmer is_crossing_time_finished  |
; |     start_operation_timmer is_operation_time_finished is_traffic_t_on     |
; |        start_config_timmer is_config_t_on is_config_time_finished         |
; |---------------------------------------------------------------------------|
; |                                 SERVIÇOS                                  |
; |   set_crossing_time check_pedestrian_button get_config_sw sw_is_pressed   |
; |  traffic_light_set_color pedestrian_light_set_color mode_light_set_color  |
; |               sysclk_init sysclk_get_ticks sysclk_elapsed                 | 
; |---------------------------------------------------------------------------|
; |                          GESTORES DE PERIFÉRICOS                          |
; |                               inport_read                                 |
; |         outport_set_bits outport_clear_bits outport_write_bits            |
; |         ptc_init ptc_start ptc_stop ptc_get_value ptc_clr_irq             |
; -----------------------------------------------------------------------------
;
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
    .equ    TRAFFIC_LIGHT, 0x03         ; Mascara para semáforo de trânsito
    .equ    PEDESTRIAN_LIGHT, 0x0C      ; Mascara para semáforo de peões
    .equ    MODE_LIGHT, 0x30            ; Mascara para semáforo de modo

    ; Definicoes do circuito pTC        ----------------------------------------
    .equ    PTC_ADDRESS,  0xFF40        ; Endereco do circuito pTC
    .equ    PTC_TCR, 0                  ; Deslocamento do registo TCR do pTC
    .equ    PTC_TMR, 2                  ; Deslocamento do registo TMR do pTC
    .equ    PTC_TC,  4                  ; Deslocamento do registo TC do pTC
    .equ    PTC_TIR, 6                  ; Deslocamento do registo TIR do pTC
    .equ    PTC_CMD_START, 0            ; Comando para iniciar a contagem no pTC
    .equ    PTC_CMD_STOP, 1             ; Comando para parar a contagem no pTC
    .equ    SYSCLK_FREQ, 0x63           ; Intervalo de contagem do circuito pTC
                                        ; que suporta a implementação do sysclk
                                        ; T = 1 / f  
                                        ; 0.001s = 1 / 1000Hz
                                        ; 0.1s   = 1 / f ( f = 10Hz )
                                        ; 1000Hz / 10Hz = 100Hz = 0x64

    ; Outras definicoes                 ----------------------------------------
    .equ    BLINK_TIME, 0x05            ; Tempo dos LEDs intermitentes 
    .equ    RED, 0x01                   ; Mascara para o LED vermelho
    .equ    GREEN, 0x02                 ; Mascara para o LED verde
    .equ    YELLOW, 0x03                ; Mascara para o LED amarelo
    .equ    LIGHT_OFF, 0x00             ; Mascara para apagar os LEDs
 

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
main:
    mov     r0, #0                      ; todos os LEDs apagados
    bl      outport_init
    mov     r0, #SYSCLK_FREQ
    bl      sysclk_init
    mrs     r0, cpsr
    mov     r1, #CPSR_BIT_I
    orr     r0, r0, r1
    msr     cpsr, r0

    ; default flags to save some clocks
    mov     r4, #0                     ; False
    mov     r5, #1                     ; True

main_loop:
    bl      get_config_sw              ; ler portos de entrada, R0 = CONFIG_SW                    
    cmp     r0, r4                     ; check CONFIG is 0
    bne     config_mode
    mov     r0, #GREEN
    bl      mode_light_set_color
    bl      is_pedestrian_crossing
    cmp     r0, r4                     ; R4 = 0
    bne     pedestrian_crossing
    bl      check_pedestrian_button
    cmp     r0, r4                     ; R4 = 0
    beq     operation_mode
pedestrian_ask_to_cross:
    mov     r0, #RED
    bl      traffic_light_set_color
    mov     r0, #GREEN
    bl      pedestrian_light_set_color
    ldr     r0, in_crossing_addr0
    strb    r5, [r0, #0]                ; R5 = 1
    bl      start_pedestrian_timmer
    b       main_loop

in_crossing_addr0:
    .word in_crossing

operation_mode:
    ldr     r0, is_operation_timmer_running_addr0
    ldrb    r0, [r0, #0]
    cmp     r0, r4                     ; R4 = 0
    bne     operation_mode_timmer_running
    bl      start_operation_timmer

is_operation_timmer_running_addr0:
    .word is_operation_timmer_running
    
operation_mode_timmer_running:
    mov     r0, #RED
    bl      pedestrian_light_set_color
    bl      is_traffic_t_on
    cmp     r0, r4                     ; R4 = 0
    bne     traffic_t_on
traffic_t_off:
    mov     r0, #LIGHT_OFF
    bl      traffic_light_set_color
    bl      is_operation_time_finished
    cmp     r0, r4                     ; R4 = 0
    bne     main_loop
    ldr     r0, traffic_t_on_addr0
    strb    r5, [r0, #0]                ; R5 = 1
    b       main_loop
traffic_t_on:
    mov     r0, #YELLOW
    bl      traffic_light_set_color
    bl      is_operation_time_finished
    cmp     r0, r4                     ; R4 = 0
    bne     main_loop
    ldr     r0, traffic_t_on_addr0
    strb    r4, [r0, #0]               ; R4 = 0
    b       main_loop    

pedestrian_crossing:
    bl      is_crossing_time_finished
    cmp     r0, r4                     ; R4 = 0
    ; ver se carregou no botao
    ;bl      check_pedestrian_button
    ;cmp     r0, r5                     ; R5 = 1
    ;beq     extend_crossing_time
    beq     main_loop
    ldr     r0, in_crossing_addr
    strb    r4, [r0, #0]               ; R4 = 0
    b       main_loop

config_mode:
    ldr     r0, is_config_timmer_running_addr
    ldrb    r0, [r0, #0]
    cmp     r4, r0                     ; R4 = 0
    bne     config_timmer_running
    bl      start_config_timmer
config_timmer_running:
    mov     r0, #YELLOW
    bl      mode_light_set_color
    bl      is_config_t_on
    cmp     r0, r4                     ; R4 = 0
    bne     config_t_on
config_t_off:
    mov     r0, #LIGHT_OFF
    bl      traffic_light_set_color
    mov     r0, #LIGHT_OFF
    bl      pedestrian_light_set_color
    bl      set_crossing_time
    bl      is_config_time_finished
    cmp     r0, r4                     ; R4 = 0
    
    bne     main_loop
    ldr     r0, config_t_on_addr0
    strb    r5, [r0, #0]                ; R5 = 1
    bl      set_crossing_time
    b       main_loop
config_t_on:
    mov     r0, #YELLOW
    bl      traffic_light_set_color
    mov     r0, #GREEN
    bl      pedestrian_light_set_color
    bl      set_crossing_time
    bl      is_config_time_finished
    cmp     r0, r4                     ; r4 = 0
    
    beq     main_loop
    ldr     r0, config_t_on_addr0
    strb    r4, [r0, #0]               ; R4 = 0
    bl      set_crossing_time
    b       main_loop

is_operation_timmer_running_addr:
    .word is_operation_timmer_running

is_config_timmer_running_addr:
    .word is_config_timmer_running

traffic_t_on_addr0:
    .word traffic_t_on

config_t_on_addr0:
    .word config_t_on

; Rotina:    is_pedestrian_crossing ------------------------------------------------
; Descricao: Devolve se um peão está a atravessar a passadeira.
; Entradas:  -
; Saidas:    R0 - 1 se um peão está a atravessar a passadeira, 0 caso contrário
; Efeitos:   -
is_pedestrian_crossing:
    ldr     r0, in_crossing_addr
    ldrb    r0, [r0, #0]
    mov     pc, lr

in_crossing_addr:
    .word in_crossing

; Rotina:    start_pedestrian_timmer ------------------------------------------------
; Descricao: Inicia a contagem do tempo de travessia.
; Entradas:  -
; Saidas:    -
; Efeitos:   crossing_time_start_tick = sysclk
start_pedestrian_timmer:
    push    lr
    bl      sysclk_get_ticks
    ldr     r1, crossing_time_start_tick_addr
    str     r0, [r1, #0]
    pop     pc

; Rotina:   start_operation_timmer ------------------------------------------------
; Descricao: Inicia a contagem do tempo de operação sem travessia de peao.
; Entradas:  -
; Saidas:    -
; Efeitos:   operation_time_start_tick = sysclk
start_operation_timmer:
    push    lr
    ldr     r0, in_operation_addr    ; set flag in_operation
    mov     r1, #1
    strb    r1, [r0, #0]
    ldr     r0, in_config_addr       ; clear flag in_config
    mov     r1, #0
    strb    r1, [r0, #0]
    bl      sysclk_get_ticks         ; R0 = sysclk
    ldr     r1, operation_time_start_tick_addr
    str     r0, [r1, #0]             ; operation_time_start_tick = sysclk
    pop     pc

; Rotina:    is_traffic_t_on ------------------------------------------------
; Descricao: Devolve se o LED amarelo do semáforo de trânsito está aceso.
; Entradas:  -
; Saidas:    R0 - 1 se o LED amarelo do semáforo de trânsito está aceso, 0 caso contrário
; Efeitos:   -
is_traffic_t_on:
    ldr     r0, traffic_t_on_addr
    ldrb    r0, [r0, #0]
    mov     pc, lr

traffic_t_on_addr:
    .word traffic_led_on

; Rotina:    is_operation_time_finished ---------------------------------------------
; Descricao: Devolve se passaram 500ms desde o inicio do tempo de operação.
; Entradas:  -
; Saidas:    R0 - 1 se passaram 500ms desde o inicio do tempo de operação, 0 caso contrário
; Efeitos:   -
is_operation_time_finished:
    push    lr
    ldr     r0, operation_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed              ; R0 = sysclk - operation_time_start_tick
    mov     r1, #BLINK_TIME && 0xFF
    cmp     r0, r1
    blo     is_operation_time_finished_0    
    bl      start_operation_timmer      ; restart operation timer
    mov     r0, #1
    b       is_operation_time_finished_end
is_operation_time_finished_0:
    mov     r0, #0
is_operation_time_finished_end:    
    pop     pc

operation_time_start_tick_addr:
    .word operation_time_start_tick

; Rotina:    is_crossing_time_finished ---------------------------------------------
; Descricao: Devolve se passou o tempo de travessia.
; Entradas:  -
; Saidas:    R0 - 1 se passou o tempo de travessia, 0 caso contrário
; Efeitos:   -
is_crossing_time_finished:
    push    lr
    ldr     r0, crossing_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed              ; R0 = sysclk - crossing_time_start_tick
    ldr     r1, crossing_time_addr
    ldr     r1, [r1, #0]
    cmp     r0, r1
    blo     is_crossing_time_finished_0
    mov     r0, #1
    b       is_crossing_time_finished_end
is_crossing_time_finished_0:
    mov     r0, #0
is_crossing_time_finished_end:
    pop     pc

crossing_time_start_tick_addr:
    .word crossing_time_start_tick

; Rotina:    start_config_timmer ------------------------------------------------
; Descricao: Inicia a contagem do tempo de configuração.
; Entradas:  -
; Saidas:    -
; Efeitos:   config_time_start_tick = sysclk
start_config_timmer:
    push    lr
    ldr     r0, in_config_addr        ; set flag in_config
    mov     r1, #1
    strb    r1, [r0, #0]
    ldr     r0, in_operation_addr     ; clear flag in_operation
    mov     r1, #0
    strb    r1, [r0, #0]
    bl      sysclk_get_ticks          ; R0 = sysclk
    ldr     r1, config_time_start_tick_addr
    str     r0, [r1, #0]              ; config_time_start_tick = sysclk
    pop     pc

in_config_addr:
    .word in_config

in_operation_addr:
    .word in_operation

; Rotina:    is_config_t_on ------------------------------------------------
; Descricao: Devolve se os LEDs dos semáforos de peao e transito estao acesos.
; Entradas:  -
; Saidas:    R0 - 1 se os LEDs dos semaforos de peao e transito estao acesos, 0 caso contrário
; Efeitos:   -
is_config_t_on:
    ldr     r0, config_t_on_addr
    ldrb    r0, [r0, #0]
    mov     pc, lr

config_t_on_addr:
    .word config_led_on

; Rotina:    is_config_time_finished ------------------------------------------------
; Descricao: Devolve se passaram 500ms desde o inicio do tempo de configuração.
; Entradas:  -
; Saidas:    R0 - 1 se passaram 500ms desde o inicio do tempo de configuração, 0 caso contrário
; Efeitos:   -
is_config_time_finished:
    push    lr
    ldr     r0, config_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed              ; R0 = sysclk - config_time_start_tick
    mov     r1, #BLINK_TIME && 0xFF
    cmp     r0, r1
    blo     is_config_time_finished_0
    bl      start_config_timmer         ; restart config timer
    mov     r0, #1
    b       is_config_time_finished_end
is_config_time_finished_0:
    mov     r0, #0
is_config_time_finished_end:
    pop     pc

config_time_start_tick_addr:
    .word config_time_start_tick

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
    ldr     r0, sysclk_addr0
    ldrb    r1, [r0, #0]
    add     r1, r1, #1
    strb    r1, [r0, #0]

    pop     r1
    pop     r0
    movs    pc, lr

ptc_addr:
    .word PTC_ADDRESS

sysclk_addr0:
    .word sysclk_addr


; SERVIÇOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Rotina:    set_crossing_time ------------------------------------------------
; Descricao: Atribui o tempo de travessia especificado à variável crossing_time.
; Entradas:  -
; Saidas:    -
; Efeitos:   crossing_time = crossing_times_array[TIME_SWS]
set_crossing_time:
    push    lr
    mov     r1, #TIME_SWS && 0xFF
    bl      inport_read
    and     r1, r0, r1                      ; selecionar apenas bits dos Time switches
    ldr     r0, crossing_times_array_addr   
    ldr     r1, [r0, r1]                    ; transferir o valor da array de times, index = r1
    ldr     r0, crossing_time_addr
    str     r1, [r0, #0]                    ; crossing_time = crossing_times_array[index]
    pop     pc

crossing_times_array_addr:
    .word crossing_times_array

crossing_time_addr:
    .word crossing_time
; Rotina:    check_pedestrian_button -------------------------------------------
; Descricao: Devolve se um peão pressionou o botão de peão.
; Entradas:  -
; Saidas:    R0 - 1 se o botão de peão foi pressionado, 0 caso contrário
; Efeitos:   -
check_pedestrian_button:
    push    lr
    bl      inport_read
    mov     r1, #PEDESTRIAN_BUTTON
    bl      sw_is_pressed
    pop     pc

; Rotina:    get_config_sw -----------------------------------------------------
; Descricao: Devolve se um peão pressionou o botão de peão.
; Entradas:  -
; Saidas:    R0 - 1 se o botão de peão foi pressionado, 0 caso contrário
; Efeitos:   -
get_config_sw:
    push    lr
    bl      inport_read
    mov     r1, #CONFIG_SW
    and     r0, r0, r1
    pop     pc

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
    sub     r0, r0, #0                  ; para testar a flag Z, sw_new_state == 0
    beq     sw_is_pressed_0             ; se Z = 1, então r0 = 0    
    mov     r0, #1
    b       sw_is_pressed_end
sw_is_pressed_0:
    mov     r0, #0
sw_is_pressed_end:
    pop     pc

sw_state_addr:
    .word sw_state

; Rotina:    traffic_light_set_color -------------------------------------------
; Descricao: Atribui a cor especificada em R0 ao semáforo de trânsito (L1).
; Entradas:  R0 - Cor a atribuir ao semáforo de trânsito (L1)
; Saidas:    -
; Efeitos:   - 
traffic_light_set_color:
    push    lr
    mov     r1, r0                      ; r1 = color
    mov     r0, #TRAFFIC_LIGHT          ; r0 = TRAFFIC_LIGHT
    bl      outport_write_bits
    pop     pc

; Rotina:    pedestrian_light_set_color ----------------------------------------
; Descricao: Atribui a cor especificada em R0 ao semáforo de peões (L2).
; Entradas:  R0 - Cor a atribuir ao semáforo de peões (L2)
; Saidas:    -
; Efeitos:   -
pedestrian_light_set_color:
    push    lr
    mov     r1, r0                      ; r1 = color
    mov     r0, #PEDESTRIAN_LIGHT       ; r0 = PEDESTRIAN_LIGHT
    lsl     r1, r1, #2                  ; r1 = color << 2
    bl      outport_write_bits
    pop     pc

; Rotina:    mode_light_set_color ----------------------------------------------
; Descricao: Atribui a cor especificada em R0 ao semáforo de modo (L3).
; Entradas:  R0 - Cor a atribuir ao semáforo de modo (L3)
; Saidas:    -
; Efeitos:   -
mode_light_set_color:
    push    lr
    mov     r1, r0                      ; r1 = color
    mov     r0, #MODE_LIGHT             ; r0 = MODE_LIGHT
    lsl     r1, r1, #4                  ; r1 = color << 4
    bl      outport_write_bits
    pop     pc

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

; Rotina:    sysclk_elapsed ----------------------------------------------------
; Descricao: Devolve o tempo decorrido, em ticks, desde o instante last_read
; Entradas:  R0 - valor do instante last_read
; Saidas:    R0 - tempo decorrido, em ticks, desde o instante last_read
; Efeitos:   -
sysclk_elapsed:
    ldr     r1, sysclk_addr
    ldr     r2, [r1, #0]            ; r2 = sysclk
    sub     r0, r2, r0
    mov     pc, lr

sysclk_addr:
    .word sysclk

; GESTORES DE PERIFÉRICOS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
; Gestor de periférico para o porto de entrada =================================
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

; Gestor de periférico para o porto de saída ===================================
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

; Rotina:    outport-write_bits ------------------------------------------------
; Descricao: Atribui aos pinos do porto de saida identificados com o valor 1 em
;            pin_mask (R0) o valor correspondente de value (R1). O valor dos
;            restantes bits nao e alterado.
; Entradas:  R0 - Mascara com os bits a alterar.
;            R1 - Valor a atribuir aos bits identificados em R0.
; Saidas:    -
; Efeitos:   Altera o valor da variavel global outport_img.
outport_write_bits:
    push    lr
    and     r1, r1, r0                  ; r1 = pin_mask & value
    ldr     r2, outport_img_addr
    ldrb    r3, [r2, #0]
    mvn     r0, r0                      ; r0 = ~pin_mask
    and     r3, r0, r3                  ; r3 = outport_img &= ~pin_mask
    orr     r0, r3, r1                  ; r0 = outport_img |= pin_mask & value
    bl      outport_write
    pop     pc

; Rotina:    outport_write -----------------------------------------------------
; Descricao: Escreve no porto de saida o valor recebido em R0.
;            Interface exemplo: void outport_write( uint8_t value );
; Entradas:  R0 - valor a atribuir ao porto de saida.
; Saidas:    -
; Efeitos:   -
outport_write:
    ldr     r1, outport_addr
    strb    r0, [r1, #0]
    ldr     r2, outport_img_addr
    strb    r0, [r2, #0]
    mov     pc, lr

outport_addr:
    .word   OUTPORT_ADDRESS

outport_img_addr:
    .word   outport_img

; Gestor de periférico para o Pico Timer/Counter (pTC) =========================
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
    ldr     r1, PTC_ADDR0
    mov     r2, #PTC_CMD_STOP
    strb    r2, [r1, #PTC_TCR]
    strb    r0, [r1, #PTC_TMR]
    bl      ptc_clr_irq
    ldr     r1, PTC_ADDR
    mov     r2, #PTC_CMD_START
    strb    r2, [r1, #PTC_TCR]
    pop     pc

PTC_ADDR0:
    .word   PTC_ADDRESS

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
    .word 100

crossing_times_array:
    .word  100, 200, 300, 400, 500, 600, 600, 600 ; 1 tick = 100ms / 10 ticks = 1s
    ; hex: 063, 0C8, 12C, 190, 1F4, 258, 258, 258

in_crossing:     ; flag para saber se ha peao a atravessar
    .byte 0

in_config:       ; flag para saber se o modo de configuracao esta ativo
    .byte 0

in_operation:    ; flag para saber se o modo de operacao esta ativo
    .byte 0
    .align

crossing_time_start_tick:
    .space 2

operation_time_start_tick:
    .space 2

config_time_start_tick:
    .space 2

traffic_led_on:    ; flag para saber se o semaforo de transito esta aceso
    .byte 1

config_led_on:      ; flag para saber se o semaforo de transito e peoes esta aceso
    .byte 1       ; durante o modo de configuracao

is_operation_timmer_running:
    .byte 0

is_config_timmer_running:
    .byte 0


; ##############################################################################
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
    .space  STACK_SIZE
stack_top:
