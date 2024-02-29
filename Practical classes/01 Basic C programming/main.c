#include <stdio.h>  // To print results
#include <string.h> // Include the header for memset


#define SIZE 5

__int16_t which_vowel( __uint8_t const letter ) {
    // Note: the exit of a function must be only in one place
    __int16_t result;

    switch( letter ) {
        case 'a': result = 0;
            break;
        case 'e': result = 1;
            break;
        case 'i': result = 2;
            break;
        case 'o': result = 3;
            break;
        case 'u': result = 4;
            break;
        default: result = -1;
            break;
    }

    return result;
}

void vowel_histogram( char phrase[], __uint16_t max_letters, __uint16_t occurrences[5] ) {
    __uint16_t idx = 0;

    while( idx < max_letters && phrase[idx] != '\0' ) {
        __int16_t const letter = which_vowel( phrase[idx] );

        if( letter != -1 ) {
            occurrences[letter]++;
        }

        idx++;
    }
}

void fill_array_with_zeros( int arr[] ) {
    for ( int i = 0; i < SIZE; i++ ) {
        arr[i] = 0;
    }
}

int main() {
    __uint16_t occurrences1[SIZE];
    __uint16_t occurrences2[SIZE];
    fill_array_with_zeros(occurrences1);  // sometimes arrays are initialized with dummy values!!
    fill_array_with_zeros(occurrences2);
    char const vowels[] = "aeiou";
    char phrase[] = "Hello World\0";  // '\0' is automatic but...
    char test_phrase[] = "the quick brown fox jumps over the lazy dog\0";

    // question 3 a) ---------------------------------------------------
    vowel_histogram( phrase, 7, occurrences1 );
    printf("\nQuestion 3. a) ------- \n");
    for (int i = 0; i < SIZE; i++ ) {
        printf( "Vowel %c: %d occurrences\n", vowels[i], occurrences1[i] );
    }

    // question 3 b) ---------------------------------------------------
    vowel_histogram( test_phrase, 43, occurrences2 );
    printf("\nQuestion 3. b) ------- \n");
    for (int i = 0; i < SIZE; i++ ) {
        printf( "Vowel %c: %d occurrences\n", vowels[i], occurrences2[i] );
    }

    return 0;
}
