; program box
; 


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


.ifdef CPU_M8

.include "m8def.inc"
.message "use ATmega8"
.else

.include "m48def.inc"
.message "use ATmega48"
.endif

.def	zero	= r0
.def	tcnt0_h	= r2
.def	i_sreg	= r3
.def	tcnt2_h	= r4

.def	r_send_l = r6
.def	r_send_h = r7

;.def	flag	= r29
.equ	key_pressed = 0
.equ	key_delay	= 1
.equ	sending		= 2


.equ		KEY_PORT	= PORTD
.equ		KEY_PIN		= PIND
.equ		KEY_DDR		= DDRD
.equ		KEY1		= 0
.equ		KEY2		= 4
.equ		KEY3		= 3
.equ		KEY4		= 1
.equ		KEY_PATTERN = 0xff

.equ		BF_PIN		= PINC
.equ		BF			= 1

.equ		CMD_PORT	= PORTD
.equ		CMD_DDR		= DDRD
.equ		LCD_E		= 5
.equ		LCD_RW		= 6
.equ		LCD_RS		= 7


.equ		SIGNAL_PORT	= PORTD
.equ		SIGNAL_DDR	= DDRD
.equ		SIGNAL_P	= 2


; 8MHz
; t1 in clk/8
; 20000us
.equ		SIGNAL_LEN	= 20971		
; 3500us
.equ		HEAD_LEN	= 3670

; 160us
; clk/1 on timer2
.equ		START_LEN	= 1342

; figure indicate signal that carry data
;                                                         |<---------16 stages--------->|
; ,,,__|`````````````3500us`````````````|__160us__|``160us``|XXXXX320usXXXXX|~~ ~~| ..... |_________|
; ,,,__|<---------------------------------1 cycle/20000us --------------------------------------->|

; figure indicate idle signal
; ,,,__|`````````````3500us`````````````|_________________________________________________________|
; ,,,__|<---------------------------------1 cycle/20000us --------------------------------------->|

; EEP ROM ADDRESS DEFINITION
; 记录当前选择的1,2层的菜单位置
.equ		EEP_MENU_INDEX	= 0		; 2 bytes

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

.macro current_tcnt0
	mov		@1,tcnt0_h
	in		@0,TCNT0
	cp		@1,tcnt0_h
	breq	ct1
	mov		@1,tcnt0_h
	in		@0,TCNT0
ct1:
.endm

.macro current_tcnt2
.ifdef CPU_M8
	mov		@1,tcnt2_h
	in		@0,TCNT2
	cp		@1,tcnt2_h
	breq	ct2
	mov		@1,tcnt2_h
	in		@0,TCNT2
.else
	mov		@1,tcnt2_h
	;in		@0,TCNT2
	lds		@0,TCNT2
	cp		@1,tcnt2_h
	breq	ct2
	mov		@1,tcnt2_h
	;in		@0,TCNT2
	lds		@0,TCNT2

.endif
ct2:
.endm


.dseg
mem_esc_type_code:	.byte 2
mem_option_code:	.byte 2

mem_menu_level:		.byte 1
mem_menu_selected:	.byte 1

mem_menu_lv3:		.byte 2

mem_menu_index:		.byte 4

mem_current_option_name: .byte 2

;mem_key:			.byte 1
mem_key_tcnt0:	.byte 2

mem_send_tcnt2:	.byte 2
;mem_key_t0			.byte 1

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
	rjmp	t2_ovfl	; Overflow2 Interrupt Vector Address
	rjmp	vect	; Input Capture1 Interrupt Vector Address
	rjmp	oc1a_int	; Output Compare1A Interrupt Vector Address
	rjmp	vect	; Output Compare1B Interrupt Vector Address
	rjmp	t1_overflow	; Overflow1 Interrupt Vector Address
	rjmp	t0_ovfl	; Overflow0 Interrupt Vector Address
	rjmp	vect	; SPI Interrupt Vector Address
	rjmp	vect	; USART Receive Complete Interrupt Vector Address
	rjmp	vect	; USART Data Register Empty Interrupt Vector Address
	rjmp	vect	; USART Transmit Complete Interrupt Vector Address
	rjmp	vect	; ADC Interrupt Vector Address
	rjmp	vect	; EEPROM Interrupt Vector Address
	rjmp	vect	; Analog Comparator Interrupt Vector Address
	rjmp	vect	; Irq. vector address for Two-Wire Interface
	rjmp	vect	; SPM complete Interrupt Vector Address
	rjmp	vect	; SPM complete Interrupt Vector Address

.else
; M48 Interrupt Lists
	Rjmp	vect				;1.equ	INT0addr=$001	; External Interrupt0 Vector Address
	Rjmp	vect				;2.equ	INT1addr=$002	; External Interrupt1 Vector Address
	Rjmp	vect				;3 Pin Change Interrupt Request 0
	Rjmp	vect				;4 Pin Change Interrupt Request 1
	Rjmp	vect				;5 Pin Change Interrupt Request 2
	Rjmp	vect				;6 Watchdog Time-out Interrupt
	Rjmp	vect				;7 Timer/Counter2 Compare Match A
	Rjmp	vect				;8 Timer/Counter2 Compare Match B
	Rjmp	t2_ovfl				;9 Timer/Counter2 Overflow
	Rjmp	vect				;a Timer/Counter1 Capture Event
	Rjmp	oc1a_int				;b Timer/Counter1 Compare Match A
	Rjmp	vect				;c Timer/Coutner1 Compare Match B
	Rjmp	t1_overflow				;d Timer/Counter1 Overflow
	Rjmp	vect				;e Timer/Counter0 Compare Match A
	Rjmp	vect				;f Timer/Counter0 Compare Match B
	rjmp	t0_ovfl				;10 Timer/Counter0 Overflow
	Rjmp	vect				;11 SPI Serial Transfer Complete
	Rjmp	vect				;12 USART Rx Complete
	Rjmp	vect				;13 USART, Data Register Empty
	Rjmp	vect				;14 USART, Tx Complete
	Rjmp	vect				;15 ADC Conversion Complete
	Rjmp	vect				;16 EEPROM Ready
	Rjmp	vect				;17 Analog Comparator
	Rjmp	vect				;18 2-wire Serial Interface
	Rjmp	vect				;19 Store Program Memory Ready
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



	rcall	timer_init

;	ldi		r16,0xff
;	out		CMD_DDR,r16
;	out		DATA_DDR,r16

	
	; key pad initialized
	cbi		KEY_DDR,KEY1
	cbi		KEY_DDR,KEY2
	cbi		KEY_DDR,KEY3
	cbi		KEY_DDR,KEY4
	sbi		KEY_PORT,KEY1
	sbi		KEY_PORT,KEY2
	sbi		KEY_PORT,KEY3
	sbi		KEY_PORT,KEY4
	
	sbi		SIGNAL_DDR,SIGNAL_P
	
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

	sei
;	out		DATA_PORT,zero
;	out		CMD_PORT,zero
	rcall	long_delay
	
	rcall	lcd_init
	ldi		r18,0x80
	ldi		r30,low(product_name*2)
	ldi		r31,high(product_name*2)
	rcall	lcd_puts

	rcall	long_long_delay
	cli
; load last esc selection
	ldi		r18,low(EEP_MENU_INDEX)
	ldi		r19,high(EEP_MENU_INDEX)
	rcall	eep_read
	ldi		r17,A_CODE
	cpi		r16,0
	breq	start_1
	ldi		r17,H_CODE
	cpi		r16,1
	breq	start_1
	ldi		r17,C_CODE
	cpi		r16,2
	breq	start_1
	ldi		r17,B_CODE
	cpi		r16,3
	breq	start_1
	ldi		r17,O_CODE
	ldi		r16,4
start_1:
	sts		mem_menu_index,r16
	sts		mem_esc_type_code+1,r17

	ldi		r18,low(EEP_MENU_INDEX+1)
	ldi		r19,high(EEP_MENU_INDEX+1)
	rcall	eep_read
	cpi		r16,ESC_TYPE_COUNT
	brcs	start_2
	clr		r16
start_2:
	sts		mem_menu_index+1,r16
	ldi		r30,low(esc_type*2)
	ldi		r31,high(esc_type*2)
	add		r30,r16
	adc		r31,zero
	lpm		r17,Z
	sts		mem_esc_type_code,r17
	

	ldi		r16,2
	sts		mem_menu_level,r16
	sts		mem_menu_selected,zero
	rcall	show_menu
; load last esc selection end	
	sei
; debug -------------------------------------------
.if 1==2	
X1:
	lds		r20,mem_temp
	lds		r21,mem_temp+1
	ldi		r16,0x11
	add		r20,r16
	adc		r21,zero
	sts		mem_temp,r20
	sts		mem_temp+1,r21
	ldi		r18,0xc8
	lds		r19,mem_temp+1
	rcall	lcd_put_hex
	ldi		r18,0xca
	lds		r19,mem_temp
	rcall	lcd_put_hex
	lds		r20,mem_temp
	lds		r21,mem_temp+1
	rcall	code_send
	rcall	long_long_delay
	rjmp	X1
.endif
; debug end ---------------------------------------
	
	rcall	long_delay
	lds		r_send_l,mem_esc_type_code
	lds		r_send_h,mem_esc_type_code+1
	rcall	code_send
;	ldi		r18,0x80
;	ldi		r30,low(aircraft*2)
;	ldi		r31,high(aircraft*2)
;	rcall	lcd_puts
;	ldi		r16,KEY_PATTERN
;	sts		mem_key,r16
main_loop:
	rcall	key_input

	cpi		r17,1
	breq	menu_left
	cpi		r17,4
	breq	menu_right
	cpi		r17,2
	breq	menu_up
	cpi		r17,3
	breq	menu_down
	rjmp	main_loop

menu_left:
	lds		r16,mem_menu_selected
	and		r16,r16
	breq	main_loop
	dec		r16
	sts		mem_menu_selected,r16
	rjmp	menu_end
menu_right:
	lds		r16,mem_menu_selected
	inc		r16
	sts		mem_menu_selected,r16
	rjmp	menu_end
menu_up:
	lds		r16,mem_menu_level
	and		r16,r16
	breq	main_loop
;	rcall	save_position
	dec		r16
	sts		mem_menu_level,r16
	rcall	correct_menu_item
	rjmp	menu_end
menu_down:
	lds		r16,mem_menu_level
	cpi		r16,3
	brcs	sm_md_2
	
	lds		r_send_l,mem_option_code
	lds		r_send_h,mem_option_code+1
	sbr		r29,1<<sending
	rjmp	menu_end1
sm_md_2:
	; 选择了电调类型，则保存当前的类型，以便下次开机时直接选择当前类型
	cpi		r16,1
	brne	sm_md_1
	cli
	ldi		r18,low(EEP_MENU_INDEX)
	ldi		r19,high(EEP_MENU_INDEX)
	lds		r16,mem_menu_index
	rcall	eep_write
	ldi		r18,low(EEP_MENU_INDEX+1)
	ldi		r19,high(EEP_MENU_INDEX+1)
	lds		r16,mem_menu_selected
	rcall	eep_write
	sbr		r29,1<<sending
	sei
sm_md_1:
	rcall	save_position
	inc		r16
	sts		mem_menu_level,r16
;	rcall	correct_menu_item
	
	sts		mem_menu_selected,zero
menu_end:
	rcall	show_menu
menu_end1:
	sbrc	r29,sending
	rcall	code_send
; debug -------------------------------------------
;	ldi		r18,1
;	rcall	lcd_put_cmd
;	ldi		r18,0x8e
;	rcall	show_menu_number
;	ldi		r18,0xcc
;	rcall	show_menu_index
; debug end ---------------------------------------
	
	rjmp	main_loop


infinity:
	rjmp	infinity
; 发送r20:r21中的值，系统阻塞
code_send:
	cbr		r29,1<<sending
cs_wait_falling_edge:
	sbis	PORTD,2
	rjmp	cs_wait_falling_edge
cs_wfe_1:
	sbic	PORTD,2
	rjmp	cs_wfe_1
	current_tcnt2 r16,r17
	sts		mem_send_tcnt2,r16
	sts		mem_send_tcnt2+1,r17
	movw	r18,r16
cs_start_signal:
	current_tcnt2 r16,r17
	sub		r16,r18
	sbc		r17,r19
	subi	r16,low(START_LEN)
	sbci	r17,high(START_LEN)
	brcs	cs_start_signal
	sbi		PORTD,2
	current_tcnt2 r16,r17
	movw	r18,r16
cs_ss_1:
	current_tcnt2 r16,r17
	sub		r16,r18
	sbc		r17,r19
	subi	r16,low(START_LEN)
	sbci	r17,high(START_LEN)
	brcs	cs_ss_1

	ldi		r22,16
cs_transfer:
	sbrs	r_send_h,7
	cbi		PORTD,2
	sbrc	r_send_h,7
	sbi		PORTD,2
	lsl		r_send_l
	rol		r_send_h
	
	current_tcnt2 r16,r17
	movw	r18,r16
cs_hold_signal:
	current_tcnt2 r16,r17
	sub		r16,r18
	sbc		r17,r19
	subi	r16,low(START_LEN*2)
	sbci	r17,high(START_LEN*2)
	brcs	cs_hold_signal
	
	dec		r22
	brne	cs_transfer
	
	cbi		PORTD,2
	
	ret
; 保存当前的菜单位置
save_position:
	lds		r16,mem_menu_level
	ldi		r30,low(mem_menu_index)
	ldi		r31,high(mem_menu_index)
	add		r30,r16
	adc		r31,zero
	lds		r17,mem_menu_selected
	st		Z,r17
	ret
; 把当前菜单层的选择项调整到 上次选择匹配
correct_menu_item:
	lds		r16,mem_menu_level
	ldi		r30,low(mem_menu_index)
	ldi		r31,high(mem_menu_index)
	add		r30,r16
	adc		r31,zero
	ld		r17,Z
	sts		mem_menu_selected,r17
	ret
key_input:
	sbrs	r29,key_delay
	rjmp	ki_1
; check delay
	current_tcnt0 r18,r19
	lds		r16,mem_key_tcnt0
	lds		r17,mem_key_tcnt0+1
	sub		r18,r16
	sbc		r19,r17
	
	ldi		r16,low(2048)		; 0.25 second
	ldi		r17,high(2048)
	cp		r18,r16
	cpc		r19,r17
	brcs	ki_exit

;	movw	r16,r18
;	ldi		r18,0xc2
;	mov		r19,r17
;	push	r16
;	rcall	lcd_put_hex
;	pop		r16
;	ldi		r18,0xc4
;	mov		r19,r16
;	rcall	lcd_put_hex

	; input acceptance
	cbr		r29,1<<key_delay
ki_1:
	ldi		r17,0
	sbis	KEY_PIN,KEY1
	ldi		r17,1
	sbis	KEY_PIN,KEY2
	ldi		r17,2
	sbis	KEY_PIN,KEY3
	ldi		r17,3
	sbis	KEY_PIN,KEY4
	ldi		r17,4
	and		r17,r17
	breq	ki_exit
	sbr		r29,1<<key_delay

	current_tcnt0 r18,r19
	sts		mem_key_tcnt0,r18
	sts		mem_key_tcnt0+1,r19
	
ki_exit:
	ret
; R18 ADDRESS
show_type:
	lds		r16,mem_esc_type_code+1
	cpi		r16,A_CODE
	brne	st_1
	ldi		r30,low(aircraft*2)
	ldi		r31,high(aircraft*2)
	rjmp	st_hx
st_1:
	cpi		r16,H_CODE
	brne	st_2
	ldi		r30,low(heli*2)
	ldi		r31,high(heli*2)
	rjmp	st_hx
st_2:
	cpi		r16,C_CODE
	brne	st_3
	ldi		r30,low(vehicle*2)
	ldi		r31,high(vehicle*2)
	rjmp	st_hx
st_3:
	cpi		r16,B_CODE
	brne	st_4
	ldi		r30,low(boat*2)
	ldi		r31,high(boat*2)
	rjmp	st_hx
st_4:
	ldi		r30,low(other*2)
	ldi		r31,high(other*2)
st_hx:
;	ldi		r18,0x80
	rcall	lcd_puts
	ret
; R18 ADDRESS
show_subtype:
	lds		r16,mem_esc_type_code
	and		r16,r16
	brne	st_5
	ldi		r30,low(no_chosen*2)
	ldi		r31,high(no_chosen*2)
;	ldi		r18,0x8A
	rcall	lcd_puts
	rjmp	st_exit
st_5:
	push	r18
	rcall	hex2bcd
	movw	r16,r18
	pop		r18
	rcall	lcd_put_bcd
	ldi		r18,'A'
	rcall	lcd_put_data
	
st_exit:
	ret

; in r16
; out r18:r19
hex2bcd:
	ldi		r17,100
	ldi		r18,0
	ldi		r19,0
h2b_1:
	cp		r16,r17
	brcc	h2b_2
	rjmp	h2b_10x
h2b_2:
	sub		r16,r17
	inc		r19
	rjmp	h2b_1
h2b_10x:
	ldi		r17,10
h2b_3:
	cp		r16,r17
	brcc	h2b_4
	rjmp	h2b_1x
h2b_4:
	sub		r16,r17
	subi	r18,-0x10
	rjmp	h2b_3
h2b_1x:
	add		r18,r16
	ret
timer_init:
; TIMER0 initializing
; clk/1024 use for key input delay
	ldi		r16,(1<<CS02)+(1<<CS00)
.ifdef	CPU_M8
	out		TCCR0,r16
	ldi		r16,(1<<TOIE0)+(1<<OCIE1A)+(1<<TOIE1)+(1<<TOIE2)
	out		TIMSK,r16		; T0 overflow interupt Enable
.else
	out		TCCR0B,r16

;	in		r16,TIMSK0
;	lds		r16,TIMSK0
	ldi		r16,1<<TOIE0
;	out		TIMSK0,r16
	sts		TIMSK0,r16
.endif
; TIMER1 initializing
; clk/8 use for PWM of idle signal
.ifdef	CPU_M8
	ldi		r16,(1<<WGM11)+(0<<WGM10)
	out		TCCR1A,r16
	ldi		r16,(1<<WGM13)+(1<<WGM12)+(0<<CS12)+(1<<CS11)+(0<<CS10)
	out		TCCR1B,r16
	; Top of t1
	ldi		r17,high(SIGNAL_LEN)
	ldi		r16,low(SIGNAL_LEN)
	out		ICR1H,r17
	out		ICR1L,r16
	ldi		r17,high(HEAD_LEN)
	ldi		r16,low(HEAD_LEN)
	out		OCR1AH,r17
	out		OCR1AL,r16
.else
	ldi		r16,(1<<WGM11)+(0<<WGM10)
	;out		TCCR1A,r16
	sts		TCCR1A,r16
	ldi		r16,(1<<WGM13)+(1<<WGM12)+(0<<CS12)+(1<<CS11)+(0<<CS10)
	;out		TCCR1B,r16
	sts		TCCR1B,r16

	ldi		r17,high(SIGNAL_LEN)
	ldi		r16,low(SIGNAL_LEN)
	;out		ICR1H,r17
	sts		ICR1H,r17
	;out		ICR1L,r16
	sts		ICR1L,r16

	ldi		r17,high(HEAD_LEN)
	ldi		r16,low(HEAD_LEN)
	;out		OCR1AH,r17
	sts		OCR1AH,r17
	;out		OCR1AL,r16
	sts		OCR1AL,r16
	
	ldi		r16,(1<<OCIE1A)+(1<<TOIE1)
	;out		TIMSK1,r16
	sts		TIMSK1,r16
	
.endif

; TIMER2 initializing
; clk/1 use for counting length of data frame
	ldi		r16,(0<<CS22)+(0<<CS21)+(1<<CS20)
.ifdef	CPU_M8
	out		TCCR2,r16
;	ldi		r16,(1<<TOIE0)+(1<<OCIE1A)+(1<<TOIE1)
;	out		TIMSK,r16		; T0 overflow interupt Enable
.else
	;out		TCCR2B,r16
	sts		TCCR2B,r16

	ldi		r16,1<<TOIE2
	;out		TIMSK2,r16
	sts		TIMSK2,r16
.endif

	ret

; interrupt route ---------------------------------------------------------------------------
t0_ovfl:
	in		i_sreg,SREG
	inc		tcnt0_h
	out		SREG,i_sreg
	reti
t2_ovfl:
	in		i_sreg,SREG
	inc		tcnt2_h
	out		SREG,i_sreg
	reti
t1_overflow:
	sbi		SIGNAL_PORT,SIGNAL_P
	reti
oc1a_int:
	cbi		SIGNAL_PORT,SIGNAL_P
	reti
; interupte route end -----------------------------------------------------------------------



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
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r17,mem_temp+1
	and		r17,r17
	breq	lpbcd_1
	add		r30,r17
	adc		r31,zero
	lpm		r18,Z
	rcall	lcd_put_data
lpbcd_1:
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
; r30:r31 ._option index
show_option_name:
;	ldi		r16,mem_menu_selected
;	add		r16,r16
;	add		r30,r16
;	add		r31,zero
	put_char 0xc0,'<'

	lpm		r16,Z+
	lds		r17,mem_menu_selected
	ldi		r18,0xc0
	and		r17,r17
	breq	son_x1
	inc		r18
son_x1:
	mov		r19,r16
	dec		r19
	cp		r17,r16
	brcs	son_1
	dec		r16
	mov		r17,r16
	sts		mem_menu_selected,r16
son_1:

	cp		r17,r19
	breq	son_2
	push	r18
	put_char 0xcf,'>'
	pop		r18
son_2:
	add		r17,r17
	add		r30,r17
	adc		r31,zero
	lpm		r16,Z+
	lpm		r17,Z
	; m_*_index store in r16:r17
	movw	r30,r16
	sts		mem_menu_lv3,r16
	sts		mem_menu_lv3+1,r17
	
	
	lpm		r16,Z+
	lpm		r17,Z
	; m_* store in r16:r17
	movw	r30,r16
	lpm		r16,Z+
	sts		mem_current_option_name,r30
	sts		mem_current_option_name+1,r31
	; option high of code
	sts		mem_option_code+1,r16
;	ldi		r18,0xc0
	rcall	lcd_puts
	ret

show_menu:
	; CLEAR SCREEN
	ldi		r18,1
	rcall	lcd_put_cmd

	lds		r16,mem_menu_level
	and		r16,r16
	breq	menu_lv0
	cpi		r16,1
	brne	sm_1
	rjmp	menu_lv1
sm_1:
	cpi		r16,2
	brne	sm_2
	rjmp	menu_lv2
sm_2:
	rjmp	menu_lv3
	ret

; 顶级菜单
menu_lv0:

	lds		r16,mem_menu_selected
	and		r16,r16
	brne	lv0_1
	put_char 0x8f,'>'
	ldi		r16,A_CODE
	ldi		r18,0x80
	rjmp	lv0_exit
lv0_1:
	cpi		r16,1
	brne	lv0_2
	put_char 0x80,'<'
	put_char 0x8f,'>'
	ldi		r18,0x81
	ldi		r16,H_CODE
	rjmp	lv0_exit
lv0_2:
	cpi		r16,2
	brne	lv0_3

	put_char 0x80,'<'
	put_char 0x8f,'>'

	ldi		r18,0x81
	ldi		r16,C_CODE
	rjmp	lv0_exit
lv0_3:
	cpi		r16,3
	brne	lv0_4

	put_char 0x80,'<'
	put_char 0x8f,'>'


	ldi		r18,0x81
	ldi		r16,B_CODE
	rjmp	lv0_exit
lv0_4:
;	cpi		r16,4
;	brne	lv0_5
	put_char 0x80,'<'

	ldi		r16,4
	sts		mem_menu_selected,r16
	ldi		r16,O_CODE
	ldi		r18,0x81
;	rjmp	lv0_exit
;lv0_5:

lv0_exit:
	sts		mem_esc_type_code+1,r16
;	ldi		r18,0x80
	rcall	show_type
	ret
; 一级菜单
menu_lv1:


	ldi		r18,0x80
	rcall	show_type

	lds		r16,mem_esc_type_code+1
	cpi		r16,O_CODE
	brne	lv1_skip
	ldi		r30,low(no_chosen*2)
	ldi		r31,high(no_chosen*2)
	ldi		r18,0xc0
	rcall	lcd_puts
	ret
lv1_skip:
	put_char 0xcf,'>'
	lds		r16,mem_menu_selected
	cpi		r16,13
	brcs	m_lv1_1
	ldi		r16,13
	sts		mem_menu_selected,r16
	put_char 0xcf,' '
m_lv1_1:
	and		r16,r16
	breq	m_lv1_2
	put_char 0xc0,'<'
	ldi		r18,0xc1
	rjmp	m_lv1_3
m_lv1_2:
	ldi		r18,0xc0
m_lv1_3:
	ldi		r30,low(esc_type*2)
	ldi		r31,high(esc_type*2)
	add		r30,r16
	adc		r31,zero
	lpm		r16,Z
	sts		mem_esc_type_code,r16
	lds		r_send_l,mem_esc_type_code
	lds		r_send_h,mem_esc_type_code+1
	rcall	show_subtype
	ret
; 二级菜单
menu_lv2:
	lds		r16,mem_esc_type_code+1
	cpi		r16,O_CODE
	brne	lv2_skip
	ldi		r16,1
	sts		mem_menu_level,r16
	rjmp	menu_lv1
lv2_skip:
	rcall	show_type_abbr
	lds		r16,mem_esc_type_code+1
	ldi		r30,low(a_options*2)
	ldi		r31,high(a_options*2)
	cpi		r16,A_CODE
	breq	lv2_end
	ldi		r30,low(h_options*2)
	ldi		r31,high(h_options*2)
	cpi		r16,H_CODE
	breq	lv2_end
	ldi		r30,low(v_options*2)
	ldi		r31,high(v_options*2)
	cpi		r16,C_CODE
	breq	lv2_end
	ldi		r30,low(b_options*2)
	ldi		r31,high(b_options*2)
	cpi		r16,B_CODE
	breq	lv2_end
	ldi		r30,low(o_options*2)
	ldi		r31,high(o_options*2)

lv2_end:
;	sts		mem_menu_lv3,r30
;	sts		mem_menu_lv3+1,r31
	rcall	show_option_name
	ret
show_type_abbr:
	ldi		r18,0x80
	rcall	lcd_put_cmd

	lds		r16,mem_esc_type_code+1
	ldi		r18,'A'
	cpi		r16,A_CODE
	breq	sta_end
	ldi		r18,'H'
	cpi		r16,H_CODE
	breq	sta_end
	ldi		r18,'C'
	cpi		r16,C_CODE
	breq	sta_end
	ldi		r18,'B'
	cpi		r16,B_CODE
	breq	sta_end
	ldi		r18,'O'
sta_end:
	rcall	lcd_put_data
	ldi		r18,0x82
	rcall	show_subtype
	ret
; 三级菜单
menu_lv3:
	rcall	show_type_abbr
	lds		r30,mem_current_option_name
	lds		r31,mem_current_option_name+1
	ldi		r18,0x88
	rcall	lcd_puts
	put_char 0xc0,'<'
	lds		r30,mem_menu_lv3
	lds		r31,mem_menu_lv3+1
	adiw	r30,2
	lpm		r17,Z
	adiw	r30,2
	; r17: total of menu
	lds		r16,mem_menu_selected
	; r16: current menu
	cp		r16,r17
	brcc	mlv3_1
	dec		r17
	rjmp	mlv3_2
mlv3_1:
	dec		r17
	sts		mem_menu_selected,r17
	mov		r16,r17
mlv3_2:
	cp		r16,r17
	breq	mlv3_3
	put_char 0xcf,'>'
mlv3_3:
	ldi		r18,0xc0
	lds		r16,mem_menu_selected
	and		r16,r16
	breq	mlv3_4
	inc		r18
mlv3_4:
	add		r16,r16
	add		r30,r16
	adc		r31,zero
	lpm		r16,Z+
	lpm		r17,Z
	movw	r30,r16
	lpm		r16,Z+
	sts		mem_option_code,r16
	rcall	lcd_puts
	ret
;debug ---------------------------------------------------------
show_menu_number:
	rcall	lcd_put_cmd
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r16,mem_menu_level
	cpi		r16,16
	brcs	smn_3
	ldi		r18,'*'
	rjmp	smn_4
smn_3:
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
smn_4:
	rcall	lcd_put_data

	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r16,mem_menu_selected
	cpi		r16,16
	brcs	smn_1
	ldi		r18,'*'
	rjmp	smn_2
smn_1:
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
smn_2:
	rcall	lcd_put_data
	ret
show_menu_index:
	rcall	lcd_put_cmd
	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r16,mem_menu_index
	cpi		r16,16
	brcs	smi_1
	ldi		r18,'*'
	rjmp	smi_2
smi_1:
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
smi_2:
	rcall	lcd_put_data

	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r16,mem_menu_index+1
	cpi		r16,16
	brcs	smi_3
	ldi		r18,'*'
	rjmp	smi_4
smi_3:
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
smi_4:
	rcall	lcd_put_data

	ldi		r30,low(hex*2)
	ldi		r31,high(hex*2)
	lds		r16,mem_menu_index+2
	cpi		r16,16
	brcs	smi_5
	ldi		r18,'*'
	rjmp	smi_6
smi_5:
	add		r30,r16
	adc		r31,zero
	lpm		r18,Z
smi_6:
	rcall	lcd_put_data
	ret
;debug ---------------------------------------------------------


product_name:
	.db "Program Box",0
no_chosen:
	.db "N/A",0
; code cosists of 8bits and high 4bits is fix 1000, low 4bits define as bellow

; name
.equ	A_CODE = 0x81
.equ	H_CODE = 0x82
.equ	C_CODE = 0x83
.equ	B_CODE = 0x84
.equ	O_CODE = 0x8f
aircraft:
	.db		"Aircraft",0,0
heli:
	.db		"Heli",0,0
vehicle:
	.db		"Vehicle",0
boat:
	.db		"Boat",0,0
other:
	.db		"Other",0


.equ	ESC_TYPE_COUNT = 14
esc_type:
	.db		10,20,30,40,50,60,70,80,100,120,140,160,200,250

a_options:
	.db		8,low(m_brake_index*2),high(m_brake_index*2),\
			low(m_cv_ccv_index*2),high(m_cv_ccv_index*2),\
			low(m_timing_index*2)
	.db		high(m_timing_index*2),\
			low(m_accel_index*2),high(m_accel_index*2),\
			low(m_lipo_cells_index*2),
	.db		high(m_lipo_cells_index*2),\
			low(m_rcp_low_index*2),high(m_rcp_low_index*2),\
			low(m_rcp_high_index*2),high(m_rcp_high_index*2),\
			low(m_pwm_index*2),high(m_pwm_index*2),0

h_options:
	.db		9,low(m_brake_index*2),high(m_brake_index*2),\
			low(m_cv_ccv_index*2),high(m_cv_ccv_index*2),\
			low(m_timing_index*2)
	.db		high(m_timing_index*2),\
			low(m_accel_index*2),high(m_accel_index*2),\
			low(m_lipo_cells_index*2)
	.db		high(m_lipo_cells_index*2),\
			low(m_rcp_low_index*2),high(m_rcp_low_index*2),\
			low(m_rcp_high_index*2)
	.db		high(m_rcp_high_index*2),\
			low(m_governor_index*2),high(m_governor_index*2),\
			low(m_pwm_index*2),high(m_pwm_index*2),0
v_options:
	.db		6,low(m_timing_index*2),high(m_timing_index*2),\
			low(m_cv_ccv_index*2),high(m_cv_ccv_index*2),\
			low(m_reverse_index*2)
	.db		high(m_reverse_index*2),\
			low(m_accel_index*2),high(m_accel_index*2),\
			low(m_protected_v_index*2),high(m_protected_v_index*2),\
			low(m_pwm_index*2),high(m_pwm_index*2),0
b_options:
	.db		8,low(m_timing_index*2),high(m_timing_index*2),\
			low(m_cv_ccv_index*2),high(m_cv_ccv_index*2),\
			low(m_reverse_index*2)
	.db		high(m_reverse_index*2),\
			low(m_accel_index*2),high(m_accel_index*2),\
			low(m_lipo_cells_index*2)
	.db		high(m_lipo_cells_index*2),\
			low(m_rcp_low_index*2),high(m_rcp_low_index*2),\
			low(m_rcp_high_index*2),high(m_rcp_high_index*2),\
			low(m_pwm_index*2),high(m_pwm_index*2),0
o_options:
	.db		0,0

; option structure
; ============================================================
; * CV/CCV
; ============================================================

m_cv_ccv:
	.db		25,"CV/CCV",0
mm_cv_ccv_1:
	.db		1,"CV",0
mm_cv_ccv_2:
	.db		2,"CCV",0,0
m_cv_ccv_index:
	.dw		m_cv_ccv*2
	.dw		2
	.dw		mm_cv_ccv_1*2
	.dw		mm_cv_ccv_2*2
; ============================================================
; * brake
; ============================================================
m_brake:
	.db		0x08,"Brake",0,0
mm_no_1:
	.db		0x01,"No",0
mm_very_soft_2:
	.db		0x02,"Very soft",0,0
mm_soft_3:
	.db		0x03,"Soft",0
mm_medium_4:
	.db		0x04,"Medium",0
mm_hard_5:
	.db		0x05,"Hard",0
mm_very_hard_6:
	.db		0x06,"Very hard",0,0
m_brake_index:
	.dw		m_brake*2
	.dw		6
	.dw		mm_no_1*2
	.dw		mm_very_soft_2*2
	.dw		mm_soft_3*2
	.dw		mm_medium_4*2
	.dw		mm_hard_5*2
	.dw		mm_very_hard_6*2


; ============================================================
; * timing
; ============================================================
m_timing:
	.db		0x0e,"Timing",0
mm_timing_1:
	.db		1,"0 degree",0
mm_timing_2:
	.db		8,"8 degree",0
mm_timing_3:
	.db		15,"15 degree",0,0
mm_timing_4:
	.db		30,"30 degree",0,0
m_timing_index:
	.dw		m_timing*2
	.dw		4
	.dw		mm_timing_1*2
	.dw		mm_timing_2*2
	.dw		mm_timing_3*2
	.dw		mm_timing_4*2


; ============================================================
; * reverse
; ============================================================
m_reverse:
	.db		0x08,"Reverse",0,0
mm_reverse_1:
	.db		1,"No",0
mm_reverse_2:
	.db		2,"100%",0
mm_reverse_3:
	.db		3,"50%",0,0
mm_reverse_4:
	.db		4,"25%",0,0

m_reverse_index:
	.dw		m_reverse*2,4,mm_reverse_1*2,mm_reverse_2*2,mm_reverse_3*2,mm_reverse_4*2

; ============================================================
; * pwm
; ============================================================
m_pwm:
	.db		15,"PWM",0,0
mm_pwm_1:
	.db		1,"8M",0
mm_pwm_2:
	.db		2,"16M",0,0
mm_pwm_3:
	.db		3,"32M",0,0
m_pwm_index:
	.dw		m_pwm*2,3,mm_pwm_1*2,mm_pwm_2*2,mm_pwm_3*2

; ============================================================
; * acceleration
; ============================================================
m_accel:
	.db		0x10,"Acceleration",0
m_accel_index:
	.dw		m_accel*2,6,mm_no_1*2,mm_very_soft_2*2,mm_soft_3*2,mm_medium_4*2,mm_hard_5*2,mm_very_hard_6*2


; ============================================================
; * Lipo Cells
; ============================================================
m_lipo_cells:
	.db		19,"Lipo Cells",0
mm_auto_1:
	.db		1,"Auto",0
mm_2s_2:
	.db		2,"2s",0
mm_4s_3:
	.db		3,"4s",0
mm_6s_4:
	.db		4,"6s",0
mm_8s_5:
	.db		5,"8s",0
mm_10s_6:
	.db		6,"10s",0,0
mm_12s_7:
	.db		7,"12s",0,0
m_lipo_cells_index:
	.dw		m_lipo_cells*2
	.dw		7
	.dw		mm_auto_1*2
	.dw		mm_2s_2*2
	.dw		mm_4s_3*2
	.dw		mm_6s_4*2
	.dw		mm_8s_5*2
	.dw		mm_10s_6*2
	.dw		mm_12s_7*2


; ============================================================
; * Protected Voltage
; ============================================================
m_protected_v:
	.db		21,"Protected Voltag",0
mm_55v_1:
	.db		1,"5.5V",0
mm_60v_1:
	.db		2,"6V",0
mm_90v_1:
	.db		3,"9V",0
mm_120v_1:
	.db		4,"12V",0,0
m_protected_v_index:
	.dw		m_protected_v*2,4,mm_55v_1*2,mm_60v_1*2,mm_90v_1*2,mm_120v_1*2


; ============================================================
; * RCP Low
; ============================================================
m_rcp_low:
	.db		22,"RCP Low",0,0
mm_rcp_low_1:
	.db		1,"Auto",0
mm_rcp_low_2:
	.db		2,"1.0",0,0
mm_rcp_low_3:
	.db		3,"1.1",0,0
mm_rcp_low_4:
	.db		4,"1.2",0,0
mm_rcp_low_5:
	.db		5,"1.3",0,0
m_rcp_low_index:
	.dw		m_rcp_low*2,5,mm_rcp_low_1*2,mm_rcp_low_2*2,mm_rcp_low_3*2,mm_rcp_low_4*2,mm_rcp_low_5*2

; ============================================================
; * RCP High
; ============================================================
m_rcp_high:
	.db		22,"RCP High",0
mm_rcp_high_1:
	.db		1,"Auto",0
mm_rcp_high_2:
	.db		2,"1.7",0,0
mm_rcp_high_3:
	.db		3,"1.8",0,0
mm_rcp_high_4:
	.db		4,"1.9",0,0
mm_rcp_high_5:
	.db		5,"2.0",0,0
m_rcp_high_index:
	.dw		m_rcp_high*2,5,mm_rcp_high_1*2,mm_rcp_high_2*2,mm_rcp_high_3*2,mm_rcp_high_4*2,mm_rcp_high_5*2

; ============================================================
; * Governor Mode
; ============================================================
m_governor:
	.db		12,"Governor",0
mm_on_1:
	.db		1,"On",0
mm_off_2:
	.db		2,"Off",0,0
m_governor_index:
	.dw		m_governor*2,2,mm_on_1*2,mm_off_2*2


m_lipo_volt:
	.db		"Lipo Voltage",0,0
m_cut_off:
	.db		"Cut Off",0


hex:
	.db		"0123456789ABCDEF"

.exit

