; test.asm
; The purpose of this program is for testing ESC circuit,
; all P FET close(1) if RCP    high
; all N FET open(0) if RCP low

.include "m48def.inc"
;.include "../brushless/18_3p.inc"
;.include "../brushless/t50.inc"

.def	zero			= r0		; stays at 0
.def	i_sreg			= r1		; SREG save in interrupts


.equ	RCP_HIGH				= 16777 * 2
.equ	RCP_LOW					= 8388 * 2
.equ	RCP_MID					= (RCP_HIGH + RCP_LOW) / 2

.equ	RCP_ERROR_COUNT			= 100
.equ	RCP_HIGH_X				= 20000 * 2
.equ	RCP_LOW_X				= 7500 * 2

.equ	CCLK					= 3
.equ	CDTI					= 1
.equ	CSN						= 0
.dseg				; DATA segment

mem_t0_temp_l:	.byte	1	;t0 temp address
mem_t0_temp_h:	.byte	1

mem_addr:		.byte	1
mem_data:		.byte	1
mem_temp:		.byte 1
mem_temp1:		.byte 1

.cseg
.org 0
;**** **** **** **** ****

;-----bko-----------------------------------------------------------------
; Reset and interrupt jump table
; When multiple interrupts are pending, the vectors are executed from top
; (ext_int0) to bottom.
	rjmp	reset
	nop					;1.equ	INT0addr=$001	; External Interrupt0 Vector Address
	nop					;2.equ	INT1addr=$002	; External Interrupt1 Vector Address
	
	nop					;3 Pin Change Interrupt Request 0
	nop					;4 Pin Change Interrupt Request 1
	nop					;5 Pin Change Interrupt Request 2
	nop							;6 Watchdog Time-out Interrupt
	nop				;7 Timer/Counter2 Compare Match A
	reti				;8 Timer/Counter2 Compare Match B
	nop					;9 Timer/Counter2 Overflow
	reti					;a Timer/Counter1 Capture Event
	nop				;b Timer/Counter1 Compare Match A
	reti				;c Timer/Coutner1 Compare Match B
	nop					;d Timer/Counter1 Overflow
	nop				;e Timer/Counter0 Compare Match A
	nop				;f Timer/Counter0 Compare Match B
	nop					;10 Timer/Counter0 Overflow
	nop						;11 SPI Serial Transfer Complete
	nop					;12 USART Rx Complete
	nop					;13 USART, Data Register Empty
	nop					;14 USART, Tx Complete
	nop						;15 ADC Conversion Complete
	nop					;16 EEPROM Ready
	nop					;17 Analog Comparator
	nop						;18 2-wire Serial Interface
	reti					;19 Store Program Memory Ready

reset:
	clr	zero
	out	SREG, zero		; Clear interrupts and flags
	; Set up stack
	ldi	ZH, high(RAMEND)
	ldi	ZL, low (RAMEND)
	out	SPH, ZH
	out	SPL, ZL


;ext int
;	ldi		r16,(1<<INT1)+(1<<INT0)
;	ldi		r16,(1<<INT0)
	clr		r16
	out		EIMSK,r16

	sbi		DDRD,5

	rcall	long_delay
	sbi		PORTD,5
	rcall	long_delay
	cbi		PORTD,5
	rcall	long_delay
	sbi		PORTD,5
	rcall	long_delay

	sei
loop:
	sbi		PORTD,5
	rcall	short_delay
	cbi		PORTD,5
	rcall	long_delay
	rjmp	loop


short_delay:
	ldi		r17,255
d1:
	ldi		r16,255
d2:
	dec		r16
	brne	d2
	dec		r17
	brne	d1
	ret

long_delay:
	ldi		r16,50
	sts		mem_temp1,r16
ld_1:
	rcall	short_delay
	lds		r16,mem_temp1
	dec		r16
	sts		mem_temp1,r16
	brne	ld_1
	ret
	

.exit
