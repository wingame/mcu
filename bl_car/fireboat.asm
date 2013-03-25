; fireboat.asm
; 关闭了电压保护
;        +---------+         +---------+
;  Vcc---|  R1:47K |----+----| R2:2k   |----| GND
;        +---------+    |    +---------+
;                   ---------
;                   ADC input
; max voltage = ADC voltage max / R1 * (R1+R2) = 1.1 / 2 * (47 + 2) = 26.95v
; ADC VOLTAGE MAX(ATMega 48) = 1.1v


; 2013-3-24
; 修正：中杆，关闭发射机时，由于干扰，会偶尔发生电机异常启动然后停机的现象，
; 		专为这个BUG，添加了返回bad rcp的机制。用于判断连续的正常RCP。
;		修改了 
;		1. evaluate_rcp0中由停止到启动的逻辑。
;		2. int0中断中断rcp接收增加了rcp0_cycle
;		3. rcp0_updated方法

.include "m48def.inc"

.def	zero		= r0
.def	i_sreg		= r1
.def	tcnt0h		= r2
.def	idle_cnt	= r3
.def	rcp0_l		= r4
.def	rcp0_h		= r5
.def	battery_check_cnt = r6
;def	rcp1_resume_cnt = r7

.def	pwm_duty_l	=r10
.def	pwm_duty_h	=r11

;PORTB
.equ	FORWARD_N1	= 0
.equ	FORWARD_N2	= 1
.equ	FORWARD_N3	= 2
;PORTD
.equ	FORWARD_P	= 0
.equ	WATER_PUMP	= 5
.equ	REVERSE_P	= 1
;PORTC
.equ	REVERSE_N1	= 4
.equ	REVERSE_N2	= 5


;.equ	SHUTDOWN_VOLT = 190		; 5V
.equ	PROTECT_VOLT = 	387		; 10.2V


.equ	PWM_TOP		= 4194

.equ	PWM_MIN		= 335


;.equ	SETTING_RCP_H = 26000		;3100
;.equ	SETTING_RCP_L = 24326		;2900

.equ	RCP_MAX_X	= 19293			;2300
.equ	RCP_MIN_X	= 5872			;700

.equ	RCP1_SW_L	= 12163			;1450
.equ	RCP1_SW_H	= 13002			;1550

.equ	RCP_MAX		= 14500			; 1850
.equ	RCP_MIN		= 9646			; 1150
.equ	RCP_MID_L	= 10905
.equ	RCP_MID_H	= 13841
.equ	RCP_IDLE_ZONE = 410			; 30ns

.equ	PWM_INCREMENT = 200


.equ	IDLE_COUNT	= 10

;GPIOR0
; 0 forward, 1 reverse
.equ	motor_reverse		= 0
.equ	motor_idle			= 1
.equ	rcp0_ready			= 2
.equ	enabled_water_pump	= 3
.equ	full_power			= 4
.equ	power_failed		= 5
.equ	rcp0_cycle			= 6
.equ	rcp0_pre_run		= 7

.macro	commit_pwm
	sts		OCR1AH,@1
	sts		OCR1AL,@0
.endm
.macro	pause_t1
	ldi		@0,(1<<WGM13)+(1<<WGM12)
	sts		TCCR1B,@0
.endm
.macro	resume_t1
	ldi		@0,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
	sts		TCCR1B,@0
.endm
.macro	forward_n_off
	in		@0,PORTB
	cbr		@0,(1<<FORWARD_N1)+(1<<FORWARD_N3)+(1<<FORWARD_N2)
	out		PORTB,@0
.endm

.macro	reverse_n_off
	in		@0,PORTC
	cbr		@0,(1<<REVERSE_N1)+(1<<REVERSE_N2)
	out		PORTC,@0
.endm

.macro	forward
	in		@0,PORTB
	sbr		@0,(1<<FORWARD_N1)+(1<<FORWARD_N3)+(1<<FORWARD_N2)
	out		PORTB,@0
	sbi		PORTD,FORWARD_P
.endm
.macro	reverse
	in		@0,PORTC
	sbr		@0,(1<<REVERSE_N1)+(1<<REVERSE_N2)
	out		PORTC,@0
	sbi		PORTD,REVERSE_P
.endm
.macro	idle
	in		@0,PORTD
	cbr		@0,(1<<FORWARD_P)+(1<<REVERSE_P)
	out		PORTD,@0
	in		@0,PORTB
	cbr		@0,(1<<FORWARD_N1)+(1<<FORWARD_N3)+(1<<FORWARD_N2)
	out		PORTB,@0
	in		@0,PORTC
	cbr		@0,(1<<REVERSE_N1)+(1<<REVERSE_N2)
	out		PORTC,@0
.endm

.dseg
mem_temp1:		.byte 1
mem_rcp0_temp:	.byte 2
mem_rcp1_temp:	.byte 2

; count good rcp0 in continusouly
mem_rcp0_count:	.byte 1
mem_run_confirm_count: .byte 1
.equ		GOOD_RCP0_COUNT= 4
.equ		RUN_CONFIRM_COUNT=4

mem_a:			.byte 2
mem_b:			.byte 2
mem_c:			.byte 2

mem_rcp0_neutral: .byte 2

mem_rcp1:		.byte 2		; water pump rcp value
mem_shutdown_cnt: .byte 1
.equ		SHUTDOWN_COUNT = 10


;mem_rcp0_err_cnt:	.byte 1
;mem_rcp1_err_cnt:	.byte 1

;DEBUG ***********************************************
mem_debug_data:		.byte 100
mem_debug_idx:		.byte 1
;DEBUG END *******************************************

.cseg
.equ		RCP_ERROR_COUNT	= 100

.org 0
; M48 Interrupt Lists
	Rjmp	reset
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
	reti
; interrupts route ---------------------------------------------------------------
timer1_compa:
	in		i_sreg,SREG
	sbis	GPIOR0,motor_reverse
	rjmp	forward_off
	reverse_n_off r20
	rjmp	t1_cpa_exit
forward_off:
	forward_n_off r20
t1_cpa_exit:
	out		SREG,i_sreg
	reti

timer1_ovf:
	in		i_sreg,SREG
	sbis	GPIOR0,motor_reverse
	rjmp	forward_on
	; reverse
	reverse	r20
	rjmp	t1_ovf_exit
forward_on:
	forward	r20
t1_ovf_exit:
	out		SREG,i_sreg
	reti

timer0_ovf:
	in		i_sreg,SREG
	inc		tcnt0h
	brne	t0_ovf_exit
	in		r20,GPIOR1
	and		r20,r20
	breq	t0_skip1
	dec		r20
	out		GPIOR1,r20
t0_skip1:
	in		r20,GPIOR2
	and		r20,r20
	breq	t0_ovf_exit
	dec		r20
	out		GPIOR2,r20

t0_ovf_exit:
	out		SREG,i_sreg
	reti

ext0_int:
;	cbi		PORTD,WATER_PUMP
	in		i_sreg,SREG
	in		r20,TCNT0
	mov		r21,tcnt0h
	sbis	TIFR0,TOV0
	rjmp	int0_1
	in		r20,TCNT0
	inc		r21
int0_1:
	lds		r22,mem_rcp0_temp
	lds		r23,mem_rcp0_temp+1
	sts		mem_rcp0_temp,r20
	sts		mem_rcp0_temp+1,r21
	
	sub		r20,r22
	sbc		r21,r23

	lds		r22,EICRA
	sbrs	r22,ISC00
	rjmp	int0_2
	; 上升弦触发,下一次中断必须改为下降弦
	; triggered by falling edge at next time
	lds		r23,EICRA
	sbr		r23,(1<<ISC01)
	cbr		r23,(1<<ISC00)
	sts		EICRA,r23
	cbi		GPIOR0,rcp0_ready
	rjmp	int0_exit
int0_2:
	sbi		GPIOR0,rcp0_cycle
	lds		r23,EICRA
	sbr		r23,(1<<ISC01)+(1<<ISC00)
	sts		EICRA,r23
	movw	rcp0_l,r20
	

	; if(r20:r21 > RCP_LOW && r20:r21 < RCP_HIGH) goto int0_rcp_ready
	subi	r20,low(RCP_MIN_X)
	sbci	r21,high(RCP_MIN_X)
	subi	r20,low(RCP_MAX_X-RCP_MIN_X)
	sbci	r21,high(RCP_MAX_X-RCP_MIN_X)
	brcs	int0_rcp0_ready
;	cbi		GPIOR0,rcp0_ready
	rjmp	int0_exit
int0_rcp0_ready:
	ldi		r20,RCP_ERROR_COUNT
	out		GPIOR1,r20
	sbi		GPIOR0,rcp0_ready
int0_exit:
	out		SREG,i_sreg
	reti


ext1_int:
	in		i_sreg,SREG
	
	in		r20,TCNT0
	mov		r21,tcnt0h
	sbis	TIFR0,TOV0
	rjmp	int1_1
	in		r20,TCNT0
	inc		r21
int1_1:
	lds		r22,mem_rcp1_temp
	lds		r23,mem_rcp1_temp+1
	sts		mem_rcp1_temp,r20
	sts		mem_rcp1_temp+1,r21
	
	sub		r20,r22
	sbc		r21,r23

	lds		r22,EICRA
	sbrs	r22,ISC10
	rjmp	int1_2
	; 上升弦触发,下一次中断必须改为下降弦
	; triggered by falling edge at next time
	lds		r23,EICRA
	cbr		r23,(1<<ISC10)
	sbr		r23,(1<<ISC11)
	sts		EICRA,r23
	rjmp	int1_exit
int1_2:
	lds		r23,EICRA
	sbr		r23,(1<<ISC11)+(1<<ISC10)
;	ldi		r23,(1<<ISC01)+(1<<ISC00)
	sts		EICRA,r23
	movw	r22,r20
;	sts		mem_rcp1,r20
;	sts		mem_rcp1+1,r21
	



	; if(r20:r21 > RCP_LOW && r20:r21 < RCP_HIGH) goto int0_rcp_ready
	subi	r20,low(RCP_MIN_X)
	sbci	r21,high(RCP_MIN_X)
	subi	r20,low(RCP_MAX_X-RCP_MIN_X)
	sbci	r21,high(RCP_MAX_X-RCP_MIN_X)
	brcs	int1_rcp_ready
;	cbi		GPIOR0,rcp1_ready
	rjmp	int1_exit
int1_rcp_ready:
;debug *********************************************
;	push	r16
;	push	r17
;	movw	r16,r22
;	rcall	save_word
;	pop		r17
;	pop		r16
;debug end *****************************************


	ldi		r20,RCP_ERROR_COUNT
	out		GPIOR2,r20
;	sbi		GPIOR0,rcp1_ready
	sbis	PORTD,WATER_PUMP
	rjmp	wp_current_off
	ldi		r20,low(RCP1_SW_L)
	ldi		r21,high(RCP1_SW_L)
	cp		r22,r20
	cpc		r23,r21
	brcc	int1_exit
	cbi		PORTD,WATER_PUMP
	rjmp	int1_exit
wp_current_off:
	ldi		r20,low(RCP1_SW_H)
	ldi		r21,high(RCP1_SW_H)
	cp		r22,r20
	cpc		r23,r21
	brcs	int1_exit

	sbic	GPIOR0,enabled_water_pump
	sbi		PORTD,WATER_PUMP
; debug -----------------------------------------------
;	rcall	debug_adc
; debug -----------------------------------------------
int1_exit:
	out		SREG,i_sreg
	reti
; interrupts route end ------------------------------------------------------------

reset:
	clr	zero
	out	SREG, zero		; Clear interrupts and flags
	; Set up stack
	ldi	ZH, high(RAMEND)
	ldi	ZL, low (RAMEND)
	out	SPH, ZH
	out	SPL, ZL
	
	rcall	short_delay
	rcall	init_port
	rcall	init_timer0
	rcall	init_timer1
	rcall	init_extint
	rcall	init_adc7
	
	sts		mem_rcp0_neutral+1,zero

;debug ******************************************************
;PORTB
;.equ	FORWARD_N1	= 0
;.equ	FORWARD_N2	= 1
;.equ	FORWARD_N3	= 2
;PORTD
;.equ	FORWARD_P	= 0
;.equ	WATER_PUMP	= 5
;.equ	REVERSE_P	= 1
;;PORTC
;.equ	REVERSE_N1	= 4
;.equ	REVERSE_N2	= 5


	sts		mem_debug_idx,zero
;	sbi		PORTD,WATER_PUMP
;	ldi		r16,0xff
;	out		PORTB,r16
;	out		PORTD,r16
;	out		PORTc,r16
;stop: rjmp stop
;debug end **************************************************



	sei
rcp0_resume:
	ldi		r17,50
find_nuetral_pos:
	rcall	rcp0_updated
;	sbis	GPIOR0,rcp0_ready
;	rjmp	find_nuetral_pos
;	cbi		GPIOR0,rcp0_ready
	movw	r18,rcp0_l
	subi	r18,low(RCP_MID_L)
	sbci	r19,high(RCP_MID_L)
	subi	r18,low(RCP_MID_H-RCP_MID_L)
	sbci	r19,high(RCP_MID_H-RCP_MID_L)
	brcc	find_nuetral_pos
	dec		r17
	brne	find_nuetral_pos


	lds		r16,mem_rcp0_neutral+1
	and		r16,r16
	brne	fnp_1
	sts		mem_rcp0_neutral,rcp0_l
	sts		mem_rcp0_neutral+1,rcp0_h
fnp_1:
;	movw	r16,rcp0_l
;	rcall	save_word
;	rjmp	data_to_eep
;	cbi		GPIOR0,motor_reverse
;	ldi		r16,low(1600)
;	ldi		r17,high(1600)
;	commit_pwm r16,r17
;	resume_t1 r16
;	rcall	short_delay
;	rcall	short_delay
;	pause_t1 r16
;	idle	r16
;	rcall	short_delay
;	sbi		GPIOR0,motor_reverse
;	resume_t1 r16
;	rcall	short_delay
;	rcall	short_delay
	pause_t1 r16
	rcall	start_beep

	idle	r16
	sbi		GPIOR0,enabled_water_pump
main_loop:
;debug **********************************************
;	lds		r16,mem_debug_idx
;	cpi		r16,100
;	brne	xxxx
;	rjmp	data_to_eep
;xxxx:
;debug end ******************************************
;	sbis	GPIOR0,rcp0_ready
;	rjmp	main_loop
;	cbi		GPIOR0,rcp0_ready
	rcall	rcp0_updated
	sbis	GPIOR0,rcp0_ready
	rjmp	bad_rcp0
good_rcp0:
	lds		r16,mem_rcp0_count
	and		r16,r16
	breq	ml_0
	dec		r16
	sts		mem_rcp0_count,r16
	rjmp	ml_0
bad_rcp0:
	ldi		r16,GOOD_RCP0_COUNT
	sts		mem_rcp0_count,r16
	rjmp	ml_3
ml_0:	
	and		idle_cnt,idle_cnt
	breq	ml_1
	dec		idle_cnt
ml_1:
	inc		battery_check_cnt
	rcall	check_battery
	sbic	GPIOR0,power_failed
	rjmp	ml_motor_idle
	rcall	evaluate_rcp0
	sbis	GPIOR0,motor_idle
	rjmp	ml_motor_engage
ml_motor_idle:
	pause_t1 r16
	idle	r16

; 马达停止时，一直重置停止计数器。
	
	sbic	GPIOR0,rcp0_pre_run
	rjmp	main_loop
ml_3:
	; RCP信号错误和中杆位置都会一直重置这个值。
	ldi		r16,RUN_CONFIRM_COUNT
	sts		mem_run_confirm_count,r16

	rjmp	main_loop
ml_motor_engage:
; confirm run motor
	


	commit_pwm pwm_duty_l,pwm_duty_h
	resume_t1 r16
	rjmp	main_loop

rcp0_lost:
	cbi		GPIOR0,enabled_water_pump
	cbi		PORTD,WATER_PUMP
	pause_t1 r16
	idle	r16
	ldi		r16,50
rcp0_lost_1:
	sbis	GPIOR0,rcp0_ready
	rjmp	rcp0_lost_1
	cbi		GPIOR0,rcp0_ready
	dec		r16
	brne	rcp0_lost_1
	rjmp	rcp0_resume

rcp0_updated:
	in		r16,GPIOR1
	and		r16,r16
	brne	ru_1
	pop		r16
	pop		r16
	rjmp	rcp0_lost
ru_1:
	sbis	GPIOR0,rcp0_cycle
	rjmp	rcp0_updated
	cbi		GPIOR0,rcp0_cycle
	ret

infinity:
	rjmp	infinity
init_extint:
	;rising edge 
;	ldi		r16,(1<<ISC11)+(1<<ISC10)+(1<<ISC01)+(1<<ISC00)
;	ldi		r16,(1<<ISC01)+(1<<ISC00)
;	sts		EICRA,r16
	ldi		r16,(1<<INT1)+(1<<INT0)
	out		EIMSK,r16
	ret
init_port:
	ldi		r16,(1<<FORWARD_N1)+(1<<FORWARD_N3)+(1<<FORWARD_N2)
	out		DDRB,r16
	ldi		r16,(1<<REVERSE_N1)+(1<<REVERSE_N2)
	out		DDRC,r16
	ldi		r16,(1<<FORWARD_P)+(1<<REVERSE_P)+(1<<WATER_PUMP)
	out		DDRD,r16
	ret
init_timer0:
;TCCR0A[COM0A1:COM0A0:COM0B1:COM0B0:-:-:WGM01:WGM00]
;TCCR0B[FOC0A:FOC0B:-:-:WGM02:CS02:CS01:CS00]
;WGM02:0 = 000 NORMAL MODE
;CS02:0  = 001 No prescaler
	out		TCCR0A,zero
	ldi		r16,(1<<CS00)
	out		TCCR0B,r16
;TIMSK0[-:-:-:-:-:OCIE0B:OCIE0A:TOIE0]
	ldi		r16,(1<<TOIE0)
	sts		TIMSK0,r16
	ret
init_timer1:
;TCCR1A[COM1A1:COM1A0:COM1B1:COM1B0: - : - :WGM11:WGM10]
	ldi		r16,(1<<WGM11)
	sts		TCCR1A,r16
;TCCR1B[ICNC1:ICNS1:-:WGM13:WGM12:CS12:CS11:CS10]
	ldi		r16,(1<<WGM13)+(1<<WGM12)
	sts		TCCR1B,r16
	
;TIMSK1[-:-:ICIE1:-:-:OCIE1B:OCIE1A:TOIE1]
	ldi		r16,(1<<OCIE1A)+(1<<TOIE1)
	sts		TIMSK1,r16


	ldi		r16,high(PWM_TOP)
	sts		ICR1H,r16
	ldi		r16,low(PWM_TOP)
	sts		ICR1L,r16
	ret

init_adc7:
;ADMUX[REFS1:REFS0:ADLAR: - :MUX3:MUX2:MUX1:MUX0]
	ldi		r16,(1<<REFS1)+(1<<REFS0)+(1<<MUX2)+(1<<MUX1)+(1<<MUX0)
	sts		ADMUX,r16
;ADCSRA[ADEN:ADSC:ADATE:ADIF:ADIE:ADPS2:ADPS1:ADPS0]
	ldi		r16,(1<<ADEN)+(1<<ADSC)+(1<<ADATE)+(1<<ADPS2)+(1<<ADPS1)+(1<<ADPS0)
	sts		ADCSRA,r16
;ADCSRB[ - : ACME : - : - : - :ADTS2:ADTS1:ADTS0]
	sts		ADCSRB,zero
	ret

check_battery:
;	sbi		GPIOR0,enabled_water_pump
	ret
	ldi		r16,5
	cp		battery_check_cnt,r16
	brcs	check_battery_exit
	mov		battery_check_cnt,zero
;ADCSRA[ADEN:ADSC:ADATE:ADIF:ADIE:ADPS2:ADPS1:ADPS0]

;	lds		r16,ADCSRA
;	sbrc	r16,ADSC
;	ret
	; set ADIF to clear itself.
;	sbr		r16,1<<ADSC
;	sts		ADCSRA,r16
	lds		r16,ADCL
	lds		r17,ADCH

;	sbi		PORTD,WATER_PUMP
;	rcall	short_delay
;	cbi		PORTD,WATER_PUMP
;	rcall	short_delay
	ldi		r18,low(PROTECT_VOLT)
	ldi		r19,high(PROTECT_VOLT)
	cp		r16,r18
	cpc		r17,r19
	brcc	cb_1
	cbi		GPIOR0,enabled_water_pump
	cbi		PORTD,WATER_PUMP
	sbi		GPIOR0,power_failed
	rjmp	check_battery_exit
cb_1:
	sbi		GPIOR0,enabled_water_pump
	cbi		GPIOR0,power_failed
check_battery_exit:
	ret
;  a     b
; --- = ---
;  x     c
; a = mem_a, b = mem_b, c = mem_c
; x = r26:r27 为结果
; a = current rcp
; b = max rcp
; c = top pwm
x_function:
	clr		r26
	clr		r27
    rjmp	x_2
x_1:
	lds		r16,mem_c
	lds		r17,mem_c+1
	lsr		r17
	ror		r16
	sts		mem_c,r16
	sts		mem_c+1,r17
	cpi		r16,0
	cpc		r17,zero
    breq	x_3
	lds		r16,mem_b
	lds		r17,mem_b+1
	lsr		r17
	ror		r16
	sts		mem_b,r16
	sts		mem_b+1,r17
x_2:
	lds		r18,mem_a
	lds		r19,mem_a+1
	lds		r16,mem_b
	lds		r17,mem_b+1
    sub		r18,r16
    sbc		r19,r17
    brcs	x_1
	sts		mem_a,r18
	sts		mem_a+1,r19
	lds		r16,mem_c
	lds		r17,mem_c+1
    add		r26,r16
    adc		r27,r17
    rjmp	x_1
x_3:
	ret


evaluate_rcp0:
	lds		r16,mem_rcp0_neutral
	lds		r17,mem_rcp0_neutral+1
	ldi		r18,low(RCP_IDLE_ZONE)
	ldi		r19,high(RCP_IDLE_ZONE)
	add		r18,r16
	adc		r19,r17
	cp		rcp0_l,r18
	cpc		rcp0_h,r19
	brcc	high_rcp
	ldi		r18,low(RCP_IDLE_ZONE)
	ldi		r19,high(RCP_IDLE_ZONE)
	sub		r16,r18
	sbc		r17,r19
	cp		rcp0_l,r16
	cpc		rcp0_h,r17
	brcs	rcp_low_pos


;	sbi		PORTD,WATER_PUMP
;	rcall	short_delay
;	cbi		PORTD,WATER_PUMP
;	rcall	short_delay

; rcp0 neutral position
	sbic	GPIOR0,motor_idle
	rjmp	eva_rcp0_exit
go_idle:
	ldi		r16,IDLE_COUNT
	mov		idle_cnt,r16
	sbi		GPIOR0,motor_idle
	cbi		GPIOR0,rcp0_pre_run
	rjmp	eva_rcp0_exit
rcp_low_pos:
; rcp0 low position
	sbis	GPIOR0,motor_idle
	rjmp	r_check_dir
	and		idle_cnt,idle_cnt
	breq	pre_reverse
	rjmp	eva_rcp0_exit
r_check_dir:

	sbis	GPIOR0,motor_reverse
	rjmp	go_idle
	rjmp	go_reverse
	
pre_reverse:
	; 上次状态为停止。在转动马达之前需要确认是否是干扰
	sbi		GPIOR0,rcp0_pre_run
	lds		r16,mem_run_confirm_count
	and		r16,r16
	breq	go_reverse
	dec		r16
	sts		mem_run_confirm_count,r16
	rjmp	eva_rcp0_exit
go_reverse:
	sbi		GPIOR0,motor_reverse
	ldi		r16,low(RCP_MIN)
	ldi		r17,high(RCP_MIN)
	cp		rcp0_l,r16
	cpc		rcp0_h,r17
	brcc	g_rev_1
	ldi		r26,low(PWM_TOP)
	ldi		r27,high(PWM_TOP)
	rjmp	post_calc_pwm
g_rev_1:
	lds		r16,mem_rcp0_neutral
	lds		r17,mem_rcp0_neutral+1
	movw	r18,r16
	sub		r16,rcp0_l
	sbc		r17,rcp0_h
	lsr		r17
	ror		r16
	sts		mem_a,r16
	sts		mem_a+1,r17
	ldi		r16,low(RCP_MIN)
	ldi		r17,high(RCP_MIN)
	sub		r18,r16
	sbc		r19,r17
	sts		mem_b,r18
	sts		mem_b+1,r19
	
	rjmp	calc_pwm
high_rcp:
; rcp0 high position
	sbis	GPIOR0,motor_idle
	rjmp	f_check_dir
	and		idle_cnt,idle_cnt
	breq	pre_forward
	rjmp	eva_rcp0_exit
pre_forward:
	; 上次状态为停止。在转动马达之前需要确认是否是干扰
	sbi		GPIOR0,rcp0_pre_run
	lds		r16,mem_run_confirm_count
	and		r16,r16
	breq	go_forward
	dec		r16
	sts		mem_run_confirm_count,r16
	rjmp	eva_rcp0_exit	
f_check_dir:
	sbis	GPIOR0,motor_reverse
	rjmp	go_forward
	rjmp	go_idle



go_forward:
	cbi		GPIOR0,motor_reverse
	ldi		r16,low(RCP_MAX)
	ldi		r17,high(RCP_MAX)
	cp		rcp0_l,r16
	cpc		rcp0_h,r17
	brcs	g_fwd_1
	ldi		r26,low(PWM_TOP+10)
	ldi		r27,high(PWM_TOP+10)
	rjmp	post_calc_pwm
g_fwd_1:
	lds		r18,mem_rcp0_neutral
	lds		r19,mem_rcp0_neutral+1
	sub		r16,r18
	sbc		r17,r19
	sts		mem_b,r16
	sts		mem_b+1,r17
	movw	r16,rcp0_l
	sub		r16,r18
	sbc		r17,r19
	sts		mem_a,r16
	sts		mem_a+1,r17
calc_pwm:
;  a     b
; --- = ---
;  x     c
; a = mem_a, b = mem_b, c = mem_c
; x = r26:r27 为结果
; a = current rcp
; b = max rcp
; c = top pwm
	ldi		r16,low(PWM_TOP)
	ldi		r17,high(PWM_TOP)
	sts		mem_c,r16
	sts		mem_c+1,r17
	rcall	x_function
	ldi		r16,low(PWM_TOP/10)
	ldi		r17,high(PWM_TOP/10)
	cp		r26,r16
	cpc		r27,r17
	brcc	post_calc_pwm
	movw	pwm_duty_l,r16
	rjmp	eva_rcp0_exit
post_calc_pwm:
	cbi		GPIOR0,motor_idle
	cp		r26,pwm_duty_l
	cpc		r27,pwm_duty_h
	brcc	pcp_1
	movw	pwm_duty_l,r26
	rjmp	eva_rcp0_exit
pcp_1:
	ldi		r16,low(PWM_INCREMENT)
	ldi		r17,high(PWM_INCREMENT)
	add		pwm_duty_l,r16
	adc		pwm_duty_h,r17
	cp		r26,pwm_duty_l
	cpc		r27,pwm_duty_h
	brcc	eva_rcp0_exit
	movw	pwm_duty_l,r26
eva_rcp0_exit:
	ret
; r18:r19 EEPROM address
; r16 value will be wroten to EEPROM
eep_write:
	; Wait for completion of previous write
	sbic	EECR,EEWE
	rjmp	eep_write
	; Set up address (r19:r18) in address register
	out		EEARH, r19
	out		EEARL, r18
	; Write data (r16) to Data Register
	out		EEDR,r16
	; Write logical one to EEMPE
	sbi		EECR,EEMWE
	; Start eeprom write by setting EEPE
	sbi		EECR,EEWE
	ret

; r18:r19 EEPROM address
; r16 return value
eep_read:
	; Wait for completion of previous write
	sbic	EECR,EEWE
	rjmp	eep_read
	; Set up address (r18:r19) in address register
	out		EEARH, r19
	out		EEARL, r18
	; Start eeprom read by writing EERE
	sbi		EECR,EERE
	; Read data from Data Register
	in		r16,EEDR
	ret

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

ss_delay:
	ldi		r17,150
ss_1:
	dec		r17
	and		r17,r17
	brne	ss_1
	ret
.equ	BEEP_IDLE =10
.equ	BEEP_LONG=200
start_beep:
	ldi		r18,BEEP_LONG
sb_fd:
	forward r16
	rcall	ss_delay
	idle	r16
	ldi		r16,BEEP_IDLE
sb_1:
	dec		r16
	breq	sb_r
	rcall	ss_delay
	rjmp	sb_1

sb_r:

	reverse	r16
	rcall	ss_delay
	idle	r16
	ldi		r16,BEEP_IDLE
sb_3:
	dec		r16
	breq	sb_4
	rcall	ss_delay
	rjmp	sb_3
sb_4:


	dec		r18
	and		r18,r18
	brne	sb_fd

	ret


save_word:
	lds		r18,mem_debug_idx
	cpi		r18,100
	brcc	sword_exit
	ldi		r26,low(mem_debug_data)
	ldi		r27,high(mem_debug_data)
	add		r26,r18
	adc		r27,zero
	st		X+,r16
	st		X,r17
	inc		r18
	inc		r18
	sts		mem_debug_idx,r18
sword_exit:
	ret

data_to_eep:
	cli
	clr		r18
	clr		r19
	ldi		r17,200
	ldi		r26,low(mem_debug_data)
	ldi		r27,high(mem_debug_data)
dte_1:
	ld		r16,X+
	rcall	eep_write
	inc		r18
	dec		r17
	brne	dte_1
	
break_point:
	cli
loop:
	rcall	long_delay
	sbis	PORTD,WATER_PUMP
	rjmp	sw1
	cbi		PORTD,WATER_PUMP
	rjmp	loop
sw1:
	sbi		PORTD,WATER_PUMP
	rjmp	loop

debug_adc:
	push	r16
	push	r18
	push	r19
	push	r20
	push	r21
	lds		r20,ADCL
	lds		r21,ADCH
	ldi		r18,0
	ldi		r19,0
	mov		r16,r20
	rcall	eep_write
	inc		r18
	mov		r16,r21
	rcall	eep_write
	pop		r21
	pop		r20
	pop		r19
	pop		r18
	pop		r16
	ret
.exit
