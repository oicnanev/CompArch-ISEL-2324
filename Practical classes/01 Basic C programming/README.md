# Basic C Development

## Introduction
The main objective of this work is to make a quick introduction/review of programming 
using the C language [3] so that all students who attend Computer Architecture classes, regardless of the course in which they are enrolled, who to analyze and understand the code snippets written in this programming language that will be presented in class, assignments and exams.

The exercises proposed in this work involve 

- i) the operation of integers, with and without sign, and characters, 
- ii) the processing of in-memory arrays, 
- iii) the invocation and return of functions, 
- iv) the passing of arguments and the return of function values, and 
- v) the use of local and global variables.



## Types



In the specification of the exercises, the types defined in library C are considered, since the numerical types shown are represented in base 2 and have the following meanings:

- **int8_t** - 8 bits integer with signal
- **int16_t** - 16 bits integer with signal
- **int32_t** - 32 bits integer with signal
- **uint8_t** - 8 bits integer without signal (positive)
- **uint16_t** - 16 bits integer without signal (positive)
- **uint32_t** - 32 bits integer without signal (positive)



The **char** data type is used to represent characters according to the *American standard Standard Code for Information Interchange* [ASCII](https://iselpt.sharepoint.com/sites/acp/Documentos%20Partilhados/Forms/AllItems.aspx?id=%2Fsites%2Facp%2FDocumentos%20Partilhados%2Fdoc%2Fascii%5Fstandard%2Epdf&parent=%2Fsites%2Facp%2FDocumentos%20Partilhados%2Fdoc&p=true&ga=1), each character occupying 8 bits with values possible between 0 and 127.



It is also considered the composite data type **array** of the C language to represent collections of one or more values, all of the same type, stored in contiguous memory positions, and accessible by a single name.



A **string** is a particular case of the composite **array** data type, where its elements are of type char and the last element of the collection is the character **'\0'**.



## Exercises



1. Implement, in C language, the **which_vowel** function that is identical if the **letter** argument is a vowel. The function must return **0**, when **letter** takes the value **a**; returns **1**, in the case of the value **e**; and so on. If the content does not correspond to a vowel, it should be returned the value -1. ``ìnt16_t which_vowel( uint8_t letter );``
2. Implement, in C language, the **vowel_histogram** function that calculates the number of occurrences of each vowel in the *string* **phrase**, encoded in ASCII and terminated by the character \0, updating the **occurences** array with this information. Only the first **max_letters** characters should be considered. ```void vowel_histogram( uint8_t phrase[], uint16_t max_letters, uint16_t occurrences[5] )```
3. Implement, in C language, a test program for the function **vowel_histogram** that enable you to verify and demonstrate your behavior in the following usage scenarios:
   - The **vowel_histogram** function takes **"Hello World"** as the **phrase** argument, **7** as the argument of **max_letters** and the *array* **occurrences1** as the third parameter. The *array* **occurrences1** is a global variable of the program.
   - The function **vowel_histogram** takes the *string* **test_phrase** as the first parameter, **43** as an argument from **max_letters** and the **occurrences2** *array* as the third parameter. The **occurrences2** *array* and the *string* **test_phrase** are global variables of the program, with the string with the initial value **"the quick brown fox jumps over the lazy dog"**.
4. Indicate, *justifying*, the results of the execution of the program produced in the variables **occurrences1** and **occurrences2**.



