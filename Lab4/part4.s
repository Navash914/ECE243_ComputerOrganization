/* Program that counts consecutive 1's, 0's, and alternating 1's and 0's */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV     R3, #TEST_NUM   // load the data word ...
          LDR     R1, [R3]        // into R1

          MOV    R5, #0         // R5 holds the longest string of 1's so far
          MOV    R6, #0         // R6 holds the longest string of 0's so far
          MOV    R7, #0         // R7 holds the longest string of alternating 1's and 0's so far

LOOP:     CMP       R1, #0         // End execution if word is 0
          BEQ       DISPLAY        

          // Perform calculations in subroutines
          // Update largest so far values after each calculation
          // Reload word to R1 afterwards

          // ONES:
          BL        ONES
          CMP       R0, R5
          MOVGT     R5, R0
          LDR       R1, [R3]

          // ZEROS:
          BL        ZEROS
          CMP       R0, R6
          MOVGT     R6, R0
          LDR       R1, [R3]

          // ALTERNATE:
          BL        ALTERNATE
          CMP       R0, R7
          MOVGT     R7, R0

          // Load next word and repeat
          ADD    R3, #4
          LDR    R1, [R3]
          B      LOOP

END:      B       END             


/* Subroutine to find the longest string of 1's in a word
 * Parameters: R1 has the input word
 * Returns: R0 returns the length of the longest string of 1's
 */
 
ONES:   
          MOV     R0, #0          // R0 will hold the result

O_LOOP:   CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     O_END             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       O_LOOP      

O_END:
          MOV     PC, LR       // Return from subroutine

/**
 * End of subroutine ONES
 */           


/* Subroutine to find the longest string of 0's in a word
 * Parameters: R1 has the input word
 * Returns: R0 returns the length of the longest string of 0's
 */
 
ZEROS:   
// To get longest string of 0's, simply NOT the number and get longest string of 1's
          MOV     R4, #0xFFFFFFFF
          EOR     R1, R1, R4
          MOV     PC, #ONES

/**
 * End of subroutine ZEROS
 */   

/* Subroutine to find the longest string of alternating 1's and 0's in a word
 * Parameters: R1 has the input word
 * Returns: R0 returns the length of the longest string of alternating 1's and 0's
 */
 
ALTERNATE:
          LDR     R4, =0x55555555
          EOR     R1, R1, R4  // All 5's has alternating 0's and 1's

          MOV     R0, #0          // R0 will hold the result

A_LOOP_1: CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     A_END_1             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       A_LOOP_1      

A_END_1:
          LDR     R1, [R3]           // Reload R1
          LDR     R4, =0xAAAAAAAA
          EOR     R1, R1, R4  // All 5's has alternating 0's and 1's

          MOV     R4, R0             // Store the value in R4

          MOV     R0, #0          // R0 will hold the result

A_LOOP_2: CMP     R1, #0          // loop until the data contains no more 1's
          BEQ     A_END_2             
          LSR     R2, R1, #1      // perform SHIFT, followed by AND
          AND     R1, R1, R2      
          ADD     R0, #1          // count the string length so far
          B       A_LOOP_2      

A_END_2:

          CMP     R0, R4             // If the new value is less than the older value,
          MOVLT   R0, R4             // restore the older value

          MOV     PC, LR             // Return from subroutine

 /**
 * End of subroutine ALTERNATE
 */                                 

/* Subroutine to convert the digits from 0 to 9 to be shown on a HEX display.
 *    Parameters: R0 = the decimal value of the digit to be displayed
 *    Returns: R0 = bit patterm to be written to the HEX display
 */

SEG7_CODE:  MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

/* Display R5 on HEX1-0, R6 on HEX3-2 and R7 on HEX5-4 */
DISPLAY:    LDR     R8, =0xFF200020 // base address of HEX3-HEX0

            // R5:
            MOV     R0, R5          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0

            // R6:
            MOV     R0, R6          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            LSL     R0, #16
            ORR     R4, R0

            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #24
            ORR     R4, R0

            STR     R4, [R8]        // display the number from R7

            // R7:
            LDR     R8, =0xFF200030

            MOV     R0, R7          // display R5 on HEX1-0
            BL      DIVIDE          // ones digit will be in R0; tens
                                    // digit in R1
            MOV     R9, R1          // save the tens digit
            BL      SEG7_CODE       
            MOV     R4, R0          // save bit code
            MOV     R0, R9          // retrieve the tens digit, get bit
                                    // code
            BL      SEG7_CODE       
            LSL     R0, #8
            ORR     R4, R0

            STR     R4, [R8]        // display the number from R7

            B       END

/* Subroutine to perform the integer division R0 / 10.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     MOV    R2, #0     // Initial quotient is 0
CONT:       CMP    R0, #10
            BLT    DIV_END    // End Division if R0 < R1
            SUB    R0, #10    // Subtract divisor from R0
            ADD    R2, #1     // Increment quotient
            B      CONT       // Loop
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR     // Return from subroutine

TEST_NUM: .word   0x103fe00f  
            .word   0x100fe00f  
            .word   0x103fe30f  
            .word   0x103fefff  
            .word   0x0000000f  
            .word   0b101101010001
            .word   0xffffffff  
            .word   0xfffffffe  
            .word   0x00000001  
            .word   0x103fe00f
            .word   0x00000000  

          .end   