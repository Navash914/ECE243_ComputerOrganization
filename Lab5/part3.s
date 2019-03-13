          .text                   // executable code follows
          .global _start                  
_start:           
			MOV 	R4, #1				// Program counts up if R4 is 1             
		 	MOV 	R5, #0				// R5 contains value shown on HEX0
        	MOV 	R6, #KEY_ADDRESS
        	LDR 	R6, [R6]
        	MOV 	R1, #0xF
        	STR 	R1, [R6]
          	MOV 	R7, #HEX0_ADDRESS
          	LDR 	R7, [R7]
            MOV     R8, #TIMER_ADDRESS
            LDR     R8, [R8]
            LDR     R1, =50000000
            STR     R1, [R8]

LOOP:	  	BL 		DISPLAY

            LDR     R1, [R8, #8]
            ORR     R1, #0b11
            STR     R1, [R8, #8]

DO_DELAY:   LDR     R1, [R8, #12]
            ANDS    R1, #0b1
            BEQ     DO_DELAY

            LDR     R1, [R8, #8]
            AND     R1, #0xFFFFFFFC
            STR     R1, [R8, #8]
            MOV     R1, #1
            STR     R1, [R8, #12]

			LDR 	R0, [R6]
			ANDS 	R0, #0b1111
			CMP 	R0, #0
			BEQ 	COUNT

			CMP		R4, #0
			MOVEQ	R4, #1
			MOVNE	R4, #0
			MOV 	R1, #0xF
			STR 	R1, [R6]

COUNT:		CMP		R4, #0
			ADDNE	R5, #1
			CMP 	R5, #100
			MOVEQ	R5, #0

			B 		LOOP

DISPLAY:    PUSH 	{LR}

			MOV     R0, R5
			BL 		DIVIDE
			MOV 	R3, R1
            BL      SEG7_CODE

            MOV 	R2, R0
            MOV 	R0, R3
            BL 		SEG7_CODE

            LSL 	R0, #8
            ORR 	R0, R2

            STR     R0, [R7]        // display the number from R7
            POP 	{LR}
            MOV 	PC, LR

SEG7_CODE:  CMP 	R8, #1
			MOVEQ	R0, #0
			MOVEQ	PC, LR

			MOV     R1, #BIT_CODES  
            ADD     R1, R0         // index into the BIT_CODES "array"
            LDRB    R0, [R1]       // load the bit pattern (to be returned)
            MOV     PC, LR              

DIVIDE:     MOV    R2, #0     // Initial quotient is 0
CONT:       CMP    R0, #10
            BLT    DIV_END    // End Division if R0 < R1
            SUB    R0, #10    // Subtract divisor from R0
            ADD    R2, #1     // Increment quotient
            B      CONT       // Loop
DIV_END:    MOV    R1, R2     // quotient in R1 (remainder in R0)
            MOV    PC, LR     // Return from subroutine

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment


HEX0_ADDRESS:  .word 0xFF200020
KEY_ADDRESS:   .word 0xFF20005C
TIMER_ADDRESS: .word 0xFFFEC600