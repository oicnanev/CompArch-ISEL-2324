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
    .equ    SYSCLK_FREQ, 100            ; Intervalo de contagem do circuito pTC

    ; Outras definicoes                 ----------------------------------------
    .equ    BLINK_TIME, 0x0005          ; Tempo dos LEDs intermitentes 
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
    mov     r0, #SYSCLK_FREQ            ; frequencia para o pTC
    bl      sysclk_init
    mrs     r0, cpsr                    ; habilitar interrupcoes
    mov     r1, #CPSR_BIT_I
    orr     r0, r0, r1
    msr     cpsr, r0

main_loop:
    bl      get_config_sw              ; verificar a posicao do switch de mode
    mov     r1, #CONFIG_SW
    cmp     r0, r1
    beq     main_config_mode
    bl      operation_mode
    b       main_loop
main_config_mode:
    bl      config_mode
    b       main_loop
    b       .

; Rotina:    operation_mode ----------------------------------------------------
; Descricao: *** TODO ***
; Entradas:  -
; Saidas:    -
; Efeitos:   *** TODO ***
operation_mode:
    push   lr
    push   r4
    push   r5

    ; values 1 and 0 to use in flags to save clocks ---
    mov     r4, #0                              ; False
    mov     r5, #1                              ; True

    ; check if is the first time in operation mode --------
    ldr     r0, in_operation_addr0
    ldrb    r1, [r0, #0]
    cmp     r1, r5
    beq     not_first_time_in_operation_mode
    ; set in_config to 0, in_operation to 1 and in_crossing to 0
    strb    r5, [r0, #0]                        ; in_operation = 1
    ldr     r0, in_config_addr0
    strb    r4, [r0, #0]                        ; in_config = 0
    ldr     r0, in_crossing_addr0
    strb    r4, [r0, #0]                        ; in_crossing = 0
    ; set operation first time on phase to 1 -------------
    ldr     r0, op_first_time_on_phase_addr0
    strb    r5, [r0, #0]                        ; op_first_time_on_phase = 1
    ; turn on mode light L3 to green ---------------------
    mov     r0, #GREEN
    bl      mode_light_set_color
not_first_time_in_operation_mode:
    ; check if a pedestrian is crossing ------------------
    ldr     r0, in_crossing_addr0
    ldrb    r0, [r0, #0]
    cmp     r0, r5
    beq     pedestrian_crossing
    ; check if a pedestrian pressed the button to cross --
    bl      check_pedestrian_button
    cmp     r0, r5
    beq     pedestrian_ask_to_cross
    ; check if is the first time in operation mode --------
    ldr     r0, op_first_time_on_phase_addr0
    ldrb    r1, [r0, #0]
    cmp     r1, r4
    beq     not_first_time_on_op
    ; first time in operation mode to 0 ------------------
    strb    r4, [r0, #0]                        ; first_time_on_op = 0
    ; turn on pedestrian light L2 to red ------------------
    mov     r0, #RED
    bl      pedestrian_light_set_color
    ; start timer to turn ON/OFF L1 LED -------------------
    bl      sysclk_get_ticks                    ; get actual tick number to start timer
    ldr     r1, operation_time_start_tick_addr0
    str     r0, [r1, #0]                        ; operation_time_start_tick = sysclk_get_ticks
not_first_time_on_op:
    ; check if L1 LED are in ON or OFF phase --------------
    ldr     r0, op_led_phase_addr0
    ldrb    r0, [r0, #0]
    cmp     r0, r5
    beq     led_on_phase
; leds are in OFF phase
    mov     r0, #LIGHT_OFF                      ; turn OFF traffic light
    bl      traffic_light_set_color
    bl      operation_mode_led_phases
    b       end_operation_mode
led_on_phase:
    mov     r0, #YELLOW                          ; turn ON traffic green
    bl      traffic_light_set_color
    bl      operation_mode_led_phases
    b       end_operation_mode

in_operation_addr0:
    .word   in_operation

in_config_addr0:
    .word   in_config

op_first_time_on_phase_addr0:
    .word   op_first_time_on_phase

operation_time_start_tick_addr0:
    .word operation_time_start_tick

op_led_phase_addr0:
    .word op_led_phase

pedestrian_ask_to_cross:
    mov     r0, #RED
    bl      traffic_light_set_color
    mov     r0, #GREEN
    bl      pedestrian_light_set_color
    ldr     r0, in_crossing_addr0
    strb    r5, [r0, #0]                          ; R5 = 1, in_crossing = 1
    bl      start_pedestrian_timmer
    b       end_operation_mode

pedestrian_crossing:
    ; check if crossing time finished ---------------------
    ldr     r0, crossing_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed
    ldr     r1, crossing_time_addr0
    ldr     r1, [r1, #0]
    cmp     r0, r1
    bhs     pedestrian_time_finished
    ; check if anothers pedestrian pressed the button to cross
    bl      check_pedestrian_button
    cmp     r0, r5
    beq     pedestrian_ask_to_cross
    b       end_operation_mode
pedestrian_time_finished:
    ldr     r0, in_crossing_addr0
    strb    r4, [r0, #0]                          ; R4 = 0, in_crossing = 0

end_operation_mode:
    pop     r5
    pop     r4
    pop     pc
    
in_crossing_addr0:  
    .word   in_crossing

crossing_time_addr0:
    .word   crossing_time

; Rotina:    operation_mode_led_phases ---------------------------------------
; Descricao : *** TODO ***
; Entradas  : R0 - cor a colocar no L1 (transito)
; Saidas    : -
; Efeitos   : -
operation_mode_led_phases:
    push    lr
    push    r4
    push    r5

    mov     r4, #0                              ; False
    mov     r5, #1                              ; True

    ldr     r0, op_first_time_on_phase_addr
    ldrb    r1, [r0, #0]
    cmp     r1, r5
    bne     op_not_first_time_in_phase
    strb    r4, [r1, #0]                        ; set first_time_in_phase = False
    ;bl      traffic_light_set_color
op_not_first_time_in_phase:
    ldr     r0, operation_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed
    mov     r1, #BLINK_TIME & 0xFF
    movt    r1, #BLINK_TIME >> 8 & 0xFF
    cmp     r0, r1
    blo     operation_mode_led_phases_end
    ldr     r0, op_led_phase_addr
    ldrb    r1, [r0, #0]
    mvn     r1, r1                              ; R1 = ~r1
    and     r1, r1, r5                          ; R1 = r1 & 1, mascara para ficar só com o último bit
    strb    r1, [r0, #0]                        ; op_led_phase = r1
    ldr     r0, op_first_time_on_phase_addr
    strb    r5, [r0, #0]                        ; first_time_in_phase = True
operation_mode_led_phases_end:
    pop     r5
    pop     r4
    pop     pc

op_first_time_on_phase_addr:
    .word   op_first_time_on_phase

op_led_phase_addr:
    .word   op_led_phase

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

operation_time_start_tick_addr:
    .word operation_time_start_tick

crossing_time_start_tick_addr:
    .word crossing_time_start_tick

; Rotina:    config_mode -------------------------------------------------------
; Descricao: *** TODO ***
; Entradas:  -
; Saidas:    -
; Efeitos:   *** TODO ***
config_mode:
    push    lr
    push    r4
    push    r5

    ; values 1 and 0 to use in flags to save clocks ---
    mov     r4, #0                              ; False  
    mov     r5, #1                              ; True

    ; check if is the first time in config mode --------
    ldr     r0, in_config_addr
    ldrb    r1, [r0, #0]
    cmp     r1, r5
    beq     not_first_time_in_config_mode
    ; set in_config to 1, in_operation to 0 and in_crossing to 0
    strb    r5, [r0, #0]                        ; in_config = 1     
    ldr     r0, in_operation_addr
    strb    r4, [r0, #0]                        ; in_operation = 0
    ldr     r0, in_crossing_addr
    strb    r4, [r0, #0]                        ; in_crossing = 0
    ; set config first time on phase to 1 -------------
    ldr     r0, conf_first_time_on_phase_addr
    strb    r5, [r0, #0]                        ; conf_first_time_on_phase = 1
    ; turn on mode light L3 to yellow ------------------
    mov     r0, #YELLOW
    bl      mode_light_set_color
not_first_time_in_config_mode:
    ; check if L1 and L2 LEDS are in ON or OFF phase ---
    ldr     r0, conf_leds_phase_addr
    ldrb    r0, [r0, #0]
    cmp     r0, r5
    beq     config_mode_leds_on_phase
; leds are in OFF phase
    mov     r0, #LIGHT_OFF                      ; turn OFF traffic light
    mov     r1, #LIGHT_OFF                      ; turn OFF pedestrian light
    bl      config_mode_leds_phases
    b       config_mode_end
config_mode_leds_on_phase:
    ; check if is first time in ON phase ---------------
    mov     r0, #YELLOW                         ; turn ON traffic yellow
    mov     r1, #GREEN                          ; turn ON pedestrian green
    bl      config_mode_leds_phases
config_mode_end:
    bl      set_crossing_time
    pop     r5
    pop     r4
    pop     pc

in_config_addr:
    .word   in_config
in_operation_addr:
    .word   in_operation
in_crossing_addr:    
    .word   in_crossing

; Rotina:    config_mode_leds_phases -------------------------------------------
; Descricao : *** TODO ***
; Entradas  : R0 - cor a colocar no L1 (transito)
;             R1 - cor a colocar no L2 (peoes)
; Saidas    : -
config_mode_leds_phases:
    push    lr
    push    r4
    push    r5
    push    r6

    mov     r5, #1                              ; True

    ldr     r3, conf_first_time_on_phase_addr
    ldrb    r2, [r3, #0]
    cmp     r2, r5
    bne     not_first_time_in_phase 

    ; save the light colors
    mov     r6, r0                              ; R0 = cor a colocar no L1 (transito), guardada em R6
    mov     r4, r1                              ; R1 = cor a colocar no L2 (peoes), guardada em R4
    
    ; start timer to turn ON/OFF L1 and L2 LEDS ------------
    bl      sysclk_get_ticks                    ; get actual tick number to start timer
    ldr     r1, config_time_start_tick_addr
    str     r0, [r1, #0]                        ; config_time_start_tick = sysclk_get_ticks

    
    mov     r0, r6                              ; R0 = cor a colocar no L1 (transito)
    bl      traffic_light_set_color             ; R0 = cor a colocar no L1 (transito)
    mov     r0, r4                              ; R0 = cor a colocar no L2 (peoes)
    bl      pedestrian_light_set_color
    mov     r0, #0 && 0xFF
    movt    r0, #0 >> 8 & 0xFF
    ldr     r3, conf_first_time_on_phase_addr
    strb    r0, [r3, #0]                        ; set first_time_in_phase = False
not_first_time_in_phase:
    ldr     r0, config_time_start_tick_addr
    ldr     r0, [r0, #0]
    bl      sysclk_elapsed
    mov     r1, #BLINK_TIME & 0xFF
    movt    r1, #BLINK_TIME >> 8 & 0xFF
    cmp     r0, r1
    blo     config_mode_leds_phase_end
    ldr     r0, conf_leds_phase_addr
    ldrb    r1, [r0, #0]
    mvn     r1, r1                              ; R1 = ~r1
    and     r1, r1, r5                          ; R1 = r1 & 1, mascara para ficar só com o último bit
    strb    r1, [r0, #0]                        ; config_leds_on = r1
    ldr     r0, conf_first_time_on_phase_addr
    strb    r5, [r0, #0]                        ; first_time_in_phase = True
config_mode_leds_phase_end:
    pop     r6
    pop     r5
    pop     r4
    pop     pc

conf_first_time_on_phase_addr:
    .word   conf_first_time_on_phase
config_time_start_tick_addr:
    .word   config_time_start_tick
conf_leds_phase_addr:
    .word   conf_leds_phase

; Rotina:    isr ---------------------------------------------------------------
; Descricao: Incrementa o valor da variável global sysclk.
; Entradas:  -
; Saidas:    -
; Efeitos:   Incrementa o valor da variável global sysclk
isr:
    push    r0
    push    r1

    ; incrementar sysclk
    ldr     r0, sysclk_addr0
    ldr     r1, [r0, #0]
    add     r1, r1, #1
    str     r1, [r0, #0]

    ; "limpar" a interrupção no pTC
    ldr     r0, ptc_addr
    strb    r1, [r0, #PTC_TIR]

    pop     r1
    pop     r0
    movs    pc, lr

ptc_addr:
    .word PTC_ADDRESS

sysclk_addr0:
    .word sysclk

; SERVICOS ####################################################################
; Rotina:    set_crossing_time ------------------------------------------------
; Descricao: Atribui o tempo de travessia especificado à variável crossing_time.
; Entradas:  -
; Saidas:    -
; Efeitos:   crossing_time = crossing_times_array[TIME_SWS]
set_crossing_time:
    push    lr
    bl      inport_read
    mov     r1, #TIME_SWS & 0xFF
    movt    r1, #TIME_SWS >> 8 & 0xFF
    and     r2, r0, r1                      ; selecionar apenas bits dos Time switches
    lsr     r2, r2, #5                      ; shift right para obter o index
    add     r2, r2, r2                      ; r2 = r2 * 3
    ldr     r0, crossing_times_array_addr   
    ldr     r1, [r0, r2]                    ; transferir o valor da array de times, index = r2
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
    bl      sw_is_released
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

; Rotina:    sw_is_released -----------------------------------------------------
; Descricao: Deteta se existiu uma transicao descendente no bit identificado em 
;            IN_PEDESTRIAN_MASK.
; Entradas:  R0 - valor do porto de entrada
;            R1 - bit a analisar
; Saidas:    R0 - 1 se houve transicao descendente, 0 caso contrario
; Efeitos:   -
sw_is_released:
    push    lr
    and     r0, r0, r1                  ; r0 = sw_new_state = inport_value & pin_mask
    ldr     r1, sw_state_addr
    ldrb    r2, [r1, #0]                ; r2 = sw_state
    cmp     r0, r2                      ; r0 = sw_new_state, r2 = sw_state
    beq     sw_is_released_0
    strb    r0, [r1, #0]                ; sw_state = sw_new_state
    mov     r1, #1
    cmp     r0, r1                      ; r0 = sw_new_state
    bne     sw_is_released_1
sw_is_released_0:
    mov     r0, #0
    b       sw_is_released_end
sw_is_released_1:
    mov     r0, #1
sw_is_released_end:
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
    strb    r0, [r1, #0]
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
    strb    r0, [r1, #0]
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
    push    r0                  ; guardar o valor do intervalo
    bl      ptc_stop
    pop     r0                  ; recuperar o valor do intervalo
    ldr     r1, ptc_addr0
    strb    r0, [r1, #PTC_TMR]
    bl      ptc_clr_irq
    bl      ptc_start
    pop     pc

ptc_addr0:
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

; operation mode variables -----------------------------------------------------
crossing_time:
    .word 0x0064

crossing_times_array:
    .word  100, 200, 300, 400, 500, 600, 600, 600 ; 1 tick = 100ms / 10 ticks = 1s
    ;.word  0x0064, 0x00C8, 0x012C, 0x0190, 0x01F4, 0x0258, 0x0258, 0x0258

in_crossing:     ; flag para saber se ha peao a atravessar
    .byte 0

in_operation:    ; flag para saber se o modo de operacao esta ativo
    .byte 0      ; 0 - 1a entrada em modo operação, 1 - reentradas vindas do main_loop

crossing_time_start_tick: ; para ter o valor do tick em que o peao comecou a atravessar
    .space 2

operation_time_start_tick: ; para ter o valor do tick em que o semaforo de transito apagou ou acendeu
    .space 2

first_time_on_op:  ; flag para saber se e para acender ou nao o led dos peoes
    .byte 1

op_led_phase:      ; flag para saber se e para acender ou nao o led do transito
    .byte 1

op_first_time_on_phase: ; flag para saber se e a primeira vez que os leds estao acesos
    .byte 1

; config mode variables --------------------------------------------------------
in_config:       ; flag para saber se o modo de configuracao esta ativo
    .byte 0      ; 0 - 1a entrada em modo operação, 1 - reentradas vindas do main_loop

config_time_start_tick: ; para ter o valor do tick em que os semaforos apagaram ou acenderam
    .space 2

conf_leds_phase:  ; flag para saber se e para acender ou nao os leds
    .byte 1

conf_first_time_on_phase: ; flag para saber se e a primeira vez que os leds estao acesos
    .byte 1

; ##############################################################################
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
    .space  STACK_SIZE
stack_top:
