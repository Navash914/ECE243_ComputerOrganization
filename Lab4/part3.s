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
          BEQ       END        

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
