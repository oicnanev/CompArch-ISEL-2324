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
    bl      get_config_sw
    bne     main_config_mode
    bl      operation_mode
    b       main_loop
main_config_mode:
    bl      config_mode
    b       main_loop

; Rotina:    operation_mode ----------------------------------------------------
operation_mode:
    ; TODO

; Rotina:    config_mode -------------------------------------------------------
config_mode:
    push    lr
    push    r4
    push    r5

    ; values 1 and 0 to use in flags to save some clocks
    mov     r4, #0
    mov     r5, #1

    ; check if is the first time in config mode
    ldr     r0, in_config_addr
    ldrb    r0, [r0]
    cmp     r0, r5
    beq     not_first_time_in_config_mode
    ; set in_config to 1 and in_operation to 0
    strb    r5, [r0]
    ldr     r0, in_operation_addr
    strb    r4, [r0, #0]
    ; turn on mode light L3 to yellow
    mov     r1, #YELLOW
    bl      mode_light_set_color
not_first_time_in_config_mode:
    ; check if L1 and L2 LEDS are in ON or OFF phase
    ldr     r0, config_leds_on_addr
    ldrb    r0, [r0, #0]
    cmp     r0, r5
    bne     config_mode_leds_off_phase

config_mode_leds_on_phase:
    ; check if is first time in ON phase
    ldr     r0, in_c_leds_on_addr
    ldrb    r1, [r0, #0]
    cmp     r1, r5
    beq     not_first_time_in_on_phase
    strb    r5, [r2, #0]        ; set_c_leds_on = 1    
    bl      sysclk_get_ticks
    ldr     r1, config_time_start_tick_addr  ; start timer
    str     r0, [r1, #0]        ; config_time_start_tick = sysclk_get_ticks
    mov     r0, #YELLOW         ; turn ON traffic yellow
    bl      traffic_light_set_color
    mov     r0, #GREEN          ; turn ON pedestrian green
    bl      pedestrian_light_set_color
not_first_time_in_on_phase:
    ; check if time finished (passed 500ms)
    bl      sysclk_elapsed
    ldr     r1, config_time_start_tick_addr
    ldr     r1, [r1, #0]              ; R0 = config_time_start_tick
    mov     r2, #BLINK_TIME
    cmp     r1, r2
    blo     config_mode_end
    ; Time is finished - turn off L1 and L2 LEDS
    ldr     r0, config_leds_on_addr
    strb    r4, [r0, #0]
    ldr     r0, in_c_leds_off
    strb    r4, [r0, #0]
    bl      config_mode_end

config_mode_leds_off_phase:
    ; check if is first time in OFF phase
    ldr     r0, in_c_leds_off_addr
    ldrb    r1, [r0, #0]
    cmp     r1, r5
    beq     not_first_time_in_off_phase
    strb    r5, [r2, #0]        ; set_c_leds_off = 1
    bl      sysclk_get_ticks
    ldr     r1, config_time_start_tick_addr  ; start timer
    str     r0, [r1, #0]        ; config_time_start_tick = sysclk_get_ticks
    mov     r0, #LIGHT_OFF      ; turn OFF traffic light
    bl      traffic_light_set_color
    mov     r0, #LIGHT_OFF      ; turn OFF pedestrian light
    bl      pedestrian_light_set_color
not_first_time_in_off_phase:
    ; check if time finished (passed 500ms)
    bl      sysclk_elapsed
    ldr     r1, config_time_start_tick_addr
    ldr     r1, [r1, #0]              ; R0 = config_time_start_tick
    mov     r2, #BLINK_TIME
    cmp     r1, r2
    blo     config_mode_end
    ; Time is finished - turn on L1 and L2 LEDS
    ldr     r0, config_leds_on_addr
    strb    r5, [r0, #0]
    ldr     r0, set_c_lights_on
    strb    r5, [r0, #0]
    bl      config_mode_end

config_mode_end:
    bl      set_crossing_time
    pop     r4
    pop     r5
    pop     pc

in_config_addr:
    .word   in_config
in_operation_addr:
    .word   in_operation
in_c_leds_on_addr:
    .word   in_c_leds_on
in_c_leds_off_addr:
    .word   in_c_leds_off
config_leds_on_addr:
    .word   config_leds_on




; SERVICOS ####################################################################
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
    .byte 0      ; 0 - 1a entrada em modo operação, 1 - reentradas vindas do main_loop

in_operation:    ; flag para saber se o modo de operacao esta ativo
    .byte 0      ; 0 - 1a entrada em modo operação, 1 - reentradas vindas do main_loop
    .align

crossing_time_start_tick:
    .space 2

operation_time_start_tick:
    .space 2

config_time_start_tick:
    .space 2

traffic_led_on:    ; flag para saber se o semaforo de transito esta aceso
    .byte 1

config_leds_on:    ; flag para saber se o semaforo de transito e peoes esta aceso
    .byte 1        ; durante o modo de configuracao

in_c_leds_off:     ; flag para saber se é a primeira vez que os leds estão apagados
    .byte 0        ; durante o modo de configuracao

in_c_leds_on:      ; flag para saber se e a primeira vez que os leds estão acesos
    .byte 0        ; durante o modo de configuracao

; ##############################################################################
; Seccao:    stack
; Descricao: Implementa a pilha com o tamanho definido pelo simbolo STACK_SIZE
;
    .stack
    .space  STACK_SIZE
stack_top:
