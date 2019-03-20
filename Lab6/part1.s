.include    "address_map_arm.s"
.include    "defines.s"
.include    "interrupt_ID.s"
.include 	"exceptions.s"
//.include    "CONFIG_GIC.s"

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
.global _start 

_start:                                  
MOV     R9, #0          // R9 holds values for which hex should display
/* Set up stack pointers for IRQ and SVC processor modes */
LDR     R0, =IRQ_MODE
MSR     CPSR, R0
LDR     SP, =0x20000
LDR     R0, =SVC_MODE
MSR     CPSR, R0
LDR     SP, =0x40000

BL      CONFIG_GIC      // configure the ARM generic
// interrupt controller
/* Configure the KEY pushbuttons port to generate interrupts */
LDR     R0, =KEY_BASE
LDR     R1, =0xF
STR     R1, [R0, #8]

/* Enable IRQ interrupts in the ARM processor */
LDR     R0, =SVC_MODE
ORR     R0, #INT_ENABLE
MSR     CPSR, R0

IDLE:                                    
B       IDLE            // main program simply idles

/* Define the exception service routines */

SERVICE_IRQ:    
PUSH    {R0-R7, LR}     
LDR     R4, =0xFFFEC100 // GIC CPU interface base address
LDR     R5, [R4, #0x0C] // read the ICCIAR in the CPU
// interface

KEYS_HANDLER:                       
CMP     R5, #KEYS_IRQ         // check the interrupt ID
BNE     UNEXPECTED            // if not recognized, stop here

BL      KEY_ISR         

EXIT_IRQ:
STR     R5, [R4, #0x10] // write to the End of Interrupt
// Register (ICCEOIR)
POP     {R0-R7, LR}     
SUBS    PC, LR, #4      // return from exception

KEY_ISR:
PUSH    {LR}
LDR     R3, =KEY_BASE
LDR     R2, [R3, #0xC]

// Check Key 0
LDR     R0, =KEY0
ANDS    R1, R2, R0
BNE     KEY_ISR_END

// Check Key 1
LDR     R0, =KEY1
ANDS    R1, R2, R0
BNE     KEY_ISR_END

// Check Key 2
LDR     R0, =KEY2
ANDS    R1, R2, R0
BNE     KEY_ISR_END

// Check Key 3
LDR     R0, =KEY3
ANDS    R1, R2, R0
BNE     KEY_ISR_END

B       UNEXPECTED // Should never get here

KEY_ISR_END:
// R0 contains the key that was pressed
EOR     R9, R0          // Invert appropriate bit
STR     R0, [R3, #0xC]   // Reset Edge Capture
BL      DISPLAY
POP     {LR}
MOV     PC, LR          // Return from subroutine

DISPLAY:    
PUSH    {LR}

ANDS    R0, R9, #KEY0
MOV     R0, #0
BLNE    SEG7_CODE

MOV     R2, R0

ANDS    R0, R9, #KEY1
MOVEQ   R0, #0
MOVNE   R0, #1
BLNE    SEG7_CODE

LSL     R0, #8
ORR     R2, R0

ANDS    R0, R9, #KEY2
MOVEQ   R0, #0
MOVNE   R0, #2
BLNE    SEG7_CODE

LSL     R0, #16
ORR     R2, R0

ANDS    R0, R9, #KEY3
MOVEQ   R0, #0
MOVNE   R0, #3
BLNE    SEG7_CODE

LSL     R0, #24
ORR     R2, R0

LDR     R0, =HEX3_HEX0_BASE
STR     R2, [R0]
POP     {LR}
MOV     PC, LR

SEG7_CODE:
LDR     R1, =BIT_CODES  
ADD     R1, R0         // index into the BIT_CODES "array"
LDRB    R0, [R1]       // load the bit pattern (to be returned)
MOV     PC, LR              

BIT_CODES:  .byte   0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110
            .byte   0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111
            .skip   2      // pad with 2 bytes to maintain word alignment            

UNEXPECTED:     B      UNEXPECTED