; $copyright$
; Last modified
; 重新设计程序结构

.include "m8def.inc"
.include "18_3p_t50.inc"
;.include "t50.inc"

.equ		F_CPU		= 16

; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; Register Definitions
.def	zero			= r0		; stays at 0
.def	i_sreg			= r1		; SREG save in interrupts
.def	state_on		= r2		; motor output on
.def	state_off		= r3		; motor output off
.def	pwm_duty_l		= r4
.def	pwm_duty_h		= r5
.def	tcnt0_h			= r6		; t0 high byte, extend t0 to 16bit
.def	rcp_error_cnt	= r7		; rcp error count
.def	state_index		= r8		; current state
.def	tcnt2_h			= r9		; t2 high byte, extend t2 to 16bit
.def	rcp_l			= r10
.def	rcp_h			= r11
;.def	correct_zc		= r12

.def	r_temp1			= r16		; main temporary (L)
.def	r_temp2			= r17		; main temporary (H)
.def	r_temp3			= r18		; main temporary (L)
.def	r_temp4			= r19		; main temporary (H)

.def	i_temp1			= r20		; interrupt temporary
.def	i_temp2			= r21		; interrupt temporary
.def	i_temp3			= r22		; interrupt temporary
.def	i_temp4			= r23		; interrupt temporary

.def	flag1			= r25
	.equ	tcnt0_h_ovf	= 0
;	.equ	limit_pwm	= 1		; pwm should work at limit duty before motor run successful
	; 1 startup mode, 0 run mode
	; 1 启动模式,   0 高速模式
;	.equ	STARTUP		= 2
;	.equ	convert_rcp	= 3
;	.equ	motor_stop	= 4
;	.equ	wait_before_scan_zc = 5		; if set don't evaluate zero-cross
;	.equ	com_period	= 6			; if set indicate commutation period
	.equ	full_power	= 7
	
.def	flag2			= r24
	
	.equ	debug_start		= 2
	.equ	debug_data_done = 3
;	.equ	debug_zc_timeout = 4

.equ	STARTUP_STEPS		= 12

.equ	ZERO_CROSS			= 5
.equ	ZC_TIMEOUT_LIMIT	= 3
.equ	BRAKE_ENABLE		= 0



.equ	RCP_ERROR_COUNT			= 100
.equ	RCP_HIGH_X				= 20000 * (F_CPU/8)
.equ	RCP_LOW_X				= 7500 * (F_CPU/8)

.equ	PWM_TOP					= 1048 * (F_CPU/8)		; 8k/sec pwm
;.equ	RCP_HIGH				= 14260 * (F_CPU/8)		; 1700 ns
.equ	RCP_HIGH				= 14000 * (F_CPU/8)		; 1700 ns
.equ	RCP_LOW					= 9227 * (F_CPU/8)		; 1100 ns
.equ	RCP_STOP_AREA			= 500 * (F_CPU/8)

.equ	PWM_INCREMENT			=20 * (F_CPU/8)
.equ	FULL_PWM_DUTY			=PWM_TOP - 100

;.equ	CALCULATE_COM			= 1


;.equ	STARTUP_PWM				= PWM_TOP/10+PWM_TOP/20	; 15% PWM at startup
;.equ	STARTUP_PWM				= PWM_TOP*16/100		; 16% PWM at startup
.equ	STARTUP_PWM				= PWM_TOP*8/100			; 8% PWM at startup
.equ	BRAKE_PWM				= PWM_TOP/10


.equ	RCP_MID					= (RCP_HIGH + RCP_LOW) / 2

;.equ	STARTUP_STATE_ELAPSED		= 3495 * (F_CPU/8)		;3495 ~= 3333ns  3000 rpm/ clk/8
;.equ	STARTUP_STATE_ELAPSED		= 1747 * (F_CPU/8)		;6000 rpm/ clk/8
;.equ	STARTUP_STATE_ELAPSED		= 5242 * (F_CPU/8)		;5242 ~= 5000ns  2000 rpm/ clk/8
;.equ	STARTUP_STATE_ELAPSED		= 10484 * (F_CPU/8)		;10484 ~= 10000ns  1000 rpm/ clk/8
;.equ	STARTUP_STATE_ELAPSED		= 20972 * (F_CPU/8)		;500 rpm/ clk/8
.equ	STARTUP_STATE_ELAPSED		= 60000 * (F_CPU/8)

.macro	motor_stop
	andi	flag2,0b11111100
.endm
.equ		STOP	= 0
.macro	motor_forward
	sbr		flag2,0b00000001
	cbr		flag2,0b00000010
.endm
.equ		FORWARD	= 1
.macro	motor_brake
	ori		flag2,0b00000011
.endm
.equ		BRAKE	= 3
.macro	motor_reverse
	sbr		flag2,0b00000010
	cbr		flag2,0b00000001
.endm
.equ		REVERSE	= 2
.macro motor_dir
	ldi		@0,0b00000011
	and		@0,flag2
.endm

; 选择模拟比较器负端选择
; @0 register
; @1 immedate
.macro ac_select
; SFIOR [-|-|-|-|ACME|PUD|PSR2|PSR10]
; ACME - 模拟比较器多路复用器使能
	ldi		@0,0b00001000
	out		SFIOR,@0
; ADCSRA [ADEN|ADSC|ADFR|ADIF|ADIE|ADPS2|ADPS1|ADPS0]
	cbi		ADCSRA,ADEN
; ADMUX [REFS1|REFS0|ADLAR|-|MUX3|MUX2|MUX1|MUX0]
	ldi		@0,0b11100000+@1
	out		ADMUX,@0
.endm

.macro current_tcnt2
	mov		@1,tcnt2_h
	in		@0,TCNT2
	cp		@1,tcnt2_h
	breq	ct1
	mov		@1,tcnt2_h
	in		@0,TCNT2
ct1:
.endm

.macro set_current_tcnt2
	mov		@1,tcnt2_h
	in		@0,TCNT2
	cp		@1,tcnt2_h
	breq	sct1
	mov		@1,tcnt2_h
	in		@0,TCNT2
sct1:
	sts		mem_last_tcnt2,@0
	sts		mem_last_tcnt2+1,@1
.endm

;.macro current_tcnt2
;	mov		@1,tcnt2_h
;	in		@0,TCNT2
;	cpi		@0,15
;	brcc	ct2
;	mov		@1,tcnt2_h
;ct2:
;.endm

;.macro set_current_tcnt2
;	mov		@1,tcnt2_h
;	in		@0,TCNT2
;	cpi		@0,15
;	brcc	sct2
;	mov		@1,tcnt2_h
;sct2:
;	sts		mem_last_tcnt2,@0
;	sts		mem_last_tcnt2+1,@1
;.endm


;@0 low byte
;@1 high byte
.macro commit_pwm
	out		OCR1AH,@1
	out		OCR1AL,@0
.endm

.macro resume_t1
; TCCR1B [ICNC1 |ICES1 |-     |WGM13 |WGM12|CS12 |CS11 |CS10 ]
; CS12:0=001	clk/1 prescaler
	ldi		@0,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
	out		TCCR1B,@0
.endm
.macro pause_t1
; TCCR1B [ICNC1 |ICES1 |-     |WGM13 |WGM12|CS12 |CS11 |CS10 ]
; CS12:0=000	CLK STOP
	ldi		@0,(1<<WGM13)+(1<<WGM12)
	out		TCCR1B,@0
.endm
.macro all_output_off
	out		PORTD,zero
.endm

;**** **** **** **** ****
; ATmega8 interrupts

;.equ	INT0addr=$001	; External Interrupt0 Vector Address
;.equ	INT1addr=$002	; External Interrupt1 Vector Address
;.equ	OC2addr =$003	; Output Compare2 Interrupt Vector Address
;.equ	OVF2addr=$004	; Overflow2 Interrupt Vector Address
;.equ	ICP1addr=$005	; Input Capture1 Interrupt Vector Address
;.equ	OC1Aaddr=$006	; Output Compare1A Interrupt Vector Address
;.equ	OC1Baddr=$007	; Output Compare1B Interrupt Vector Address
;.equ	OVF1addr=$008	; Overflow1 Interrupt Vector Address
;.equ	OVF0addr=$009	; Overflow0 Interrupt Vector Address
;.equ	SPIaddr =$00a	; SPI Interrupt Vector Address
;.equ	URXCaddr=$00b	; USART Receive Complete Interrupt Vector Address
;.equ	UDREaddr=$00c	; USART Data Register Empty Interrupt Vector Address
;.equ	UTXCaddr=$00d	; USART Transmit Complete Interrupt Vector Address
;.equ	ADCCaddr=$00e	; ADC Interrupt Vector Address
;.equ	ERDYaddr=$00f	; EEPROM Interrupt Vector Address
;.equ	ACIaddr =$010	; Analog Comparator Interrupt Vector Address
;.equ	TWIaddr =$011	; Irq. vector address for Two-Wire Interface
;.equ	SPMaddr =$012	; SPM complete Interrupt Vector Address
;.equ	SPMRaddr =$012	; SPM complete Interrupt Vector Address
;-----bko-----------------------------------------------------------------
.dseg				; DATA segment

mem_t0_temp_l:	.byte	1	;t0 temp address
mem_t0_temp_h:	.byte	1
; for x_function used
mem_a_l:	.byte	1
mem_a_h:	.byte	1
mem_b_l:	.byte	1
mem_b_h:	.byte	1
mem_c_l:	.byte	1
mem_c_h:	.byte	1

mem_rcp_low:	.byte	2
mem_rcp_high:	.byte	2

;last time of phase changed
mem_last_tcnt2: .byte 2
; last commutation length
mem_com_length:	.byte 2
; wait time before zero-cross scan
; evaluate rcp can be executed at this period.
mem_wait_zc:	.byte 2
; zero-cross timeout length
mem_zc_timeout:	.byte 2
mem_zc_count:	.byte 1
; startup pwm duty
mem_st_pwm_duty: .byte 2

mem_correct_zc: .byte 1

mem_last_pwm_duty:	.byte 2

;mem_startup_state_cnt: .byte 1
;debug *******************************
debug_mem_data1:	.byte 200
debug_mem_count: .byte 1

;debug_mem_dummy_pwm:	.byte 2
;debug end ***************************


mem_states:		.byte	12

;**** **** **** **** ****
.cseg
.org 0
;**** **** **** **** ****

;-----bko-----------------------------------------------------------------
; Reset and interrupt jump table
; When multiple interrupts are pending, the vectors are executed from top
; (ext_int0) to bottom.
	rjmp	reset
	rjmp	ext_int0
	nop		; ext_int1
	nop		; t2oc_int
	rjmp	t2ovfl_int
	nop		; icp1_int
	rjmp	t1oca_int
	nop		; t1ocb_int
	rjmp	t1ovfl_int
	rjmp	t0ovfl_int
	nop		; spi_int
	nop		; urxc
	nop		; udre
	nop		; utxc
;------------------------------------------------------------------------------------
; state feedback change
next_state:
	ldi		ZL,low (case_jmp)
	clr		ZH
	add		ZL,state_index
	ijmp
case_jmp:
	rjmp	state_fb_1
	rjmp	state_fb_2
	rjmp	state_fb_3
	rjmp	state_fb_4
	rjmp	state_fb_5
	rjmp	state_fb_6
state_fb_1:
state_fb_4:
	ac_select r_temp2,fb_b
	rjmp	state_change
state_fb_2:
state_fb_5:
	ac_select r_temp2,fb_c
	rjmp	state_change
state_fb_3:
state_fb_6:
	ac_select r_temp2,fb_a

state_change:
	ldi		yl,low(mem_states)
	ldi		yh,high(mem_states)
	mov		r_temp1,state_index
	add		r_temp1,r_temp1
	add		yl,r_temp1
	adc		yh,zero
	ld		state_on,Y+
	ld		state_off,Y
	sbrs	flag1,full_power	; full power?
	rjmp	state_change_2		; ... no
instant_full_pwm:				; ... yes
	pause_t1 r_temp1
	rjmp	state_change_1
state_change_2:
;	resume_t1 r_temp1
	sbis	PORTB,PB1
	out		PORTD,state_off
	sbic	PORTB,PB1
state_change_1:
	out		PORTD,state_on
	ret
;------------------------------------------------------------------------------------

reset:
	clr	zero
	out	SREG, zero		; Clear interrupts and flags
	; Set up stack
	ldi	ZH, high(RAMEND)
	ldi	ZL, low (RAMEND)
	out	SPH, ZH
	out	SPL, ZL

;debug ********************************************
	sts		debug_mem_count,zero
	ldi		r_temp1,200
	ldi		yl,low(debug_mem_data1)
	ldi		yh,high(debug_mem_data1)
r_1:
	st		Y+,zero
	dec		r_temp1
	brne	r_1
;debug end ****************************************
; initialize PORTD
	ldi		r_temp1,(1<<anFET)+(1<<apFET)+(1<<bnFET)+(1<<bpFET)+(1<<cnFET)+(1<<cpFET)
	out		DDRD,r_temp1


; state initial
	ldi		YL,low(mem_states)
	ldi		YH,high(mem_states)
	ldi		r_temp1,STATE_1
	st		Y+,r_temp1
	ldi		r_temp1,STATE_2
	st		Y+,r_temp1
	ldi		r_temp1,STATE_3
	st		Y+,r_temp1
	ldi		r_temp1,STATE_4
	st		Y+,r_temp1
	ldi		r_temp1,STATE_5
	st		Y+,r_temp1
	ldi		r_temp1,STATE_6
	st		Y+,r_temp1
	ldi		r_temp1,STATE_7
	st		Y+,r_temp1
	ldi		r_temp1,STATE_8
	st		Y+,r_temp1
	ldi		r_temp1,STATE_9
	st		Y+,r_temp1
	ldi		r_temp1,STATE_A
	st		Y+,r_temp1
	ldi		r_temp1,STATE_B
	st		Y+,r_temp1
	ldi		r_temp1,STATE_C
	st		Y+,r_temp1


; TIMER0 扩展到R6, CLK/1
; TCCR0[-|-|-|-|-|CS02|CS01|CS00]
; CS02:0=001 CLK/1
	ldi		r_temp1, (1<<CS00)
	out		TCCR0,r_temp1
; TIMER2 扩展到R9, CLK/8
; TCCR2[FOC2|WGM20|COM21|COM20|WGM21|CS22|CS21|CS20]
; CS22:0=010	CLK/8
	ldi		r_temp1,(0<<CS22)+(1<<CS21)+(0<<CS20)
	out		TCCR2,r_temp1

; TIMSK[OCIE2|TOIE2|TICIE1|OCIE1A|OCIE1B|TOIE1|-|TOIE0]
; TOIE0=1 T0 overflow interrupt enable
; TOIE1=1 T1 overflow interrupt enable
; TOIE2=1 T2 overflow interrupt enable
; OCIE1A=1 T1 output compare interrupt enable
	ldi		r_temp1,(1<<TOIE0)+(1<<OCIE1A)+(1<<TOIE1)+(1<<TOIE2)
	out		TIMSK,r_temp1

	pause_t1 r_temp1
	all_output_off
;	clr		state_on
;	clr		state_off

; PWM setting
; TCCR1A [COM1A1|COM1A0|COM1B1|COM1B0|FOC1A|FOC1B|WGM11|WGM10]
; TCCR1B [ICNC1 |ICES1 |-     |WGM13 |WGM12|CS12 |CS11 |CS10 ]
; COM1A1:0 = 10	比较匹配时清零, 在TOP时 置位
; WGM[4:0] = 1110 (Fast PWM, TOP = ICR1)
;    t1 overflow intterupt indicate PWM TOP, pwm on stage
;    t1 output compare intterupt indicate PWM active. pwm off stage
	ldi		r_temp1,(1<<COM1A1)+(0<<COM1A0)+(1<<WGM11)
	out		TCCR1A,r_temp1

;	ldi		r_temp1,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
;	out		TCCR1B,r_temp1

	; 在T1 的 PWM 中断设置
	; OCR1A PWM的强度, TOV1 是PWM 的长度.由 ICR1 作为TOP
	ldi		r_temp1, low (PWM_TOP)
	ldi		r_temp2, high(PWM_TOP)
	out		ICR1H,r_temp2
	out		ICR1L,r_temp1

; clear rcp ready flag
	clt
; int0 enable
; MCUCR [SE|SM2|SM1|SM0|ISC11|ISC10|ISC01|ISC00]
; ISC01:00 = 1:1 rising edge trigger interrupt
	ldi		r_temp1,0b00000011
	out		MCUCR,r_temp1
; GICR [INT1|INT0|-|-|-|-|IVSEL|IVCE]
; INT0 int0 enable
	ldi		r_temp1,0b01000000
	out		GICR,r_temp1


; 模拟比较器开始设置
; ACSR [ACD|ACBG|ACO|ACI|ACIE|ACIC|ACIS1|ACIS0]
; ACD 1 disabled 模拟比较器
	out		ACSR,zero


	;rcall	delay_1sec


	; clear flag
	clr		flag1
	clr		flag2
	ldi		r_temp1,RCP_ERROR_COUNT
	mov		rcp_error_cnt,r_temp1
	
	rcall	short_delay

	rcall	beep_a
	rcall	beep_b
	rcall	beep_c

start:

	ldi		r_temp1,low(RCP_LOW)
	sts		mem_rcp_low,r_temp1
	ldi		r_temp1,high(RCP_LOW)
	sts		mem_rcp_low+1,r_temp1
	ldi		r_temp1,low(RCP_HIGH)
	sts		mem_rcp_high,r_temp1
	ldi		r_temp1,high(RCP_HIGH)
	sts		mem_rcp_high+1,r_temp1

	lds		r_temp1,mem_rcp_low
	lds		r_temp2,mem_rcp_low+1
	ldi		r_temp3,low(RCP_STOP_AREA)
	ldi		r_temp4,high(RCP_STOP_AREA)
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ldi		r_temp3,50
	sei
rcp_low_ready:
	rcall	rcp_ready

	cp		r_temp1,rcp_l
	cpc		r_temp2,rcp_h
	brcs	rcp_low_ready
	dec		r_temp3
	brne	rcp_low_ready

	cli
	rcall	beep_a
;	rcall	beep_b
;	rcall	beep_c
; the follow 2 lines cause system restart?
;	clr		state_on
;	clr		state_off
	sei
	rcall	delay_half_sec
	
;	rjmp	debug_evaluate_rcp

stop_motor:

	pause_t1 r_temp1
	all_output_off
	ldi		r_temp1,low(STARTUP_PWM)
	sts		mem_st_pwm_duty,r_temp1
	ldi		r_temp1,high(STARTUP_PWM)
	sts		mem_st_pwm_duty+1,r_temp1
	rcall	rcp_ready
	rcall	evaluate_rcp
	motor_dir r_temp1
	cpi		r_temp1,STOP
	breq	sys_voltage
	cpi		r_temp1,BRAKE
	breq	brake_motor
;debug ****************************************
	sbrs	flag2,debug_start
	rjmp	debug_smo_z
	lds		r_temp1,debug_mem_count
	cpi		r_temp1,100
	brne	debug_smo_z
	rjmp	buff2eep
debug_smo_z:
	sts		debug_mem_count,zero
;debug end ************************************
	rjmp	start_motor
brake_motor:
	ldi		r_temp1,BRAKE_ON
	mov		state_on,r_temp1
	ldi		r_temp1,BRAKE_OFF
	mov		state_off,r_temp1
	
	ldi		r_temp1,low(BRAKE_PWM)
	ldi		r_temp2,high(BRAKE_PWM)
	commit_pwm	r_temp1,r_temp2

	clr		r_temp1
sbm_1:
	sbrs	flag1,tcnt0_h_ovf
	rjmp	sbm_1
	cbr		flag1,1<<tcnt0_h_ovf
	inc		r_temp1
	; t0 clk/1
	cpi		r_temp1,30
	brcs	sbm_1
	motor_stop
sys_voltage:
;	rcall	check_battery
	rjmp	stop_motor

; 自动模式换相
running_mode:
	brtc	before_zc_wait		; rcp ready?
	clt							; .. yes
	rcall	evaluate_rcp
	;rcall	debug_rcp
	motor_dir r_temp1
	cpi		r_temp1,STOP
;	brne	rm_loc_1
	breq	stop_motor

;	cpi		r_temp1,BRAKE
;	breq	brake_motor
	sbrc	flag1,full_power
	rjmp	before_zc_wait
	commit_pwm pwm_duty_l,pwm_duty_h
	resume_t1 r_temp1
before_zc_wait:
	current_tcnt2 r_temp1,r_temp2
	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	lds		r_temp3,mem_wait_zc
	lds		r_temp4,mem_wait_zc+1
	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcc	scan_zc
	rjmp	before_zc_wait

scan_zc:
	ldi		r_temp1,ZERO_CROSS
	sts		mem_zc_count,r_temp1
	rcall	scan_zero_cross
	sbrs	r_temp3,0
	rjmp	r_zc_happen
r_zc_timeout:
r_zc_happen:
;set_com_length:

;	motor_dir r_temp1
;	cpi		r_temp1,BRAKE
;	brne	scl_1
;	rjmp	brake_motor
;scl_1:
;debug *********************************************************
	lds		r_temp1,mem_com_length
	lds		r_temp2,mem_com_length+1
	rcall	save_word
;debug end ******************************************************


	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
 	
	set_current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
;debug *********************************************************
	rcall	save_word
;debug end ******************************************************

	lds		r_temp3,mem_com_length
	lds		r_temp4,mem_com_length+1


	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ror		r_temp2
	ror		r_temp1
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ror		r_temp2
	ror		r_temp1
;	add		r_temp1,r_temp3
;	adc		r_temp2,r_temp4
;	ror		r_temp2
;	ror		r_temp1

	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	movw	r_temp3,r_temp1
	lsr		r_temp4
	ror		r_temp3
	lsr		r_temp4
	ror		r_temp3
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	sts		mem_zc_timeout,r_temp3
	sts		mem_zc_timeout+1,r_temp4
	lsr		r_temp2
	ror		r_temp1
	sts		mem_wait_zc,r_temp1
	sts		mem_wait_zc+1,r_temp2
;	sbr		flag1,1<<com_period
;	rcall	check_battery

wait_before_sw_state:
	current_tcnt2 r_temp1,r_temp2
	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	lds		r_temp3,mem_com_length
	lds		r_temp4,mem_com_length+1
	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcs	wait_before_sw_state
	; 自动模式换相
	inc		state_index
	mov		r_temp1,state_index
	cpi		r_temp1,6
	brne	run_phase_change_1
	clr		state_index
run_phase_change_1:
;	commit_pwm pwm_duty_l,pwm_duty_h
	rcall	next_state
	set_current_tcnt2 r_temp1,r_temp2	; switch state checkpoint
;	sbr		flag1,1<<wait_before_scan_zc
;	cbr		flag1,1<<com_period
;	sbr		flag1,1<<convert_rcp
;run_phase_change_exit:
	rjmp	running_mode

scan_zc_or_timeout:
	current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r4
	sbc		r_temp2,r5
	ldi		r_temp3,high(18000)
	cpi		r_temp1,low(18000)
	cpc		r_temp2,r_temp3
	brcc	exit_to_startup
	ldi		r_temp3,10
szot_1:
	sbrc	r_temp4,0
	rjmp	scan_zc_high
	sbic	ACSR,ACO
	rjmp	scan_zc_or_timeout
	rjmp	szot_2
scan_zc_high:
	sbis	ACSR,ACO
	rjmp	scan_zc_or_timeout
szot_2:
	dec		r_temp3
	brne	szot_1

	ret
exit_to_startup:
	pop		r_temp1
	pop		r_temp1
	rjmp	startup_mode
start_motor:
;	rcall	buff2eep			; debug
	pause_t1	r_temp1
	all_output_off
	ac_select r_temp1,fb_a
run_again:
; find low to high
;eval_running:
	current_tcnt2 r_temp1,r_temp2
; r4:r5 were used as pwm_duty during running mode, but it's safety to use here
	movw	r4,r_temp1
	clr		r_temp4
	rcall	scan_zc_or_timeout
	current_tcnt2 r_temp1,r_temp2
	movw	r4,r_temp1
	inc		r_temp4
	rcall	scan_zc_or_timeout
	clr		r_temp4
	clr		r26
	clr		r27
sm_scan_zc:
	current_tcnt2 r_temp1,r_temp2
	movw	r4,r_temp1
	rcall	scan_zc_or_timeout
	cpi		r_temp1,low(500)
	ldi		r_temp3,high(500)
	cpc		r_temp2,r_temp3
	brcs	run_again
	add		r26,r_temp1
	adc		r27,r_temp2
	ldi		r_temp3,0
	adc		r_temp3,zero
	inc		r_temp4
	cpi		r_temp4,4
	brcs	sm_scan_zc

;	set_current_tcnt2 r_temp3,r_temp4
	lsr		r_temp3
	ror		r27
	ror		r26
	lsr		r27
	ror		r26
	set_current_tcnt2 r_temp3,r_temp4
	sts		mem_a_l,r26
	sts		mem_a_h,r27
	rcall	divide
	lds		r_temp1,mem_b_l
	lds		r_temp2,mem_b_h
	
	
	sts		mem_zc_timeout,r_temp1
	sts		mem_zc_timeout+1,r_temp2
	lsr		r_temp2
	ror		r_temp1
	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	
	
	lsr		r_temp2
	ror		r_temp1
	sts		mem_wait_zc,r_temp1
	sts		mem_wait_zc+1,r_temp2
	
	ldi		r_temp1,0
	mov		state_index,r_temp1
	rcall	next_state
	lds		pwm_duty_l,mem_st_pwm_duty
	lds		pwm_duty_h,mem_st_pwm_duty+1
	commit_pwm	pwm_duty_l,pwm_duty_h
	resume_t1 r_temp1
	rjmp	running_mode

startup_mode:
	clr		state_index
	clr		state_on
	clr		state_off
	lds		r_temp1,mem_st_pwm_duty
	lds		r_temp2,mem_st_pwm_duty+1
	commit_pwm	r_temp1,r_temp2
	ldi		r_temp3,low(STARTUP_STATE_ELAPSED/2)
	ldi		r_temp4,high(STARTUP_STATE_ELAPSED/2)
	sts		mem_com_length,r_temp3
	sts		mem_com_length+1,r_temp4

;	ldi		r_temp3,low(STARTUP_STATE_ELAPSED/4)
;	ldi		r_temp4,high(STARTUP_STATE_ELAPSED/4)
	ldi		r_temp3,low(500)
	ldi		r_temp4,high(500)
	sts		mem_wait_zc,r_temp3
	sts		mem_wait_zc+1,r_temp4

	ldi		r_temp3,low(STARTUP_STATE_ELAPSED/2)
	ldi		r_temp4,high(STARTUP_STATE_ELAPSED/2)
	sts		mem_zc_timeout,r_temp3
	sts		mem_zc_timeout+1,r_temp4

	
;	ldi		r_temp1,STARTUP_STEPS
;	mov		correct_zc,r_temp1
	resume_t1	r_temp1
startup_loop:
	rcall	next_state
	set_current_tcnt2 r_temp1,r_temp2
	brtc	st_loop1
	clt
	rcall	evaluate_rcp
	motor_dir r_temp1
	cpi		r_temp1,STOP
	brne	st_loop1
	rjmp	stop_motor
;	movw	r4,r_temp1
st_loop1:
	current_tcnt2 r_temp1,r_temp2
	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	lds		r_temp3,mem_wait_zc
	lds		r_temp4,mem_wait_zc+1
	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcs	st_loop1
	ldi		r_temp3,80
	sts		mem_zc_count,r_temp3
	rcall	scan_zero_cross
	sbrs	r_temp3,0
	rjmp	st_zc_happen
	; zc timeout
	ldi		r_temp3,STARTUP_STEPS
	sts		mem_correct_zc,r_temp3
	rjmp	st_loc_2
st_zc_happen:
	ldi		r_temp3,low(1000)
	ldi		r_temp4,high(1000)
	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcc	st_loc_3
	ldi		r_temp3,STARTUP_STEPS
	sts		mem_correct_zc,r_temp3
	rjmp	st_loc_2
st_loc_3:
	lds		r_temp3,mem_correct_zc
	dec		r_temp3
	sts		mem_correct_zc,r_temp3
st_loc_2:
;debug ****************************************************
	movw	r_temp3,r_temp1
	lds		r_temp1,mem_com_length
	lds		r_temp2,mem_com_length+1
	rcall	save_word
	movw	r_temp1,r_temp3
	rcall	save_word
;debug end ************************************************
	lds		r_temp3,mem_com_length
	lds		r_temp4,mem_com_length+1
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ror		r_temp2
	ror		r_temp1
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ror		r_temp2
	ror		r_temp1

	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	
	sts		mem_zc_timeout,r_temp1
	sts		mem_zc_timeout+1,r_temp2
	
	lsr		r_temp2
	ror		r_temp1
	
	ldi		r_temp3,low(500)
	ldi		r_temp4,high(500)
	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcs	st_loc_1
	movw	r_temp1,r_temp3
st_loc_1:
	sts		mem_wait_zc,r_temp1
	sts		mem_wait_zc+1,r_temp2
	set_current_tcnt2 r_temp1,r_temp2
st_consume_rest_time:
	current_tcnt2 r_temp1,r_temp2
	ldi		r_temp3,mem_last_tcnt2
	ldi		r_temp4,mem_last_tcnt2+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	lds		r_temp3,mem_com_length
	lds		r_temp4,mem_com_length+1
	cp		r_temp1,r_temp3
	cp		r_temp2,r_temp4
	brcs	st_consume_rest_time
	
	inc		state_index
	ldi		r_temp1,6
	cp		state_index,r_temp1
	brne	st_2
	clr		state_index
st_2:
	lds		r_temp1,mem_correct_zc
	and		r_temp1,r_temp1
	breq	st_3
	rjmp	startup_loop
st_3:
; debug ***********************
; don't enter running mode
;	rjmp	startup_loop
	clr		r_temp1
	clr		r_temp2
	rcall	save_word
; debug end *******************
	; enter running mode
	rcall	next_state
	set_current_tcnt2 r_temp1,r_temp2

;	lds		r_temp1,mem_com_length
;	lds		r_temp2,mem_com_length+1
;	lsr		r_temp2
;	ror		r_temp1
;	sts		mem_com_length,r_temp1
;	sts		mem_com_length+1,r_temp2
;	sts		mem_zc_timeout,r_temp1
;	sts		mem_zc_timeout+1,r_temp2
;	ldi		r_temp1,low(500)
;	ldi		r_temp2,high(500)
;	sts		mem_wait_zc,r_temp1
;	sts		mem_wait_zc+1,r_temp2
	lds		r_temp1,mem_st_pwm_duty
	lds		r_temp2,mem_st_pwm_duty+1
	movw	pwm_duty_l,r_temp1
	rjmp	running_mode


scan_zero_cross:
	mov		r_temp3,state_index
	;ldi		r_temp1,ZERO_CROSS
	sbrc	r_temp3,0
	rjmp	wait_zc_high
wait_zc_low:
	sbic	ACSR,ACO
	rjmp	zc_not_happen
	nop
	nop
	nop
	nop
	lds		r_temp3,mem_zc_count
	dec		r_temp3
	sts		mem_zc_count,r_temp3
	breq	zc_happen
	rjmp	wait_zc_low
wait_zc_high:
	sbis	ACSR,ACO
	rjmp	zc_not_happen
	nop
	nop
	nop
	nop
	lds		r_temp3,mem_zc_count
	dec		r_temp3
	sts		mem_zc_count,r_temp3
	breq	zc_happen
	rjmp	wait_zc_high
zc_not_happen:
	current_tcnt2 r_temp1,r_temp2
	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4

	lds		r_temp3,mem_zc_timeout
	lds		r_temp4,mem_zc_timeout+1

	cp		r_temp1,r_temp3
	cpc		r_temp2,r_temp4
	brcc	zc_timeout			;zero-cross timeout?
	rjmp	scan_zero_cross		; .. no
zc_timeout:
	ldi		r_temp3,1
	ret
zc_happen:
	ldi		r_temp3,0
	ret

; interrupt routine ====================================================================
t1oca_int:
	out		PORTD,state_off
	reti
t1ovfl_int:
	out		PORTD,state_on
	reti
;------------------------------------------------------------------------------------
t0ovfl_int:
	in		i_sreg,SREG
	inc		tcnt0_h
	breq	t0ovfl_1
	rjmp	t0ovfl_exit
t0ovfl_1:
	dec		rcp_error_cnt
	breq	lost_rcp
	sbr		flag1,1<<tcnt0_h_ovf
t0ovfl_exit:
	out		SREG,i_sreg
	reti
lost_rcp:
	pop		r_temp1
	pop		r_temp1
	rcall	delay_1sec
	rjmp	reset
;------------------------------------------------------------------------------------
t2ovfl_int:
	in		i_sreg,SREG
	inc		tcnt2_h
	out		SREG,i_sreg
	reti
;------------------------------------------------------------------------------------
;	RCP in uses extend INT0
ext_int0:
	in		i_sreg,SREG
	in		i_temp1,TCNT0
	mov		i_temp2,tcnt0_h

	in		i_temp3,TIFR
	sbrs	i_temp3,TOV0
	rjmp	int0_1
	in		i_temp1,TCNT0
	inc		i_temp2
int0_1:
	lds		i_temp3,mem_t0_temp_l
	lds		i_temp4,mem_t0_temp_h
	sts		mem_t0_temp_l,i_temp1
	sts		mem_t0_temp_h,i_temp2
	
	sub		i_temp1,i_temp3
	sbc		i_temp2,i_temp4

; 检查信号的状态.如果是上升弦触发, RCP 信号开始

	in		i_temp3,MCUCR
	sbrs	i_temp3,ISC00
	rjmp	int0_2
	; 上升弦触发,下一次中断必须改为下降弦
	; triggered by falling edge at next time
	ldi		i_temp3,(1<<ISC01)
	out		MCUCR,i_temp3
	rjmp	int0_exit

int0_2:
	; 下降弦触发, RCP 结束.
	; 下次中断改上升弦触发
	ldi		i_temp3,(1<<ISC01)+(1<<ISC00)
	out		MCUCR,i_temp3

	movw	rcp_l,i_temp1
	; if(r20:r21 > RCP_LOW && r20:r21 < RCP_HIGH) goto int0_rcp_ready
	subi	i_temp1,low(RCP_LOW_X)
	sbci	i_temp2,high(RCP_LOW_X)
	subi	i_temp1,low(RCP_HIGH_X-RCP_LOW_X)
	sbci	i_temp2,high(RCP_HIGH_X-RCP_LOW_X)
	brcs	int0_rcp_ready
	; rcp signal is incorrect
	ldi		i_temp3,0xff-(1<<6)
	and		i_sreg,i_temp3
	rjmp	int0_exit
int0_rcp_ready:
	ldi		i_temp3,RCP_ERROR_COUNT
	mov		rcp_error_cnt,i_temp3
	; 设置 SREG.t RCP ready
	ldi		i_temp3,1<<6
	or		i_sreg,i_temp3
int0_exit:
	out		SREG,i_sreg
	reti
; interrupt routine end ================================================================
.include "sound.inc"
delay_half_sec:
	clr		r_temp1
half_sec:
	sbrs	flag1,tcnt0_h_ovf
	rjmp	half_sec
	cbr		flag1,1<<tcnt0_h_ovf
	inc		r_temp1
	; t0 clk/1
	cpi		r_temp1,64 * (F_CPU/8)
	brcs	half_sec
	ret

;  a     b
; --- = ---
;  x     c
; a = mem_a, b = mem_b, c = mem_c
; x = r26:r27 为结果
x_function:
;	sts		mem_last_pwm_duty,pwm_duty_l
;	sts		mem_last_pwm_duty+1,pwm_duty_h
	clr		r26
	clr		r27
    rjmp	x_2
x_1: ;al_73:
	lds		r16,mem_c_l
	lds		r17,mem_c_h
	lsr		r17
	ror		r16
	sts		mem_c_l,r16
	sts		mem_c_h,r17
	cpi		r16,0
	cpc		r17,zero
    breq	x_3
	lds		r16,mem_b_l
	lds		r17,mem_b_h
	lsr		r17
	ror		r16
	sts		mem_b_l,r16
	sts		mem_b_h,r17
x_2: ;al_71:
	lds		r18,mem_a_l
	lds		r19,mem_a_h
	lds		r16,mem_b_l
	lds		r17,mem_b_h
    sub		r18,r16
    sbc		r19,r17
    brcs	x_1
	sts		mem_a_l,r18
	sts		mem_a_h,r19
	lds		r16,mem_c_l
	lds		r17,mem_c_h
    add		r26,r16
    adc		r27,r17
    rjmp	x_1
x_3: ;al_72:
;	lds		r_temp1,mem_last_pwm_duty
;	lds		r_temp2,mem_last_pwm_duty+1
;	cp		r_temp1,pwm_duty_l
;	cp		r_temp2,pwm_duty_h
;	brcc	x_exit
;	ldi		r_temp3,PWM_INCREMENT
;	add		r_temp1,r_temp3
;	adc		r_temp2,zero
;	cp		pwm_duty_l,r_temp1
;	cpc		pwm_duty_h,r_temp2
;	brcs	x_exit
;	movw	pwm_duty_l,r_temp1
;x_exit:
	ret
evaluate_rcp:
	lds		r_temp3,mem_rcp_low
	lds		r_temp4,mem_rcp_low+1
	ldi		r_temp1,low(RCP_STOP_AREA)
	ldi		r_temp2,high(RCP_STOP_AREA)
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcc	eval_rcp_high
	; evaluate RCP low
;.if	BRAKE_ENABLE == 1
;	motor_dir r_temp1
;	cpi		r_temp1,FORWARD
;	brne	to_stop
;	motor_brake
;to_stop:
;.endif
	motor_stop
	cbr		flag1,1<<full_power
	rjmp	rcp2pwm_exit
eval_rcp_high:
	motor_forward
	lds		r_temp3,mem_rcp_high
	lds		r_temp4,mem_rcp_high+1
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcs	calc_pwm_2
;debug **********************************************
	sbr		flag2,1<<debug_start
;debug end ******************************************
	sbrc	flag1,full_power
	rjmp	full_pwm
	ldi		r26,low(PWM_TOP)
	ldi		r27,high(PWM_TOP)
	rjmp	approach_pwm
calc_pwm_2:
	movw	r_temp1,rcp_l
	lds		r_temp3,mem_rcp_low
	lds		r_temp4,mem_rcp_low+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	sts		mem_a_l,r_temp1
	sts		mem_a_h,r_temp2
	ldi		r_temp1,low(PWM_TOP)
	sts		mem_c_l,r_temp1
	ldi		r_temp1,high(PWM_TOP)
	sts		mem_c_h,r_temp1

	lds		r_temp1,mem_rcp_high
	lds		r_temp2,mem_rcp_high+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	sts		mem_b_l,r_temp1
	sts		mem_b_h,r_temp2
	rcall	x_function
approach_pwm:
	ldi		r_temp1,low(PWM_INCREMENT)
	ldi		r_temp2,high(PWM_INCREMENT)
	add		pwm_duty_l,r_temp1
	adc		pwm_duty_h,r_temp2
	cp		r26,pwm_duty_l
	cpc		r27,pwm_duty_h
	brcc	approach_full
	movw 	pwm_duty_l,r26
approach_full:
	ldi		r_temp1,low(PWM_TOP-100)
	ldi		r_temp2,high(PWM_TOP-100)
	cp		pwm_duty_l,r_temp1
	cpc		pwm_duty_h,r_temp2
	brcc	full_pwm
	cbr		flag1,1<<full_power
	rjmp	rcp2pwm_exit
full_pwm:
	sbr		flag1,1<<full_power
rcp2pwm_exit:
	ret
delay_1sec:
	ldi		r_temp1,25
delay_1sec_2:
	ldi		r26,0xff
	ldi		r27,0xff
delay_1sec_1:
	sbiw	r26,1	; 2
	brne	delay_1sec_1		; 2
	dec		r_temp1
	brne	delay_1sec_2
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

rcp_ready:
	brtc	rcp_ready
	clt
	ret

divide:
	sts		mem_b_l,zero
	sts		mem_b_h,zero
	ldi		r19,16
	clr		r18
d_0:
	lds		r16,mem_a_l
	lds		r17,mem_a_h
	lsl		r16
	rol		r17
	sts		mem_a_l,r16
	sts		mem_a_h,r17
	rol		r18
	
	cpi		r18,3			; 除3
	brcc	d_1
	rjmp	d_2
d_1:
	subi	r18,3			; 除3
	lds		r16,mem_b_l
	ori		r16,0b00000001
	sts		mem_b_l,r16
d_2:
	dec		r19
	breq	d_exit

	lds		r16,mem_b_l
	lds		r17,mem_b_h
	lsl		r16
	rol		r17
	sts		mem_b_l,r16
	sts		mem_b_h,r17
	
	rjmp	d_0

d_exit:
	ret

;debug *****************************************

reg2eep:
	push	r19
	push	r18
	ldi		r18,4
	ldi		r19,0
	rcall	eep_write
	mov		r16,r17
	inc		r18
	rcall	eep_write
	pop		r16
	inc		r18
	rcall	eep_write
	pop		r16
	inc		r18
	rcall	eep_write
	ret
save_word:
	push	r_temp3
	lds		r_temp3,debug_mem_count
	cpi		r_temp3,100
	breq	saw_exit
	add		r_temp3,r_temp3
	ldi		yl,low(debug_mem_data1)
	ldi		yh,high(debug_mem_data1)
	add		yl,r_temp3
	adc		yh,zero
	st		Y+,r_temp1
	st		Y,r_temp2
	lds		r_temp3,debug_mem_count
	inc		r_temp3
	sts		debug_mem_count,r_temp3
saw_exit:
	pop		r_temp3
	ret

buff2eep:
	cli
	ldi		r_temp2,200
	ldi		r18,0
	ldi		r19,0
	ldi		yl,low(debug_mem_data1)
	ldi		yh,high(debug_mem_data1)
debug_bbb:
	ld		r16,Y+
	rcall	eep_write
	inc		r18
	dec		r_temp2
	brne	debug_bbb
	rjmp	break_point
sys_halt:
	cli
infinity:
	rjmp	infinity
break_point:
	cli
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rjmp	sys_halt
.if 1==2
debug_evaluate_rcp:
	brtc	debug_evaluate_rcp
	clt
	rcall	evaluate_rcp

	sbrc	flag1,full_power
	rjmp	s3
	motor_dir r_temp1
	cpi		r_temp1,FORWARD
	breq	s2
	cpi		r_temp1,STOP
	breq	debug_evaluate_rcp
	
s3:
	cli
	rcall	beep_a
	rcall	short_delay
s2:
	cli
	rcall	beep_b
	rcall	short_delay
s1:
	cli
	rcall	beep_c
	rcall	short_delay
	sei
	rjmp	debug_evaluate_rcp

test_fet:
	rcall	beep_a
	rcall	short_delay
	rcall	beep_b
	rcall	short_delay
	rcall	beep_c
	rcall	short_delay
	rcall	beep_d
	rcall	short_delay
	rcall	beep_e
	rcall	short_delay
	rcall	beep_f
	rcall	short_delay
	rjmp	test_fet
.endif

;debug end **************************************


.exit
