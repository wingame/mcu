; test.asm
; The purpose of this program is for testing ESC circuit,
; all P FET close(1) if RCP    high
; all N FET open(0) if RCP low

.include "m8def.inc"
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
	nop		;ext_int0
	nop		; ext_int1
	nop		; t2oc_int
	nop		;rjmp	t2ovfl_int
	nop		; icp1_int
	nop		;t1oca_int
	nop		; t1ocb_int
	nop		;t1ovfl_int
	nop		;t0ovfl_int
	nop		; spi_int
	nop		; urxc
	nop		; udre
	nop		; utxc


reset:
	clr	zero
	out	SREG, zero		; Clear interrupts and flags
	; Set up stack
	ldi	ZH, high(RAMEND)
	ldi	ZL, low (RAMEND)
	out	SPH, ZH
	out	SPL, ZL

	sbi		DDRD,CCLK
	sbi		DDRD,CDTI
	sbi		DDRD,CSN
	rcall	sdelay

	sbi		PORTD,CCLK
	sbi		PORTD,CDTI
	sbi		PORTD,CSN

	
	ldi		r16,1
	sts		mem_addr,r16
	ldi		r16,0b00000010
	sts		mem_data,r16
	rcall	send
	
	
	rjmp	$
	; clk

send:
	lds		r18,mem_addr
	andi	r18,0b00111111		; C0C1 = 00
	ori		r18,0b00100000		; R/W  = 1
	cbi		PORTD,CSN
	rcall	_send
;	sbi		PORTD,CSN
;	rcall	sdelay
;	cbi		PORTD,CSN
	lds		r18,mem_data
	rcall	_send
	rcall	sdelay
	sbi		PORTD,CSN
	ret
_send:
	clr		r19
s2:
	lsl		r18
	rcall	signal_out
	inc		r19
	cpi		r19,8
	brne	s2
	ret
signal_out:
	cbi		PORTD,CCLK
	brcs	so_1
	cbi		PORTD,CDTI
	rjmp	so_2
so_1:
	sbi		PORTD,CDTI
so_2:
	rcall	sdelay
	sbi		PORTD,CCLK
	rcall	sdelay
	cbi		PORTD,CCLK
	ret

long_delay:
	ldi		r17,255
ld_1:
	rcall	delay256
	dec		r17
	and		r17,r17
	brne	ld_1
	
	lds		r16,mem_temp
	dec		r16
	sts		mem_temp,r16
	and		r16,r16
	brne	long_delay
	
	ret
delay256:
	ldi		r16,255
d256_1:
	dec		r16
	and		r16,r16
	brne	d256_1
	ret

sdelay:			; 25
	clr		r16		;1
sd_1:
	inc		r16		;1
	cpi		r16,5	;1
	brne	sd_1	;2
					; 4 X 5 =20
	ret				;4

ddd:
	cbi		PORTD,CSN
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; C1
	rcall	sdelay
	sbi		PORTD,CCLK		; 1
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; C0
	rcall	sdelay
	sbi		PORTD,CCLK		; 2
	rcall	sdelay

	cbi		PORTD,CCLK
	sbi		PORTD,CDTI		; R/W
	rcall	sdelay
	sbi		PORTD,CCLK		; 3
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; A4
	rcall	sdelay
	sbi		PORTD,CCLK		; 4
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; A3
	rcall	sdelay
	sbi		PORTD,CCLK		;5
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; A2
	rcall	sdelay
	sbi		PORTD,CCLK		; 6
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; A1
	rcall	sdelay
	sbi		PORTD,CCLK		;7
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; A0
	rcall	sdelay
	sbi		PORTD,CCLK		; 8
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; D7
	rcall	sdelay
	sbi		PORTD,CCLK		;9
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; D6
	rcall	sdelay
	sbi		PORTD,CCLK		;10
	rcall	sdelay

	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; D5
	rcall	sdelay
	sbi		PORTD,CCLK		;11
	rcall	sdelay
	
	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; D4
	rcall	sdelay
	sbi		PORTD,CCLK		;12
	rcall	sdelay
	
	cbi		PORTD,CCLK
	cbi		PORTD,CDTI		; D3
	rcall	sdelay
	sbi		PORTD,CCLK		;13
	rcall	sdelay

	cbi		PORTD,CCLK
	sbi		PORTD,CDTI		; D2
	rcall	sdelay
	sbi		PORTD,CCLK		;14
	rcall	sdelay

	cbi		PORTD,CCLK
	sbi		PORTD,CDTI		; D1
	rcall	sdelay
	sbi		PORTD,CCLK		;15
	rcall	sdelay

	cbi		PORTD,CCLK
	sbi		PORTD,CDTI		; D0
	rcall	sdelay
	sbi		PORTD,CCLK		;16
	rcall	sdelay

	sbi		PORTD,CSN

.if  1==2
	sbi		PORTD,CSN
	cbi		PORTD,CCLK
	sbi		PORTD,CDTI

	ldi		r16,30
	sts		mem_temp,r16
	rcall	long_delay
	cbi		PORTD,CSN
	sbi		PORTD,CCLK
	cbi		PORTD,CDTI
.endif
	ldi		r16,30
	sts		mem_temp,r16
	rcall	long_delay
	
	rjmp	ddd


.exit
