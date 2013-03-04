; rcp generator

.include "m48def.inc"

.def		zero		= r0
.def		isreg		= r1
.def		tcnt0h		= r2
.def		tcnt0x		= r3

.equ		MIN_RCP		= 1100
.equ		MAX_RCP		= 1900
.equ		NEUTRAL_RCP	= 1500

; GPIOR0
.equ		bi_direct	= 0
.equ		rcp_changed	= 1

; /--------------------------------------------------------\
; |    ================================================    |
; |    |  Program Box                                 |    |
; |    |                                              |    |
; |    ================================================    |
; +--------------------------------------------------------+
; |     ---          ---          ---          ---         |
; |    | 1 |        | 2 |        | 3 |        | 4 |        |
; |     ---          ---          ---          ---         |
; \--------------------------------------------------------/

.equ		KEY_PORT	= PORTD
.equ		KEY_PIN		= PIND
.equ		KEY_DDR		= DDRD
.equ		KEY1		= 0
.equ		KEY2		= 4
.equ		KEY3		= 3
.equ		KEY4		= 1
.equ		KEY_PATTERN = (1<<KEY1)+(1<<KEY2)+(1<<KEY3)+(1<<KEY4)

.equ		BF_PIN		= PINC
.equ		BF			= 1

.equ		CMD_PORT	= PORTD
.equ		CMD_DDR		= DDRD
.equ		LCD_E		= 5
.equ		LCD_RW		= 6
.equ		LCD_RS		= 7

.MACRO SET_E
	sbi		CMD_PORT,LCD_E
.ENDM
.MACRO CLR_E
	cbi		CMD_PORT,LCD_E
.ENDM
.MACRO SET_RW
	sbi		CMD_PORT,LCD_RW
.ENDM
.MACRO CLR_RW
	cbi		CMD_PORT,LCD_RW
.ENDM
.MACRO SET_RS
	sbi		CMD_PORT,LCD_RS
.ENDM
.MACRO CLR_RS
	cbi		CMD_PORT,LCD_RS
.ENDM

.macro	put_char
	ldi		r18,@0
	rcall	lcd_put_cmd
	ldi		r18,@1
	rcall	lcd_put_data
.endm
.MACRO SET_D4
	sbi		PORTB,4
.ENDM
.MACRO CLR_D4
	cbi		PORTB,4
.ENDM

.MACRO SET_D5
	sbi		PORTB,5
.ENDM
.MACRO CLR_D5
	cbi		PORTB,5
.ENDM
.MACRO SET_D4
	sbi		PORTB,4
.ENDM
.MACRO CLR_D4
	cbi		PORTB,4
.ENDM

.MACRO SET_D5
	sbi		PORTB,5
.ENDM
.MACRO CLR_D5
	cbi		PORTB,5
.ENDM

.MACRO SET_D6
	sbi		PORTC,0
.ENDM
.MACRO CLR_D6
	cbi		PORTC,0
.ENDM

.MACRO SET_D7
	sbi		PORTC,1
.ENDM
.MACRO CLR_D7
	cbi		PORTC,1
.ENDM




.MACRO DATA_IN
	cbi		DDRC,1
.ENDM

.MACRO DATA_OUT
	sbi		DDRC,1
.ENDM

.MACRO DELAY
m_delay:
	dec		@0
	brne	m_delay
.ENDM

.dseg
mem_temp:		.byte 2
mem_temp1:		.byte 1
mem_max_rcp:	.byte 2
mem_min_rcp:	.byte 2
mem_rcp:		.byte 2

mem_bcd_code:	.byte 2

.cseg
.org 0
	rjmp	reset				;1
	Rjmp	vect				;2.equ	INT0addr=$001	; External Interrupt0 Vector Address
	Rjmp	vect				;3.equ	INT1addr=$002	; External Interrupt1 Vector Address
	Rjmp	vect				;4 Pin Change Interrupt Request 0
	Rjmp	vect				;5 Pin Change Interrupt Request 1
	Rjmp	pcir2				;6 Pin Change Interrupt Request 2
	Rjmp	vect				;7 Watchdog Time-out Interrupt
	Rjmp	vect				;8 Timer/Counter2 Compare Match A
	Rjmp	vect				;9 Timer/Counter2 Compare Match B
	Rjmp	vect				;10 Timer/Counter2 Overflow
	Rjmp	vect				;11 Timer/Counter1 Capture Event
	Rjmp	tcc1ma				;12 Timer/Counter1 Compare Match A
	Rjmp	vect				;13 Timer/Coutner1 Compare Match B
	Rjmp	t1_ovfl				;14 Timer/Counter1 Overflow
	Rjmp	vect				;15 Timer/Counter0 Compare Match A
	Rjmp	vect				;16 Timer/Counter0 Compare Match B
	rjmp	vect				;17 Timer/Counter0 Overflow
	Rjmp	vect				;18 SPI Serial Transfer Complete
	Rjmp	vect				;19 USART Rx Complete
	Rjmp	vect				;20 USART, Data Register Empty
	Rjmp	vect				;21 USART, Tx Complete
	Rjmp	vect				;22 ADC Conversion Complete
	Rjmp	vect				;23 EEPROM Ready
	Rjmp	vect				;24 Analog Comparator
	Rjmp	vect				;25 2-wire Serial Interface
	Rjmp	vect				;26 Store Program Memory Ready
; interrupt routine -------------------------------------------------------
vect:
	reti
;t0_ovfl:
;	in		isreg,SREG
;	inc		tcnt0h
;	brne	t0_ovfl_exit
;	inc		tcnt0x
;t0_ovfl_exit:
;	out		SREG,isreg
;	reti
tcc1ma:
	cbi		PORTD,2
	reti
t1_ovfl:
	sbi		PORTD,2
	; disable T1
	;sts		TIMSK1,zero
	reti
pcir2:
	in		isreg,SREG
	; clear lcd
;	ldi		r18,1
;	rcall	lcd_put_cmd

	sbic	KEY_PIN,KEY1
	rjmp	pcir2_1
	sbi		GPIOR0,rcp_changed
	lds		r24,mem_rcp
	lds		r25,mem_rcp+1
	sbiw	r24,1
	lds		r20,mem_min_rcp
	lds		r21,mem_min_rcp+1
	cp		r24,r20
	cpc		r25,r21
	brcc	ml_2
	movw	r24,r20
ml_2:
	sts		mem_rcp,r24
	sts		mem_rcp+1,r25

pcir2_1:
	sbic	KEY_PIN,KEY2
	rjmp	pcir2_2
	sbi		GPIOR0,rcp_changed
	;increase rcp
	lds		r24,mem_rcp
	lds		r25,mem_rcp+1
	inc		r24
	and		r24,r24
	brne	ml_6
	inc		r25
ml_6:
	lds		r20,mem_max_rcp
	lds		r21,mem_max_rcp+1
	cp		r24,r20
	cpc		r25,r21
	brcs	ml_4
	movw	r24,r20
ml_4:
	sts		mem_rcp,r24
	sts		mem_rcp+1,r25




pcir2_2:
	sbic	KEY_PIN,KEY3
	rjmp	pcir2_3
pcir2_3:
	sbic	KEY_PIN,KEY4
	rjmp	pcir2_4
pcir2_4:
	out		SREG,isreg
	reti
; interrupt routine end----------------------------------------------------
reset:
	cli
	clr		zero
	out		SREG, zero
	ldi		r16, high(RAMEND)	; stack = RAMEND ,初始化SP
	out		SPH, r16
	ldi		r16, low(RAMEND)
	out 	SPL, r16
	rcall	init_mem
	rcall	key_init
	rcall	timer_init
	; RCP signal pin
	sbi		DDRD,2
	cbi		PORTD,2
	
	rcall	short_delay
	rcall	lcd_init
	rcall	show_screen

	rcall	show_current_rcp
	sei




main_loop:
;	ldi		r16,2
;	cp		tcnt0x,r16
;	brcs	ml_1
;	rcall	t0_reset
;	sbi		PORTD,2
	rcall	commit_rcp
ml_1:
	sbis	GPIOR0,rcp_changed
	rjmp	main_loop

	rcall	show_current_rcp
	cbi		GPIOR0,rcp_changed
	rjmp	main_loop




short_delay:
	ldi		r16,255
sdelay:
	dec		r16
	brne	sdelay
	ret
long_long_delay:
	ldi		r16,64
lldelay:
	push	r16
	rcall	long_delay
	pop		r16
	dec		r16
	brne	lldelay
	ret
long_delay:
	ldi		r16,255
ldelay_1:
	ldi		r17,255
ldelay_2:
	dec		r17
	brne	ldelay_2
	dec		r16
	brne	ldelay_1
	ret
eep_read:
; 等待上一次写操作结束
	sbic EECR,EEWE
	rjmp eep_read
	; 设置地址寄存器 (r18:r19)
	out EEARH, r19
	out EEARL, r18
	; 设置EERE 以启动读操作
	sbi EECR,EERE
	; 自数据寄存器读取数据
	in r16,EEDR
	ret
eep_write:
	; Wait for completion of previous write
	sbic	EECR,EEPE
	rjmp	eep_write
	; Set up address (r19:r18) in address register
	out		EEARH, r19
	out		EEARL, r18
	; Write data (r16) to Data Register
	out		EEDR,r16
	; Write logical one to EEMPE
	sbi		EECR,EEMPE
	; Start eeprom write by setting EEPE
	sbi		EECR,EEPE
	ret
init_mem:
	ldi		r18,1
	ldi		r19,0
	rcall	eep_read
	cpi		r16,0x7f
	brcs	im_1
	ldi		r16,low(MIN_RCP)
	ldi		r17,high(MIN_RCP)
	rjmp	im_2
im_1:
	mov		r17,r16
	dec		r18
	rcall	eep_read
im_2:
	sts		mem_min_rcp,r16
	sts		mem_min_rcp+1,r17
	
	sts		mem_rcp,r16
	sts		mem_rcp+1,r17
	

	ldi		r18,3
	rcall	eep_read
	cpi		r16,0x7f
	brcs	im_3
	ldi		r16,low(MAX_RCP)
	ldi		r17,high(MAX_RCP)
	rjmp	im_4
im_3:
	mov		r17,r16
	dec		r18
	rcall	eep_read
im_4:
	sts		mem_max_rcp,r16
	sts		mem_max_rcp+1,r17
	ret
key_init:
	in		r16,MCUCR
	cbr		r16,1<<PUD
	out		MCUCR,r16
;.equ		KEY_PORT	= PORTD
;.equ		KEY_PIN		= PIND
;.equ		KEY_DDR		= DDRD
	ldi		r16,0xff - ((1<<KEY1)+(1<<KEY2)+(1<<KEY3)+(1<<KEY4))
	out		KEY_DDR,r16
	ldi		r16,(1<<KEY1)+(1<<KEY2)+(1<<KEY3)+(1<<KEY4)
	out		KEY_PORT,r16
	
	ldi		r16,1<<PCIE2
	;out		PCICR,r16
	sts		PCICR,r16
	ldi		r16,(1<<PCINT16)+(1<<PCINT17)+(1<<PCINT19)+(1<<PCINT20)
	;out		PCMSK2,r16
	sts		PCMSK2,r16
	ret
timer_init:
; TIMER0 initializing
; clk/1 use for calculate cycle width
	ldi		r16,(1<<CS00)
	out		TCCR0B,r16
	

;	in		r16,TIMSK0
;	lds		r16,TIMSK0
	ldi		r16,1<<TOIE0
;	out		TIMSK0,r16
	sts		TIMSK0,r16

	; mode 14 fast pwm, ICR1 use for TOP
	; clk/8 prescaler
	ldi		r16,(1<<WGM11)
;	out		TCCR1A,r16
	sts		TCCR1A,r16
	ldi		r16,(1<<WGM13)+(1<<WGM12)+(1<<CS11)
;	out		TCCR1B,r16
	sts		TCCR1B,r16
	ldi		r16,high(20000)
;	out		ICR1H,r16
	sts		ICR1H,r16
	ldi		r16,low(20000)
;	out		ICR1L,r16
	sts		ICR1L,r16
;	out		TCNT1H,zero
	sts		TCNT1H,zero
;	out		TCNT1L,zero
	sts		TCNT1L,zero
	ldi		r16,(1<<TOIE1)+(1<<OCIE1A)
;	out		TIMSK1,r16
	sts		TIMSK1,r16


	ret
commit_rcp:
	lds		r16,mem_rcp
	lds		r17,mem_rcp+1
	sts		OCR1AH,r17
	sts		OCR1AL,r16
	ret
t1_reset:
	; mode 14 fast pwm, ICR1 use for TOP
	ldi		r16,(1<<WGM11)
;	out		TCCR1A,r16
	sts		TCCR1A,r16
	ldi		r16,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
;	out		TCCR1B,r16
	sts		TCCR1B,r16
	lds		r16,mem_rcp+1
;	out		ICR1H,r16
	sts		ICR1H,r16
	lds		r16,mem_rcp
;	out		ICR1L,r16
	sts		ICR1L,r16
;	out		TCNT1H,zero
	sts		TCNT1H,zero
;	out		TCNT1L,zero
	sts		TCNT1L,zero
	ldi		r16,1<<TOIE1
;	out		TIMSK1,r16
	sts		TIMSK1,r16
	ret
t0_reset:
	out		TCCR0B,zero
	out		TCNT0,zero
	clr		tcnt0x
	clr		tcnt0h
	ldi		r16,(1<<CS00)
	out		TCCR0B,r16
	ret
; [in] r16:r17
to_bcd:
	cpi		r16,low(9999)
	ldi		r18,high(9999)
	cpc		r17,r18
	brcs	tbcd_0
	ldi		r24,0xff
	sts		mem_bcd_code,r24
	sts		mem_bcd_code+1,r24
	ret
tbcd_0:
	clr		r24
	clr		r25
	movw	r18,r16
tbcd_1:
	subi	r18,low(1000)
	sbci	r19,high(1000)
	brcs	tbcd_2
	subi	r25,-0x10
	movw	r16,r18
	rjmp	tbcd_1
tbcd_2:
	movw	r18,r16
tbcd_3:
	subi	r18,100
	sbci	r19,0
	brcs	tbcd_4
	inc		r25
	movw	r16,r18
	rjmp	tbcd_3
tbcd_4:
	movw	r18,r16
tbcd_5:
	subi	r18,10
	brcs	tbcd_6
	subi	r24,-0x10
	mov		r16,r18
	rjmp	tbcd_5
tbcd_6:
	add		r24,r16
	sts		mem_bcd_code,r24
	sts		mem_bcd_code+1,r25
	ret
show_screen:
	lds		r16,mem_min_rcp
	lds		r17,mem_min_rcp+1
	ldi		r18,0xc0
	rcall	show_rcp

	lds		r16,mem_max_rcp
	lds		r17,mem_max_rcp+1
	ldi		r18,0xc5
	rcall	show_rcp
	
	ret
show_current_rcp:
	ldi		r18,0x80
	sbis	GPIOR0,bi_direct
	rjmp	scr_one_way
	ldi		r30,low(bd*2)
	ldi		r31,high(bd*2)
scr_one_way:
	ldi		r30,low(ow*2)
	ldi		r31,high(ow*2)
	rcall	lcd_puts
	ldi		r18,0x84
	lds		r16,mem_rcp
	lds		r17,mem_rcp+1
	rcall	show_rcp
	ret
show_rcp:
	sts		mem_temp1,r18
;	lsr		r17
;	ror		r16
;	lsr		r17
;	ror		r16
;	lsr		r17
;	ror		r16
	rcall	to_bcd
	lds		r18,mem_temp1
	lds		r19,mem_bcd_code+1
	rcall	lcd_put_hex
	lds		r18,mem_temp1
	inc		r18
	inc		r18
	lds		r19,mem_bcd_code
	rcall	lcd_put_hex
	ret
; LCD functions -----------------------------------------------------------------------------
lcd_wait_cmd:
	DATA_IN
	CLR_RS
	SET_RW
	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,3
	DELAY	r16
w_cmd_loop:
	sbic	BF_PIN,BF
	rjmp	w_cmd_loop
	CLR_E
	
	ret
lcd_put_cmd:
	push	r16
	rcall	lcd_wait_cmd


	DATA_OUT
	; high 4 bits
	sbrs	r18,4
	;cbi		DATA_PORT,D4
	CLR_D4
	sbrc	r18,4
	;sbi		DATA_PORT,D4
	SET_D4

	sbrs	r18,5
	;cbi		DATA_PORT,D5
	CLR_D5
	sbrc	r18,5
	;sbi		DATA_PORT,D5
	SET_D5

	sbrs	r18,6
	;cbi		DATA_PORT,D6
	CLR_D6
	sbrc	r18,6
	;sbi		DATA_PORT,D6
	SET_D6

	sbrs	r18,7
	;cbi		DATA_PORT,D7
	CLR_D7
	sbrc	r18,7
	;sbi		DATA_PORT,D7
	SET_D7
	
	CLR_RS
	CLR_RW
	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,5
	DELAY	r16
	CLR_E
	
	; LOW 4 bits
	sbrs	r18,0
	;cbi		DATA_PORT,D4
	CLR_D4
	sbrc	r18,0
	;sbi		DATA_PORT,D4
	SET_D4

	sbrs	r18,1
	;cbi		DATA_PORT,D5
	CLR_D5
	sbrc	r18,1
	;sbi		DATA_PORT,D5
	SET_D5

	sbrs	r18,2
	;cbi		DATA_PORT,D6
	CLR_D6
	sbrc	r18,2
	;sbi		DATA_PORT,D6
	SET_D6

	sbrs	r18,3
	;cbi		DATA_PORT,D7
	CLR_D7
	sbrc	r18,3
	;sbi		DATA_PORT,D7
	SET_D7


	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,5
	DELAY	r16
	CLR_E

	pop		r16
	ret
lcd_put_data:
	push	r16
	rcall	lcd_wait_cmd
	DATA_OUT
	; high 4 bits
	sbrs	r18,4
	;cbi		DATA_PORT,D4
	CLR_D4
	sbrc	r18,4
	;sbi		DATA_PORT,D4
	SET_D4

	sbrs	r18,5
	;cbi		DATA_PORT,D5
	CLR_D5
	sbrc	r18,5
	;sbi		DATA_PORT,D5
	SET_D5

	sbrs	r18,6
	;cbi		DATA_PORT,D6
	CLR_D6
	sbrc	r18,6
	;sbi		DATA_PORT,D6
	SET_D6

	sbrs	r18,7
	;cbi		DATA_PORT,D7
	CLR_D7
	sbrc	r18,7
	;sbi		DATA_PORT,D7
	SET_D7
	SET_RS
	CLR_RW
	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,5
	DELAY	r16
	CLR_E
	; LOW 4 bits
	sbrs	r18,0
	;cbi		DATA_PORT,D4
	CLR_D4
	sbrc	r18,0
	;sbi		DATA_PORT,D4
	SET_D4

	sbrs	r18,1
	;cbi		DATA_PORT,D5
	CLR_D5
	sbrc	r18,1
	;sbi		DATA_PORT,D5
	SET_D5

	sbrs	r18,2
	;cbi		DATA_PORT,D6
	CLR_D6
	sbrc	r18,2
	;sbi		DATA_PORT,D6
	SET_D6

	sbrs	r18,3
	;cbi		DATA_PORT,D7
	CLR_D7
	sbrc	r18,3
	;sbi		DATA_PORT,D7
	SET_D7

	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,5
	DELAY	r16
	CLR_E

;	out		DATA_PORT,zero
	pop		r16
	ret
wait_4200us:
; 40000 cycles
	ldi		r17,52
w4_loop1:
	ldi		r16,255
w4_loop2:
	dec		r16			; 1
	brne	w4_loop2	; 2
						; 3 x 255 = 765
	dec		r17			; 1
	brne	w4_loop1	; 2
						; (765 + 3) x 52 = 39936
	ret
lcd_init:
	; lcd interface initialized
	sbi		CMD_DDR,LCD_E
	sbi		CMD_DDR,LCD_RW
	sbi		CMD_DDR,LCD_RS

	ldi		r16,0b00110000
	out		DDRB,r16
	SET_D4
	SET_D5
	ldi		r16,0b00000011
	out		DDRC,r16
	CLR_D6
	CLR_D7
	
;	ldi		r16,(1<<D4)+(1<<D5)
;	out		DATA_PORT,r16
	rcall	wait_4200us
	; lcd initialization stage finish


	; 4 bit interface mode
;	ldi		r18,(1<<D5)
;	out		DATA_PORT,r18
	SET_D5
	CLR_D4
	ldi		r16,3
	DELAY	r16
	SET_E
	ldi		r16,3
	DELAY	r16
	CLR_E

	; 4 bit interface mode 2 row
	; DL=0: 4D, N=1: 2R, F=1:5X10 STYLE
	ldi		r18,0b00101100		;(1<<D5)+(1<<D3)+(1<<D2)
	rcall	lcd_put_cmd


	; cursor off, blink off
	ldi		r18,0b00001100
	rcall	lcd_put_cmd

	; clear screen
	ldi		r18,0b00000001
	rcall	lcd_put_cmd
	
	ret

; r18: lcd address
; r19: character
lcd_put:
	rcall	lcd_put_cmd
	push	r18
	mov		r18,r19
	rcall	lcd_put_data
	pop		r18
	ret

; r18: lcd address, and the value of register will be changed
; r30:r31: offset of string
lcd_puts:
	rcall	lcd_put_cmd
lcd_puts_loop:
	lpm		r18,Z+
	and		r18,r18
	breq	lcd_puts_ret
	rcall	lcd_put_data
	rjmp	lcd_puts_loop
lcd_puts_ret:
	ret

; r18	lcd address
; r16:r17	value
lcd_put_bcd:
	sts		mem_temp,r16
	sts		mem_temp+1,r17
	rcall	lcd_put_cmd

	lds		r16,mem_temp+1
	swap	r16
	andi	r16,0x0f
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
	lds		r16,mem_temp+1
	andi	r16,0x0f
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data

	lds		r16,mem_temp
	swap	r16
	andi	r16,0x0f
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
	lds		r16,mem_temp
	andi	r16,0x0f
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
	
	
	ret
; r18	lcd address
; r19	value
lcd_put_hex:
	rcall	lcd_put_cmd
	push	r18
	push	r19
	eor		r18,r18

	lsl		r19
	rol		r18

	lsl		r19
	rol		r18
	
	lsl		r19
	rol		r18

	lsl		r19
	rol		r18
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r18
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
	swap	r19
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	add		r30,r19
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
	pop		r19
	pop		r18
	ret
hex:
	.db		"0123456789ABCDEF"
; LCD functions end -------------------------------------------------------------------------
one_way:
	.db		"One way mode",0,0
bi_dir:
	.db		"Bi-direct mode",0,0
ow:
	.db		"OW:",0
bd:
	.db		"BD:",0
.exit