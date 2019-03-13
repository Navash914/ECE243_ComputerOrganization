          .text                   // executable code follows
          .global _start                  
_start:                        
			MOV 	R4, #0     			// R4 contains the last key pressed
		 	MOV 	R5, #0				// R5 contains value shown on HEX0
        	MOV 	R6, #KEY_ADDRESS
        	LDR 	R6, [R6]
          	MOV 	R7, #HEX0_ADDRESS
          	LDR 	R7, [R7]
          	MOV 	R8, #0				// R8 is a flag that checks if display is/should be blank

LOOP:	  	LDR 	R0, [R6]
		  	ANDS 	R0, #0b1111
		  	BEQ 	KEY_RELEASE
		  	CMP 	R4, #0
		  	MOVEQ 	R4, R0
		  	B 		LOOP

KEY_RELEASE:
		  	CMP 	R4, #0
		  	BEQ 	LOOP

		  	// Check if HEX is blank
		  	CMP 	R8, #1
		  	MOVEQ	R8, #0
		  	BEQ 	KEY_0_PRESS

		  	// Check for KEY 0
		  	ANDS	R3, R4, #0b1110
		  	BEQ		KEY_0_PRESS

		  	// Check for KEY 1
		  	ANDS	R3, R4, #0b1101
			BEQ		KEY_1_PRESS

			// Check for KEY 2
			ANDS	R3, R4, #0b1011
			BEQ		KEY_2_PRESS

			// Check for KEY 3
			ANDS	R3, R4, #0b0111
			BEQ		KEY_3_PRESS

DISP:		BL DISPLAY
		  	B LOOP

KEY_0_PRESS:
			MOV 	R5, #0
			MOV 	R4, #0
			B 		DISP

KEY_1_PRESS:
			CMP 	R5, #9
			ADDNE	R5, #1
			MOVEQ	R5, #0
			MOV 	R4, #0
			B 		DISP

KEY_2_PRESS:
			CMP		R5, #0
			SUBNE	R5, #1
			MOVEQ 	R5, #9
			MOV 	R4, #0
			B 		DISP

KEY_3_PRESS:
			MOV 	R8, #1
			MOV 	R4, #0
			B 		DISP

DISPLAY:    PUSH 	{LR}
			MOV     R0, R5
            BL      SEG7_CODE

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

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment


HEX0_ADDRESS: .word 0xFF200020
KEY_ADDRESS: .word 0xFF200050