/* Program that finds the largest number in a list of integers	*/

            .text                   // executable code follows
            .global _start                  
_start:                             
            MOV     R4, #RESULT     // R4 points to result location
            LDR     R0, [R4, #4]    // R0 holds the number of elements in the list
            MOV     R1, #NUMBERS    // R1 points to the start of the list
            BL      LARGE           
            STR     R0, [R4]        // R0 holds the subroutine return value

END:        B       END             

/* Subroutine to find the largest integer in a list
 * Parameters: R0 has the number of elements in the lisst
 *             R1 has the address of the start of the list
 * Returns: R0 returns the largest item in the list
 */

 
LARGE:   
		 MOV	  R2, R0		// Store number of elements in R2
		 LDR	  R0, [R1]		// R0 holds the largest number found so far   

LARGE_LOOP:    
		 SUBS     R2, #1        // decrement the loop counter
         BEQ      LARGE_END     // if result is equal to 0, subroutine is complete
         ADD      R1, #4
         LDR      R3, [R1]      // get the next number
         CMP      R0, R3        // check if larger number found
         BGE      LARGE_LOOP
         MOV      R0, R3        // update the largest number
         B        LARGE_LOOP

LARGE_END:
		 MOV	  PC, LR 		// Return from subroutine
            

RESULT:     .word   0           
N:          .word   7           // number of entries in the list
NUMBERS:    .word   4, 5, 3, 6  // the data
            .word   1, 8, 2                 

            .end                            

