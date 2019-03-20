.include    "address_map_arm.s"
.include    "defines.s"
.include    "interrupt_ID.s"
.include 	"exceptions.s"

.section .vectors, "ax"  
B       _start              // reset vector
B       SERVICE_UND         // undefined instruction vector
B       SERVICE_SVC         // software interrupt vector
B       SERVICE_ABT_INST    // aborted prefetch vector
B       SERVICE_ABT_DATA    // aborted data vector
.word   0                   // unused vector
B       SERVICE_IRQ         // IRQ interrupt vector
B       SERVICE_FIQ         // FIQ interrupt vector

.text                                       
.global  _start                          
_start:                                         
/* Set up stack pointers for IRQ and SVC processor modes */
LDR     R0, =IRQ_MODE
MSR     CPSR, R0
LDR     SP, =0x20000
LDR     R0, =SVC_MODE
MSR     CPSR, R0
LDR     SP, =0x40000

BL       CONFIG_GIC       // configure the ARM generic
// interrupt controller
BL 		 CONFIG_PRIV_TIMER
BL       CONFIG_TIMER     // configure the Interval Timer
BL       CONFIG_KEYS      // configure the pushbutton
// KEYs port

/* Enable IRQ interrupts in the ARM processor */
LDR     R0, =SVC_MODE
ORR     R0, #INT_ENABLE
MSR     CPSR, R0

LDR     R5, =LEDR_BASE
LDR 	R6, =HEX3_HEX0_BASE
LOOP:                                          
LDR     R3, =COUNT        // global variable
LDR 	R3, [R3]
STR     R3, [R5]         // write to the LEDR lights
BL 		TIME_TO_HEX
LDR     R4, HEX_code        // global variable
STR     R4, [R6]            // show the time in format
                            // SS:DD
B        LOOP                

/* Configure the Interval Timer to create interrupts at 0.25 second intervals */
CONFIG_PRIV_TIMER:                             
LDR 	R0, =MPCORE_PRIV_TIMER
// Total Value: 2e6

// Load Value
LDR 	R1, =2000000
STR 	R1, [R0]

// Set interrupt status, autoload and enable the timer
MOV 	R1, #0b111
STR 	R1, [R0, #0x8]

// Return
BX      LR 

CONFIG_TIMER:                             
LDR 	R0, =TIMER_BASE
// Total Value: 25e6
// Lower 16: 0x7840
// Upper 16: 0x17D

// Load lower 16 bits
LDR 	R1, =0x7840
STR 	R1, [R0, #0x8]

// Load upper 16 bits
LDR 	R1, =0x17D
STR 	R1, [R0, #0xC]

// Set interrupt status, cont and start the timer
MOV 	R1, #0b0111
STR 	R1, [R0, #0x4]

// Return
BX      LR                  

/* Configure the pushbutton KEYS to generate interrupts */
CONFIG_KEYS:                                    
LDR     R0, =KEY_BASE
LDR     R1, =0xF
STR     R1, [R0, #8]
BX       LR                  

SERVICE_IRQ:    
PUSH    {R0-R7, LR}     
LDR     R4, =0xFFFEC100 // GIC CPU interface base address
LDR     R5, [R4, #0x0C] // read the ICCIAR in the CPU
// interface
MOV 	R0, #0

KEYS_HANDLER:                       
CMP     R5, #KEYS_IRQ         // check the interrupt ID
BLEQ 	KEY_ISR
BEQ 	EXIT_IRQ

TIMER_HANDLER:
CMP 	R5, #INTERVAL_TIMER_IRQ
BLEQ 	INTERVAL_TIMER_ISR
BEQ 	EXIT_IRQ

PRIV_TIMER_HANDLER:
CMP 	R5, #MPCORE_PRIV_TIMER_IRQ
BLEQ 	PRIV_TIMER_ISR
BEQ 	EXIT_IRQ

EXIT_IRQ:
STR     R5, [R4, #0x10] // write to the End of Interrupt
// Register (ICCEOIR)
POP     {R0-R7, LR}     
SUBS    PC, LR, #4      // return from exception

KEY_ISR:
LDR     R3, =KEY_BASE
LDR     R2, [R3, #0xC]

// Check Key 0
LDR     R0, =KEY0
ANDS    R0, R2
BNE     KEY0_PRESS

// Check Key 1
LDR     R0, =KEY1
ANDS    R0, R2
BNE     KEY1_PRESS

// Check Key 2
LDR     R0, =KEY2
ANDS    R0, R2
BNE     KEY2_PRESS

// Check Key 3
LDR     R0, =KEY3
ANDS    R1, R2, R0
BNE     KEY3_PRESS

B   	UNEXPECTED // Should never get here

KEY0_PRESS:
// Invert Run
LDR 	R1, =RUN
LDR 	R0, [R1]
EOR 	R0, #1
STR 	R0, [R1]
B 		KEY_ISR_END

KEY1_PRESS:
// Double Speed

LDR 	R3, =TIMER_BASE

// Stop the timer
MOV 	R0, #0b1011
STR 	R0, [R3, #0x4]

// Half Load Value
LDR 	R0, [R3, #0x8]	// Lower Bits
LDR 	R1, [R3, #0xC]	// Upper Bits
LSL 	R1, #16
ORR 	R1, R0
LSR 	R1, #1			// Divide by 2
LDR 	R0, =0x0000FFFF
AND 	R0, R1
// R0 contains lower values
STR 	R0, [R3, #0x8]
LDR 	R0, =0xFFFF0000
AND 	R0, R1
LSR 	R0, #16
// R0 contains upper values
STR 	R0, [R3, #0xC]

// Restart the timer
MOV 	R0, #0b0111
STR 	R0, [R3, #0x4]
B 		KEY_ISR_END

KEY2_PRESS:
// Half Speed

LDR 	R3, =TIMER_BASE

// Stop the timer
MOV 	R0, #0b1011
STR 	R0, [R3, #0x4]

// Double Load Value
LDR 	R0, [R3, #0x8]	// Lower Bits
LDR 	R1, [R3, #0xC]	// Upper Bits
LSL 	R1, #16
ORR 	R1, R0
LSL 	R1, #1			// Multiply by 2
LDR 	R0, =0x0000FFFF
AND 	R0, R1
// R0 contains lower values
STR 	R0, [R3, #0x8]
LDR 	R0, =0xFFFF0000
AND 	R0, R1
LSR 	R0, #16
// R0 contains upper values
STR 	R0, [R3, #0xC]

// Restart the timer
MOV 	R0, #0b0111
STR 	R0, [R3, #0x4]
B 		KEY_ISR_END

KEY3_PRESS:
// Invert Run
LDR 	R1, =TRUN
LDR 	R0, [R1]
EOR 	R0, #1
STR 	R0, [R1]
B 		KEY_ISR_END

KEY_ISR_END:
LDR     R3, =KEY_BASE
STR 	R2, [R3, #0xC]
MOV     PC, LR          // Return from subroutine

INTERVAL_TIMER_ISR:
LDR 	R0, =RUN
LDR 	R0, [R0]
LDR 	R1, =COUNT
LDR 	R2, [R1]
ADD 	R2, R0
STR 	R2, [R1]

LDR 	R1, =TIMER_BASE
LDR 	R0, =0xFFFFFFFE
LDR 	R2, [R1]
AND 	R0, R2
STR 	R0, [R1]

MOV 	PC, LR

PRIV_TIMER_ISR:
LDR 	R0, =TRUN
LDR 	R0, [R0]
LDR 	R1, =TIME
LDR 	R2, [R1]
ADD 	R2, R0
LDR 	R0, =6000
CMP 	R2, R0
MOVEQ 	R2, #0
STR 	R2, [R1]

LDR 	R1, =MPCORE_PRIV_TIMER
MOV 	R0, #1
STR 	R0, [R1, #0xC]

MOV 	PC, LR

TIME_TO_HEX:    
PUSH    {LR}

LDR 	R0, TIME

BL      DIVIDE
MOV     R3, R1
BL      SEG7_CODE

MOV     R2, R0
MOV     R0, R3
BL      DIVIDE
MOV     R3, R1
BL      SEG7_CODE

LSL     R0, #8
ORR     R2, R0

MOV     R0, R3
BL      DIVIDE
MOV     R3, R1
BL      SEG7_CODE

LSL     R0, #16
ORR     R2, R0

MOV     R0, R3
BL      SEG7_CODE

LSL     R0, #24
ORR     R0, R2

LDR 	R1, =HEX_code

STR     R0, [R1]        // Store hex code
POP     {PC}

SEG7_CODE:
LDR     R1, =BIT_CODES  
ADD     R1, R0         // index into the BIT_CODES "array"
LDRB    R0, [R1]       // load the bit pattern (to be returned)
MOV     PC, LR                

DIVIDE:     
MOV    R1, #0     // Initial quotient is 0

CONT:       
CMP    R0, #10
BLT    DIV_END    // End Division if R0 < R1
SUB    R0, #10    // Subtract divisor from R0
ADD    R1, #1     // Increment quotient
B      CONT       // Loop

DIV_END:    
MOV    PC, LR     // Return from subroutine

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment

UNEXPECTED:	B 	UNEXPECTED

/* Global variables */
                    .global COUNT                               
COUNT:              .word   0x0       // used by timer
                    .global RUN       // used by pushbutton KEYs
RUN:                .word   0x1       // initial value to increment COUNT
					.global TRUN      // used by pushbutton KEYs
TRUN:                .word   0x1      // initial value to increment TIME
                    .global TIME                                
TIME:               .word   0x0       // used for real-time clock
                    .global HEX_code                            
HEX_code:           .word   0x0       // used for 7-segment displays

                    .end                                        
