/* Program that counts consecutive 1's */

          .text                   // executable code follows
          .global _start                  
_start:                             
          MOV     R3, #TEST_NUM   // load the data word ...
          LDR     R1, [R3]        // into R1

          MOV	  R5, #0		  // R5 holds the longest string so far
LOOP:	  CMP 	  R1, #0		  // End execution if word is 0
		  BEQ	  END        
		  BL	  ONES			  // Call subroutine
		  						  // R0 now contains length of longest 1's in currently processed word
          CMP	  R0, R5
          MOVGT   R5, R0		  // Update longest string so far

          ADD	  R3, #4		  // Load the next word and repeat
          LDR	  R1, [R3]
          B 	  LOOP

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
		 MOV	  PC, LR 		// Return from subroutine

TEST_NUM: .word   0x103fe00f  
		  .word   0x100fe00f  
		  .word   0x103fe30f  
		  .word   0x103fefff  
		  .word   0x0000000f  
		  .word   0xeeefeeee  
		  .word   0xffffffff  
		  .word   0xfffffffe  
		  .word   0x00000001  
		  .word   0x103fe00f
		  .word   0x00000000  

          .end                            
