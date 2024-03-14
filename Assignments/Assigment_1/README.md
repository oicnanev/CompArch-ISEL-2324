# Assignment 1

## 1 Introduction

The main objectives of this work are the exercise of programming in assembly language of the P16 processor, including the organization of programs into routines and the exploration of a programming environment in this language.



## 2  Exercise Specification

The assignment consists in the development and testing of a program involving 

- i) operations with integers, with and without sign, 
- ii) use of variables in memory, 
- iii) invocation of routines and 
- iv) access to in-memory arrays. 

Listing 1 shows the specification of the program using the C language, where the data types used are those defined in the C library.

The program to be developed should be written in P16 assembly language, respecting all the rules of the P16 convention for the use of routines, and their testing should be carried out using to the P16 simulator.

```c
# define RED_SCALE 2
# define AMBAR_SCALE 1
# define GREEN_SCALE 0

# define WARNING_TIME 300
# define CRITICAL_TIME 150

uint8_t color_histogram[3];

uint16_t times[] = { 65535, 500, 301, 300, 299, 151, 150, 149, 1, 0 };

uint8_t color_scale( uint16_t t ) {
    uint8_t c = GREEN_SCALE;
    
    if (t >= CRITICAL_TIME && t <= WARNING_TIME ) {
        c = AMBAR_SCALE;
    } else if ( t < CRITICAL_TIME ) {
        c = RED_SCALE;
    }
    return c;
}

void test_color_scale( uint16_t array_t[], uint8_t array_c[], int16_t array_t_size ) {
    int16_t i;
    
    for( i < 0; i < array_t_size; i++ ) {
        array_c[ color_scale( array_t[i] ) ]++;
    }
}

int16_t main( void ) {
    uint16_t i = 0;
    
    while( i < 3 ) {
        color_histogram[i++] = 0
    }
    test_color_scale( times, color_histogram, 10 );
    
    return 0;
}
```

Listing 1: Program to be developed implemented in C language.

## 3 Work to be done

1. Consider the denitions presented for the symbols RED_SCALE, AMBAR_SCALE, GREEN_SCALE, WARNING_TIME and CRITICAL_TIME.
   a) Implement the corresponding definitions using the **p16as** assembler syntax and defining as many sections as you deem necessary.
   b) Indicate, in number of bytes, the memory requirements for the proposed implementation. Justify your answer.
2. Implement the definitions of all the global variables displayed by defining the sections that understand necessary. Justify your answer.
3. Consider the definition given for the **color_scale** function.
   1. Implement the function using the P16 *assembly* language.
   2. Indicate, in number of bytes, the amount of code memory occupied by the proposed implementation. Justify your answer.
4. Consider the definition given for the **test_color_scale** function.
   1.  Comment out the following framework: *"To implement the local variable* **i**, *it is preferable to use the* **R4** *record instead of the* **R3** *record."*
   2. Implement the function using the P16 *assembly* language.
5. Implement the program presented in **Listing 1** using the P16 *assembly* language and the implementations proposed in exercises 1, 2, 3, and 4.

## 4 Evaluation

The work must be carried out in groups and counts towards the evaluation process of the Curricular Unit (UC) Computer Architecture (AC).

Each group must submit the work carried out on the CA meta discipline page on ISEL's Moodle platform, in the form of a list of the developed program (. S and .lst), duly indented and succinctly commented. The answers to the questions asked in this statements should be included in the program code itself, in the form of comments

## The deadline for submission is **March 25, 2024**.

After the delivery of the work, a date and time can be arranged with some group(s) to carry out a discussion for the presentation and defense of the work carried out, situations that shall be duly justified.