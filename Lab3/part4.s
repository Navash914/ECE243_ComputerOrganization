/* Program that converts a binary number to decimal */
           .text               // executable code follows
           .global _start
_start:
            MOV    R4, #N
            MOV    R5, #Digits  // R5 points to the decimal digits storage location
            LDR    R4, [R4]     // R4 holds N
            MOV    R0, R4       // parameter for DIVIDE goes in R0
            MOV    R1, #10      // divisor for DIVIDE goes in R1
            MOV    R3, #4       // Number of decimal digits in N

LOOP:       BL     DIVIDE
            //STRB   R1, [R5, #1] // Tens digit is now in R1
            STRB   R0, [R5]     // Remainder digit is in R0
            MOV    R0, R1       // Quotient stored in R1 is the new dividend
            BEQ    END          // End operation if quotient is 0
            SUBS   R3, #1       // Decrement digit counter
            BEQ    END          // End operation if all digits are done
            ADD    R5, #1       // Move to next address in digit
            MOV    R1, #10      // Reset R1 to divisor value
            B      LOOP

END:        B      END

/* Subroutine to perform the integer division R0 / R1.
 * Returns: quotient in R1, and remainder in R0
*/
DIVIDE:     MOV    R2, #0     // Initial quotient is 0
CONT:       CMP    R0, R1
            BLT    DIV_END    // End Division if R0 < R1
            SUB    R0, R1     // Subtract divisor from R0
            ADD    R2, #1     // Increment quotient
            B      CONT       // Loop
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR     // Return from subroutine

N:          .word  9876         // the decimal number to be converted
Digits:     .space 4          // storage space for the decimal digits

            .end
