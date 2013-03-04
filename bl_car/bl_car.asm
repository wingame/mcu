; $copyright$
; Last modified
; 启动时,以STARTUP_COM_LENGTH为每一步的长度,启动步数为STARTUP_STEPS,
; 进入高速时,当有阻力导致过零点超时ZC_TIMEOUT_LMT再进入启动模式,并且增加启动
; 功率的PWM_INCREMENT, 当有连续2次的过零点检测成功.即把startup pwm改为初始值
; (STARTUP_PWM)

; 在自控模式下,要连续发生ZC_TIMEOUT_LMT次的过零点超时才尝试重新高速. 这方法可以解决
; 内转电机重新进入高速时的不连贯性. 但是在我们常规的外转电机,如果有这个编程方法会导致
; 电机被重负载阻挡停止时无法顺利重新进入高速.

; bug, 这个版本比较容易发生重启,现象有停止进入转动时发生,具体细节还要仔细的去实验(fixed)
; 在startup_mode 的阶段,需要先清除输出,开PWM,然后才调用sw_state

;1 开机响声根据电池类型					DONE
;	镍氢	aabbcc
;	锂电2	c   c
;	锂电3	c c c
;2 低杆进入设置. 等足够长的时间才进入
;  a. 电池设置							DONE
;     镍氢电池和锂电, 未设置视为镍氢
;	 镍氢 5伏保护
;	 锂电	>8.6 9
;			<8.6 6
;  b. 有/无倒车			DONE
;  c. 正反转(取消)
;
;
;  d. 中杆放弃设置		DONE
  
;3. 响声要更大声				DONE
;4. RCP丢失后系统重新启动	DONE


; 设置无倒车模式, 低杆开机高杆确认 回在无倒车和有倒车之间切换.并且保持状态到下次开机


.include "m8def.inc"
.include "../brushless/18_3p.inc"
;.include "../brushless/t50.inc"

.equ		HAS_FULLPOWER = 1
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
.def	zc_timeout_cnt	= r12
; motor stop countdown, motor will restart after countdown is zero
;.def	stop_countdown	= r13
;.def	zc_happen_cnt	= r14

.def	r_temp1			= r16		; main temporary (L)
.def	r_temp2			= r17		; main temporary (H)
.def	r_temp3			= r18		; main temporary (L)
.def	r_temp4			= r19		; main temporary (H)
.def	i_temp1			= r20		; interrupt temporary
.def	i_temp2			= r21		; interrupt temporary
.def	i_temp3			= r22		; interrupt temporary
.def	i_temp4			= r23		; interrupt temporary

.def	flag1			= r27
	.equ	tcnt0_h_ovf	= 0
	; before previous state
	; 0 forward, 1 reverse
	.equ	PREV_REVERSE	= 1
	; set 1 if motor is running by inertia otherwise set 0
	.equ	MOTOR_MOVE		= 2
;	.equ	convert_rcp	= 3
;	.equ	motor_stop	= 4
;	.equ	before_scan_zc = 5		; if set don't evaluate zero-cross
;	.equ	com_period	= 6			; if set indicate commutation period
	.equ	full_power	= 7
	
.def	flag2			= r26
	.equ	NO_REVERSE = 2
; debug ******************************************
	.equ	debug_save	= 6
	.equ	debug_start	= 7
; debug ******************************************

.equ	STARTUP_STEPS		= 12
.equ	ZERO_CROSS_TIME		= 5
.equ	ZC_TIMEOUT_LMT		= 3
; 无倒车在EEP ROM中的指定值
.equ	NO_REVERSE_VALUE	= 1
.equ	BTYPE_NIHM			= 1
.equ	BTYPE_LIPO			= 2

.equ	RCP_ERROR_COUNT			= 150

; correct rcp range
.equ	RCP_HIGH_X				= 18000 * (F_CPU/8)
.equ	RCP_LOW_X				= 7000 * (F_CPU/8)


.equ	PWM_TOP					= 1048 * (F_CPU/8)		; 8k/sec pwm
.equ	RCP_HIGH				= 15900 * (F_CPU/8)
.equ	RCP_LOW					= 9227 * (F_CPU/8)
.equ	RCP_STOP_AREA			= 838 * (F_CPU/8)		; 100us
;.equ	RCP_NEUTRAL				= (RCP_HIGH + RCP_LOW) / 2
.equ	RCP_NEUTRAL				= 12582 * (F_CPU/8)
.equ	RCP_MID_AREA_H			= 13841 * (F_CPU/8)
.equ	RCP_MID_AREA_L			= 10905 * (F_CPU/8)


.equ	VOLT_50			= 50		; 6.5V NiHm protection voltage
.equ	CRITERIA_VOLT	= 78		; 8.6V as criteria for determind 2s or 3s lipo
.equ	VOLT_90			= 82		; 9V Lipo 2S protection voltage
.equ	VOLT_60			= 55		; 6V Lipo 3s protection voltage

.equ	PWM_INCREMENT			= 100 * (F_CPU/8)
;.equ	PWM_INCREMENT			= 30 * (F_CPU/8)
.equ	ST_PWM_INCREMENT		= 20 * (F_CPU/8)
;.equ	CALCULATE_COM			= 1


;.equ	STARTUP_PWM				= PWM_TOP*15/100	; 15% PWM at startup
;.equ	STARTUP_PWM				= PWM_TOP*35/100	; 35% PWM at startup
.equ	STARTUP_PWM				= PWM_TOP*8/100		; 8% PWM at startup
.equ	BRAKE_PWM				= PWM_TOP*50/100



.equ	EEP_RCP_LOW_L			= 0
.equ	EEP_RCP_LOW_H			= 1
.equ	EEP_RCP_HIGH_L			= 2
.equ	EEP_RCP_HIGH_H			= 3
.equ	EEP_RCP_NEUTRAL_L		= 4
.equ	EEP_RCP_NEUTRAL_H		= 5

; 0 or 0xff 意味缺省有倒车, 1 无倒车
.equ	EEP_REVERSE				= 30
.equ	EEP_BATTERY_TYPE		= 17
;1 rotor per 1 cycle
;.equ	STARTUP_COM_LENGTH		= 1747 * (F_CPU/8)		;6000 rpm/ clk/8
.equ	STARTUP_COM_LENGTH		= 3495 * (F_CPU/8)		;3495*(F_CPU/8) ~= 1667ns  3000 rpm/ clk/8
;.equ	STARTUP_COM_LENGTH		= 5242 * (F_CPU/8)		;5242*(F_CPU/8) ~= 2500ns  2000 rpm/ clk/8
;.equ	STARTUP_COM_LENGTH		= 32000
;.equ	STARTUP_COM_LENGTH		= 20972 * (F_CPU/8)		;500 rpm/ clk/8

;.equ	STOP_COUNT				= 15	; the motor have to stay in stop status untill stop countdown done

.macro	rcp_ready
rcp_ready_1:
	brtc	rcp_ready_1
	clt
.endm

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
; @1 immedately
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

;@0 low byte
;@1 high byte
.macro set_pwm
	out		OCR1AH,@1
	out		OCR1AL,@0
.endm

.macro enable_pwm
; TIMSK[OCIE2|TOIE2|TICIE1|OCIE1A|OCIE1B|TOIE1|-|TOIE0]
; TOIE0=1 T0 overflow interrupt enable
; TOIE1=1 T1 overflow interrupt enable
; TOIE2=1 T2 overflow interrupt enable
; OCIE1A=1 T1 output compare interrupt enable
	ldi		@0,(1<<TOIE0)+(1<<OCIE1A)+(1<<TOIE1)+(1<<TOIE2)
	out		TIMSK,@0
	
.endm
.macro disable_pwm
; TIMSK[OCIE2|TOIE2|TICIE1|OCIE1A|OCIE1B|TOIE1|-|TOIE0]
; TOIE0=1 T0 overflow interrupt enable
; TOIE1=0 T1 overflow interrupt disable
; OCIE1A=0 T1 output compare interrupt disable
; TOIE2=1 T2 overflow interrupt enable
	ldi		@0,(1<<TOIE0)+(1<<TOIE2)
	out		TIMSK,@0
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

mem_shutdown_v:	.byte 1
;mem_btype:	.byte	1
;mem_last_pwm_duty:	.byte 2

;mem_rcp_low:	.byte	2
;mem_rcp_high:	.byte	2
mem_rcp_neutral: .byte	2
;mem_rcp_neutral_v: .byte	2
;mem_rcp_deadzone: .byte 2

;last time of phase changed
mem_last_tcnt2: .byte 2
; last commutation length
mem_com_length:	.byte 2
; wait time before zero-cross scan
mem_wait_zc:	.byte 2
; zero-cross timeout length
mem_zc_timeout:	.byte 2
; zero-cross count
;mem_zc_cnt:		.byte 1

mem_btty_fail_cnt: .byte 1

mem_max_forward_rcp:	.byte 2
mem_max_reverse_rcp:	.byte 2

;mem_forward_start_rcp:	.byte 2

mem_st_pwm_duty:		.byte 2

; motor stop countdown, motor will restart after countdown is zero
;mem_stop_countdown:	.byte 1

mem_states:				.byte 12

; debug *************************************************
mem_debug_data:			.byte 200
mem_debug_cnt:			.byte 1
; debug end *********************************************

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
	rjmp	reset	; utxc
;------------------------------------------------------------------------------------
; state feedback change
sw_state:
	ldi		ZL,low (case_jmp)
	clr		ZH
	add		ZL,state_index
	ijmp
case_jmp:
	rjmp	state_fb_a
	rjmp	state_fb_b
	rjmp	state_fb_c
	rjmp	state_fb_d
	rjmp	state_fb_e
	rjmp	state_fb_f
state_fb_a:
state_fb_d:
	ac_select r_temp2,fb_b
	rjmp	state_change
state_fb_b:
state_fb_e:
	ac_select r_temp2,fb_c
	rjmp	state_change
state_fb_c:
state_fb_f:
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
	rjmp	state_change_2		; .. no
	disable_pwm r_temp1			; .. yes
	rjmp	state_change_1
state_change_2:
;	enable_pwm r_temp1
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

; initialize PORTD
	ldi		r_temp1,(1<<anFET)+(1<<apFET)+(1<<bnFET)+(1<<bpFET)+(1<<cnFET)+(1<<cpFET)
	out		DDRD,r_temp1
	out		PORTD,zero
; debug ****************************************
;dddd:
;	rcall	beep_a
;	rcall	delay_short
;	rjmp	dddd
; debug end ************************************
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
; reset flags
	clr		flag1
	clr		flag2


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

	disable_pwm r_temp1
	all_output_off
	clr		state_on
	clr		state_off

; PWM setting
; TCCR1A [COM1A1|COM1A0|COM1B1|COM1B0|FOC1A|FOC1B|WGM11|WGM10]
; TCCR1B [ICNC1 |ICES1 |-     |WGM13 |WGM12|CS12 |CS11 |CS10 ]
; COM1A1:0 = 10	比较匹配时清零, 在TOP时 置位
; WGM[4:0] = 1110 (Fast PWM, TOP = ICR1)
;    t1 overflow intterupt indicate PWM TOP, pwm on stage
;    t1 output compare intterupt indicate PWM active. pwm off stage
; clk/1 预分频
	ldi		r_temp1,(1<<COM1A1)+(0<<COM1A0)+(1<<WGM11)
	out		TCCR1A,r_temp1
	ldi		r_temp1,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
	out		TCCR1B,r_temp1

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

	ldi		r_temp1,RCP_ERROR_COUNT
	mov		rcp_error_cnt,r_temp1
; start beep
;	rcall	beep_a
	sei
	rcall	delay_half_sec
;	rjmp	debug_adc
	rcall	delay_half_sec
; 高杆开机设置杆位
	ldi		r_temp3,50
start_select:
	rcp_ready
	movw	r_temp1,rcp_l
	subi	r_temp1,low(RCP_MID_AREA_L)
	sbci	r_temp2,high(RCP_MID_AREA_L)
	brcc	detect_neutral_rcp
	dec		r_temp3
	breq	other_setting
	rjmp	start_select
other_setting:
; battery_type
battery_type:
	ldi		r_temp1,1
	rcall	beep_option
	and		r_temp2,r_temp2
	brne	reverse_or_not
	; set battery type here
	rcall	beep_confirm
	and		r_temp2,r_temp2
	breq	bt_1
	rcall	set_battery_type
bt_1:
	rjmp	detect_neutral_rcp
reverse_or_not:
	ldi		r_temp1,2
	rcall	beep_option
	and		r_temp2,r_temp2
	brne	battery_type
	; set has reverse or dont have
	rcall	beep_confirm
	and		r_temp2,r_temp2
	breq	tr_1
	rcall	set_reverse_or_not
tr_1:
;	rjmp	wait_stop
;cv_ccv:
;	ldi		r_temp1,3
;	rcall	beep_option
;	and		r_temp2,r_temp2
;	brne	battery_type
	; set motor direction
;	rjmp	wait_stop

detect_neutral_rcp:
	ldi		r_temp3,100
dnr_1:
	rcp_ready
	movw	r_temp1,rcp_l
	subi	r_temp1,low(RCP_MID_AREA_H)
	sbci	r_temp2,high(RCP_MID_AREA_H)
	brcc	dnr_1
	movw	r_temp1,rcp_l
	subi	r_temp1,low(RCP_MID_AREA_L)
	sbci	r_temp2,high(RCP_MID_AREA_L)
	brcs	dnr_1
	dec		r_temp3
	brne	dnr_1
	
;wait_stop:
	; load configuration from EEP ROM
	sts		mem_rcp_neutral,rcp_l
	sts		mem_rcp_neutral+1,rcp_h
wait_stop_0:
	ldi		r_temp3,EEP_REVERSE
	clr		r_temp4
	rcall	eep_read
	cpi		r_temp1,NO_REVERSE_VALUE
	breq	ws_aa_1
	cbr		flag2,1<<NO_REVERSE
	rjmp	ws_aa_2
ws_aa_1:
	sbr		flag2,1<<NO_REVERSE
ws_aa_2:


	ldi		r_temp3,EEP_BATTERY_TYPE
	rcall	eep_read
	mov		r13,r_temp1
	cpi		r_temp1,BTYPE_LIPO
	; nihm setting
	breq	ws_aa_3
	ldi		r_temp1,VOLT_50
	rjmp	ws_aa_5
ws_aa_3:
	; lipo setting
	; evaluate current voltage
	ldi		r_temp1,0b11100111
	out		ADMUX,r_temp1
	ldi		r_temp1,0b11010111
	out		ADCSRA,r_temp1
adc_ready:
	sbis	ADCSRA,ADIF
	rjmp	adc_ready
	in		r_temp1,ADCH
	
	cpi		r_temp1,CRITERIA_VOLT
	brcc	ws_aa_4
	; 2s
	ldi		r_temp1,VOLT_60
	rjmp	ws_aa_5
ws_aa_4:
	; 3s
	ldi		r_temp1,VOLT_90
ws_aa_5:
	sts		mem_shutdown_v,r_temp1

	ldi		r_temp1,low(RCP_HIGH)
	ldi		r_temp2,high(RCP_HIGH)
	lds		r_temp3,mem_rcp_neutral
	lds		r_temp4,mem_rcp_neutral+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	sts		mem_max_forward_rcp,r_temp1
	sts		mem_max_forward_rcp+1,r_temp2
	subi	r_temp3,low(RCP_LOW)
	sbci	r_temp4,high(RCP_LOW)
	sts		mem_max_reverse_rcp,r_temp3
	sts		mem_max_reverse_rcp+1,r_temp4
rcp_resume:
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
;	movw	r24,r_temp1
	ldi		r_temp3,low(RCP_STOP_AREA)
	ldi		r_temp4,high(RCP_STOP_AREA)
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	subi	r_temp1,low(RCP_STOP_AREA)
	sbci	r_temp2,high(RCP_STOP_AREA)
	ldi		r24,25
	sei
wait_stop_1:
	rcp_ready
	cp		rcp_l,r_temp1
	cpc		rcp_h,r_temp2
	brcs	wait_stop_1
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcc	wait_stop_1
	dec		r24
	brne	wait_stop_1
	motor_stop
;	rcall	delay_half_sec
;	rcall	delay_half_sec
	cli
	ldi		r_temp1,BTYPE_NIHM
	cpse	r13,r_temp1
	rjmp	ws_bb_1
	; NIHM
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
	rjmp	ws_bb_2
ws_bb_1:
	; LIPO
	lds		r_temp1,mem_shutdown_v
	cpi		r_temp1,VOLT_60
	breq	loud_2s
	rcall	beep_c
	rcall	delay_short
loud_2s:
	rcall	beep_c
	rcall	delay_short
	rcall	beep_c
	rcall	delay_short
;	rjmp	ws_bb_2
ws_bb_2:
	sei
stop_motor:
	disable_pwm r_temp1
	all_output_off
	ldi		r_temp1,low(STARTUP_PWM)
	ldi		r_temp2,high(STARTUP_PWM)
	sts		mem_st_pwm_duty,r_temp1
	sts		mem_st_pwm_duty+1,r_temp2
	

continue_brake:
	rcp_ready
;	and		stop_countdown,stop_countdown
;	breq	cko_1
;	dec		stop_countdown
;cko_1:
	rcall	evaluate_rcp
	motor_dir r_temp1
	cpi		r_temp1,STOP
	breq	sys_voltage
	cpi		r_temp1,BRAKE
	breq	brake_motor
	rjmp	start_motor
brake_motor:
	sbrs	flag1,MOTOR_MOVE
	rjmp	brake_done

	
	ldi		r_temp1,BRAKE_ON
	mov		state_on,r_temp1
	ldi		r_temp1,BRAKE_OFF
	mov		state_off,r_temp1
	
	ldi		r_temp1,low(BRAKE_PWM)	
	ldi		r_temp2,high(BRAKE_PWM)
	set_pwm	r_temp1,r_temp2
	enable_pwm r_temp1
	cbr		flag1,1<<tcnt0_h_ovf
	ldi		r_temp1,8
brake_delay:

	sbrs	flag1,tcnt0_h_ovf
	rjmp	brake_delay
	cbr		flag1,1<<tcnt0_h_ovf
	dec		r_temp1
	brne	brake_delay
	disable_pwm r_temp1
;	all_output_off
	rjmp	continue_brake
brake_done:

; check system voltage
; do something about system voltage checking
sys_voltage:
	rcall	check_battery
	ac_select r_temp1,fb_a
	rjmp	stop_motor

; 高速模式
running_mode:
	brtc	before_zc_wait		; rcp ready?
	clt							; .. yes
	rcall	evaluate_rcp
	;rcall	debug_rcp
	motor_dir r_temp1
	cpi		r_temp1,STOP
	breq	sys_voltage
	cpi		r_temp1,BRAKE
	breq	brake_motor
	set_pwm pwm_duty_l,pwm_duty_h
	sbrc	flag1,full_power
	rjmp	before_zc_wait
	enable_pwm r_temp1
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
	brcs	before_zc_wait
eval_zero_cross:
;------------------------------------------------------	
; evaluate zero-crossing
	mov		r_temp2,state_index
	ldi		r_temp1,ZERO_CROSS_TIME
	motor_dir r_temp3
	ldi		r_temp4,FORWARD
	cpse	r_temp3,r_temp4
	inc		r_temp2
	sbrc	r_temp2,0
	rjmp	zc_wait_high
zc_wait_low:
	sbic	ACSR,ACO
	rjmp	zc_not_happen
	nop
	nop
	nop
	nop
	dec		r_temp1
	breq	zc_happen
	rjmp	zc_wait_low
zc_wait_high:
	sbis	ACSR,ACO
	rjmp	zc_not_happen
	nop
	nop
	nop
	nop
	dec		r_temp1
	breq	zc_happen
	rjmp	zc_wait_high
; zero-crossing was just happen.
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
	brcc	zc_timeout				;zero-cross timeout?
	rjmp	eval_zero_cross			; .. no
zc_timeout:
;	rjmp	run_again
	ldi		r_temp1,ZC_TIMEOUT_LMT
	cp		zc_timeout_cnt,r_temp1
	brcs	zct_1
	lds		r_temp1,mem_st_pwm_duty
	lds		r_temp2,mem_st_pwm_duty+1
	ldi		r_temp3,low(ST_PWM_INCREMENT)
	add		r_temp1,r_temp3
	adc		r_temp2,zero
	sts		mem_st_pwm_duty,r_temp1
	sts		mem_st_pwm_duty+1,r_temp2
	rjmp	run_again
zct_1:
	inc		zc_timeout_cnt
	; zero-cross timeout, force to next commutation

	rjmp	set_com_length
zc_happen:
	and 	zc_timeout_cnt,zc_timeout_cnt	; continiously zero-cross happen?
	brne	zch_1							; .. no
	ldi		r_temp1,low(STARTUP_PWM)		; .. yes
	ldi		r_temp2,high(STARTUP_PWM)
	sts		mem_st_pwm_duty,r_temp1
	sts		mem_st_pwm_duty+1,r_temp2
zch_1:
	clr		zc_timeout_cnt
;------------------------------------------------------	
set_com_length:

	lds		r_temp3,mem_last_tcnt2
	lds		r_temp4,mem_last_tcnt2+1
	set_current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4

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
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	ror		r_temp2
	ror		r_temp1

	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	movw	r_temp3,r_temp1
	lsr		r_temp4
	ror		r_temp3
;	lsr		r_temp4
;	ror		r_temp3
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	sts		mem_zc_timeout,r_temp3
	sts		mem_zc_timeout+1,r_temp4
	lsr		r_temp2
	ror		r_temp1
	sts		mem_wait_zc,r_temp1
	sts		mem_wait_zc+1,r_temp2

; check system voltage
; jump to system halt if system voltage is failure
	rcall	check_battery
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
	;brcs	run_phase_change_exit
	brcs	wait_before_sw_state
	; 自动模式换相
	motor_dir r_temp1
	cpi		r_temp1,FORWARD
	brne	dec_state
	inc		state_index
	mov		r_temp1,state_index
	cpi		r_temp1,6
	brne	run_phase_change_1
	clr		state_index
	rjmp	run_phase_change_1
dec_state:
	dec		state_index
	brpl	run_phase_change_1			; jump if N = 0
	ldi		r_temp1,5
	mov		state_index,r_temp1
	
run_phase_change_1:
	;set_pwm pwm_duty_l,pwm_duty_h
	rcall	sw_state
	set_current_tcnt2 r_temp1,r_temp2	; switch state checkpoint
	rjmp	running_mode
; 启动马达
start_motor:
;	rjmp	break_point
; determinae the direction of previous
; 判断当前的转向是否与上一次相同
;	motor_dir r_temp1
;	cpi		r_temp1,FORWARD
;	breq	sm_1
;	sbrs	flag1,PREV_REVERSE	; Same as previous direction?
;ext_go_startup:
;	rjmp	startup_mode		; .. no
;	rjmp	run_again			; .. yes
;sm_1:
;	sbrc	flag1,PREV_REVERSE	; Same as previous direction?
;	rjmp	startup_mode		; .. no
								; .. yes

run_again:

	disable_pwm r_temp1,r_temp2
	all_output_off
	ac_select r_temp1,fb_a
run_again_1:
	current_tcnt2 r_temp1,r_temp2
; r4:r5 were used as pwm_duty during running mode, but it's safety to use here
	movw	pwm_duty_l,r_temp1
; find start signal(zero-cross)
ra_first_zc:
	current_tcnt2 r_temp1,r_temp2
	movw	r_temp3,r_temp1
	sub		r_temp1,pwm_duty_l
	sbc		r_temp2,pwm_duty_h
	subi	r_temp1,low(18000)
	sbci	r_temp2,high(18000)
	brcc	go_startup
	sbis	ACSR,ACO
	rjmp	ra_first_zc
	movw	pwm_duty_l,r_temp3

ra_fzc_1:
	current_tcnt2 r_temp1,r_temp2
	movw	r_temp3,r_temp1
	sub		r_temp1,pwm_duty_l
	sbc		r_temp2,pwm_duty_h
	subi	r_temp1,low(18000)
	sbci	r_temp2,high(18000)
	brcc	go_startup
	sbic	ACSR,ACO
	rjmp	ra_fzc_1
	movw	pwm_duty_l,r_temp3
	clr		r_temp3
; --
ra_scan_zc:
	current_tcnt2 r24,r25
	movw	r_temp1,r24
	sub		r_temp1,pwm_duty_l
	sbc		r_temp2,pwm_duty_h
	ldi		r_temp4,high(18000)
	cpi		r_temp1,low(18000)
	cpc		r_temp2,r_temp4
	brcc	go_startup
	sbrs	r_temp3,0
	rjmp	ra_wait_high
	; wait low
	sbic	ACSR,ACO
	rjmp	ra_scan_zc
	rjmp	ra_zc_happen
go_startup:
	rjmp	startup_mode
ra_wait_high:
	sbis	ACSR,ACO
	rjmp	ra_scan_zc
ra_zc_happen:

	ldi		r_temp4,high(500)
	cpi		r_temp1,low(500)
	cpc		r_temp2,r_temp4			; run too fast?
	brcs	run_again_1				; .. yes, wait motor slow down
	movw	pwm_duty_l,r24
	inc		r_temp3
	cpi		r_temp3,4
	brne	ra_scan_zc
; --

	sts		mem_last_tcnt2,r24
	sts		mem_last_tcnt2+1,r25
;	set_current_tcnt2 r_temp3,r_temp4
	sts		mem_a_l,r_temp1
	sts		mem_a_h,r_temp2
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
	motor_dir r_temp1
	cpi		r_temp1,FORWARD
	breq	ra_foward
	; reverse
	ldi		r_temp1,4				; current is state 5 for reverse, next is 4
	sbr		flag1,1<<PREV_REVERSE
	rjmp	ra_1
ra_foward:
	; forward
	cbr		flag1,1<<PREV_REVERSE
	ldi		r_temp1,3				; current is state 2 for forward, next is 3
ra_1:
	mov		state_index,r_temp1
	lds		pwm_duty_l,mem_st_pwm_duty
	lds		pwm_duty_h,mem_st_pwm_duty+1
	rcall	sw_state
	set_pwm	pwm_duty_l,pwm_duty_h
	enable_pwm r_temp1
	rjmp	running_mode


startup_mode:

	clr		state_index
	; 后面这2句貌似避免了电调容易重启的现象
	clr		state_on
	clr		state_off
;	lds		r_temp1,mem_st_pwm_duty
;	lds		r_temp2,mem_st_pwm_duty+1
	clr		r_temp1
	clr		r_temp2
	set_pwm	r_temp1,r_temp2

	ldi		r_temp1,STARTUP_STEPS
	mov		r12,r_temp1
	enable_pwm r_temp1
startup_loop:
	lds		r_temp1,mem_st_pwm_duty
	lds		r_temp2,mem_st_pwm_duty+1
	ldi		r_temp3,low(STARTUP_PWM/STARTUP_STEPS)
	ldi		r_temp4,high(STARTUP_PWM/STARTUP_STEPS)
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	sts		mem_st_pwm_duty,r_temp1
	sts		mem_st_pwm_duty+1,r_temp2
	
	set_pwm	r_temp1,r_temp2
	rcall	sw_state
	current_tcnt2 r_temp1,r_temp2
	movw	r4,r_temp1
	ldi		r_temp1,low(STARTUP_COM_LENGTH)
	sts		mem_com_length,r_temp1
	ldi		r_temp1,high(STARTUP_COM_LENGTH)
	sts		mem_com_length+1,r_temp1
st_loop1:
	current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r4
	sbc		r_temp2,r5
	subi	r_temp1,low(STARTUP_COM_LENGTH)
	sbci	r_temp2,high(STARTUP_COM_LENGTH)
	brcs	st_loop1
	motor_dir r_temp1
	cpi		r_temp1,FORWARD
	brne	st_dec_state
	; forward
	cbr		flag1,1<<PREV_REVERSE
	inc		state_index
	ldi		r_temp1,6
	cp		state_index,r_temp1
	brne	st_2
	clr		state_index
	rjmp	st_2
st_dec_state:
	; reverse
	sbr		flag1,1<<PREV_REVERSE
	dec		state_index
	brpl	st_2
	ldi		r_temp1,5
	mov		state_index,r_temp1
st_2:
	dec		r12
	breq	startup_exit
	current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,pwm_duty_l
	sbc		r_temp2,pwm_duty_h
	lsr		r_temp2
	ror		r_temp1
	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	rjmp	startup_loop
startup_exit:

	; enter running mode
	rcall	sw_state
	set_current_tcnt2 r_temp1,r_temp2

	lds		r_temp1,mem_com_length
	lds		r_temp2,mem_com_length+1
	lsr		r_temp2
	ror		r_temp1
	sts		mem_com_length,r_temp1
	sts		mem_com_length+1,r_temp2
	sts		mem_zc_timeout,r_temp1
	sts		mem_zc_timeout+1,r_temp2
	lsr		r_temp2
	ror		r_temp1
	sts		mem_wait_zc,r_temp1
	sts		mem_wait_zc+1,r_temp2

;	ldi		r_temp1,low(STARTUP_COM_LENGTH/2)
;	ldi		r_temp2,high(STARTUP_COM_LENGTH/2)
;	sts		mem_com_length,r_temp1
;	sts		mem_com_length+1,r_temp2
;	sts		mem_zc_timeout,r_temp1
;	sts		mem_zc_timeout+1,r_temp2
;	ldi		r_temp1,low(STARTUP_COM_LENGTH/4)
;	ldi		r_temp2,high(STARTUP_COM_LENGTH/4)
;	sts		mem_wait_zc,r_temp1
;	sts		mem_wait_zc+1,r_temp2

	lds		r_temp1,mem_st_pwm_duty
	lds		r_temp2,mem_st_pwm_duty+1
	movw	pwm_duty_l,r_temp1

	rjmp	running_mode
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
	brne	t0ovfl_2
	rjmp	rcp_error
t0ovfl_2:
	sbr		flag1,1<<tcnt0_h_ovf
t0ovfl_exit:
	out		SREG,i_sreg
	reti
rcp_error:
	pop		r_temp1
	pop		r_temp1
	disable_pwm r_temp1
	all_output_off
	sei
	ldi		r_temp1,RCP_ERROR_COUNT
	ldi		r_temp2,30
re_1:
	mov		rcp_error_cnt,r_temp1
	brtc	re_1
	clt
	dec		r_temp2
	brne	re_1
	rjmp	rcp_resume
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
.include "../brushless/sound.inc"
delay_half_sec:
	cbr		flag1,1<<tcnt0_h_ovf
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
; x = pwm_duty_h:pwm_duty_l 为结果
; a = current rcp
; b = max rcp
; c = top pwm
x_function:
;	sts		mem_last_pwm_duty,pwm_duty_l
;	sts		mem_last_pwm_duty+1,pwm_duty_h
	clr		r24
	clr		r25
    rjmp	x_2
x_1:
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
x_2:
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
    add		r24,r16
    adc		r25,r17
    rjmp	x_1
x_3:
	ret
evaluate_rcp:
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
	ldi		r_temp3,low(RCP_STOP_AREA)
	ldi		r_temp4,high(RCP_STOP_AREA)
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	motor_dir r24
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcs	scan_stop_n_rev
	; HIGH rcp
	sbrs	flag1,PREV_REVERSE				; before of previous situation is reverse?
	rjmp	forward_pwm						; .. no, go forward immediately
	; previous status	operate
	; brake				run forward
	; reverse			brake
	; forward			run foward
	; stop				go brake or run forward

	cpi		r24,REVERSE
	breq	er_1
	rcall	check_running
;	cpi		r_temp1,1		; 1 indicate motor running, 0 motor stop
	sbrs	flag1,MOTOR_MOVE
	rjmp	forward_pwm
er_1:
	motor_brake
	rjmp	evaluate_exit
scan_stop_n_rev:
	cbr		flag1,1<<full_power
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
	subi	r_temp1,low(RCP_STOP_AREA)
	sbci	r_temp2,high(RCP_STOP_AREA)
	cp		rcp_l,r_temp1
	cpc		rcp_h,r_temp2
	brcs	rev_or_brake
	; neutral rcp
	motor_stop
	rjmp	evaluate_exit
forward_pwm:
	motor_forward
	ldi		r_temp3,low(RCP_HIGH)
	ldi		r_temp4,high(RCP_HIGH)
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcs	cfp_1
	rjmp	set_full_power_exit
cfp_1:
	cbr		flag1,1<<full_power
	lds		r_temp3,mem_max_forward_rcp
	lds		r_temp4,mem_max_forward_rcp+1
; a = current rcp
; b = max rcp
; c = top pwm
	sts		mem_b_l,r_temp3
	sts		mem_b_h,r_temp4
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
	movw	r_temp3,rcp_l
	sub		r_temp3,r_temp1
	sbc		r_temp4,r_temp2
	sts		mem_a_l,r_temp3
	sts		mem_a_h,r_temp4
	ldi		r_temp3,low(PWM_TOP)
	ldi		r_temp4,high(PWM_TOP)
	sts		mem_c_l,r_temp3
	sts		mem_c_h,r_temp4
	rcall	x_function
;	ldi		r_temp1,low(STARTUP_PWM)
;	ldi		r_temp2,high(STARTUP_PWM)
;	cp		r24,r_temp1
;	cpc		r25,r_temp2
;	brcc	sfp_2
;	movw	pwm_duty_l,r_temp1
;	rjmp	evaluate_exit
;sfp_2:
	movw	r_temp1,pwm_duty_l
;	lds		r_temp1,mem_last_pwm_duty
;	lds		r_temp2,mem_last_pwm_duty+1
	cp		r_temp1,r24
	cpc		r_temp2,r25
	brcc	cfp_2
	ldi		r_temp3,low(PWM_INCREMENT)
	ldi		r_temp4,high(PWM_INCREMENT)
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	cp		r_temp1,r24
	cpc		r_temp2,r25
	brcc	cfp_2
	movw	pwm_duty_l,r_temp1
	rjmp	evaluate_exit
cfp_2:
	movw	pwm_duty_l,r24
	rjmp	evaluate_exit
rev_or_brake:
	; low rcp
	sbrc	flag1,PREV_REVERSE
	rjmp	reverse_pwm
	cpi		r24,FORWARD
	breq	rob_1
	rcall	check_running
	cpi		r24,BRAKE
	breq	rob_1
;	cpi		r_temp1,1		; 1 indicate motor running, 0 motor stop
	sbrs	flag1,MOTOR_MOVE
	rjmp	reverse_pwm
rob_1:
	motor_brake
	rjmp	evaluate_exit
reverse_pwm:
; TODO: HERE WILL ADD DISABLE REVERSE FUNCTION
	sbrs	flag2,NO_REVERSE
	rjmp	rpwm_1
	motor_stop
	rjmp	evaluate_exit
rpwm_1:
	motor_reverse
;	sbrc	flag1,STARTUP
;	rjmp	evaluate_exit
	; calculate reverse pwm, half power
; a = current rcp
; b = max rcp
; c = top pwm
	lds		r_temp1,mem_max_reverse_rcp
	lds		r_temp2,mem_max_reverse_rcp+1
	sts		mem_b_l,r_temp1
	sts		mem_b_h,r_temp2
	movw	r_temp3,rcp_l
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	sts		mem_a_l,r_temp1
	sts		mem_a_h,r_temp2
	ldi		r_temp3,low(PWM_TOP)
	ldi		r_temp4,high(PWM_TOP)
	sts		mem_c_l,r_temp3
	sts		mem_c_h,r_temp4
	rcall	x_function
	lsr		r25
	ror		r24

	movw	r_temp1,pwm_duty_l
	cp		r_temp1,r24
	cpc		r_temp2,r25
	brcc	rp_1
	ldi		r_temp3,low(PWM_INCREMENT)
	ldi		r_temp4,high(PWM_INCREMENT)
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	cp		r_temp1,r24
	cpc		r_temp2,r25
	brcc	rp_1
	movw	pwm_duty_l,r_temp1
	rjmp	evaluate_exit
rp_1:
	movw	pwm_duty_l,r24
;	ldi		r_temp1,low(STARTUP_PWM)
;	ldi		r_temp2,high(STARTUP_PWM)
;	cp		pwm_duty_l,r_temp1
;	cpc		pwm_duty_h,r_temp2
;	brcc	evaluate_exit
;	movw	pwm_duty_l,r_temp1
	rjmp	evaluate_exit
set_full_power_exit:
	movw	r_temp1,pwm_duty_l
	ldi		r_temp3,low(PWM_INCREMENT)
	ldi		r_temp4,high(PWM_INCREMENT)
	add		r_temp1,r_temp3
	adc		r_temp2,r_temp4
	cpi		r_temp1,low(PWM_TOP-100)
	ldi		r_temp3,high(PWM_TOP-100)
	cpc		r_temp2,r_temp3
	brcs	sfpe_1
	ldi		r_temp1,low(PWM_TOP+100)
	ldi		r_temp2,high(PWM_TOP+100)
.if	HAS_FULLPOWER == 1
	sbr		flag1,1<<full_power
.endif
;	rjmp	evaluate_exit
sfpe_1:
	movw	pwm_duty_l,r_temp1
;	rjmp	evaluate_exit
evaluate_exit:
	ret

check_running:
	current_tcnt2 r_temp3,r_temp4
cr_1:
	current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	subi	r_temp1,low(18000)
	sbci	r_temp2,high(18000)
	brcs	cr_2
	cbr		flag1,1<<MOTOR_MOVE
	rjmp	cr_exit
cr_2:
	sbis	ACSR,ACO
	rjmp	cr_1
	current_tcnt2 r_temp3,r_temp4
cr_3:
	current_tcnt2 r_temp1,r_temp2
	sub		r_temp1,r_temp3
	sbc		r_temp2,r_temp4
	subi	r_temp1,low(18000)
	sbci	r_temp2,high(18000)
	brcs	cr_4
	cbr		flag1,1<<MOTOR_MOVE
	rjmp	cr_exit
cr_4:
	sbic	ACSR,ACO
	rjmp	cr_3
	sbr		flag1,1<<MOTOR_MOVE
cr_exit:
	ret


delay_short:
	ldi		r_temp2,255
ds_0:
	ldi		r_temp1,255
ds_1:
	dec		r_temp1
	brne	ds_1
	dec		r_temp2
	brne	ds_0
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
	
	cpi		r18,3			; divided by 3
	brcc	d_1
	rjmp	d_2
d_1:
	subi	r18,3			; divided by 3
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

check_battery:
; ACSR [ACD|ACBG|ACO|ACI|ACIE|ACIC|ACIS1|ACIS0]
; ACME 

; ADMUX [REFS1|REFS0|ADLAR|-|MUX3|MUX2|MUX1|MUX0]
; REFS1:0= 1:1 iNTERNAL 2.56v Voltage Reference with external capacitor at AREF pin
; ADLAR = 1  left adjust the result
; MUX3-0 = 0111  ADC7 system voltage sample pin
	ldi		r_temp1,0b11100111
	out		ADMUX,r_temp1
; ADCSRA [ADEN|ADSC|ADFR|ADIF|ADIE|ADPS2|ADPS1|ADPS0]
; ADEN = 1 ADC enabled
; ADSC = 1 write this bit to one to start the first conversion.
; ADFR = 0 When this bit is set (one) the ADC operates in Free Running mode.
; ADIF = 1 This bit is set when an ADC conversion completes and the Data Registers are updated.
;		   ADIF is cleared by writing a logical one to the flag.
; ADIE = 0 When this bit is written to one and the I-bit in SREG is set, the ADC Conversion Complete Interrupt is activated.
; ADPS2:1:0 = 100 Division Factor = 16
	ldi		r_temp1,0b11010100
	out		ADCSRA,r_temp1
;	sbi		ADCSRA,ADSC
wait_adc:
	sbis	ADCSRA,ADIF
	rjmp	wait_adc
	in		r_temp1,ADCH
	lds		r_temp2,mem_shutdown_v
	cp		r_temp1,r_temp2
	brcs	battery_fail
	sts		mem_btty_fail_cnt,zero
	ret
battery_fail:
	lds		r_temp1,mem_btty_fail_cnt
	cpi		r_temp1,4
	brcc	bf_1
	inc		r_temp1
	sts		mem_btty_fail_cnt,r_temp1
	ret
bf_1:
	pop		r_temp1
	pop		r_temp1
	cli
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
	rjmp	sys_halt

halt_beep:
	cli
	motor_dir r_temp1
	cpi		r_temp1,STOP
	;brne	sys_halt
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
sys_halt:
	cli
	out		PORTD,zero
infinity:
	rjmp	infinity

set_battery_type:
	ldi		r_temp3,EEP_BATTERY_TYPE
	clr		r_temp4
	rcall	eep_read
	cpi		r_temp1,BTYPE_LIPO
	breq	sbt_1
	ldi		r_temp1,BTYPE_LIPO
	rjmp	sbt_2
sbt_1:
	ldi		r_temp1,BTYPE_NIHM
sbt_2:
	rcall	eep_write
	ret
set_reverse_or_not:
	ldi		r_temp3,EEP_REVERSE
	clr		r_temp4
	rcall	eep_read
	cpi		r_temp1,NO_REVERSE_VALUE
	breq	sron_1
	ldi		r_temp1,NO_REVERSE_VALUE
	rjmp	sron_2
sron_1:
	clr		r_temp1
sron_2:
	rcall	eep_write
	ret
beep_option:
	cli
	push	r_temp1
	rcall	beep_b
	rcall	delay_short
	pop		r_temp1
	dec		r_temp1
	brne	beep_option

	ldi		r_temp1,100
	ldi		r_temp2,20
	ldi		r_temp3,low(RCP_LOW+RCP_STOP_AREA*2)
	ldi		r_temp4,high(RCP_LOW+RCP_STOP_AREA*2)
	sei
bo_1:
	rcp_ready
	dec		r_temp1
	breq	bo_exit
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcs	bo_1
	dec		r_temp2
	brne	bo_1
bo_exit:
	ret
; this function will disabled all interrupts
beep_confirm:
	ldi		r_temp1,25
	ldi		r_temp2,25
	ldi		r_temp3,low(RCP_HIGH-RCP_STOP_AREA*2)
	ldi		r_temp4,high(RCP_HIGH-RCP_STOP_AREA*2)
bc_1:
	rcp_ready
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcc	bc_2
	dec		r_temp2
	breq	bc_exit
	rjmp	bc_1
bc_2:
	dec		r_temp1
	brne	bc_1
	cli
	rcall	beep_c
	rcall	beep_c
	ldi		r_temp2,1		; set none zero
bc_exit:
	ret
;rcp_ready:
;	brtc	rcp_ready
;	clt
;	ret


; debug *****************************************************
.if 1==2
debug_rcp:
	motor_dir r24
	lds		r_temp1,mem_rcp_neutral
	lds		r_temp2,mem_rcp_neutral+1
	ldi		r_temp3,low(RCP_STOP_AREA)
	ldi		r_temp4,high(RCP_STOP_AREA)
	add		r_temp3,r_temp1
	adc		r_temp4,r_temp2
	cp		rcp_l,r_temp3
	cpc		rcp_h,r_temp4
	brcs	d_stop_low_rcp
	cpi		r24,REVERSE
	breq	d_go_brake
	cpi		r24,BRAKE
	breq	d_go_stop
	cpi		r24,STOP
;	brne	d_forward_1
;	subi	r_temp1,100
;	sbc		r_temp2,zero
;	sts		mem_rcp_neutral_v,r_temp1
;	sts		mem_rcp_neutral_v+1,r_temp2
;d_forward_1:
	motor_forward
	;ldi		r_temp3,100
	ldi		r_temp1,low(800)
	ldi		r_temp2,high(800)
	movw	pwm_duty_l,r_temp1
	ret
d_go_brake:
	motor_brake
	ret
d_go_stop:
	motor_stop
	ret
d_stop_low_rcp:
	subi	r_temp1,low(RCP_STOP_AREA)
	sbci	r_temp2,high(RCP_STOP_AREA)
	cp		rcp_l,r_temp1
	cpc		rcp_h,r_temp2
	brcs	d_low_rcp
	; stop
	motor_stop
	ret
d_low_rcp:
	cpi		r24,FORWARD
	breq	d_go_brake
	cpi		r24,BRAKE
	breq	d_go_brake
	cpi		r24,STOP
;	brne	d_reverse_1
;	ldi		r_temp3,100
;	add		r_temp1,r_temp3
;	adc		r_temp2,zero
;	sts		mem_rcp_neutral_v,r_temp1
;	sts		mem_rcp_neutral_v+1,r_temp2
	
;d_reverse_1:
	motor_reverse

	ldi		r_temp1,low(400)
	ldi		r_temp2,high(400)
	movw	pwm_duty_l,r_temp1
	ret
save_word:
	lds		r_temp3,mem_debug_cnt
	cpi		r_temp3,100
	brcc	sa_exit
	ldi		yl,low(mem_debug_data)
	ldi		yh,high(mem_debug_data)
	add		r_temp3,r_temp3
	add		yl,r_temp3
	adc		yh,zero
	st		Y+,r_temp1
	st		Y,r_temp2
	lds		r_temp3,mem_debug_cnt
	inc		r_temp3
	sts		mem_debug_cnt,r_temp3
sa_exit:
	ret
buff2eep:
	cli
	ldi		r_temp2,200
	ldi		r_temp3,6
	ldi		r_temp4,0
	ldi		yl,low(mem_debug_data)
	ldi		yh,high(mem_debug_data)
w2p_1:
	ld		r_temp1,Y+
	rcall	eep_write
	inc		r_temp3
	dec		r_temp2
	brne	w2p_1
	rjmp	sys_halt
debug_adc:
	cli
	out		TCCR1B,zero
	out		TCNT1H,zero
	out		TCNT1L,zero
	ldi		r20, (1<<CS10)
	out		TCCR1B,r20
	rcall	check_battery
	out		TCCR1B,zero
	in		r_temp1,TCNT1L
	in		r_temp2,TCNT1H

	ldi		r18,0
	ldi		r19,0
	rcall	eep_write
	inc		r18
	mov		r16,r17
	rcall	eep_write

	out		TCCR1B,zero
	out		TCNT1H,zero
	out		TCNT1L,zero
	ldi		r20, (1<<CS10)
	out		TCCR1B,r20
	rcall	check_battery
	out		TCCR1B,zero
	in		r_temp1,TCNT1L
	in		r_temp2,TCNT1H

	ldi		r18,2
	ldi		r19,0
	rcall	eep_write
	inc		r18
	mov		r16,r17
	rcall	eep_write



	rjmp 	halt_beep

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
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rcall	beep_a
	rjmp	sys_halt
.endif
; debug end *************************************************

.exit
