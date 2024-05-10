# Laboratory Activity 05

## Objectives

Este trabalho tem como objetivo principal explorar a utilização do circuito Pico Timer/Counter (pTC) para gerar uma base de tempo num sistema computacional baseado no processador P16, designadamente implementar um system clock. A componente experimental do trabalho incide sobre a placa SDP16 e é apoiada pelas ferramentas p16as e p16dbg.

## Preparatory Work

### 3.2 Mapa de endereçamento do sistema

#### Elabore o mapa de endereçamento do sistema objeto de estudo, composto pela placa SDP16 e por um circuito pTC, considerando que o registo TIR do periférico pTC deverá ser acessível no endereço 0xFF7E.

#### Utilize o software [diagrams.net](https://www.diagrams.net/) para desenhar o mapa, que deverá explicitar o tipo, a dimensão e os endereços de início e fim do espaço atribuído a cada dispositivo. Se for o caso, o mapa também deverá explicitar a ocorrência de subaproveitamento e/ou de fold-back e a localização de eventuais zonas interditas (também designadas por "conflito").





### 3.3 Ligação física do circuito pTC ao sistema

#### Utilize o software [diagrams.net](https://www.diagrams.net/) para desenhar o esquema de ligações do circuito pTC às placas SDP16 e ATB, considerando que o sinal de relógio aplicado ao circuito pTC é obtido do Tie-Point Block P3 ('OSCILLATOR') da placa ATB.





### 3.4 Gestor do periférico para o *system clock* (sysclk)

#### 2. Indique o valor que deve ser associado ao símbolo **PTC_ADDRESS**. Justique a sua resposta.



#### 3. Considerando que o sinal de relógio a aplicar ao circuito pTC tem período 1 ms, indique o valor que deve ser associado ao símbolo **SYSCLK_FREQ** para que o intervalo de contagem do periférico pTC corresponda a 100 ms. Justique a sua resposta.





#### 4. Implemente a rotina **sysclk_init**, responsável por iniciar uma nova contagem no circuito pTC com o intervalo de contagem interval, em *ticks*, limpando eventuais pedidos de interrupção pendentes e iniciando com o valor zero a variável global **sysclk**, do tipo **uint16_t**. Considere a seguinte interface para essa rotina:

```c
void sysclk_init ( uint8_t interval );
```





#### 5. Implemente a rotina **sysclk_get_ticks**, que devolve o valor atual da variável global **sysclk**. Considere a seguinte interface para essa rotina:

```c
uint16_t sysclk_get_ticks();
```





#### 6. Implemente a rotina **isr**, responsável pelo incremento do valor da variável global **sysclk**. Considere a seguinte interface para essa rotina:

```c
void isr();
```





#### 7. Implemente a rotina **delay**, que realiza uma espera de **hms** milissegundos por teste sucessivo do valor da variável global **sysclk**. Considere a seguinte interface para essa rotina:

```c
void delay( uint16_t hms );
```





#### 8. Indique a funcionalidade do programa implementado no ficheiro *lab05.S*.



## To Do in Laboratory

### 4.5  Conceção de programas que interagem com um *system clock*

Tomando como base o código disponibilizado no cheiro *lab05.S*, escreva um programa que realize o seguinte efeito luminoso usando os **LED 'O0' a 'O7'** da placa **SDP16**: deslocamento circular para a esquerda de um ponto luminoso, implementado tendo, em cada momento, um **LED** aceso e os restantes sete **LED** apagados. 

O ritmo de evolução do efeito luminoso é imposto pelos **interruptores 0 a 2 do DIP-switch 'SW1'** instalado na placa **SDP16**, estando compreendido na gama **0,5 s, 1 s, 1,5 s, 2 s, 2,5 s, 3 s, 3,5 s, 4 s**. O **interruptor 7 do DIP-switch 'SW1'** é utilizado para reger o funcionamento do programa, habilitando a realização do efeito luminoso quando está na posição **'ON'** ou suspendendo a sua realização na posição contrária. 

Após o arranque do sistema, o **LED 'O0'** deverá estar aceso, enquanto os **LED 'O1' a 'O7'** deverão estar apagados.

