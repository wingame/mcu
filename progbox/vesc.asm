

; program box
; 

.def	zero	=	r0

; 3500us	clk/1
.equ		HEAD_LEN	= 29360

; 80us in clk/1
.equ		START_LEN	= 1342
.equ		HEAD_CORRECT_LEN = 3000

.ifdef CPU_M8

.include "m8def.inc"
.message "use ATmega8"
.else

.include "m48def.inc"
.message "use ATmega48"
.endif


.equ		KEY_PORT	= PORTD
.equ		KEY_PIN		= PIND
.equ		KEY_DDR		= DDRD
.equ		KEY1		= 0
.equ		KEY2		= 1
.equ		KEY3		= 2
.equ		KEY4		= 3
.equ		BF_PIN		= PINC
.equ		BF			= 1

.equ		CMD_PORT	= PORTD
.equ		CMD_DDR		= DDRD
.equ		LCD_E		= 5
.equ		LCD_RW		= 6
.equ		LCD_RS		= 7

; EEP ROM ADDRESS DEFINITION
.equ		EEP_ESC_TYPE = 0


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

.macro	current_t1
.ifdef CPU_M8
.else
	;in		r16,TCNT1L
	lds		@0,TCNT1L
	;in		r17,TCNT1H
	lds		@1,TCNT1H
.endif
.endm

; D4 - PB4
; D5 - PB5
; D6 - PC0
; D7 - PC1


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
;mem_code:			.byte 2
mem_pb_tcnt1:			.byte 2
mem_pb_signal_len:		.byte 2
mem_pb_callback:		.byte 2

mem_temp:			.byte 2
.cseg

;**** Interrupt Vectors ****		
;.equ	INT0addr     =$001	;External Interrupt0
;.equ	INT1addr     =$002	;External Interrupt1
;.equ	PCINT0addr   =$003	;Pin Change Interrupt0
;.equ	PCINT1addr   =$004	;Pin Change Interrupt1
;.equ	PCINT2addr   =$005	;Pin Change Interrupt2
;.equ	WDTaddr	     =$006	;Watchdog Timeout
;.equ	OC2Aaddr     =$007	;Timer/Counter2 Compare Match Interrupt
;.equ	OC2Baddr     =$008	;Timer/Counter2 Compare Match Interrupt	
;.equ	OVF2addr     =$009	;Overflow2 Interrupt
;.equ	ICP1addr     =$00a	;Input Capture1 Interrupt 	
;.equ	OC1Aaddr     =$00b	;Output Compare1A Interrupt 
;.equ	OC1Baddr     =$00c	;Output Compare1B Interrupt 
;.equ	OVF1addr     =$00d	;Overflow1 Interrupt 
;.equ	OC0Aaddr     =$00e	;Timer/Counter0 Compare Match Interrupt
;.equ	OC0Baddr     =$00f	;Timer/Counter0 Compare Match Interrupt	
;.equ	OVF0addr     =$010	;Overflow0 Interrupt
;.equ	SPIaddr      =$011	;SPI Interrupt 	
;.equ	URXCaddr     =$012	;USART Receive Complete Interrupt 
;.equ	UDREaddr     =$013	;USART Data Register Empty Interrupt 
;.equ	UTXCaddr     =$014	;USART Transmit Complete Interrupt 
;.equ    ADCCaddr     =$015	;ADC Conversion Complete Handle
;.equ	ERDYaddr     =$016	;EEPROM write complete
;.equ	ACIaddr	     =$017	;Analog Comparator Interrupt 
;.equ    TWIaddr      =$018	;TWI Interrupt Vector Address
;.equ	SPMRaddr     =$019	;Store Program Memory Ready Interrupt 


.org 0
	Rjmp	reset
.ifdef CPU_M8
	rjmp	vect	; External Interrupt0 Vector Address
	rjmp	vect	; External Interrupt1 Vector Address
	rjmp	vect	; Output Compare2 Interrupt Vector Address
	rjmp	vect	; Overflow2 Interrupt Vector Address
	rjmp	vect	; Input Capture1 Interrupt Vector Address
	rjmp	vect	; Output Compare1A Interrupt Vector Address
	rjmp	vect	; Output Compare1B Interrupt Vector Address
	rjmp	vect	; Overflow1 Interrupt Vector Address
	rjmp	vect	; Overflow0 Interrupt Vector Address
	rjmp	vect	; SPI Interrupt Vector Address
	rjmp	vect	; USART Receive Complete Interrupt Vector Address
	rjmp	vect	; USART Data Register Empty Interrupt Vector Address
	rjmp	vect	; USART Transmit Complete Interrupt Vector Address
	rjmp	vect	; ADC Interrupt Vector Address
	rjmp	vect	; EEPROM Interrupt Vector Address
	rjmp	vect		; Analog Comparator Interrupt Vector Address
	rjmp	vect		; Irq. vector address for Two-Wire Interface
	rjmp	vect		; SPM complete Interrupt Vector Address
	rjmp	vect	; SPM complete Interrupt Vector Address

.else
; M48 Interrupt Lists
	Rjmp	ext0_int					;1.equ	INT0addr=$001	; External Interrupt0 Vector Address
	Rjmp	ext1_int					;2.equ	INT1addr=$002	; External Interrupt1 Vector Address
	Rjmp	PCINT0_INT					;3 Pin Change Interrupt Request 0
	Rjmp	PCINT1_INT					;4 Pin Change Interrupt Request 1
	Rjmp	PCINT2_INT					;5 Pin Change Interrupt Request 2
	Rjmp	WDT							;6 Watchdog Time-out Interrupt
	Rjmp	TIMER2_COMPA				;7 Timer/Counter2 Compare Match A
	Rjmp	TIMER2_COMPB				;8 Timer/Counter2 Compare Match B
	Rjmp	TIMER2_OVF					;9 Timer/Counter2 Overflow
	Rjmp	TIMER1_CAPT					;a Timer/Counter1 Capture Event
	Rjmp	timer1_compa				;b Timer/Counter1 Compare Match A
	Rjmp	TIMER1_COMPB				;c Timer/Coutner1 Compare Match B
	Rjmp	timer1_ovf					;d Timer/Counter1 Overflow
	Rjmp	TIMER0_COMPA				;e Timer/Counter0 Compare Match A
	Rjmp	TIMER0_COMPB				;f Timer/Counter0 Compare Match B
	rjmp	timer0_ovf					;10 Timer/Counter0 Overflow
	Rjmp	SPI_STC						;11 SPI Serial Transfer Complete
	Rjmp	USART_RX					;12 USART Rx Complete
	Rjmp	USART_UDRE					;13 USART, Data Register Empty
	Rjmp	USART_TX					;14 USART, Tx Complete
	Rjmp	ADC_INT						;15 ADC Conversion Complete
	Rjmp	EE_READY					;16 EEPROM Ready
	Rjmp	ANALOG_COMP					;17 Analog Comparator
	Rjmp	TWI_INT						;18 2-wire Serial Interface
	Rjmp	SPM_READY					;19 Store Program Memory Ready
ext0_int:
ext1_int:
timer1_compa:
timer0_ovf:
timer1_ovf:
PCINT0_INT:
PCINT1_INT:
PCINT2_INT:
WDT:
TIMER2_COMPA:
TIMER2_COMPB:
TIMER2_OVF:
TIMER1_CAPT:
TIMER1_COMPB:
TIMER0_COMPA:
SPI_STC:
USART_RX:
USART_UDRE:
USART_TX:
ADC_INT:
EE_READY:
ANALOG_COMP:
TWI_INT:
SPM_READY:
TIMER0_COMPB:
.endif
vect:
	reti

reset:
	cli
	clr		zero
	out		SREG, zero
	ldi		r16, high(RAMEND)	; stack = RAMEND ,初始化SP
	out		SPH, r16
	ldi		r16, low(RAMEND)
	out 	SPL, r16



;	ldi		r16,0xff
;	out		CMD_DDR,r16
;	out		DATA_DDR,r16

	
	
	; pull-up enabled
.ifdef CPU_M8
	in		r16,SFIOR
	cbr		r16,1<<PUD
	out		SFIOR,r16
.else
	in		r16,MCUCR
	cbr		r16,1<<PUD
	out		MCUCR,r16
.endif

	
;	out		DATA_PORT,zero
;	out		CMD_PORT,zero

	rcall	long_delay



	rcall	lcd_init

	ldi		r18,0x80
	ldi		r30,low(product_name*2)
	ldi		r31,high(product_name*2)
	rcall	lcd_puts

;	rjmp	ppm_reader

	ldi		r30,low(no_signal*2)
	ldi		r31,high(no_signal*2)
	ldi		r18,0xc0
	rcall	lcd_puts
	ldi		r16,low(show_code)
	ldi		r17,high(show_code)
	rcall	pb_func


	; CLEAR SCREEN
;	ldi		r18,1
;	rcall	lcd_put_cmd


	
main_loop:
	rjmp	main_loop

infinity:
	rjmp	infinity
; r21:r22 是接收到的信号代码
show_code:
	ldi		r18,0xc0
	rcall	lcd_put_cmd
	;clear line
	ldi		r16,9
	sts		mem_temp,r16
sc_1:
	ldi		r18,' '
	rcall	lcd_put_data
	lds		r16,mem_temp
	dec		r16
	sts		mem_temp,r16
	brne	sc_1
	ldi		r18,0xc0
	mov		r19,r22
	rcall	lcd_put_hex
	ldi		r18,0xc2
	mov		r19,r21
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

; LCD functions end -------------------------------------------------------------------------
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

; r18:r19 EEPROM address
; r16 value will be wroten to EEPROM
eep_write:
.ifdef CPU_M8
	; Wait for completion of previous write
	sbic	EECR,EEWE
	rjmp	eep_write
	; Set up address (r19:r18) in address register
	out		EEARH, r19
	out		EEARL, r18
	; Write data (r16) to data register
	out		EEDR,r16
	; Write logical one to EEMWE
	sbi		EECR,EEMWE
	; Start eeprom write by setting EEWE
	sbi		EECR,EEWE

.else
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
.endif
	ret
eep_read:
.ifdef CPU_M8
	; Wait for completion of previous write
	sbic EECR,EEWE
	rjmp eep_read
	; Set up address (r18:r19) in address register
	out EEARH, r19
	out EEARL, r18
	; Start eeprom read by writing EERE
	sbi EECR,EERE
	; Read data from data register
	in r16,EEDR
.else
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
.endif
	ret

pb_func:
	; initializing port
	cli
	sts		mem_pb_callback,r16
	sts		mem_pb_callback+1,r17
	cbi		DDRD,2
	cbi		PORTD,2	; disable pull-up resist
	; set t1 to clk/8
.ifdef	CPU_M8
.else
	;out		TCCR1A,zero
	sts		TCCR1A,zero
	
	ldi		r16,(1<<CS10)
	;out		TCCR1B,r16
	sts		TCCR1B,r16
	
.endif

	;clr		r20

	; wait a rising edge
rising_edge1:
	sbic	PIND,2
	rjmp	rising_edge1
rising_edge2:
	sbis	PIND,2
	rjmp	rising_edge2
	current_t1 r16,r17

	sts		mem_pb_tcnt1,r16
	sts		mem_pb_tcnt1+1,r17
	; wait a falling edge
falling_edge3:
	sbic	PIND,2
	rjmp	falling_edge3
	current_t1 r16,r17

	lds		r18,mem_pb_tcnt1
	lds		r19,mem_pb_tcnt1+1
	sts		mem_pb_tcnt1,r16
	sts		mem_pb_tcnt1+1,r17
	sub		r16,r18
	sbc		r17,r19
	
	; if(r16 > RCP_LOW && r16 < RCP_HIGH) goto int0_rcp_ready
	subi	r16,low(HEAD_LEN-HEAD_CORRECT_LEN)
	sbci	r17,high(HEAD_LEN-HEAD_CORRECT_LEN)
	subi	r16,low(HEAD_CORRECT_LEN*2)
	sbci	r17,high(HEAD_CORRECT_LEN*2)
	brcs	correct_pb_head_signal

	rjmp	rising_edge1
correct_pb_head_signal:

rising_edge4:
	
	current_t1 r16,r17
	lds		r18,mem_pb_tcnt1
	lds		r19,mem_pb_tcnt1+1
	sub		r16,r18
	sbc		r17,r19
	
	subi	r16,low(START_LEN+1000)
	sbci	r17,high(START_LEN+1000)
	brcc	rising_edge1	; 空信号，回到开始
	sbis	PIND,2
	rjmp	rising_edge4

;debug 
;	ldi		r18,0xcf
;	rcall	lcd_put_cmd
;	ldi		r18,'*'
;	rcall	lcd_put_data
;	rjmp	infinity
;debug end

	current_t1 r16,r17
	lds		r18,mem_pb_tcnt1
	lds		r19,mem_pb_tcnt1+1
	sts		mem_pb_tcnt1,r16
	sts		mem_pb_tcnt1+1,r17
	sub		r16,r18
	sbc		r17,r19
	
	; 脉冲长度被的一半长度保存在r16:r17中。
	add		r16,r16
	adc		r17,r17

	sts		mem_pb_signal_len,r16
	sts		mem_pb_signal_len+1,r17
	
	ldi		r20,16

wait_signal:
	current_t1 r16,r17
	lds		r18,mem_pb_tcnt1
	lds		r19,mem_pb_tcnt1+1
	sub		r16,r18
	sbc		r17,r19
	lds		r18,mem_pb_signal_len
	lds		r19,mem_pb_signal_len+1
	cp		r16,r18
	cpc		r17,r19
	brcs	wait_signal
	current_t1 r16,r17
	sts		mem_pb_tcnt1,r16
	sts		mem_pb_tcnt1+1,r17
	sbic	PIND,2
	sec
	sbis	PIND,2
	clc
	rol		r21
	rol		r22

	dec		r20
	brne	wait_signal
;	sts		mem_code,r21
;	sts		mem_code+1,r22
	lds		r30,mem_pb_callback
	lds		r31,mem_pb_callback+1
	icall
	rjmp	rising_edge1
	ret

ppm_reader:
	cli
	cbi		DDRD,2
	cbi		PORTD,2	; disable pull-up resist
	; set t1 to clk/1
.ifdef	CPU_M8
.else
	;out		TCCR1A,zero
	sts		TCCR1A,zero
	
	ldi		r16,(1<<CS10)
	;out		TCCR1B,r16
	sts		TCCR1B,r16
	
.endif
	
pr_rising_edge1:
	sbic	PIND,2
	rjmp	pr_rising_edge1
pr_rising_edge2:
	sbis	PIND,2
	rjmp	pr_rising_edge2
	current_t1 r16,r17

	sts		mem_pb_tcnt1,r16
	sts		mem_pb_tcnt1+1,r17
	; wait a falling edge
pr_falling_edge3:
	sbic	PIND,2
	rjmp	pr_falling_edge3
	current_t1 r20,r21

	lds		r18,mem_pb_tcnt1
	lds		r19,mem_pb_tcnt1+1
	sub		r20,r18
	sbc		r21,r19


	lds		r18,mem_temp
	dec		r18
	sts		mem_temp,r18
	andi	r18,0x1f
	brne	pr_rising_edge1
	lsr		r21
	ror		r20
	lsr		r21
	ror		r20
	lsr		r21
	ror		r20

	movw	r24,r20
	
;	ldi		r24,low(1234)
;	ldi		r25,high(1234)
	rcall	hex2bcd

	ldi		r18,0xc0
	mov		r19,r21
	rcall	lcd_put_hex
	ldi		r18,0xc2
	mov		r19,r20
	rcall	lcd_put_hex
	
	rjmp	pr_rising_edge1

; in r24:r25
; out r20:r21
hex2bcd:
	movw	r18,r24
	clr		r20
	clr		r21
thousand:
	subi	r18,low(1000)
	sbci	r19,high(1000)
	brcs	t1
;	subi	r20,low(-0x1000)
	subi	r21,-0x10
	movw	r24,r18
	rjmp	thousand
t1:
	movw	r18,r24

hundred:
	subi	r18,100
	sbc		r19,zero
	brcs	h1
	inc		r21
	movw	r24,r18
	rjmp	hundred
h1:
	movw	r18,r24

ten:
	subi	r18,10
	sbc		r19,zero
	brcs	te1
	subi	r20,-0x10
;	sbc		r21,zero
	movw	r24,r18
	rjmp	ten
te1:
	add		r20,r24
	adc		r21,zero
	
	
	ret
	

product_name:
	.db "PPM reader",0,0

no_signal:
	.db	"No signal",0

hex:
	.db		"0123456789ABCDEF"
.exit

