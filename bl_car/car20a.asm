;原装的程序在启动和高速模式时,PWM更新会有渐进增加,导致加速缓慢.
;这个版本需要暴力的加速,因此在高速时取消这段代码,在启动模式,
;限制RCP功率在75%一下,以避免开机是功率太大导致电调重启.
; 搜索关键字PWM_ACCELERATION， 可找到这段代码
; 这里是修改限制功率加速度的程度。

; 2012-8-31 作为一个生产版本应用在第一份订单中


; 16m 主频 需要晶振.
.include "m8def.inc"
.include "../brushless/18_3p.inc"
;.include "../brushless/t50.inc"

.equ APL1 =	(1<<cpFET)+(1<<anFET)
.equ APL2 =	(1<<cpFET)
.equ APL3 =	(1<<bpFET)+(1<<anFET)
.equ APL4 = (1<<bpFET)
.equ APL5 = (1<<bpFET)+(1<<cnFET)
.equ APL6 =	(1<<bpFET)
.equ APL7 =	(1<<apFET)+(1<<cnFET)
.equ APL8 =	(1<<apFET)
.equ APL9 =	(1<<apFET)+(1<<bnFET)
.equ APLA =	(1<<apFET)
.equ APLB =	(1<<cpFET)+(1<<bnFET)
.equ APLC =	(1<<cpFET)

.def		flag1	= r25
.def		flag2	= r24

.macro rcp_ready
rcp_ready1:
	sbrs	flag1,RCP_updated
	rjmp	rcp_ready1
	cbr		flag1,1<<RCP_updated
.endm
.macro ac_select
	In		@0,ADMUX
	Andi	@0,0xF0
	Ori		@0,@1
	Out		ADMUX,@0
.endm

.macro run_t1
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

.macro pause_t2
;TCCR2
;CS22-0: 010 prescaler in clk/8
	ldi		@0,0
	out		TCCR2,@0
.endm
.macro run_t2
	ldi		@0,(1<<CS21)
	out		TCCR2,@0
.endm
; flag2 system flag
.macro	motor_idle
	andi	flag2,0b11111100
.endm
.equ		IDLE	= 0
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



.def	rcp_top_l		= r2
.def	rcp_top_h		= r3
.def	rcp_bottom_l	= r4
.def	rcp_bottom_h	= r5
.def	tcnt0h			= r6
.def	state_on		= r8
.def	state_off		= r9
.def	rcp_l			= r10
.def	rcp_h			= r11
.def	rcp_error_cnt	= r12
.def	pwm_duty		= r14
.def	tcnt2h			= r15

; memories definition
.equ	mem_eep_addr	= 0x0070
.equ	mem_eep_data	= 0x0071
.equ	mem_state7_period = 0x0072	; 2 bytes
.equ	mem_neutral_rcp	= 0x0074	; 2 bytes
.equ	mem_states		= 0x0080	; 12 bytes
.equ	mem_rcp_temp	= 0x00a2	; 2 bytes
.equ	mem_admux		= 0x00a4
.equ	mem_brake_lmt_voltage	= 0x00a8	; 2 bytes
; 倒车功率, 1:无倒车 2:100%, 3:50%, 4: 25%
.equ	mem_reverse_pwm_factor = 0x00b6
.equ	mem_brake_param = 0x00b7
.equ	mem_r0_temp		= 0x00b8
.equ	mem_r1_temp		= 0x00b9
.equ	mem_r2_temp		= 0x00ba

.equ	mem_temp_90		= 0x0090
.equ	mem_temp_91		= 0x0091
.equ	mem_temp_92		= 0x0092
.equ	mem_com_period_96	= 0x0096		; 2 bytes
.equ	mem_temp2		= 0x0098
.equ	mem_temp1		= 0x0099
;commutation period
.equ	mem_unknown_9c	= 0x009c		; 2 bytes
.equ	mem_com_period_a0	= 0x00a0	; 2 bytes
.equ	mem_volt_protect	= 0x00a6		;2 bytes
.equ	mem_low_power_count		= 0x00aa
.equ	mem_sys_voltage = 0x00ab

.equ	mem_st_pwm_duty	= 0x00b0
.equ	mem_unknown_bb	= 0x00bb		; 2 bytes
.equ	mem_unknown_bd	= 0x00bd		; 2 bytes
.equ	mem_parameters	= 0x0100

.equ	mem_mcucsr		= 0x0060

;this flag work	with flag1
;.equ	no_idle	= 7
.equ	RCP_updated	= 6
.equ	direction	= 5				; 0=System working CV	, 1=System Working CCV
.equ	weak_power = 4
.equ	tcnt2h_ovf = 3
.equ	unknown_option_xh_2 = 2
;.equ	Break_flag_on =	1
.equ	unknown_option_xh_0 = 0


;电压保护
.equ	V55		= 200
;.equ	V55		= 176
.equ	V60		= 218
;.equ	V60		= 190
.equ	V90		= 327
;.equ	V90		= 286
.equ	V120	= 436
;.equ	V120	= 384

;.equ lipo2_3    = 320   ; <Lipo2_3 adc就是2lipo, >Lipo2_3就是3lipo


; 2way 相关修改关键字 "way"
; flag2 system flag
; direction: 0 run at reverse , 1 run at forward
;.equ	direction	= 2
;.equ	Wast_Time_2Way = 25			; RCP counter. it just skip that system frequency speed.
.equ	RCP_IDLE_ZONE = 60			; 0 <= RCP_IDLE_ZONE <= 63

; rcp allow range from 600 us to 2400 us on timer0
.equ	RCP_ALLOW_H	= 5000			; legal rcp must between RCP_ALLOW_L and RCP_ALLOW_H
.equ	RCP_ALLOW_L	= 1258

.equ	Mid_RCP		= 3000			; 16M_Mid= 3000, 8M_Mid= 1500	1430 us
.equ	Low_RCP		= 2300			; 16M_Mid= 2300, 8M_Mid= 1150	1096 us
.equ	Hig_RCP		= 3700			; 16M_Mid= 3700, 8M_Mid= 1850	1764 us


; neutral area 1192 ~ 1478 us
.equ	RCP_NEUTRAL_AREA_H=Mid_RCP+300
.equ	RCP_NEUTRAL_AREA_L=Mid_RCP-500

.equ	PWM_TOP_8K		= 1998
.equ	PWM_TOP_16K		= 999
.equ	PWM_TOP_32K		= 499

;.equ	RCP_ERROR_COUNT	= 100
; 为了让开关可以一控制马达。减少丢失RCP以后控制马达在0.5秒后停止
.equ	RCP_ERROR_COUNT	= 5
; 2way about
; 1*, Make_It_Two_Way
; 2*, init运动池的时候加入方向判别. Sbr Cbr
; 3 , 锁定 MinRCP = 1.2, MaxRCP = 1.8, 这样可以和应1.5中杆的对称性.
; 4 , 关闭游戏
; 5*, evaluate_rcp在调用Make_It_Two_Way之前的爆高低杆处理修改.

;Master

;.equ	SoundOn	= 0b00101000	;0x28
;.equ	SoundOff= 0

;.equ	NoneOutput = 0


.cseg
.org 0
	Rjmp	Reset					;+0000000: C01F		; Destination: 0x000020
	Rjmp	ext0_int				;+0000001: C0C2		; Destination: 0x0000C4
	Rjmp	Reset					;+0000002: FFFF
	Reti							;+0000003: 9518
	Rjmp	t2_ovf_int				;+0000004: C0AD		; Destination: 0x0000B2
	Rjmp	Reset					;+0000005: FFFF
	rjmp	oc1a_int				;+0000006: C0A3		; Destination: 0x0000AA
	Rjmp	oc1b_int				;+0000007: C0A7		; Destination: 0x0000AF
	Rjmp	t1_ovf_int				;+0000008: C09F		; Destination: 0x0000A8
	Rjmp	t0_ovf_int				;+0000009: C079		; Destination: 0x000083
	Rjmp	Reset					;+000000A: FFFF
	Rjmp	Reset					;+000000B: FFFF
	Rjmp	Reset					;+000000C: FFFF
	Rjmp	Reset					;+000000D: FFFF
	Rjmp	Reset	;Rjmp	AL008			;+000000E: C0F6		; Destination: 0x000105
	Rjmp	Reset					;+000000F: FFFF
	Rjmp	Reset	;rjmp	AL009					;+0000010: C2C2		; Destination: 0x0002D3
	Rjmp	Reset					;+0000011: FFFF
	Rjmp	Reset					;+0000012: FFFF

Reset:
	ldi	r16, high(RAMEND)
	out	SPH,r16
	ldi	r16, low (RAMEND)
	out	SPL,r16

	in		r17,MCUCSR
	sts		mem_mcucsr,r17
	clr		r16
	out		MCUCSR,r16

	Rcall	sDDRX
	rcall	boot_checking


;debug *****************************************
	
.if 1==2
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay
	rcall	short_delay

; ADMUX [REFS1|REFS0|ADLAR|-|MUX3|MUX2|MUX1|MUX0]
; REFS1:0= 1:1 iNTERNAL 2.56v Voltage Reference with external capacitor at AREF pin
; ADLAR = 1  left adjust the result
; MUX3-0 = 0111  ADC7 system voltage sample pin
	ldi		r16,0b11000111
	out		ADMUX,r16
; ADCSRA [ADEN|ADSC|ADFR|ADIF|ADIE|ADPS2|ADPS1|ADPS0]
; ADEN = 1 ADC enabled
; ADSC = 1 write this bit to one to start the first conversion.
; ADFR = 0 When this bit is set (one) the ADC operates in Free Running mode.
; ADIF = 1 This bit is set when an ADC conversion completes and the Data Registers are updated.
;		   ADIF is cleared by writing a logical one to the flag.
; ADIE = 0 When this bit is written to one and the I-bit in SREG is set, the ADC Conversion Complete Interrupt is activated.
; ADPS2:1:0 = 100 Division Factor = 16
	ldi		r16,0b11010101
	out		ADCSRA,r16
;	sbi		ADCSRA,ADSC
wait_adc:
	sbis	ADCSRA,ADIF
	rjmp	wait_adc
;	in		r16,ADCH

	In		R16,ADCL					;+0000111: B104
	In		R17,ADCH					;+0000112: B115
	ldi		r18,0
	sts		mem_eep_addr,r18
	sts		mem_eep_data,r16
	rcall	eep_write
	ldi		r18,1
	sts		mem_eep_addr,r18
	sts		mem_eep_data,r17
	rcall	eep_write
	rcall	beep_a
	rjmp	infinity

;	rcall	beep_a
;	rcall	short_delay
;
;

	ldi		r16,BRAKE_ON
	mov		state_on,r16
	ldi		r16,APL2
	mov		state_off,r16
ddd_1:
	out		PORTD,state_on
	ldi		r16,255
ddd_2:
;	rjmp	ddd_2

	dec		r16
	brne	ddd_2
	out		PORTD,state_off
	ldi		r16,50
ddd_3:
	ldi		r17,255
ddd_4:
	dec		r17
	brne	ddd_4
	dec		r16
	brne	ddd_3
	rjmp	ddd_1
.endif



;debug end *****************************************


; Power	on Sound
; 注意声音和电池种类相关
; eep_read	是读eep,

;	rcall	Beep_H_new
;	rcall	Beep_H_new
;	rcall	Beep_H_new



;	clr		r16
;	sts		mem_neutral_rcp+1,r16
;	sts		0x00FE,	R16
;	sts		0x00FF,	R16


;	Ldi		R19,0x0A				;+0000026: E03A		; 0x0A = 0b00001010	= 10
;AL012:
;	Ldi		R16,0xFF				;+0000027: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		0x009E,R16				;+0000028: 9300009E
;	Ldi		R16,0xFF				;+000002A: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		0x009F,R16				;+000002B: 9300009F
;	Rcall	KsTim					;+000002D: 940E06CE
;	Dec		R19						;+000002F: 953A
;	Brne	AL012					;+0000030: F7B1		; Destination: 0x000027
;	Rcall	sDDRX					;+0000031: DAA0		; Destination: 0x000AD2
;	Rcall	AL013					;+0000032: 940E0C7A
;	Rcall	sw_direct					;+0000034: 940E09CA
	Rcall	setting_timer0			;+0000036: D06A		; Destination: 0x0000A1
	Rcall	setting_timer2			;+0000037: D082		; Destination: 0x0000BA
	Rcall	rising_int0_en
	Rcall	setting_adc7_pre32
AL019:
	Sbis	ADCSRA,ADIF				;+000003A: 9B34
	Rjmp	AL019					;+000003B: CFFE		; Destination: 0x00003A
	Rcall	eep2mem40					;+000003D: 940E0606
;	ANDI	flag2,0x7F				;+000003F: 77AF		; 0x7F = 0b01111111 = 127
;	Ldi		R16,0x05				;+0000040: E005		; 0x05 = 0b00000101	= 5
;	Sts		0x00BF,R16				;+0000041: 930000BF
;	Rcall	sGame					;+0000043: 940E01ED


; timing_Monitor_Disable
;	Rcall	AL022					;+0000045: 940E0C35
	Rcall	all_fet_off				;+0000047: 940E0A1A
	sbr		flag1,1<<direction
	Rcall	sw_direct					;+0000049: 940E09CA
	Rcall	setting_timer1			;+000004B: 940E0913
	Rcall	init_timer1				;+000004D: 940E0901
;	Andi	flag1,0x7F				;+000004F: 77BF		; 0x7F = 0b01111111	= 127
	ldi		R16,0				;+0000050: E000		; 0x00 = 0b00000000	= 0
	mov		pwm_duty,R16
;	don't use at car application
;	rcall	load_brake_param		;+0000052: 940E0BEE
	rcall	load_reverse
	rcall	load_volt_protect
	rcall	load_timing_adv			;+0000054: 940E0C14
;	rcall	evaluate_rcp
;	Rcall	battery_detect			;+0000057: 940E0142
;---------------------------------------------------------------------------------
;-------------------------- interrupt enable -------------------------------------
;---------------------------------------------------------------------------------
	sei								;+000003C: 9478
	ldi		r16,50
	ldi		r17,50
setting_wait:
;	sbrs	flag1,RCP_updated
;	RJMP	setting_wait
;	cbr		flag1,1<<RCP_updated
	rcp_ready
	movw	r18,rcp_l
	subi	r18,low(RCP_NEUTRAL_AREA_L)
	sbci	r19,high(RCP_NEUTRAL_AREA_L)
	brcc	main_loc_1
	dec		r16
	brne	setting_wait
	rcall	root_menu
	rjmp	detect_neutral_rcp
main_loc_1:
	dec		r17
	brne	setting_wait
detect_neutral_rcp:
	ldi		r16,25
main_loc_2:
;	sbrs	flag1,RCP_updated
;	rjmp	main_loc_2
;	cbr		flag1,1<<RCP_updated
	rcp_ready
	movw	r18,rcp_l
	subi	r18,low(RCP_NEUTRAL_AREA_L)
	sbci	r19,high(RCP_NEUTRAL_AREA_L)
	subi	r18,low(RCP_NEUTRAL_AREA_H-RCP_NEUTRAL_AREA_L)
	sbci	r19,high(RCP_NEUTRAL_AREA_H-RCP_NEUTRAL_AREA_L)
	brcc	main_loc_2
	dec		r16
	brne	main_loc_2
	; automatically detect neutral position of rcp
;	lds		r16,mem_neutral_rcp+1
;	and		r16,r16
;	brne	main_loc_3
	sts		mem_neutral_rcp,rcp_l
	sts		mem_neutral_rcp+1,rcp_h
;main_loc_3:
;waiting_for_idle:
;	ldi		r16,15
;	sts		mem_temp1,r16
;wfi_1:
;	rcp_ready
;	ldi		r16,low(RCP_IDLE_ZONE)
;	ldi		r17,high(RCP_IDLE_ZONE)
;	lds		r18,mem_neutral_rcp
;	lds		r19,mem_neutral_rcp+1
;	add		r16,r18
;	adc		r17,r19
;	cp		rcp_l,r16
;	cpc		rcp_h,r17
;	brcc	wfi_1
;	subi	r18,low(RCP_IDLE_ZONE)
;	ldi		r16,high(RCP_IDLE_ZONE)
;	sbc		r19,r16
;	cp		rcp_l,r16
;	cpc		rcp_h,r17
;	brcs	wfi_1
;	lds		r16,mem_temp1
;	dec		r16
;	sts		mem_temp1,r16
;	brne	wfi_1
	
	cli
	lds		r16,mem_parameters+21
	cpi		r16,1
	brne	loud_other
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
	rjmp	loud_end
loud_other:
	cpi		r16,3
	breq	loud_3s
	cpi		r16,4
	breq	loud_4s
	rjmp	loud_2s
loud_4s:
	rcall	beep_a
	rcall	short_delay
loud_3s:
	rcall	beep_a
	rcall	short_delay
loud_2s:
	rcall	beep_a
	rcall	short_delay
	rcall	beep_a
	rcall	short_delay
loud_end:
	sei
;	Rcall	Lipo_Cells_Detect

;	Nop								;+0000059: 0000
;	ldi		r18,0x02				;+000005A: E022		; 0x02 = 0b00000010	= 2
;	out		TCCR2,R18				;+000005B: BD25
	run_t2	r18
;	Andi	flag1,0xFE				;+000005C: 7FBE		; 0xFE = 0b11111110	= 254
;	cbr		flag1,1<<unknown_option_xh_0
;	STS	 0x00B5,flag2				;+000005D:	93A000B5
	rjmp	control_start			;+000005F: C298		; Destination: 0x0002F8
; useless ------------------------------------------------------------------------
.if 1==2
Lipo_Cells_Detect:
; 判别是lipo2还是lipo3,避免乱飘
    push    R29
    IN      R16,ADMUX
    STS     mem_admux,R16
    clr     R18
    clr     R19
    ldi     R29,8
    LDI     R16,0xC7
    OUT     ADMUX,R16
    LDI     R16,0x85
    OUT     ADCSRA,R16
Myloc_ADC_init:
    SBI     ADCSRA,ADSC
    nop
Myloc_get_ADC:
    SBIS    ADCSRA,ADIF
    RJMP    Myloc_get_ADC
    IN      R16,ADCL
    IN      R17,ADCH
    Add     R18,R16
    Adc     R19,R17
    Dec     R29
    brne    Myloc_ADC_init
; 8 次和
    LSR     R19
    ROR     R18
    LSR     R19
    ROR     R18
    LSR     R19
    ROR     R18
; 除8 = 平均值
    ldi     R16,low(lipo2_3)
    ldi     R17,high(lipo2_3)
    ldi     R29,2
    cp      R18,R16
    cpc     R19,R17
    brcs    set_lipo_cells_Number
    ldi     R29,3
set_lipo_cells_Number:
    sts     0x0113,R29
;.include "../brushless/sound.inc"
;在这里自动判别lipo已经确定了,
;所以可以取0x0113来唱音乐
cells_Sound_EX:
    Rcall   Beep_H
    dec     R29
    brne    cells_Sound_EX

    lds     R16,mem_admux
    Out     ADMUX,R16
    pop     R29
    Ret
.endif
; useless end --------------------------------------------------------------------

t0_ovf_int:
	In		R7,SREG
	Inc		tcnt0h
	And		tcnt0h,tcnt0h
	brne	AL031
	dec		rcp_error_cnt			;+0000089: 94CA
	breq	rcp_lost
AL031:
	Out		SREG,R7
	Reti
;	mov		R21,rcp_error_cnt		;+000008A: 2D5C
;	subi	R21,0x64				;+000008B: 5654		; 0x64 = 0b01100100	= 100
;	cpi		R21,0x64
;	brcs	AL032					;+000008C: F010		; Destination: 0x00008F
;	out		SREG,R7					;+000008D: BE7F
;	reti							;+000008E: 9518
;AL032:
;	Mov		R21,rcp_error_cnt		;+000008F: 2D5C
;	Subi	R21,0x0A				;+0000090: 505A		; 0x0A = 0b00001010	= 10
;	cpi		r21,10
;	Brcs	AL033					;+0000091: F030		; Destination: 0x000098
;	Ori		flag1,0x10				;+0000092: 61B0		; 0x10 = 0b00010000	= 16
;	Andi	flag1,0x7F				;+0000093: 77BF		; 0x7F = 0b01111111	= 127
;	cbr		flag1,1<<RCP_updated
;	Out		Sreg,R7					;+0000094: BE7F
;	Reti							;+0000095: 9518
;AL033:
rcp_lost:
;	cli
	pop		r16
	pop		r16
	Rcall	all_fet_off				;+0000098: 940E0A1A
;	Ldi		R16,0x0A				;+000009A: E00A		; 0x0A = 0b00001010	= 10
;	Out		0x21,R16				;+000009B: BD01
	rcall	brake_for_fail
.if 1==2
	rcall	beep_b
	rcall	beep_b
	rcall	beep_b
	rcall	beep_b
	rcall	beep_b
	rcall	beep_b
.endif
	sei
	ldi		r16,50
waiting_rcp_signal:
	ldi		r17,RCP_ERROR_COUNT
	mov		rcp_error_cnt,r17
	sbrs	flag1,RCP_updated
	rjmp	waiting_rcp_signal
	cbr		flag1,1<<RCP_updated
	dec		r16
	brne	waiting_rcp_signal
;	rjmp	detect_neutral_rcp
	rjmp	reset
power_fail:
	rcall	brake_for_fail

	rcall	beep_b
	rcall	beep_c
	rcall	beep_b
	rcall	beep_c
	rcall	beep_b
	rcall	beep_c
	rcall	beep_b
	rcall	beep_c
infinity:
	rjmp	infinity

brake_for_fail:
	cli
	ldi		r19,4				; around 1 second
pf_0:
	ldi		r18,255				
pf_1:
	ldi		r16,BRAKE_ON		;1x
	out		PORTD,r16			;1x
	ldi		r16,255				;1x
pf_2:
	dec		r16					;1*256x
	brne	pf_2				;2*256x
	ldi		r16,BRAKE_OFF		;1x
	out		PORTD,r16			;1x
	ldi		r16,20				;1x
pf_3:
	ldi		r17,255				;1*256*20x
pf_4:
	dec		r17					;1*256*20x
	brne	pf_4				;2*256*20x
	dec		r16					;1*20x
	brne	pf_3				;2*20x
	dec		r18					;1x
	brne	pf_1				;2x
	dec		r19
	brne	pf_0
	ret
;AL034:
;	Nop								;+000009C: 0000
;	Nop								;+000009D: 0000
;	Rjmp	AL034					;+000009E: CFFD		; Destination: 0x00009C
;	Rjmp	Reset					;+000009F: CF80		; Destination: 0x000020

setting_timer0:
	In		R16,TIMSK				;+00000A1: B709
;	Ori		R16,0x01				;+00000A2: 6001		; 0x01 = 0b00000001	= 1
	sbr		r16,1<<TOIE0
	Out		TIMSK,R16				;+00000A3: BF09
	Ldi		R16,(0<<CS02)+(1<<CS01)+(0<<CS00)	; CLK/8
	Out		TCCR0,R16				;+00000A5: BF03
	Ret								;+00000A6: 9508

t1_ovf_int:
	Out		PortD,state_on				 ;+00000A8:	BA82
	Reti							;+00000A9: 9518

oc1a_int:
;	Sbic	PINB,2					;+00000AA: 99B2
;	Out		PortD,state_on				;+00000AB: BA82
;	Sbis	PINB,2					;+00000AC: 9BB2
;	Out		PortD,state_off				;+00000AD: BA92
	Reti							;+00000AE: 9518

oc1b_int:
	Out		PortD,state_off				;+00000AF: BA92
	Reti							;+00000B0: 9518

t2_ovf_int:
	In		R7,SREG					;+00000B2: B67F
	Inc		tcnt2h						;+00000B3: 94F3
;	Breq	AL035					;+00000B4: F011		; Destination: 0x0000B7
	brne	AL035					;+00000B4: F011		; Destination: 0x0000B7
	sbr		flag1,1<<tcnt2h_ovf
AL035:
	Out		SREG,R7					;+00000B5: BE7F
	Reti							;+00000B6: 9518

;AL035:
;	Ori		flag1,0x08				;+00000B7: 60B8		; 0x08 = 0b00001000	= 8
;	sbr		flag1,1<<tcnt2h_ovf
;	out		SREG,r7					;+00000B8: BE7F
;	Reti							;+00000B9: 9518

setting_timer2:
	In		R16,TIMSK				;+00000BA: B709
;	Andi	R16,0x7F				;+00000BB: 770F		; 0x7F = 0b01111111	= 127
;	Ori		R16,0x40				;+00000BC: 6400		; 0x40 = 0b01000000	= 64
	cbr		r16,1<<OCIE2
	sbr		r16,1<<TOIE2
	Out		TIMSK,r16				;+00000BD: BF09
	Ret								;+00000BE: 9508

ext0_int:
	In		R7,Sreg					;+00000C4: B67F

	ldi		r20,RCP_ERROR_COUNT
	mov		rcp_error_cnt,r20

	In		R20,TCNT0				;+00000C5: B742
	Mov		R21,tcnt0h				;+00000C6: 2D56
	In		R22,TIFR				;+00000C7: B768
	Sbrs	R22,TOV0				;+00000C8: FF60
	Rjmp	AL036					;+00000C9: C002		; Destination: 0x0000CC
	In		R20,TCNT0				;+00000CA: B742
	Inc		R21						;+00000CB: 9553
AL036:
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;	 CLT							 ;+00000CC:	94E8
;	 IN		 R22,MCUCR				 ;+00000CD:	B765
;	 SBRC	 R22,0					 ;+00000CE:	FD60
;	 SET							 ;+00000CF:	9468
;	 LDS	 R23,0x00A2				 ;+00000D0:	917000A2
;	 LDS	 R22,0x00A3				 ;+00000D2:	916000A3
;	 STS	 0x00A2,R21				 ;+00000D4:	935000A2
;	 STS	 0x00A3,R20				 ;+00000D6:	934000A3
;	 SUB	 R20,R22				 ;+00000D8:	1B46
;	 SBC	 R21,R23				 ;+00000D9:	0B57

;	CLT
;	IN		R22,MCUCR
; 0=1=上升沿=RCPing	. 0=0=下降沿=空闲
;	SBRC	R22,0
;	SET
; SREG中的 T 位被程序中用于接收RCP信号的局部过程标志(非全局),
; 如果T位set表示此时no rcpin(也可以理解为rcp_updatED).
; 被clear表示rcp接收ing.

	Lds		R22,mem_rcp_temp
	Lds		R23,mem_rcp_temp+1
	Sts		mem_rcp_temp,R20
	Sts		mem_rcp_temp+1,R21
	Sub		R20,R22
	Sbc		R21,R23

; 现在按取反rcp信号使用,测试用.完毕

	In		R22,MCUCR		;+000000ED:	B765		; sbrc = 取反使用	sbrs = 取正使用	
;	SBRC	R22,0			;+000000EE:	FD60
	Sbrs	R22,0			;+000000EE:	FD60
	Rjmp	AL037

;	 BRTS	 AL037					 ;+00000DA:	F01E	 ; Destination:	0x0000DE

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; RCP取反 03=下降 02=上升
	Ldi		R23,0x02				;+00000DB: E053		; 0x03 = 0b00000011	= 3
	Out		MCUCR,R23				;+00000DC: BF55
; MCUCR=03表示上升沿触发中断,按信号取反,则意味着RCP结束.
; 目前是RCP开始接收, T=Clear
	Rjmp	rcp_input_exit					;+00000DD: C014		; Destination: 0x0000F2
AL037:
	movw	rcp_l,r20
;	Ldi		R21,0x03				;+00000F0: E052		; 0x02 = 0b00000010	= 2
;	Out		MCUCR,R21				;+00000F1: BF55
	Ldi		R23,0x03
	Out		MCUCR,R23
;	Mov		R10,R21					;+00000DE: 2EA5
;	Mov		R11,R20					;+00000DF: 2EB4
;	Subi	R20,0xDC				;+00000E0: 5D4C		; 0xDC = 0b11011100	= 220
;	Sbci	R21,0x05				;+00000E1: 4055		; 0x05 = 0b00000101	= 5
;	Brcs	AL039					;+00000E2: F068		; Destination: 0x0000F0
;	Subi	R20,0xA4				;+00000E3: 5A44		; 0xA4 = 0b10100100	= 164
;	Sbci	R21,0x06				;+00000E4: 4056		; 0x06 = 0b00000110	= 6
;	Brcc	AL040					;+00000E5: F410		; Destination: 0x0000E8
;	Andi	flag1,0xDF				;+00000E6: 7DBF		; 0xDF = 0b11011111	= 223
;	Rjmp	AL041					;+00000E7: C005		; Destination: 0x0000ED
;AL040:
;	Subi	R20,0x78				;+00000E8: 5748		; 0x78 = 0b01111000	= 120
;	Sbci	R21,0x05				;+00000E9: 4055		; 0x05 = 0b00000101	= 5
;	Brcs	AL042					;+00000EA: F008		; Destination: 0x0000EC
;	Rjmp	AL043					;+00000EB: C008		; Destination: 0x0000F4
;AL042:
;	Ori		flag1,0x20				;+00000EC: 62B0		; 0x20 = 0b00100000	= 32
;AL041:
; 容易解析,理所当然, flag1(6)(mask01000000) =	RCP_updated
;	Ori		flag1,0x40				;+00000ED: 64B0		; 0x40 = 0b01000000	= 64
;	Ldi		R20,0x96				;+00000EE: E946		; 0x96 = 0b10010110	= 150
;	Mov		R12,R20					;+00000EF: 2EC4
;AL039:
; RCP取反 02=下降 03=上升
	; if(r20:r21 > RCP_LOW && r20:r21 < RCP_HIGH) goto int0_rcp_ready
	subi	r20,low(RCP_ALLOW_L)
	sbci	r21,high(RCP_ALLOW_L)
	subi	r20,low(RCP_ALLOW_H-RCP_ALLOW_L)
	sbci	r21,high(RCP_ALLOW_H-RCP_ALLOW_L)
	brcs	int0_rcp_ready
	; rcp signal is incorrect
	cbr		flag1,1<<RCP_updated
	rjmp	rcp_input_exit
int0_rcp_ready:
	; 设置 SREG.t RCP ready
	sbr		flag1,1<<RCP_updated

; 下降沿触发,表示开始rcp信号间的1800微秒空闲,并等待rcp信号.
rcp_input_exit:
	Out		SREG,R7					;+00000F2: BE7F
	Reti							;+00000F3: 9518
;AL043:
; RCP取反 02=下降 03=上升
;	Ldi		R21,0x03				;+00000F4: E052		; 0x02 = 0b00000010	= 2
;	Out		MCUCR,R21				;+00000F5: BF55
;	Lds		R20,0x00BF				;+00000F6: 914000BF
;	Dec		R20						;+00000F8: 954A
;	Sts		0x00BF,R20				;+00000F9: 934000BF
;	Brne	AL044					;+00000FB: F409		; Destination: 0x0000FD
;	 ORI	 flag2,0x80				 ;+00000FC:	68A0	 ; 0x80	= 0b10000000 = 128
;AL044:
;	Out		Sreg,R7					;+00000FD: BE7F
;	Reti							;+00000FE: 9518
rising_int0_en:
	Ldi		r16,(1<<INT0)
	Out		GICR,r16				;+0000100: BF0B
	ldi		R16,(1<<ISC01)+(1<<ISC00)
	Out		MCUCR,R16				;+0000102: BF05
	Ret								;+0000103: 9508

;AL008:
;	Reti							;+0000105: 9518

setting_adc7_pre32:
	In		R16,ADMUX					;+0000106: B107
	Sts		mem_admux,R16				;+0000107: 930000A4
;	Ldi		R16,0xC7				;+0000109: EC07		; 0xC7 = 0b11000111	= 199
	ldi		r16,(1<<REFS1)+(1<<REFS0)+(1<<MUX2)+(1<<MUX1)+(1<<MUX0)
	Out		ADMUX,R16					;+000010A: B907
;	Ldi		R16,0x85				;+000010B: E805		; 0x85 = 0b10000101	= 133
	ldi		r16,(1<<ADEN)+(1<<ADPS2)+(1<<ADPS0)
	Out		ADCSRA,R16					;+000010C: B906
	Sbi		ADCSRA,ADSC					;+000010D: 9A36
	Ret								;+000010E: 9508

retreve_voltage:
	Sbis	ADCSRA,4					;+000010F: 9B34
	Rjmp	retreve_voltage					;+0000110: CFFE		; Destination: 0x00010F
	In		R16,ADCL					;+0000111: B104
	In		R17,ADCH					;+0000112: B115
	Sts		mem_sys_voltage,R16				;+0000113: 930000AC
	Sts		mem_sys_voltage+1,R17				;+0000115: 931000AB
;	Lds		R18,mem_volt_protect+1				;+0000117: 912000A7
;	Lds		R19,mem_volt_protect				;+0000119: 913000A6
	lds		r18,mem_volt_protect
	lds		r19,mem_volt_protect+1

	Sub		R16,R18					;+000011B: 1B02
	Sbc		R17,R19					;+000011C: 0B13
	Brcc	AL046					;+000011D: F440		; Destination: 0x000126
	Lds		R17,mem_low_power_count				;+000011E: 911000AA
	Dec		R17						;+0000120: 951A
	Sts		mem_low_power_count,R17				;+0000121: 931000AA
	Brne	AL047					;+0000123: F431		; Destination: 0x00012A
;	Ori		flag1,0x10				;+0000124: 61B0		; 0x10 = 0b00010000	= 16
	sbr		flag1,1<<weak_power
	Rjmp	AL048					;+0000125: C001		; Destination: 0x000127
AL046:
;	Andi	flag1,0xEF				;+0000126: 7EBF		; 0xEF = 0b11101111	= 239
	cbr		flag1,1<<weak_power
AL048:
;	Ldi		R17,0x02				;+0000127: E012		; 0x02 = 0b00000010	= 2
	ldi		r17,10
	Sts		mem_low_power_count,R17				;+0000128: 931000AA
AL047:
	Rcall	select_ac_input					;+000012A: D1A9		; Destination: 0x0002D4
	Lds		R16,mem_admux				;+000012B: 910000A4
	Out		ADMUX,R16					;+000012D: B907
	Ret								;+000012E: 9508
.if 1==2
brake_protect:
	Rcall	setting_adc7_pre32					;+000012F: DFD6		; Destination: 0x000106
AL050:
	Sbis	ADCSRA,4					;+0000130: 9B34
	Rjmp	AL050					;+0000131: CFFE		; Destination: 0x000130
	In		R16,ADCL					;+0000132: B104
	In		R17,ADCH					;+0000133: B115
	Lds		R18,mem_brake_lmt_voltage		;+0000134: 912000A9
	Lds		R19,mem_brake_lmt_voltage+1	;+0000136: 913000A8
	Sub		R16,R18					;+0000138: 1B02
	Sbc		R17,R19					;+0000139: 0B13
;	Brcc	AL051					;+000013A: F418		; Destination: 0x00013E
	brcc	output_off
;	Ldi		R16,BRAKE_ON				;+000013B: E00B		; 0x0B = 0b00001011	= 11
;	Mov		state_on,R16					;+000013C: 2E80
;	Rjmp	AL052					;+000013D: C003		; Destination: 0x000141
;AL051:
;	Ldi		R16,SoundOff			;+000013E: E000		; 0x00 = 0b00000000	= 0
;	Mov		state_on,R16					;+000013F: 2E80
;	Out		PortD,R16				;+0000140: BB02
;AL052:
	Ret								;+0000141: 9508
.endif
all_fet_off:
	clr		state_off
;output_off:
	clr		state_on
	out		PORTD,state_on
	ret


.if 1==2
battery_detect:
	rcall	setting_adc7_pre32		;+0000142: DFC3		; Destination: 0x000106
AL053:
	sbis	ADCSRA,ADIF
	rjmp	AL053					;+0000144: CFFE		; Destination: 0x000143
	in		R16,ADCL				;+0000145: B104
	in		R17,ADCH				;+0000146: B115
	Subi	R16,low(-0x17)				; add 0x17
	Sbci	R17,high(-0x17)
	Sts		mem_brake_lmt_voltage,R16		;+0000149: 930000A9
	Sts		mem_brake_lmt_voltage+1,R17	;+000014B: 931000A8
	Subi	R16,0x17				;+000014D: 5107		; 0x17 = 0b00010111	= 23
	Sbci	R17,0				;+000014E: 4010		; 0x00 = 0b00000000	= 0
	Rcall	AL054					;+000014F: 940E0ADA
;	Sts		mem_volt_protect+1,R16				;+0000151: 930000A7
;	Sts		mem_volt_protect,R17	;+0000153: 931000A6
	sts		mem_volt_protect,r16
	sts		mem_volt_protect+1,r17

	Subi	R16,0x91			;+0000155: 5901		; 0x91 = 0b10010001	= 145
	Sbci	R17,0				;+0000156: 4010		; 0x00 = 0b00000000	= 0
	Brcc	AL055				;+0000157: F430		; Destination: 0x00015E
	Ldi		R16,0x91			;+0000158: E901		; 0x91 = 0b10010001	= 145
	Ldi		R17,0				;+0000159: E010		; 0x00 = 0b00000000	= 0
;	Sts		mem_volt_protect+1,R16				;+000015A: 930000A7
;	Sts		mem_volt_protect,R17				;+000015C: 931000A6
	sts		mem_volt_protect,r16
	sts		mem_volt_protect+1,r17
AL055:
	Ret								;+000015E: 9508
.endif
calcuate_st_pwm_duty:
	Ldi		R16,0x0A				;+000015F: E00A		; 0x0A = 0b00001010	= 10
	Sts		mem_st_pwm_duty,R16		;+0000160: 930000B0
;	Ldi		R17,0x03				;+0000162: E013		; 0x03 = 0b00000011	= 3
;	Ldi		R16,0x3E				;+0000163: E30E		; 0x3E = 0b00111110	= 62
	ldi		r17,high(830)
	ldi		r16,low(830)
AL057:
	Lds		R19,mem_sys_voltage+1				;+0000164: 913000AB
	Lds		R18,mem_sys_voltage				;+0000166: 912000AC
	Lsr		R19						;+0000168: 9536
	Ror		R18						;+0000169: 9527
	Sub		R18,R16					;+000016A: 1B20
	Sbc		R19,R17					;+000016B: 0B31
	Brcc	AL056					;+000016C: F440		; Destination: 0x000175
	Subi	R16,0x0B				;+000016D: 500B		; 0x0B = 0b00001011	= 11
	Sbci	R17,0				;+000016E: 4010		; 0x00 = 0b00000000	= 0
	Lds		R18,mem_st_pwm_duty				;+000016F: 912000B0
	Inc		R18						;+0000171: 9523
	Sts		mem_st_pwm_duty,R18				;+0000172: 932000B0
	Rjmp	AL057					;+0000174: CFEF		; Destination: 0x000164
AL056:
	Lds		R18,mem_st_pwm_duty				;+0000175: 912000B0
	Sts		mem_st_pwm_duty+1,R18				;+0000177: 932000B1
	Add		R18,R18					;+0000179: 0F22
	Sts		mem_st_pwm_duty+2,R18				;+000017A: 932000B2
	Ret								;+000017C: 9508

evaluate_rcp:
	Sbrs	flag1,RCP_updated			;+000017F: FFB6
	Ret								;+0000180: 9508
	Rcall	setting_adc7_pre32		;+0000181: DF84		; Destination: 0x000106
;	Andi	flag1,0xBF				;+0000182: 7BBF		; 0xBF = 0b10111111	= 191
;	Ori		flag1,0x80				;+0000183: 68B0		; 0x80 = 0b10000000	= 128
	cbr		flag1,1<<RCP_updated
;	sbr		flag1,1<<no_idle
;	Cli								;+0000184: 94F8
;	Mov		R16,R11					;+0000185: 2D0B
;	Mov		R17,R10					;+0000186: 2D1A
;	Sei								;+0000187: 9478
;	motor_dir r18
;	movw	r16,rcp_l
;	Cp		R16,rcp_top_l			;+0000188: 1903
;	Cpc		R17,rcp_top_h			;+0000189: 0912
;	Brcc	AL058					;+000018A: F5F0		; Destination: 0x0001C9
;	brcc	fullpower
;	Cp		R16,rcp_bottom_l		;+0000192: 1905
;	Cpc		R17,rcp_bottom_h		;+0000193: 0914
;	Brcs	er_loc_1				;+0000194: F418		; Destination: 0x000198

;	cpi		r18,FORWARD
;	brne	AL060	
;	motor_idle
;	Rjmp	AL060
;AL058:

;	cpi		r18,REVERSE
;	brne	AL060
;AL060:
;	ldi		r16,255
;	mov		rcp_duty,r16
;	rjmp	AL061

; 2 way about. MakeItTwoWay
; 入口参数同下面Al063,
; 返回参数有2种情况
; 1, brcs成立, 则使用Clr r27的效果直接跳AL061, 跳过convert_rcp_to_pwm
; 2, brcc成立, 则使用处理过的R17:R16进入convert_rcp_to_pwm...
	Rcall	Make_It_Two_Way


; 人口参数:	R17:R16	为 当前RCP-RCP下限
; 输出参数:	r27	(映射功率输出比例 X/256	)
;	Rcall	convert_rcp_to_pwm		;+0000198: D03A		; Destination: 0x0001D3
;AL061:
	Add		r27,pwm_duty					;+0000199: 0D9E
	Ror		r27						;+000019A: 9597
; Acc About
;	Ldi		R18,0x14				;+000019B: E124		; 0x14 = 0b00010100	= 20
	ldi		r18,90
	Lds		R16,mem_parameters+16				;+000019C: 91000110
	Cpi		R16,3				;+000019E: 3003		; 0x03 = 0b00000011	= 3
	Breq	AL064					;+000019F: F031		; Destination: 0x0001A6
;	Ldi		R18,0x05				;+00001A0: E025		; 0x05 = 0b00000101	= 5
	ldi		r18,20
	Cpi		R16,1				;+00001A3: 3001		; 0x01 = 0b00000001	= 1
	Breq	AL064					;+00001A4: F009		; Destination: 0x0001A6
;	Ldi		R18,0x0A				;+00001A5: E02A		; 0x0A = 0b00001010	= 10
	Ldi		R18,40
AL064:
	Mov		R16,pwm_duty					;+00001A6: 2D0E
	Sub		R16,r27					;+00001A7: 1B09
	Breq	AL065					;+00001A8: F0A1		; Destination: 0x0001BD
	Brcs	AL066					;+00001A9: F048		; Destination: 0x0001B3
	Add		R18,R18					;+00001AA: 0F22
	Sub		R16,R18					;+00001AB: 1B02
	Brcc	AL067					;+00001AC: F410		; Destination: 0x0001AF
	Mov		pwm_duty,r27					;+00001AD: 2EE9
	Rjmp	AL065					;+00001AE: C00E		; Destination: 0x0001BD
AL067:
	Sub		pwm_duty,R18					;+00001AF: 1AE2
	Brcc	AL065					;+00001B0: F460		; Destination: 0x0001BD
	Clr		pwm_duty						;+00001B1: 24EE
	Rjmp	AL065					;+00001B2: C00A		; Destination: 0x0001BD
AL066:
	Mov		R16,r27					;+00001B3: 2F09
	Sub		R16,pwm_duty					;+00001B4: 190E
	Sub		R16,R18					;+00001B5: 1B02
	Brcc	AL068					;+00001B6: F410		; Destination: 0x0001B9
	Mov		pwm_duty,r27					;+00001B7: 2EE9
	Rjmp	AL065					;+00001B8: C004		; Destination: 0x0001BD
AL068:
	Add		pwm_duty,R18					;+00001B9: 0EE2
	Brcc	AL065					;+00001BA: F410		; Destination: 0x0001BD
	Ldi		R16,0xFF				;+00001BB: EF0F		; 0xFF = 0b11111111	= 255
	Mov		pwm_duty,R16					;+00001BC: 2EE0
AL065:
	Mov		r27,pwm_duty					;+00001BD: 2D9E
	Subi	r27,0x02				;+00001BE: 5092		; 0x02 = 0b00000010	= 2
	Brcc	AL069					;+00001BF: F418		; Destination: 0x0001C3
	Clr		pwm_duty						;+00001C0: 24EE
;	Andi	flag1,0x7F				;+00001C1: 77BF		; 0x7F = 0b01111111	= 127
;	cbr		flag1,1<<no_idle
	Rjmp	AL070					;+00001C2: C004		; Destination: 0x0001C7
AL069:
	Subi	r27,250				;+00001C3: 5F9A		; 0xFA = 0b11111010	= 250
	Brcs	AL070					;+00001C4: F010		; Destination: 0x0001C7
	Ldi		r27,0xFF				;+00001C5: EF9F		; 0xFF = 0b11111111	= 255
	Mov		pwm_duty,r27			;+00001C6: 2EE9
AL070:
	Rcall	retreve_voltage					;+00001C7: DF47		; Destination: 0x00010F
	Ret								;+00001C8: 9508
; useless ----------------------------------------------------------------------
.if 1==2
;sGame:
;	Rjmp	AL087
;
;; some init	about R2:R3	,data from Default Datasheet.index by EEP and SRAM.
;;	Rcall	AL074					;+00001ED: D473		; Destination: 0x000661
;; some init	about R18:R19 ,data	from Default Datasheet.index by	SRAM.
;;	Rcall	AL075					;+00001EE: D4A4		; Destination: 0x000693
;
;; 2 way about, nogame
;;	Rjmp	AL087
;
;;编程合在这里 Program_Box
;;	 SBRC	 flag2,6					 ;+00001F1:	FDA7
;;	 rcall	 AL076					 ;+00001F2:	940E0A21
;
;;高杆计数器,2* 1.0 =3秒
;	Ldi		R16,40					;+00001EF: ED0C		; 0xDC = 0b11011100	= 220
;;低杆计数器,1* 1.0 =1.5秒
;	Ldi		R17,40					 ;+00001F0:	E119	 ; 0x19	= 0b00011001 = 25
;AL077:
;
;	sbrs	flag1, RCP_updated
;	rjmp	AL077
;	cbr		flag1,1<<RCP_updated
;	sbrs	flag1,rcp_Hpos
;	Rjmp	temp_loc_1
;	Rjmp	AL078
;
;;取消中杆位置
;;	rcall	Get_Command
;;	cpi		R19,1
;;	breq	temp_loc_1
;;	cpi		R19,3
;;	breq	AL078
;;	rjmp	AL077
;
;temp_loc_1:
;	Dec		R17						;+00001F9: 951A
;	Brne	AL077					;+00001FA: F7B1		; Destination: 0x0001F1
;	Rjmp	AL079					;+00001FB: C00A		; Destination: 0x000206
;AL078:
;	Dec		R16						;+00001FC: 950A
;	Brne	AL077					;+00001FD: F799		; Destination: 0x0001F1
;
;; 怀疑是ProgramBox相关,以及AL081有声音.......WTF???
;;	 rcall	 AL080					 ;+00001FE:	940E0615
;;	 RCALL	 AL081					 ;+0000200:	D565	 ; Destination:	0x000766
;
;;	 RCALL	 AL082_OldGame			;+0000201: D02D		; Destination: 0x00022F
;	Rcall	NewGame_Master
;
;loc_DeathEnd:
;; 严重警告,此死循环用于测试!!!!
;; BTW: 由于new game不是ret回父进程,而是直接跳reset来reboot,所以这里可以留着不要紧.
;	Rjmp	loc_DeathEnd
;
;AL118:
;;	Ldi		R17,0x3C				;+0000202: E31C		; 0x3C = 0b00111100	= 60
;	Ldi		R17, 30
;AL084:
;	Rcall	AL083					;+0000203: D025		; Destination: 0x000229
;	Dec		R17						;+0000204: 951A
;	Brne	AL084					;+0000205: F7E9		; Destination: 0x000203
;AL079:
;	Clr		R16						;+0000206: 2700
;	Clr		R17						;+0000207: 2711
;	Ldi		R19,0x08				;+0000208: E038		; 0x08 = 0b00001000	= 8
;AL085:
;	Rcall	AL083					;+0000209: D01F		; Destination: 0x000229
;;	Cli								;+000020A: 94F8
;;	Add		R16,R11					;+000020B: 0D0B
;;	Adc		R17,R10					;+000020C: 1D1A
;;	Sei								;+000020D: 9478
;	movw	r16,rcp_l
;	Dec		R19						;+000020E: 953A
;	Brne	AL085					;+000020F: F7C9		; Destination: 0x000209
;	Ldi		R19,0x03				;+0000210: E033		; 0x03 = 0b00000011	= 3
;AL086:
;	Lsr		R17						;+0000211: 9516
;	Ror		R16						;+0000212: 9507
;	Dec		R19						;+0000213: 953A
;	Brne	AL086					;+0000214: F7E1		; Destination: 0x000211
;;	Lds		R19,0x0116				;+0000215: 91300116
;;	Cpi		R19,0x01				;+0000217: 3031		; 0x01 = 0b00000001	= 1
;;	Breq	AL087					;+0000218: F011		; Destination: 0x00021B
;;	Rcall	AL075					;+0000219: D479		; Destination: 0x000693
;;	Brcc	sGame					;+000021A: F690		; Destination: 0x0001ED
;AL087:
;; 平均低杆 + 150, 这个素设置低杆死区.
;;	 SUBI	 R16,0x6A				 ;+000021B:	560A	 ; 0x6A	= 0b01101010 = 106
;;	 SBCI	 R17,0xFF				 ;+000021C:	4F1F	 ; 0xFF	= 0b11111111 = 255
;
;;	Lds		R16,mem_parameters+9				;+000021F: 91000109
;;	Ori		flag1,0x02				;+0000221: 60B2		; 0x02 = 0b00000010	= 2
;;	Cpi		R16,0x01				;+0000222: 3001		; 0x01 = 0b00000001	= 1
;;	Brne	AL088					;+0000223: F409		; Destination: 0x000225
;	Andi	flag1,0xFD				;+0000224: 7FBD		; 0xFD = 0b11111101	= 253
;AL088:
;
;;开机的刹车声
;;	 SBRS	 flag1,1					 ;+0000225:	FFB1
;;	 RCALL	 AL089					 ;+0000226:	D53C	 ; Destination:	0x000763
;;	 RCALL	 AL090					 ;+0000227:	D538	 ; Destination:	0x000760
;
;Safe_Sound_Exit:
;	Ret								;+0000228: 9508
;
;AL083:
;	Sbrs	flag1,RCP_updated			;+0000229: FFB6
;	Rjmp	AL083					;+000022A: CFFE		; Destination: 0x000229
;;	Andi	flag1,0xBF				;+000022B: 7BBF		; 0xBF = 0b10111111	= 191
;	cbr		flag1,1<<RCP_updated
;	Sbrc	flag1,RCP_Hpos			;+000022C: FDB5
;	Rjmp	AL083					;+000022D: CFFB		; Destination: 0x000229
;	Ret								;+000022E: 9508
;
;AL082_OldGame:
;	Ret								;+00002CE: 9508
;
.endif
; useless end ------------------------------------------------------------------

;AL009:
;	Reti							;+00002D3: 9518
; 

; Select anolog compare input
select_ac_input:
	In		R16,SFIOR				;+00002D4: B700
;	Ori		R16,0x08				;+00002D5: 6008		; 0x08 = 0b00001000	= 8
	sbr		r16,1<<ACME

	Out		SFIOR,R16				;+00002D6: BF00
	In		R16,ADCSRA					;+00002D7: B106
;	Andi	R16,0x7F				;+00002D8: 770F		; 0x7F = 0b01111111	= 127
	cbr		r16,1<<ADEN
	Out		ADCSRA,R16					;+00002D9: B906
	
;	Ldi		R16,0x02				;+00002DA: E002		; 0x02 = 0b00000010	= 2
	ldi		r16,(1<<ACIS1)
	Out		ACSR,R16					;+00002DB: B908
	Ret								;+00002DC: 9508

feedback_x2:
	Lds		R16,mem_parameters+25				;+00002DD: 91000119
	Cpi		R16,0x02				;+00002DF: 3002		; 0x02 = 0b00000010	= 2
	mov		r16,flag1
	brne	fb_x2_1
	ldi		r16,1<<direction
	eor		r16,flag1
fb_x2_1:
	sbrc	r16,direction
;	Breq	feedback_b					;+00002E0: F051		; Destination: 0x0002EB
	rjmp	feedback_b
feedback_c:
	Rcall	select_ac_input					;+00002E1: DFF2		; Destination: 0x0002D4
;	In		R16,ADMUX					;+00002E2: B107
;	Andi	R16,0xF0				;+00002E3: 7F00		; 0xF0 = 0b11110000	= 240
;	Ori		R16,fb_c				;+00002E4: 6004		; 0x04 = 0b00000100	= 4
;	Out		ADMUX,R16					;+00002E5: B907
	ac_select r16,fb_c
	Ret								;+00002E6: 9508

feedback_x1:
	Lds		R16,mem_parameters+25				;+00002E7: 91000119
	Cpi		R16,0x02				;+00002E9: 3002		; 0x02 = 0b00000010	= 2
	mov		r16,flag1
	brne	fb_x1_1
	ldi		r16,1<<direction
	eor		r16,flag1
fb_x1_1:
	sbrc	r16,direction
;	Breq	feedback_c					;+00002EA: F3B1		; Destination: 0x0002E1
	rjmp	feedback_c
feedback_b:
	Rcall	select_ac_input					;+00002EB: DFE8		; Destination: 0x0002D4
;	In		R16,ADMUX					;+00002EC: B107
;	Andi	R16,0xF0				;+00002ED: 7F00		; 0xF0 = 0b11110000	= 240
;	Ori		R16,fb_b				;+00002EE: 6003		; 0x03 = 0b00000011	= 3
;	Out		ADMUX,R16					;+00002EF: B907
	ac_select r16,fb_b
	Ret								;+00002F0: 9508

feedback_a:
	Rcall	select_ac_input					;+00002F1: DFE2		; Destination: 0x0002D4
;	In		R16,ADMUX					;+00002F2: B107
;	Andi	R16,0xF0				;+00002F3: 7F00		; 0xF0 = 0b11110000	= 240
;	Ori		R16,fb_a				;+00002F4: 6002		; 0x02 = 0b00000010	= 2
;	Out		ADMUX,R16					;+00002F5: B907
	ac_select r16,fb_a
	Ret								;+00002F6: 9508

braking_motor:
;	Rcall	all_fet_off					;+000054C: 940E0A1A

	ldi		r16,BRAKE_ON
	mov		state_on,r16
	ldi		r16,BRAKE_OFF
	mov		state_off,r16


;	Ldi		R16,0x1E				;+000054E: E10E		; 0x1E = 0b00011110	= 30
;	Sts		mem_temp_90,R16				;+000054F: 93000090
;	Mov		R18,R16					;+0000551: 2F20
	ldi		r18,127
	Rcall	commit_pwm8k					;+0000552: 940E0959
;	Ldi		R17,0x02				;+0000554: E012		; 0x02 = 0b00000010	= 2
;	Sts		mem_temp_91,R17				;+0000555: 93100091
;AL197:
;	Lds		R17,mem_brake_param		;+0000557: 911000B7
;	ldi		r17,255
;	Sts		mem_temp_92,R17				;+0000559: 93100092
	ldi		r16,25
	sts		mem_temp1,r16
AL194:
;	Sbrc	flag1,Break_flag_on		;+000055B: FDB1
;	Rcall	brake_protect			;+000055C: DBD2		; Destination: 0x00012F
;	Sbrc	flag1,RCP_updated			;+000055D: FDB6
;	Rjmp	AL192					;+000055E: C007		; Destination: 0x000566
	sbrs	flag1,RCP_updated
	rjmp	AL194
	lds		r16,mem_temp1
	and		r16,r16
	breq	al194_1
	dec		r16
	sts		mem_temp1,r16
	rjmp	al194_2
al194_1:
	pause_t1 r16
	ldi		r16,BRAKE_ON
	out		PORTD,r16
	motor_dir r16
	cpi		r16,BRAKE
	brne	brake_exit
al194_2:
	rcall	evaluate_rcp	; braking
	motor_dir r16
	cpi		r16,IDLE
	breq	brake_exit
;	cpi		r16,BRAKE
;	in		r16
	rjmp	AL194

;	cpi		r16,FORWARD
;	breq	brake_exit
;	Breq	AL193					;+0000564: F029		; Destination: 0x00056A
;	Rjmp	AL194					;+0000565: CFF5		; Destination: 0x00055B
;AL192:
;	rcall	evaluate_rcp			;+0000566: DC18		; Destination: 0x00017F
;	Sbrc	flag1,no_idle				;+0000567: FDB7
;	Rjmp	AL195					;+0000568: C00D		; Destination: 0x000576
;AL198:
;	Andi	flag1,0x7F				;+0000569: 77BF		; 0x7F = 0b01111111	= 127
;	cbr		flag1,1<<no_idle
;AL193:
;	Lds		R16,mem_temp_90				;+000056A: 91000090
;	Ldi		R17,0x01				;+000056C: E011		; 0x01 = 0b00000001	= 1
;	Add		R16,R17					;+000056D: 0F01
;	Brcc	AL196					;+000056E: F408		; Destination: 0x000570
;	Ldi		R16,0xFF				;+000056F: EF0F		; 0xFF = 0b11111111	= 255
;AL196:
;	Sts		mem_temp_90,R16				;+0000570: 93000090
;	Mov		R18,R16					;+0000572: 2F20
;	Rcall	commit_pwm8k					;+0000573: 940E0959
;	Rjmp	AL197					;+0000575: CFE1		; Destination: 0x000557
;AL195:
;	Lds		R17,mem_temp_91				;+0000576: 91100091
;	Dec		R17						;+0000578: 951A
;	Sts		mem_temp_91,R17				;+0000579: 93100091
;	Brne	AL198					;+000057B: F769		; Destination: 0x000569
;	motor_idle
brake_exit:
;	motor_idle
;	Rjmp	control_start			;+000057C: CD7B		; Destination: 0x0002F8
control_start:
	rcall	all_fet_off				;+00002F8: 940E0A1A
;	 LDS	 flag2,0x00B5				;+00002FA:	91A000B5
	pause_t1 r16
;	rcall	init_timer1				;+00002FC: 940E0901
;	Ldi		R18,0x05				;+00002FE: E025		; 0x05 = 0b00000101	= 5
;	Rcall	commit_pwm8k					;+00002FF: 940E0959
;	Andi	flag1,0xEF				;+0000301: 7EBF		; 0xEF = 0b11101111	= 239
;	cbr		flag1,1<<weak_power
;	Andi	flag1,0xFE				;+0000302: 7FBE		; 0xFE = 0b11111110	= 254
;	cbr		flag1,1<<unknown_option_xh_0
; 2 way about ??? 低杆干扰1
;	Ldi		R16,0x28				;+0000303: E208		; 0x28 = 0b00101000	= 40
;	Clr		R17						;+0000304: 2711
;	Add		R4,R16					;+0000305: 0E50
;	Adc		R5,R17					;+0000306: 1E41
	Ldi		R16,0x02				;+0000307: E002		; 0x02 = 0b00000010	= 2
	Sts		mem_temp1,R16				;+0000308: 93000099
AL122:
;	rcall	output_off
;	Sbrs	flag1,RCP_updated			;+000030A: FFB6
;	Rjmp	AL122					;+000030B: CFFE		; Destination: 0x00030A
	Rcall	evaluate_rcp			;constrol start +000030C: DE72		; Destination: 0x00017F
;	sbrs	flag1,no_idle			;+000030D: FFB7
;	Rjmp	AL123					;+000030E: C00D		; Destination: 0x00031C
	motor_dir R17
	cpi		r17,IDLE
	breq	AL122
;	cpi		r17,BRAKE
;	breq	braking_motor
	Lds		R16,mem_temp1
	Dec		R16						;+0000311: 950A
	Sts		mem_temp1,R16				;+0000312: 93000099
	Brne	AL122					;+0000314: F7A9		; Destination: 0x00030A
; 2 way about ??? 低杆干扰2
;	Ldi		R18,0x28				;+0000315: E228		; 0x28 = 0b00101000	= 40
;	Sub		R4,R18					;+0000316: 1A52
;	Clr		R18						;+0000317: 2722
;	Sbc		R5,R18					;+0000318: 0A42
	Sbrc	flag1,weak_power			;+0000319: FDB4
	rjmp	power_fail			;+000031A: C264		; Destination: 0x00057F



;	Rjmp	starting_motor					;+000031B: C005		; Destination: 0x000321
;AL123:
; 2 way about ??? 低杆干扰3
;	Ldi		R18,0x28				;+000031C: E228		; 0x28 = 0b00101000	= 40
;	Sub		R4,R18					;+000031D: 1A52
;	Clr		R18						;+000031E: 2722
;	Sbc		R5,R18					;+000031F: 0A42
;	Rjmp	braking_motor					;+0000320: C22B		; Destination: 0x00054C
starting_motor:
	Rcall	all_fet_off				;+0000321: 940E0A1A
	run_t1 r16
	Ldi		R16,0x0A				;+0000323: E00A		; 0x0A = 0b00001010	= 10
	Sts		mem_temp1,R16			;+0000324: 93000099
;	Cbi		PORTB,4					;+0000326: 98C4
AL135:
	Clr		R29						;+0000327: 27DD
;	Sbrc	flag1,weak_power	;+0000328: FDB4
;	Rjmp	running_failure					;+0000329: C255		; Destination: 0x00057F
	Rcall	feedback_x1					;+000032A: DFBC		; Destination: 0x0002E7
	Rcall	zc_happen_or_timeout_1					;+000032B: D034		; Destination: 0x000360
	Rcall	exam_zc_gt_6000					;+000032C: D05D		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+000032D: FFB3
	Inc		R29						;+000032E: 95D3
	Rcall	feedback_x2					;+000032F: DFAD		; Destination: 0x0002DD
	Rcall	zc_happen_or_timeout_2					;+0000330: D038		; Destination: 0x000369
	Rcall	exam_zc_gt_6000					;+0000331: D058		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+0000332: FFB3
	Inc		R29						;+0000333: 95D3
	Rcall	feedback_a					;+0000334: DFBC		; Destination: 0x0002F1
	Rcall	zc_happen_or_timeout_1					;+0000335: D02A		; Destination: 0x000360
	Rcall	exam_zc_gt_6000					;+0000336: D053		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+0000337: FFB3
	Inc		R29						;+0000338: 95D3
	Rcall	feedback_x1					;+0000339: DFAD		; Destination: 0x0002E7
	Rcall	zc_happen_or_timeout_2					;+000033A: D02E		; Destination: 0x000369
	Rcall	exam_zc_gt_6000					;+000033B: D04E		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+000033C: FFB3
	Inc		R29						;+000033D: 95D3
	Rcall	feedback_x2					;+000033E: DF9E		; Destination: 0x0002DD
	Rcall	zc_happen_or_timeout_1					;+000033F: D020		; Destination: 0x000360
	Rcall	exam_zc_gt_6000					;+0000340: D049		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+0000341: FFB3
	Inc		R29						;+0000342: 95D3
	Rcall	feedback_a					;+0000343: DFAD		; Destination: 0x0002F1
	Rcall	zc_happen_or_timeout_2					;+0000344: D024		; Destination: 0x000369
	Rcall	exam_zc_gt_6000					;+0000345: D044		; Destination: 0x00038A
	Sbrs	flag1,tcnt2h_ovf			;+0000346: FFB3
	Inc		R29						;+0000347: 95D3
;	Nop								;+0000348: 0000
;	Ldi		R16,0x00				;+0000349: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+000034A: BD05
	pause_t2 r16
	Sbrc	flag1,tcnt2h_ovf			;+000034B: FDB3
;	Rjmp	AL133					;+000034C: C010		; Destination: 0x00035D
AL133:
	rjmp	startup_mode
	Subi	R29,0x06				;+000034D: 50D6		; 0x06 = 0b00000110	= 6
	Brcs	AL133					;+000034E: F070		; Destination: 0x00035D
;	Cbi		PORTB,4					;+000034F: 98C4
	Lds		R16,mem_temp1				;+0000350: 91000099
	Dec		R16						;+0000352: 950A
	Sts		mem_temp1,R16				;+0000353: 93000099
	Breq	AL134					;+0000355: F011		; Destination: 0x000358
	Rjmp	AL135					;+0000356: CFD0		; Destination: 0x000327
;	Nop								;+0000357: 0000
AL134:
; motor 正在转动
; 判断方向
; 相反 -> 刹车
; 相同 -> 转
	motor_dir r16
	sbrs	flag1,direction		; 电机滑动方向
	rjmp	at_reverse
	; 正转
	cpi		r16,FORWARD
	breq	continue_run
	motor_brake
	rjmp	braking_motor
at_reverse:
	; 倒转
	cpi		r16,REVERSE
	breq	continue_run
	motor_brake
	rjmp	braking_motor
continue_run:
	Rcall	calcuate_st_pwm_duty					;+0000358: 940E015F
	rjmp	running_mode					 ;+000035A:	940C0476
;	Nop								;+000035C: 0000
;AL133:
;	Nop								;+000035D: 0000
;	Sbi		PORTB,4					;+000035E: 9AC4
;	rjmp	startup_mode					;+000035F: C035		; Destination: 0x000395
zc_happen_or_timeout_1:
	Rcall	reset_t2					;+0000360: D012		; Destination: 0x000373
AL140:
	Ldi		R28,0x3C				;+0000361: E3CC		; 0x3C = 0b00111100	= 60
AL141:
	Sbrc	flag1,tcnt2h_ovf			;+0000362: FDB3
	Ret								;+0000363: 9508
	Sbic	ACSR,5					;+0000364: 9945
	Rjmp	AL140					;+0000365: CFFB		; Destination: 0x000361
	Dec		R28						;+0000366: 95CA
	Brne	AL141					;+0000367: F7D1		; Destination: 0x000362
	Ret								;+0000368: 9508
zc_happen_or_timeout_2:
	Rcall	reset_t2					;+0000369: D009		; Destination: 0x000373
AL142:
	Ldi		R28,0x3C				;+000036A: E3CC		; 0x3C = 0b00111100	= 60
AL143:
	Sbrc	flag1,tcnt2h_ovf			;+000036B: FDB3
	Ret								;+000036C: 9508
	Sbis	ACSR,ACO				;+000036D: 9B45
	Rjmp	AL142					;+000036E: CFFB		; Destination: 0x00036A
	Dec		R28						;+000036F: 95CA
	Brne	AL143					;+0000370: F7D1		; Destination: 0x00036B
	Rcall	AL144					;+0000371: D00C		; Destination: 0x00037E
	Ret								;+0000372: 9508
reset_t2:
;	Ldi		R16,0x00				;+0000373: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+0000374: BD05
	pause_t2 r16
	In		R18,TCNT2				;+0000375: B524
	Mov		R19,tcnt2h					;+0000376: 2D3F
	Ldi		R16,0				;+0000377: E000		; 0x00 = 0b00000000	= 0
	Out		TCNT2,R16				;+0000378: BD04
	Mov		tcnt2h,R16				;+0000379: 2EF0
;	Ldi		R16,(1<<CS21)			;+000037A: E002		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R16				;+000037B: BD05
	run_t2	r16
;	Andi	flag1,0xF7				;+000037C: 7FB7		; 0xF7 = 0b11110111	= 247
	cbr		flag1,1<<tcnt2h_ovf
	Ret								;+000037D: 9508
AL144:
;	Ldi		R18,0x00				;+000037E: E020		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R18				;+000037F: BD25
	pause_t2 r18
	In		R16,TCNT2				;+0000380: B504
	Mov		R17,tcnt2h					;+0000381: 2D1F
;	Ldi		R18,0x02				;+0000382: E022		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R18				;+0000383: BD25
	run_t2	r18
	Sts		mem_com_period_a0,R16				;+0000384: 930000A0
	Sts		mem_com_period_a0+1,R17				;+0000386: 931000A1
;	Rcall	evaluate_rcp					;+0000388: DDF6		; Destination: 0x00017F
	Ret								;+0000389: 9508
exam_zc_gt_6000:
;	Ldi		R16,0x00				;+000038A: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+000038B: BD05
	pause_t2 r16
	In		R18,TCNT2				;+000038C: B524
	Mov		R19,tcnt2h					;+000038D: 2D3F
	Subi	R18,low(6000)			;+000038E: 5720		; 0x70 = 0b01110000	= 112
	Sbci	R19,high(6000)			;+000038F: 4137		; 0x17 = 0b00010111	= 23
;	Subi	R18,low(12000)
;	Sbci	R19,high(12000)
	Brcs	AL145					;+0000390: F008		; Destination: 0x000392
;	Ori		flag1,0x08				;+0000391: 60B8		; 0x08 = 0b00001000	= 8
	sbr		flag1,1<<tcnt2h_ovf
AL145:
	Ret								;+0000392: 9508
;	Nop								;+0000393: 0000
;	Nop								;+0000394: 0000


startup_mode:
;	ldi		r16,255
;sm_loc_1:
;	ldi		r17,255
;sm_loc_2:
;	sbis	ACSR,ACO
;	rjmp	sm_loc_3
;	dec		r17
;	brne	sm_loc_2
;	dec		r16
;	brne	sm_loc_1
;	rjmp	continue_startup
;sm_loc_3:
;	ldi		r16,255
;sm_loc_4:
;	ldi		r17,255
;sm_loc_5:
;	sbic	ACSR,ACO
;	rjmp	braking_motor
;	dec		r17
;	brne	sm_loc_5
;	dec		r16
;	brne	sm_loc_4
;continue_startup:
	motor_dir r16
	cpi		r16,FORWARD
	breq	to_forward
	cbr		flag1,1<<direction
	rjmp	stm_1
to_forward:
	sbr		flag1,1<<direction
stm_1:
	rcall	sw_direct
	Rcall	calcuate_st_pwm_duty		;+0000395: 940E015F
	Lds		R18,mem_st_pwm_duty			;+0000397: 912000B0
	Sts		mem_st_pwm_duty+1,R18		;+0000399: 932000B1
	Lsr		R18						;+000039B: 9526
	Rcall	commit_pwm8k					;+000039C: 940E0959
	Ldi		R19,high(60000)				;+000039E: EE3A		; 0xEA = 0b11101010	= 234
	Ldi		R18,low(60000)				;+000039F: E620		; 0x60 = 0b01100000	= 96

;	Ldi		R19,high(5000)
;	Ldi		R18,low(5000)


	Sts		mem_com_period_a0+1,R19				;+00003A0: 933000A1
	Sts		mem_com_period_a0,R18				;+00003A2: 932000A0
	Sts		mem_unknown_9c,r19				;+00003A4: 9330009C
	Sts		mem_unknown_9c+1,R18				;+00003A6: 9320009D
	Sts		mem_com_period_96,R18				;+00003A8: 93200096
	Sts		mem_com_period_96+1,R19				;+00003AA: 93300097
;	Ldi		R16,255				;+00003AC: EF0F		; 0xFF = 0b11111111	= 255
	ldi		r16,127
	Sts		mem_temp2,R16				;+00003AD: 93000098
;	Rjmp	AL146					;+00003AF: C001		; Destination: 0x0003B1
;AL147:
;	Rjmp	running_failure			;+00003B0: C1CE		; Destination: 0x00057F
AL146:
	Lds		R16,mem_temp2			;+00003B1: 91000098
	Subi	R16,1				;+00003B3: 5001		; 0x01 = 0b00000001	= 1
	Sts		mem_temp2,R16			;+00003B4: 93000098
;	Brcs	AL147					;+00003B6: F3C8		; Destination: 0x0003B0
	brcc	AL156
;	rjmp	running_failure			;+00003B0: C1CE		; Destination: 0x00057F
	rjmp	startup_mode
AL156:
	Rcall	feedback_x1					;+00003B7: DF2F		; Destination: 0x0002E7
	Lds		state_on,mem_states				;+00003B8: 90800080
	Lds		state_off,mem_states+1				;+00003BA: 90900081
	Rcall	AL148					;+00003BC: D04C		; Destination: 0x000409
	Rcall	feedback_x2					;+00003BD: DF1F		; Destination: 0x0002DD
	Lds		state_on,mem_states+2				;+00003BE: 90800082
	Lds		state_off,mem_states+3				;+00003C0: 90900083
	Rcall	AL149					;+00003C2: D055		; Destination: 0x000418
	Rcall	feedback_a					;+00003C3: DF2D		; Destination: 0x0002F1
	Lds		state_on,mem_states+4				;+00003C4: 90800084
	Lds		state_off,mem_states+5				;+00003C6: 90900085
	Rcall	AL148					;+00003C8: D040		; Destination: 0x000409
	Rcall	feedback_x1					;+00003C9: DF1D		; Destination: 0x0002E7
	Lds		state_on,mem_states+6				;+00003CA: 90800086
	Lds		state_off,mem_states+7				;+00003CC: 90900087
	Rcall	AL149					;+00003CE: D049		; Destination: 0x000418
	Rcall	feedback_x2					;+00003CF: DF0D		; Destination: 0x0002DD
	Lds		state_on,mem_states+8				;+00003D0: 90800088
	Lds		state_off,mem_states+9				;+00003D2: 90900089
	Rcall	AL148					;+00003D4: D034		; Destination: 0x000409
	Rcall	feedback_a					;+00003D5: DF1B		; Destination: 0x0002F1
	Lds		state_on,mem_states+10				;+00003D6: 9080008A
	Lds		state_off,mem_states+11				;+00003D8: 9090008B
	Rcall	AL149					;+00003DA: D03D		; Destination: 0x000418
	Lds		R16,mem_st_pwm_duty+1				;+00003DB: 910000B1
;	Subi	R16,0xF6				;+00003DD: 5F06		; 0xF6 = 0b11110110	= 246
	subi	r16,-10
	Lds		R17,mem_st_pwm_duty+2				;+00003DE: 911000B2
	Sub		R17,R16					;+00003E0: 1B10
	Brcc	AL150					;+00003E1: F410		; Destination: 0x0003E4
	Lds		R16,mem_st_pwm_duty				;+00003E2: 910000B0
AL150:
	Sts		mem_st_pwm_duty+1,R16				;+00003E4: 930000B1
;	Lds		R18,mem_st_pwm_duty+1				;+00003E6: 912000B1
	mov		r18,r16
	Lsr		R18						;+00003E8: 9526
	Mov		R17,pwm_duty					;+00003E9: 2D1E
	Sub		R17,R18					;+00003EA: 1B12
	Brcs	AL151					;+00003EB: F018		; Destination: 0x0003EF
	Rcall	commit_pwm8k					;+00003EC: 940E0959
;	Rjmp	AL152					;+00003EE: C004		; Destination: 0x0003F3
AL151:
;	Sbrc	flag1,RCP_updated			;+00003EF: FDB6

;	sbrc	flag1,tcnt2h_ovf
	; 根据RCP设置启动功率
	Rcall	calc_startup_pwm					;+00003F0: 940E096D
;	sbrs	flag1,tcnt2h_ovf
;	rcall	commit_pwm_by_setting

;	Rcall	evaluate_rcp			;+00003F2: DD8C		; Destination: 0x00017F
;	motor_dir r16
;	cpi		r16,IDLE
;	brne	AL152
;	rjmp	control_start
;AL152:
	Sbrc	flag1,tcnt2h_ovf			;+00003F3: FDB3
	Rjmp	AL146					;+00003F4: CFBC		; Destination: 0x0003B1
	In		R16,TCNT2				;+00003F5: B504
	Mov		R17,tcnt2h					;+00003F6: 2D1F
	Subi	R16,0x90				;+00003F7: 5900		; 0x90 = 0b10010000	= 144
	Sbci	R17,0x01				;+00003F8: 4011		; 0x01 = 0b00000001	= 1
	Brcs	AL154					;+00003F9: F068		; Destination: 0x000407
	Subi	R16,0x34				;+00003FA: 5304		; 0x34 = 0b00110100	= 52
	Sbci	R17,0x21				;+00003FB: 4211		; 0x21 = 0b00100001	= 33
	Brcc	AL154					;+00003FC: F450		; Destination: 0x000407
	Lds		R16,mem_temp2				;+00003FD: 91000098
	Subi	R16,0x0A				;+00003FF: 500A		; 0x0A = 0b00001010	= 10
;	subi	r16,100
	Sts		mem_temp2,R16				;+0000400: 93000098
; for run only one round for startup mode, comment following 2 line
	Brcs	AL155					;+0000402: F008		; Destination: 0x000404
	Rjmp	AL156					;+0000403: CFB3		; Destination: 0x0003B7
AL155:
;	 LDS	 flag2,0x00B5				 ;+0000404:	91A000B5
;debug ++++++++++++++++++++++++++++++++++++++++++++++
.if	1==2
	cli
	ldi		r16,BRAKE_ON
	out		PORTD,r16
	ldi		r18,255
loop1:
	ldi		r17,255
loop2:
	ldi		r16,255
loop3:
	dec		r16
	brne	loop3
	dec		r17
	brne	loop2
	dec		r18
	brne	loop1
;	rcall	brake_for_fail
	rcall	beep_a
	rcall	all_fet_off
	sei
debug_x:
	rcall	evaluate_rcp
	motor_dir r16
	cpi		r16,IDLE
	brne	debug_x
	rjmp	control_start
.endif
;debug end ++++++++++++++++++++++++++++++++++++++++++

	Rjmp	running_mode					;+0000406: C06F		; Destination: 0x000476

AL154:
	Rjmp	AL146					;+0000407: CFA9		; Destination: 0x0003B1
;	Rjmp	AL146					;+0000408: CFA8		; Destination: 0x0003B1
AL148:
	Rcall	commit_output					;+0000409: D0BD		; Destination: 0x0004C7
	Sbrc	flag1,tcnt2h_ovf			;+000040A: FDB3
	; tcnt2h overflow
	Rcall	AL158					;+000040B: D04E		; Destination: 0x00045A
	; motor is running in very slow by inertia motion
	Rcall	AL159					;+000040C: D01A		; Destination: 0x000427
AL162:
	Ldi		R28,0x46				;+000040D: E4C6		; 0x46 = 0b01000110	= 70
;	motor_dir r16
;	cpi		r16,BRAKE
;	brne	AL163
;	pop		r16
;	pop		r16
;	rjmp	braking_motor
;	Sbrs	flag1,no_idle			;+000040E: FFB7
;	Rjmp	AL160					;+000040F: C0E4		; Destination: 0x0004F4
AL163:
	Sbrc	flag1,tcnt2h_ovf			;+0000410: FDB3
	Rjmp	AL161					;+0000411: C004		; Destination: 0x000416
	Sbic	ACSR,ACO					;+0000412: 9945
	Rjmp	AL162					;+0000413: CFF9		; Destination: 0x00040D
	Dec		R28						;+0000414: 95CA
	Brne	AL163					;+0000415: F7D1		; Destination: 0x000410
AL161:
	Rcall	AL164					;+0000416: D027		; Destination: 0x00043E
	Ret								;+0000417: 9508
AL149:
	Rcall	commit_output					;+0000418: D0AE		; Destination: 0x0004C7
	Sbrc	flag1,tcnt2h_ovf			;+0000419: FDB3
	; tcnt2h overflow
	Rcall	AL158					;+000041A: D03F		; Destination: 0x00045A
	; motor is running in very slow by inertia motion
	Rcall	AL159					;+000041B: D00B		; Destination: 0x000427
AL166:
	Ldi		R28,0x46				;+000041C: E4C6		; 0x46 = 0b01000110	= 70
;	motor_dir r16
;	cpi		r16,BRAKE
;	brne	AL167
;	pop		r16
;	pop		r16
;	rjmp	braking_motor
;	Sbrs	flag1,no_idle				;+000041D: FFB7
;	Rjmp	AL160					;+000041E: C0D5		; Destination: 0x0004F4
AL167:
	Sbrc	flag1,tcnt2h_ovf					;+000041F: FDB3
	Rjmp	AL165					;+0000420: C004		; Destination: 0x000425
	Sbis	ACSR,5					;+0000421: 9B45
	Rjmp	AL166					;+0000422: CFF9		; Destination: 0x00041C
	Dec		R28						;+0000423: 95CA
	Brne	AL167					;+0000424: F7D1		; Destination: 0x00041F
AL165:
	Rcall	AL164					;+0000425: D018		; Destination: 0x00043E
	Ret								;+0000426: 9508
AL159:
;	Ldi		R16,0x00				;+0000427: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+0000428: BD05
	pause_t2 r16
	In		R18,TCNT2				;+0000429: B524
	Mov		R19,tcnt2h					;+000042A: 2D3F
	Ldi		R16,0x00				;+000042B: E000		; 0x00 = 0b00000000	= 0
	Out		TCNT2,R16				;+000042C: BD04
	Mov		tcnt2h,R16					;+000042D: 2EF0
;	Ldi		R16,0x02				;+000042E: E002		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R16				;+000042F: BD05
	run_t2	r16
	Lds		R16,mem_com_period_96	;+0000430: 91000096
	Lds		R17,mem_com_period_96+1	;+0000432: 91100097
	Add		R18,R16					;+0000434: 0F20
	Adc		R19,R17					;+0000435: 1F31
	Ror		R19						;+0000436: 9537
	Ror		R18						;+0000437: 9527
	Sts		mem_com_period_96,R18	;+0000438: 93200096
	Sts		mem_com_period_96+1,R19	;+000043A: 93300097
	Rcall	evaluate_rcp			;startup mode +000043C: DD42		; Destination: 0x00017F
	motor_dir r16
	cpi		r16,IDLE
	breq	al159_1
	cpi		r16,BRAKE
	breq	al159_2
	Rjmp	AL168					;+000043D: C0CA		; Destination: 0x000508
al159_1:
	pop		r17
	pop		r17
	pop		r17
	pop		r17
	rjmp	control_start
al159_2:
	pop		r17
	pop		r17
	pop		r17
	pop		r17
	rjmp	braking_motor
AL164:
;	Ldi		R18,0x00				;+000043E: E020		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R18				;+000043F: BD25
	pause_t2 r18
	In		R16,TCNT2				;+0000440: B504
	Mov		R17,tcnt2h					;+0000441: 2D1F
;	Ldi		R18,0x02				;+0000442: E022		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R18				;+0000443: BD25
	run_t2	r18
	Sts		mem_com_period_a0+1,R17				;+0000444: 931000A1
	Sts		mem_com_period_a0,R16				;+0000446: 930000A0
	Lds		R18,mem_com_period_96				;+0000448: 91200096
	Lds		R19,mem_com_period_96+1				;+000044A: 91300097
	Add		R16,R18					;+000044C: 0F02
	Adc		R17,R19					;+000044D: 1F13
	Ror		R17						;+000044E: 9517
	Ror		R16						;+000044F: 9507
	Lsr		R17						;+0000450: 9516
	Ror		R16						;+0000451: 9507
	Lsr		R17						;+0000452: 9516
	Ror		R16						;+0000453: 9507
	Sts		mem_com_period_96,R16				;+0000454: 93000096
	Sts		mem_com_period_96+1,R17				;+0000456: 93100097
;	Rcall	evaluate_rcp					;+0000458: DD26		; Destination: 0x00017F
	Rjmp	AL169					;+0000459: C0BA		; Destination: 0x000514

AL158:
	Lds		R19,mem_unknown_9c		;+000045A: 9130009C
	Lds		R18,mem_unknown_9c+1	;+000045C: 9120009D
	Subi	R18,0xE8				;+000045E: 5E28		; 0xE8 = 0b11101000	= 232
	Sbci	R19,0x03				;+000045F: 4033		; 0x03 = 0b00000011	= 3
	Brcs	AL170					;+0000460: F028		; Destination: 0x000466
	Mov		R16,R18					;+0000461: 2F02
	Mov		R17,R19					;+0000462: 2F13
	Subi	R16,0xC4				;+0000463: 5C04		; 0xC4 = 0b11000100	= 196
	Sbci	R17,0x09				;+0000464: 4019		; 0x09 = 0b00001001	= 9
	Brcc	AL171					;+0000465: F410		; Destination: 0x000468
AL170:
	Ldi		R19,0x09				;+0000466: E039		; 0x09 = 0b00001001	= 9
	Ldi		R18,0xC4				;+0000467: EC24		; 0xC4 = 0b11000100	= 196
AL171:
	Sts		mem_unknown_9c,R19		;+0000468: 9330009C
	Sts		mem_unknown_9c+1,R18	;+000046A: 9320009D
	Sts		mem_com_period_a0+1,R19				;+000046C: 933000A1
	Sts		mem_com_period_a0,R18				;+000046E: 932000A0
	Out		TCNT2,R18				;+0000470: BD24
	Mov		tcnt2h,R19					;+0000471: 2EF3
;	Andi	flag1,0xF7				;+0000472: 7FB7		; 0xF7 = 0b11110111	= 247
	Cbr		flag1,1<<tcnt2h_ovf
	Ret								;+0000473: 9508
	Nop								;+0000474: 0000
	Nop								;+0000475: 0000
running_mode:
;	Ldi		R16,0x00				;+0000476: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+0000477: BD05
	pause_t2 r16
	Lds		R18,mem_st_pwm_duty+1	;+0000478: 912000B1
	Lsr		R18						;+000047A: 9526
	Mov		pwm_duty,R18			;+000047B: 2EE2
;	Lds		R16,0x0118				;+000047C: 91000118
;	Cpi		R16,0x02				;+000047E: 3002		; 0x02 = 0b00000010	= 2
;	Breq	AL172					;+000047F: F021		; Destination: 0x000484
;	Cpi		R16,0x03				;+0000480: 3003		; 0x03 = 0b00000011	= 3
;	Breq	AL172					;+0000481: F011		; Destination: 0x000484
;	Lsr		R18						;+0000482: 9526
;	Mov		pwm_duty,R18			;+0000483: 2EE2
AL172:
	Rcall	feedback_x1					;+0000484: DE62		; Destination: 0x0002E7
	Lds		state_on,mem_states				;+0000485: 90800080
	Lds		state_off,mem_states+1				;+0000487: 90900081
	Rcall	AL173					;+0000489: D042		; Destination: 0x0004CC
AL177:
	Rcall	feedback_x2					;+000048A: DE52		; Destination: 0x0002DD
	Lds		state_on,mem_states+2				;+000048B: 90800082
	Lds		state_off,mem_states+3				;+000048D: 90900083
	Rcall	AL174					;+000048F: D050		; Destination: 0x0004E0
	Rcall	feedback_a					;+0000490: DE60		; Destination: 0x0002F1
	Lds		state_on,mem_states+4				;+0000491: 90800084
	Lds		state_off,mem_states+5				;+0000493: 90900085
	Rcall	AL173					;+0000495: D036		; Destination: 0x0004CC
	Rcall	feedback_x1					;+0000496: DE50		; Destination: 0x0002E7
	Lds		state_on,mem_states+6				;+0000497: 90800086
	Lds		state_off,mem_states+7				;+0000499: 90900087
	Rcall	AL174					;+000049B: D044		; Destination: 0x0004E0
	Rcall	feedback_x2					;+000049C: DE40		; Destination: 0x0002DD
	Lds		state_on,mem_states+8				;+000049D: 90800088
	Lds		state_off,mem_states+9				;+000049F: 90900089
	Rcall	AL173					;+00004A1: D02A		; Destination: 0x0004CC
	Rcall	feedback_a					;+00004A2: DE4E		; Destination: 0x0002F1
	Lds		state_on,mem_states+10				;+00004A3: 9080008A
	Lds		state_off,mem_states+11				;+00004A5: 9090008B
	Rcall	AL174					;+00004A7: D038		; Destination: 0x0004E0
	Sbrs	flag1,RCP_updated			;+00004A8: FFB6
	Rjmp	AL172					;+00004A9: CFDA		; Destination: 0x000484
	Lds		state_on,mem_states				;+00004AA: 90800080
	Lds		state_off,mem_states+1				;+00004AC: 90900081
	Rcall	commit_output					;+00004AE: D018		; Destination: 0x0004C7
;	Ldi		R16,0x00				;+00004AF: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+00004B0: BD05
	pause_t2 r16
	In		R18,TCNT2				;+00004B1: B524
	Mov		R19,tcnt2h					;+00004B2: 2D3F
	Ldi		R16,0x00				;+00004B3: E000		; 0x00 = 0b00000000	= 0
	Out		TCNT2,R16				;+00004B4: BD04
	Mov		tcnt2h,R16					;+00004B5: 2EF0
;	Ldi		R16,0x02				;+00004B6: E002		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R16				;+00004B7: BD05
	run_t2	r16
	Sts		mem_com_period_96,R18				;+00004B8: 93200096
	Sts		mem_com_period_96+1,R19				;+00004BA: 93300097
; 启动马达开始加速度
;	Rcall	calc_startup_pwm					;+00004BC: 940E096D
	rcall	commit_pwm_by_setting
	Rcall	evaluate_rcp			;running mode +00004BE: DCC0		; Destination: 0x00017F
	motor_dir r18
	cpi		r18,IDLE
	breq	rm_loc_1
	cpi		r18,BRAKE
	breq	rm_loc_2
	rjmp	rm_loc_3
rm_loc_1:
	rjmp	control_start
rm_loc_2:
	rjmp	braking_motor
rm_loc_3:
	Lds		R18,mem_state7_period				;+00004BF: 91200072
	Lds		R19,mem_state7_period+1				;+00004C1: 91300073
	Rcall	stay_until_t2_reach_r18r19					;+00004C3: D068		; Destination: 0x00052C
	Sbrc	flag1,weak_power			;+00004C4: FDB4
;	Rjmp	limit_pwm_due_to_battery_fail					;+00004C5: C0EA		; Destination: 0x0005B0
	rjmp	power_fail
	Rjmp	AL177					;+00004C6: CFC3		; Destination: 0x00048A
commit_output:
	Sbic	PINB,2					;+00004C7: 99B2
	Out		PortD,state_on				;+00004C8: BA82
	Sbis	PINB,2					;+00004C9: 9BB2
	Out		PortD,state_off				;+00004CA: BA92
	Ret								;+00004CB: 9508
AL173:
	Rcall	commit_output					;+00004CC: DFFA		; Destination: 0x0004C7
	Rcall	r_before_zc_waiting					;+00004CD: D029		; Destination: 0x0004F7
AL180:
	Mov		R28,tcnt2h				;+00004CE: 2DCF
	Subi	R28,-10				;+00004CF: 5FC6		; 0xF6 = 0b11110110	= 246
;	never reach here
;	motor_dir r16
;	cpi		r16,BRAKE
;	brne	AL181
;	cli
;	Sbrs	flag1,no_idle				;+00004D0: FFB7
;	Rjmp	AL160					;+00004D1: C022		; Destination: 0x0004F4
AL181:
	Sbrc	flag1,tcnt2h_ovf					;+00004D2: FDB3
	Rjmp	AL179					;+00004D3: C005		; Destination: 0x0004D9
	Sbic	ACSR,ACO				;+00004D4: 9945
	Rjmp	AL180					;+00004D5: CFF8		; Destination: 0x0004CE
	Dec		R28						;+00004D6: 95CA
	Brne	AL181					;+00004D7: F7D1		; Destination: 0x0004D2
	Rcall	AL182					;+00004D8: D031		; Destination: 0x00050A
AL179:
	Sbrc	flag1,tcnt2h_ovf			;+00004D9: FDB3
	Rjmp	zc_timeout				;+00004DA: C0A2		; Destination: 0x00057D
	Sbrc	tcnt2h,6				;+00004DB: FCF6
	Rjmp	zc_timeout				;+00004DC: C0A0		; Destination: 0x00057D
	Sbrc	tcnt2h,7				;+00004DD: FCF7
	Rjmp	zc_timeout				;+00004DE: C09E		; Destination: 0x00057D
	Ret								;+00004DF: 9508
AL174:
	Rcall	commit_output					;+00004E0: DFE6		; Destination: 0x0004C7
	Rcall	r_before_zc_waiting					;+00004E1: D015		; Destination: 0x0004F7
AL185:
	Mov		R28,tcnt2h					;+00004E2: 2DCF
	Subi	R28,-10				;+00004E3: 5FC6		; 0xF6 = 0b11110110	= 246
;	motor_dir r16
;	cpi		r16,BRAKE
;	brne	AL186
;	rjmp	braking_motor
;	Sbrs	flag1,no_idle					;+00004E4: FFB7
;	Rjmp	AL160					;+00004E5: C00E		; Destination: 0x0004F4
AL186:
	Sbrc	flag1,tcnt2h_ovf			;+00004E6: FDB3
	Rjmp	AL184					;+00004E7: C005		; Destination: 0x0004ED
	Sbis	ACSR,ACO				;+00004E8: 9B45
	Rjmp	AL185					;+00004E9: CFF8		; Destination: 0x0004E2
	Dec		R28						;+00004EA: 95CA
	Brne	AL186					;+00004EB: F7D1		; Destination: 0x0004E6
	Rcall	AL182					;+00004EC: D01D		; Destination: 0x00050A
AL184:
	Sbrc	flag1,tcnt2h_ovf			;+00004ED: FDB3
	Rjmp	zc_timeout					;+00004EE: C08E		; Destination: 0x00057D
	Sbrc	tcnt2h,6					;+00004EF: FCF6
	Rjmp	zc_timeout					;+00004F0: C08C		; Destination: 0x00057D
	Sbrc	tcnt2h,7					;+00004F1: FCF7
	Rjmp	zc_timeout					;+00004F2: C08A		; Destination: 0x00057D
	Ret								;+00004F3: 9508
;AL160:
;	Pop		R16						;+00004F4: 910F
;	Pop		R16						;+00004F5: 910F
;	Rjmp	braking_motor					;+00004F6: C055		; Destination: 0x00054C
;	rjmp	control_start
r_before_zc_waiting:
;	Ldi		R16,0x00				;+00004F7: E000		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R16				;+00004F8: BD05
	pause_t2 r16
	In		R18,TCNT2				;+00004F9: B524
	Mov		R19,tcnt2h					;+00004FA: 2D3F
	Ldi		R16,0x00				;+00004FB: E000		; 0x00 = 0b00000000	= 0
	Out		TCNT2,R16				;+00004FC: BD04
	Mov		tcnt2h,R16					;+00004FD: 2EF0
;	Ldi		R16,0x02				;+00004FE: E002		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R16				;+00004FF: BD05
	run_t2	r16
	Sts		mem_com_period_96,R18				;+0000500: 93200096
	Sts		mem_com_period_96+1,R19				;+0000502: 93300097
	Sts		mem_state7_period,R18				;+0000504: 93200072
	Sts		mem_state7_period+1,R19				;+0000506: 93300073
AL168:
	Rcall	calc_timing_adv_before					;+0000508: D02B		; Destination: 0x000534
	Rjmp	stay_until_t2_reach_r18r19					;+0000509: C022		; Destination: 0x00052C
AL182:
;	Ldi		R18,0x00				;+000050A: E020		; 0x00 = 0b00000000	= 0
;	Out		TCCR2,R18				;+000050B: BD25
	pause_t2 r18
	In		R16,TCNT2				;+000050C: B504
	Mov		R17,tcnt2h					;+000050D: 2D1F
;	Ldi		R18,0x02				;+000050E: E022		; 0x02 = 0b00000010	= 2
;	Out		TCCR2,R18				;+000050F: BD25
	run_t2	r18
	Sts		mem_com_period_96,R16				;+0000510: 93000096
	Sts		mem_com_period_96+1,R17				;+0000512: 93100097
AL169:
	Rcall	calc_timing_adv_after					;+0000514: D02A		; Destination: 0x00053F
	Lds		R16,mem_com_period_96				;+0000515: 91000096
	Lds		R17,mem_com_period_96+1				;+0000517: 91100097
	Add		R18,R16					;+0000519: 0F20
	Adc		R19,R17					;+000051A: 1F31
	Brcs	AL189					;+000051B: F0B8		; Destination: 0x000533
	Lds		R16,mem_com_period_a0				;+000051C: 910000A0
	Lds		R17,mem_com_period_a0+1				;+000051E: 911000A1
	Add		R16,R18					;+0000520: 0F02
	Adc		R17,R19					;+0000521: 1F13
	Ror		R17						;+0000522: 9517
	Ror		R16						;+0000523: 9507
	Add		R18,R16					;+0000524: 0F20
	Adc		R19,R17					;+0000525: 1F31
	Ror		R19						;+0000526: 9537
	Ror		R18						;+0000527: 9527
	Sts		mem_com_period_a0,R18				;+0000528: 932000A0
	Sts		mem_com_period_a0+1,R19				;+000052A: 933000A1
stay_until_t2_reach_r18r19:
	Sbrc	flag1,tcnt2h_ovf					;+000052C: FDB3
	Rjmp	AL189					;+000052D: C005		; Destination: 0x000533
	In		R16,TCNT2				;+000052E: B504
	Mov		R17,tcnt2h				;+000052F: 2D1F
	Sub		R16,R18					;+0000530: 1B02
	Sbc		R17,R19					;+0000531: 0B13
	Brcs	stay_until_t2_reach_r18r19					;+0000532: F3C8		; Destination: 0x00052C
AL189:
	Ret								;+0000533: 9508

calc_timing_adv_before:
;	Push	R31
;	Push	R30
	Lds		R18,mem_com_period_96				;+0000534: 91200096
	Lds		R19,mem_com_period_96+1				;+0000536: 91300097
	Lds		R16,mem_unknown_bb+1				;+0000538: 910000BC
	Lds		R17,mem_unknown_bb				;+000053A: 911000BB
	Rcall	AL190					;+000053C: 940E0B8B
;	Pop		R30
;	Pop		R31
	Ret								;+000053E: 9508

calc_timing_adv_after:
;	Push	R31
;	Push	R30
	Lds		R18,mem_com_period_96				;+000053F: 91200096
	Lds		R19,mem_com_period_96+1				;+0000541: 91300097
	Lds		R16,mem_unknown_bd+1				;+0000543: 910000BE
	Lds		R17,mem_unknown_bd				;+0000545: 911000BD
	Rcall	AL190					;+0000547: 940E0B8B
;	Pop		R30
;	Pop		R31
	Ret								;+0000549: 9508

zc_timeout:
	Pop		R16						;+000057D: 910F
	Pop		R16						;+000057E: 910F
running_failure:
	Rjmp	starting_motor
;	Rcall	all_fet_off					;+000057F: 940E0A1A
;	Ldi		R16,0x1E				;+0000581: E10E		; 0x1E = 0b00011110	= 30
;	Sts		mem_temp_90,R16				;+0000582: 93000090
;	Mov		R18,R16					;+0000584: 2F20
;	Rcall	commit_pwm8k					;+0000585: 940E0959
;	Ldi		R17,0x02				;+0000587: E012		; 0x02 = 0b00000010	= 2
;	Sts		mem_temp_91,R17				;+0000588: 93100091
;AL204:
;	Lds		R17,mem_brake_param				;+000058A: 911000B7
;	Sts		mem_temp_92,R17				;+000058C: 93100092
;AL201:
;	sbrc	flag1,Break_flag_on		;+000058E: FDB1
;	Rcall	brake_protect					;+000058F: DB9F		; Destination: 0x00012F
;	Sbrc	flag1,RCP_updated			;+0000590: FDB6
;	Rjmp	AL199					;+0000591: C007		; Destination: 0x000599
;	Lds		R17,mem_temp_92				;+0000592: 91100092
;	Dec		R17						;+0000594: 951A
;	Sts		mem_temp_92,R17				;+0000595: 93100092
;	Breq	AL200					;+0000597: F029		; Destination: 0x00059D
;	Rjmp	AL201					;+0000598: CFF5		; Destination: 0x00058E
;AL199:
;	Rcall	evaluate_rcp					;+0000599: DBE5		; Destination: 0x00017F
;	Sbrs	flag1,7					;+000059A: FFB7
;	Rjmp	AL202					;+000059B: C00D		; Destination: 0x0005A9
;AL205:
;	Ori		flag1,0x80				;+000059C: 68B0		; 0x80 = 0b10000000	= 128
;	sbr		flag1,1<<no_idle
;AL200:
;	Lds		R16,mem_temp_90				;+000059D: 91000090
;	Ldi		R17,0x01				;+000059F: E011		; 0x01 = 0b00000001	= 1
;	Add		R16,R17					;+00005A0: 0F01
;	Brcc	AL203					;+00005A1: F408		; Destination: 0x0005A3
;	Ldi		R16,0xFF				;+00005A2: EF0F		; 0xFF = 0b11111111	= 255
;AL203:
;	Sts		mem_temp_90,R16				;+00005A3: 93000090
;	Mov		R18,R16					;+00005A5: 2F20
;	Rcall	commit_pwm8k					;+00005A6: 940E0959
;	Rjmp	AL204					;+00005A8: CFE1		; Destination: 0x00058A
;AL202:
;	Lds		R17,mem_temp_91				;+00005A9: 91100091
;	Dec		R17						;+00005AB: 951A
;	Sts		mem_temp_91,R17				;+00005AC: 93100091
;	Brne	AL205					;+00005AE: F769		; Destination: 0x00059C
;	Rjmp	control_start			;+00005AF: CD48		; Destination: 0x0002F8
.if 1==2
limit_pwm_due_to_battery_fail:
;	Lds		R16,0x0115				;+00005B0: 91000115
;	Cpi		R16,0x02				;+00005B2: 3002		; 0x02 = 0b00000010	= 2
;	Breq	AL206					;+00005B3: F141		; Destination: 0x0005DC
	Ldi		R18,0x04				;+00005B4: E024		; 0x04 = 0b00000100	= 4
	Lds		R19,mem_parameters+15				;+00005B5: 9130010F
	Cpi		R19,0x03				;+00005B7: 3033		; 0x03 = 0b00000011	= 3
	Breq	AL207					;+00005B8: F021		; Destination: 0x0005BD
	Ldi		R18,0x08				;+00005B9: E028		; 0x08 = 0b00001000	= 8
	Cpi		R19,0x02				;+00005BA: 3032		; 0x02 = 0b00000010	= 2
	Breq	AL207					;+00005BB: F009		; Destination: 0x0005BD
	Ldi		R18,0x10				;+00005BC: E120		; 0x10 = 0b00010000	= 16
AL207:
	Cli								;+00005BD: 94F8
	In		R16,OCR1BL				;+00005BE: B508
	In		R17,OCR1BH				;+00005BF: B519
	Sei								;+00005C0: 9478
	Sub		R16,R18					;+00005C1: 1B02
	Sbci	R17,0x00				;+00005C2: 4010		; 0x00 = 0b00000000	= 0
	Brcs	AL206					;+00005C3: F0C0		; Destination: 0x0005DC
	Cli								;+00005C4: 94F8
	Out		OCR1BH,R17				;+00005C5: BD19
	Out		OCR1BL,R16				;+00005C6: BD08
	Sei								;+00005C7: 9478
	Cpi		R19,0x03				;+00005C8: 3033		; 0x03 = 0b00000011	= 3
	Breq	AL208					;+00005C9: F031		; Destination: 0x0005D0
	Cpi		R19,0x02				;+00005CA: 3032		; 0x02 = 0b00000010	= 2
	Breq	AL209					;+00005CB: F041		; Destination: 0x0005D4
	Subi	R16,0xFF				;+00005CC: 5F0F		; 0xFF = 0b11111111	= 255
	Sbci	R17,0x00				;+00005CD: 4010		; 0x00 = 0b00000000	= 0
	Brcs	AL206					;+00005CE: F068		; Destination: 0x0005DC
	Rjmp	AL210					;+00005CF: C007		; Destination: 0x0005D7
AL208:
	Subi	R16,0x40				;+00005D0: 5400		; 0x40 = 0b01000000	= 64
	Sbci	R17,0x00				;+00005D1: 4010		; 0x00 = 0b00000000	= 0
	Brcs	AL206					;+00005D2: F048		; Destination: 0x0005DC
	Rjmp	AL210					;+00005D3: C003		; Destination: 0x0005D7
AL209:
	Subi	R16,0x80				;+00005D4: 5800		; 0x80 = 0b10000000	= 128
	Sbci	R17,0x00				;+00005D5: 4010		; 0x00 = 0b00000000	= 0
	Brcs	AL206					;+00005D6: F028		; Destination: 0x0005DC
AL210:
	Ldi		R16,0x01				;+00005D7: E001		; 0x01 = 0b00000001	= 1
	Sts		mem_low_power_count,R16				;+00005D8: 930000AA
;	Ori		flag1,0x01				;+00005DA: 60B1		; 0x01 = 0b00000001	= 1
;	sbr		flag1,1<<unknown_option_xh_0
	Rjmp	AL177					;+00005DB: CEAE		; Destination: 0x00048A

.endif

AL206:
	Rjmp	running_failure					;+00005DC: CFA2		; Destination: 0x00057F

eep_write:
;	Sbic	EECR,1					;+00005E0: 99E1
;	Rjmp	eep_write					;+00005E1: CFFE		; Destination: 0x0005E0
;	Rcall	nop4					;+00005EA: D010		; Destination: 0x0005FB
;	Sbi		EECR,EEMWE				;+00005EB: 9AE2
;	Nop								;+00005EC: 0000
;	Sbi		EECR,EEWE				;+00005ED: 9AE1
;	Rcall	nop4					;+00005EE: D00C		; Destination: 0x0005FB

	sbic	EECR,EEWE
	rjmp	eep_write
	Lds		R16,mem_eep_addr				;+00005E2: 91000070
	out		EEARL,r16				;+00005E4: BB0E
	Clr		R16						;+00005E5: 2700
	Out		EEARH,R16				;+00005E6: BB0F
	; Write data (r16) to Data Register
	Lds		R16,mem_eep_data				;+00005E7: 91000071
	Out		EEDR,R16				;+00005E9: BB0D
	; Write logical one to EEMPE
	sbi		EECR,EEMWE
	nop
	; Start eeprom write by setting EEPE
	sbi		EECR,EEWE

	Ret								;+00005EF: 9508

eep_read:
	sbic	EECR,EEWE				;+00005F0: 99E1
	Rjmp	eep_read					;+00005F1: CFFE		; Destination: 0x0005F0
	Lds		R16,mem_eep_addr				;+00005F2: 91000070
	Out		EEARL,R16				;+00005F4: BB0E
	Clr		R16						;+00005F5: 2700
	Out		EEARH,R16				;+00005F6: BB0F
	Sbi		EECR,EERE				;+00005F7: 9AE0
	Rcall	nop4					;+00005F8: D002		; Destination: 0x0005FB
	In		R16,EEDR				;+00005F9: B30D
	Ret								;+00005FA: 9508

nop4:
	Nop								;+00005FB: 0000
	Nop								;+00005FC: 0000
	Nop								;+00005FD: 0000
	Nop								;+00005FE: 0000
	Ret								;+00005FF: 9508
AL252:
	Sts		mem_eep_addr,R29				;+0000600: 93D00070
	Sts		mem_eep_data,R28				;+0000602: 93C00071
	Rcall	eep_write					;+0000604: DFDB		; Destination: 0x0005E0
	Ret								;+0000605: 9508

eep2mem40:
	push	ZH
	push	ZL
	ldi		R31,high(mem_parameters)
	ldi		R30,low(mem_parameters)
	ldi		R16,0x00				;+0000608: E000		; 0x00 = 0b00000000	= 0
	sts		mem_eep_addr,R16				;+0000609: 93000070
AL213:
	Rcall	eep_read					;+000060B: DFE4		; Destination: 0x0005F0
	St		Z+,R16					;+000060C: 9301
	Lds		R16,mem_eep_addr				;+000060D: 91000070
;	Subi	R16,0xFF				;+000060F: 5F0F		; 0xFF = 0b11111111	= 255
	inc		r16
	Sts		mem_eep_addr,R16				;+0000610: 93000070
	Subi	R16,0x40				;+0000612: 5400		; 0x40 = 0b01000000	= 64
	Brcs	AL213					;+0000613: F3B8		; Destination: 0x00060B

; 1=Nimh, 2=Lipo
	Ldi		R16, 1
	Sts		0x0111, R16				; LockDown Cells as Lipo

; 锁定数值,貌似错了啊, 应该素1(Auto)才对....
; 2	way	about Lock MinMaxRCP
; 2 way about set MinMaxRCP

	Ldi		R16, low(Low_RCP)
	Ldi		R17, high(Low_RCP)
	Movw	R4, R16
	Ldi		R16, low(Hig_RCP)
	Ldi		R17, high(Hig_RCP)
	Movw	R2, R16

	Pop		ZL
	Pop		ZH
	Ret								;+0000614: 9508
; useless ---------------------------------------------------------------------------
.if	1==2
AL080:
	Lds		R16,mem_parameters+9				;+0000615: 91000109
	Cpi		R16,0x01				;+0000617: 3001		; 0x01 = 0b00000001	= 1
	Breq	AL214					;+0000618: F099		; Destination: 0x00062C
	Sts		mem_eep_data,R16				;+0000619: 93000071
	Ldi		R16,0x50				;+000061B: E500		; 0x50 = 0b01010000	= 80
	Sts		mem_eep_addr,R16				;+000061C: 93000070
	Rcall	eep_write					;+000061E: DFC1		; Destination: 0x0005E0
	Ldi		R18,0x01				;+000061F: E021		; 0x01 = 0b00000001	= 1
	Sts		mem_parameters+9,R18				;+0000620: 93200109
	Ldi		R16,0x09				;+0000622: E009		; 0x09 = 0b00001001	= 9
	Ldi		R17,0x01				;+0000623: E011		; 0x01 = 0b00000001	= 1
	Subi	R16,0x00				;+0000624: 5000		; 0x00 = 0b00000000	= 0
	Sbci	R17,0x01				;+0000625: 4011		; 0x01 = 0b00000001	= 1
	Sts		mem_eep_data,R18				;+0000626: 93200071
	Sts		mem_eep_addr,R16				;+0000628: 93000070
	Rcall	eep_write					;+000062A: DFB5		; Destination: 0x0005E0
	Ret								;+000062B: 9508
AL214:
	Ldi		R16,0x50				;+000062C: E500		; 0x50 = 0b01010000	= 80
	Sts		mem_eep_addr,R16				;+000062D: 93000070
	Rcall	eep_read					;+000062F: DFC0		; Destination: 0x0005F0
	Ldi		R18,0xFF				;+0000630: EF2F		; 0xFF = 0b11111111	= 255
	Cpi		R16,0x01				;+0000631: 3001		; 0x01 = 0b00000001	= 1
	Breq	AL215					;+0000632: F009		; Destination: 0x000634
	Mov		R18,R16					;+0000633: 2F20
AL215:
	Sts		mem_parameters+9,R18				;+0000634: 93200109
	Ldi		R16,0x09				;+0000636: E009		; 0x09 = 0b00001001	= 9
	Ldi		R17,0x01				;+0000637: E011		; 0x01 = 0b00000001	= 1
	Subi	R16,0x00				;+0000638: 5000		; 0x00 = 0b00000000	= 0
	Sbci	R17,0x01				;+0000639: 4011		; 0x01 = 0b00000001	= 1
	Sts		mem_eep_data,R18				;+000063A: 93200071
	Sts		mem_eep_addr,R16				;+000063C: 93000070
	Rcall	eep_write					;+000063E: DFA1		; Destination: 0x0005E0
	Ret								;+000063F: 9508
AL109:
	Ldi		R16,0x19				;+0000640: E109		; 0x19 = 0b00011001	= 25
	Ldi		R17,0x01				;+0000641: E011		; 0x01 = 0b00000001	= 1
	Subi	R16,0x00				;+0000642: 5000		; 0x00 = 0b00000000	= 0
	Sbci	R17,0x01				;+0000643: 4011		; 0x01 = 0b00000001	= 1
	Mov		R18,R16					;+0000644: 2F20
	Sts		mem_eep_addr,R16				;+0000645: 93000070
	Rcall	eep_read					;+0000647: DFA8		; Destination: 0x0005F0
	Ldi		R17,0x01				;+0000648: E011		; 0x01 = 0b00000001	= 1
	Cpi		R16,0x02				;+0000649: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL216					;+000064A: F009		; Destination: 0x00064C
	Ldi		R17,0x02				;+000064B: E012		; 0x02 = 0b00000010	= 2
AL216:
	Sts		mem_parameters+0x19,R17				;+000064C: 93100119
	Sts		mem_eep_data,R17				;+000064E: 93100071
	Sts		mem_eep_addr,R18				;+0000650: 93200070
	Rcall	eep_write					;+0000652: DF8D		; Destination: 0x0005E0
	Ret								;+0000653: 9508
	Sts		mem_eep_data,R3				;+0000654: 92200071
	Ldi		R16,0x52				;+0000656: E502		; 0x52 = 0b01010010	= 82
	Sts		mem_eep_addr,R16				;+0000657: 93000070
	Rcall	eep_write					;+0000659: DF86		; Destination: 0x0005E0
	Sts		mem_eep_data,rcp_top_l			;+000065A: 92300071
	Ldi		R16,0x53				;+000065C: E503		; 0x53 = 0b01010011	= 83
	Sts		mem_eep_addr,R16				;+000065D: 93000070
	Rcall	eep_write					;+000065F: DF80		; Destination: 0x0005E0
	Ret								;+0000660: 9508
AL074:
	Lds		R16,0x0117				;+0000661: 91000117
	Cpi		R16,0x01				;+0000663: 3001		; 0x01 = 0b00000001	= 1
	Brne	AL217					;+0000664: F4A1		; Destination: 0x000679
	Ldi		R16,0x52				;+0000665: E502		; 0x52 = 0b01010010	= 82
	Sts		mem_eep_addr,R16				;+0000666: 93000070
	Rcall	eep_read					;+0000668: DF87		; Destination: 0x0005F0
	Mov		R3,R16					;+0000669: 2E20
	Ldi		R16,0x53				;+000066A: E503		; 0x53 = 0b01010011	= 83
	Sts		mem_eep_addr,R16				;+000066B: 93000070
	Rcall	eep_read					;+000066D: DF82		; Destination: 0x0005F0
	Mov		R2,R16					;+000066E: 2E30
	Mov		R17,R3					;+000066F: 2D12
	Subi	R16,0x70				;+0000670: 5700		; 0x70 = 0b01110000	= 112
	Sbci	R17,0x17				;+0000671: 4117		; 0x17 = 0b00010111	= 23
	Brcc	AL218					;+0000672: F408		; Destination: 0x000674
	Ret								;+0000673: 9508
AL218:
	Ldi		R16,0x48				;+0000674: E408		; 0x48 = 0b01001000	= 72
	Ldi		R17,0x0D				;+0000675: E01D		; 0x0D = 0b00001101	= 13
AL219:
	Movw	R2,R16					;+0000676: 2E30
;	Mov		R2,R17					;+0000677: 2E21
	Ret								;+0000678: 9508
AL217:
	Lds		R16,0x0117				;+0000679: 91000117
	Cpi		R16,0x02				;+000067B: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL218					;+000067C: F3B9		; Destination: 0x000674
	Lds		R16,0x0117				;+000067D: 91000117
	Cpi		R16,0x03				;+000067F: 3003		; 0x03 = 0b00000011	= 3
	Ldi		R16,0x10				;+0000680: E100		; 0x10 = 0b00010000	= 16
	Ldi		R17,0x0E				;+0000681: E01E		; 0x0E = 0b00001110	= 14
	Breq	AL219					;+0000682: F399		; Destination: 0x000676
	Lds		R16,0x0117				;+0000683: 91000117
	Cpi		R16,0x04				;+0000685: 3004		; 0x04 = 0b00000100	= 4
	Ldi		R16,0xD8				;+0000686: ED08		; 0xD8 = 0b11011000	= 216
	Ldi		R17,0x0E				;+0000687: E01E		; 0x0E = 0b00001110	= 14
	Breq	AL219					;+0000688: F369		; Destination: 0x000676
	Lds		R16,0x0117				;+0000689: 91000117
	Cpi		R16,0x05				;+000068B: 3005		; 0x05 = 0b00000101	= 5
	Ldi		R16,0xA0				;+000068C: EA00		; 0xA0 = 0b10100000	= 160
	Ldi		R17,0x0F				;+000068D: E01F		; 0x0F = 0b00001111	= 15
	Breq	AL219					;+000068E: F339		; Destination: 0x000676
	Ldi		R16,0x01				;+000068F: E001		; 0x01 = 0b00000001	= 1
	Sts		0x0117,R16				;+0000690: 93000117
	Rjmp	AL218					;+0000692: CFE1		; Destination: 0x000674
AL075:
	Sts		mem_temp_90,R16				;+0000693: 93000090
	Sts		mem_temp_91,R17				;+0000695: 93100091
	Lds		R16,0x0116				;+0000697: 91000116
	Cpi		R16,0x02				;+0000699: 3002		; 0x02 = 0b00000010	= 2
	Ldi		R16,0xD0				;+000069A: ED00		; 0xD0 = 0b11010000	= 208
	Ldi		R17,0x07				;+000069B: E017		; 0x07 = 0b00000111	= 7
	Breq	AL220					;+000069C: F121		; Destination: 0x0006C1
	Lds		R16,0x0116				;+000069D: 91000116
	Cpi		R16,0x03				;+000069F: 3003		; 0x03 = 0b00000011	= 3
	Ldi		R16,0x98				;+00006A0: E908		; 0x98 = 0b10011000	= 152
	Ldi		R17,0x08				;+00006A1: E018		; 0x08 = 0b00001000	= 8
	Breq	AL220					;+00006A2: F0F1		; Destination: 0x0006C1
	Lds		R16,0x0116				;+00006A3: 91000116
	Cpi		R16,0x04				;+00006A5: 3004		; 0x04 = 0b00000100	= 4
	Ldi		R16,0x60				;+00006A6: E600		; 0x60 = 0b01100000	= 96
	Ldi		R17,0x09				;+00006A7: E019		; 0x09 = 0b00001001	= 9
	Breq	AL220					;+00006A8: F0C1		; Destination: 0x0006C1
	Lds		R16,0x0116				;+00006A9: 91000116
	Cpi		R16,0x05				;+00006AB: 3005		; 0x05 = 0b00000101	= 5
	Ldi		R16,0x28				;+00006AC: E208		; 0x28 = 0b00101000	= 40
	Ldi		R17,0x0A				;+00006AD: E01A		; 0x0A = 0b00001010	= 10
	Breq	AL220					;+00006AE: F091		; Destination: 0x0006C1
	Lds		R16,0x0116				;+00006AF: 91000116
	Cpi		R16,0x06				;+00006B1: 3006		; 0x06 = 0b00000110	= 6
	Ldi		R16,0xF0				;+00006B2: EF00		; 0xF0 = 0b11110000	= 240
	Ldi		R17,0x0A				;+00006B3: E01A		; 0x0A = 0b00001010	= 10
	Breq	AL220					;+00006B4: F061		; Destination: 0x0006C1
	Lds		R16,0x0116				;+00006B5: 91000116
	Cpi		R16,0x07				;+00006B7: 3007		; 0x07 = 0b00000111	= 7
	Ldi		R16,0xB8				;+00006B8: EB08		; 0xB8 = 0b10111000	= 184
	Ldi		R17,0x0B				;+00006B9: E01B		; 0x0B = 0b00001011	= 11
	Breq	AL220					;+00006BA: F031		; Destination: 0x0006C1
	Lds		R16,mem_temp_90				;+00006BB: 91000090
	Lds		R17,mem_temp_91				;+00006BD: 91100091
	Sec								;+00006BF: 9408
	Ret								;+00006C0: 9508
AL220:
	Lds		R18,mem_temp_90				;+00006C1: 91200090
	Lds		R19,mem_temp_91				;+00006C3: 91300091
	Sub		R18,R16					;+00006C5: 1B20
	Sbc		R19,R17					;+00006C6: 0B31
	Ret								;+00006C7: 9508

	Nop								;+00006C8: 0000
	Sts		0x009E,R16				;+00006C9: 9300009E
	Ldi		R16,0xFF				;+00006CB: EF0F		; 0xFF = 0b11111111	= 255
	Sts		0x009F,R16				;+00006CC: 9300009F
.endif
; useless end -----------------------------------------------------------------------

KsTim:
	Lds		R16,0x009F				;+00006CE: 9100009F
AL221:
	Dec		R16						;+00006D0: 950A
	Brne	AL221					;+00006D1: F7F1		; Destination: 0x0006D0
	Sts		0x009F,R16				;+00006D2: 9300009F
	Lds		R16,0x009E				;+00006D4: 9100009E
	Dec		R16						;+00006D6: 950A
	Sts		0x009E,R16				;+00006D7: 9300009E
	Brne	KsTim					;+00006D9: F7A1		; Destination: 0x0006CE
	Ret								;+00006DA: 9508

;AL094:
;AL095:
;AL096:
;AL097:
;AL098:
;AL099:
;AL100:
;AL101:
;AL106:
;AL224:
;AL223:
;AL225:
;AL090:
;AL089:
;AL081:

; sound	here
;Beep1:
;Beep2:
;	Ret								;+000079E: 9508

init_timer1:
;	Ldi		R16,0x18				;+0000901: E108		; 0x18 = 0b00011000	= 24
; PWM DISABLED
	pause_t1 r16
;	ldi		r16,(1<<WGM13)+(1<<WGM12)
;	Out		TCCR1B,R16				;+0000902: BD0E

	Ldi		R18,low(15000)
	Ldi		R19,high(15000)
	Out		TCNT1H,R19				;+0000905: BD3D
	Out		TCNT1L,R18				;+0000906: BD2C
	Ldi		R18,0x00				;+0000907: E020		; 0x00 = 0b00000000	= 0
	Ldi		R19,0x00				;+0000908: E030		; 0x00 = 0b00000000	= 0
	Out		OCR1BH,R19				;+0000909: BD39
	Out		OCR1BL,R18				;+000090A: BD28
	Ldi		R18,0xFF				;+000090B: EF2F		; 0xFF = 0b11111111	= 255
	Ldi		R19,0x00				;+000090C: E030		; 0x00 = 0b00000000	= 0
	Out		OCR1AH,R19				;+000090D: BD3B
	Out		OCR1AL,R18				;+000090E: BD2A
;	Ldi		R16,0x19				;+000090F: E109		; 0x19 = 0b00011001	= 25
; PWM ENABLE
;	ldi		r16,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
;	Out		TCCR1B,R16				;+0000910: BD0E
	run_t1 r16
	Cbi		PORTB,2					;+0000911: 98C2
	Ret								;+0000912: 9508
setting_timer1:
; enable ocie1a,ocie1b,overflow,

	rcall	all_fet_off					;+0000913: 940E0A1A
;	cli								;+0000915: 94F8
;	ldi		R16,0xCE				;+0000916: EC0E		; 0xCE = 0b11001110	= 206
	ldi		r16,low(PWM_TOP_8K)
;	ldi		R17,0x07				;+0000917: E017		; 0x07 = 0b00000111	= 7
	ldi		r17,high(PWM_TOP_8K)
	out		ICR1H,R17				;+0000918: BD17
	out		ICR1L,R16				;+0000919: BD06
	in		R16,TIMSK				;+000091A: B709
;	ori		R16,0x1C				;+000091B: 610C		; 0x1C = 0b00011100	= 28
	sbr		r16,(1<<OCIE1A)+(1<<OCIE1B)+(1<<TOIE1)
	out		TIMSK,R16				;+000091C: BF09
;	ldi		R16,0x22				;+000091D: E202		; 0x22 = 0b00100010	= 34
;WGM13-0: 1110 Fast pwm mode top=ICR1
;CS12-0: 001 CLK/1(NO PRESCALER)
;clear OC1B(pb2) on compare match, set OC1B(pb2) at bottom
	ldi		r16,(1<<COM1B1)+(1<<WGM11)
	out		TCCR1A,R16				;+000091E: BD0F
;	ldi		R16,0x19				;+000091F: E109		; 0x19 = 0b00011001	= 25
	ldi		r16,(1<<WGM13)+(1<<WGM12)+(1<<CS10)
	out		TCCR1B,R16				;+0000920: BD0E
;	sei								;+0000921: 9478
	ret								;+0000922: 9508
;AL243:
;	clr		R19						;+0000923: 2733
;	add		R18,R18					;+0000924: 0F22
;	Adc		R19,R19					;+0000925: 1F33
;	Add		R18,R18					;+0000926: 0F22
;	Adc		R19,R19					;+0000927: 1F33
;	Add		R18,R18					;+0000928: 0F22
;	Adc		R19,R19					;+0000929: 1F33
;	Cli								;+000092A: 94F8
;	Out		OCR1BH,R19				;+000092B: BD39
;	Out		OCR1BL,R18				;+000092C: BD28
;	Ldi		R18,0xFF				;+000092D: EF2F		; 0xFF = 0b11111111	= 255
;	Ldi		R19,0x03				;+000092E: E033		; 0x03 = 0b00000011	= 3
;	Out		OCR1AH,R19				;+000092F: BD3B
;	Out		OCR1AL,R18				;+0000930: BD2A
;	Ldi		R18,0xCE				;+0000931: EC2E		; 0xCE = 0b11001110	= 206
;	Ldi		R19,0x07				;+0000932: E037		; 0x07 = 0b00000111	= 7
;	Out		ICR1H,R19				;+0000933: BD37
;	Out		ICR1L,R18				;+0000934: BD26
;	Sei								;+0000935: 9478
;	ret								;+0000936: 9508
commit_pwm16k:
	Clr		R19						;+0000937: 2733
	Add		R18,R18					;+0000938: 0F22
	Adc		R19,R19					;+0000939: 1F33
	Add		R18,R18					;+000093A: 0F22
	Adc		R19,R19					;+000093B: 1F33
	Cli								;+000093C: 94F8
	Out		OCR1BH,R19				;+000093D: BD39
	Out		OCR1BL,R18				;+000093E: BD28
	Ldi		R18,0xFF				;+000093F: EF2F		; 0xFF = 0b11111111	= 255
	Ldi		R19,0x01				;+0000940: E031		; 0x01 = 0b00000001	= 1
	Out		OCR1AH,R19				;+0000941: BD3B
	Out		OCR1AL,R18				;+0000942: BD2A
;	Ldi		R18,0xE7				;+0000943: EE27		; 0xE7 = 0b11100111	= 231
;	Ldi		R19,0x03				;+0000944: E033		; 0x03 = 0b00000011	= 3
	ldi		r18,low(PWM_TOP_16K)
	ldi		r19,high(PWM_TOP_16K)
	Out		ICR1H,R19				;+0000945: BD37
	Out		ICR1L,R18				;+0000946: BD26
	Sei								;+0000947: 9478
	Ret								;+0000948: 9508
commit_pwm32k:
	Clr		R19						;+0000949: 2733
	Add		R18,R18					;+000094A: 0F22
	Adc		R19,R19					;+000094B: 1F33
	Cli								;+000094C: 94F8
	Out		OCR1BH,R19				;+000094D: BD39
	Out		OCR1BL,R18				;+000094E: BD28
	Ldi		R18,0xFF				;+000094F: EF2F		; 0xFF = 0b11111111	= 255
	Ldi		R19,0x00				;+0000950: E030		; 0x00 = 0b00000000	= 0
	Out		OCR1AH,R19				;+0000951: BD3B
	Out		OCR1AL,R18				;+0000952: BD2A
;	Ldi		R18,0xF3				;+0000953: EF23		; 0xF3 = 0b11110011	= 243
;	Ldi		R19,0x01				;+0000954: E031		; 0x01 = 0b00000001	= 1
	ldi		r18,low(PWM_TOP_32K)
	ldi		r19,high(PWM_TOP_32K)
	Out		ICR1H,R19				;+0000955: BD37
	Out		ICR1L,R18				;+0000956: BD26
	Sei								;+0000957: 9478
	Ret								;+0000958: 9508
commit_pwm8k:
	Clr		R19						;+0000959: 2733
	Add		R18,R18					;+000095A: 0F22
	Adc		R19,R19					;+000095B: 1F33
	Add		R18,R18					;+000095C: 0F22
	Adc		R19,R19					;+000095D: 1F33
	Add		R18,R18					;+000095E: 0F22
	Adc		R19,R19					;+000095F: 1F33
	Cli								;+0000960: 94F8
	Out		OCR1BH,R19				;+0000961: BD39
	Out		OCR1BL,R18				;+0000962: BD28
	Ldi		R18,0xFF				;+0000963: EF2F		; 0xFF = 0b11111111	= 255
	Ldi		R19,0x03				;+0000964: E033		; 0x03 = 0b00000011	= 3
	Out		OCR1AH,R19				;+0000965: BD3B
	Out		OCR1AL,R18				;+0000966: BD2A
;	Ldi		R18,0xCE				;+0000967: EC2E		; 0xCE = 0b11001110	= 206
;	Ldi		R19,0x07				;+0000968: E037		; 0x07 = 0b00000111	= 7
	ldi		r18,low(PWM_TOP_8K)
	ldi		r19,high(PWM_TOP_8K)
	Out		ICR1H,R19				;+0000969: BD37
	Out		ICR1L,R18				;+000096A: BD26
	Sei								;+000096B: 9478
	Ret								;+000096C: 9508
; 根据RCP计算启动功率.
calc_startup_pwm:
	sbrc	flag1,weak_power			;+000096D: FDB4
	ret								;+000096E: 9508
;	Sbrs	flag1,unknown_option_xh_0	;+000096F: FFB0
;	Rjmp	commit_pwm_by_setting					;+0000970: C029		; Destination: 0x00099A
	Cli								;+0000971: 94F8
	In		R16,OCR1BL				;+0000972: B508
	In		R17,OCR1BH				;+0000973: B519
	Sei								;+0000974: 9478
	Sts		0x009A,R16				;+0000975: 9300009A
	Sts		0x009B,R17				;+0000977: 9310009B
	Rcall	commit_pwm_by_setting					;+0000979: D020		; Destination: 0x00099A
	
	Cli								;+000097A: 94F8
	In		R18,OCR1BL				;+000097B: B528
	In		R19,OCR1BH				;+000097C: B539
	Sei								;+000097D: 9478
	Lds		R16,0x009A				;+000097E: 9100009A
	Lds		R17,0x009B				;+0000980: 9110009B
	Sub		R18,R16					;+0000982: 1B20
	Sbc		R19,R17					;+0000983: 0B31
	Brcs	AL230					;+0000984: F0A0		; Destination: 0x000999
	; RCP功率比启动功率大

; PWM_ACCELERATION
; 这里是修改限制功率加速度的程度。

; 如果RCP功率大于25%?
;	ldi		r16,64			;
;	cp		pwm_duty,r16
;	brcc	csp_1
;	ret						; .. no
;csp_1:						;yes

	Ldi		R18,-4					;+0000985: EF2C		; 0xFC = 0b11111100	= 252
;	ldi		r18,-10
	Lds		R19,0x010F				;+0000986: 9130010F
	Cpi		R19,0x03				;+0000988: 3033		; 0x03 = 0b00000011	= 3
	Breq	AL231					;+0000989: F021		; Destination: 0x00098E
	Ldi		R18,-8					;+000098A: EF28		; 0xF8 = 0b11111000	= 248
	Cpi		R19,0x02				;+000098B: 3032		; 0x02 = 0b00000010	= 2
	Breq	AL231					;+000098C: F009		; Destination: 0x00098E
	Ldi		R18,-10					;+000098D: EF20		; 0xF0 = 0b11110000	= 240
AL231:
	Sub		R16,R18					;+000098E: 1B02
	Sbci	R17,0xFF				;+000098F: 4F1F		; 0xFF = 0b11111111	= 255
	Cli								;+0000990: 94F8
	Out		OCR1BH,R17				;+0000991: BD19
	Out		OCR1BL,R16				;+0000992: BD08
	In		R18,OCR1BL				;+0000993: B528
	In		R19,OCR1BH				;+0000994: B539
	Sei								;+0000995: 9478
	Cp		R19,R17					;+0000996: 1731
	Brne	AL230					;+0000997: F409		; Destination: 0x000999
	Ret								;+0000998: 9508
AL230:
	; RCP功率比启动功率小
;	Andi	flag1,0xFE				;+0000999: 7FBE		; 0xFE = 0b11111110	= 254
	cbr		flag1,1<<unknown_option_xh_0
commit_pwm_by_setting:
	Mov		R18,pwm_duty					;+000099A: 2D2E
;	Lds		R16,0x0118				;+000099B: 91000118
;	Cpi		R16,0x01				;+000099D: 3001		; 0x01 = 0b00000001	= 1
;	Breq	AL232					;+000099E: F021		; Destination: 0x0009A3
;	Cpi		R16,0x02				;+000099F: 3002		; 0x02 = 0b00000010	= 2
;	Breq	AL233					;+00009A0: F0E1		; Destination: 0x0009BD
;	Cpi		R16,0x03				;+00009A1: 3003		; 0x03 = 0b00000011	= 3
;	Breq	AL234					;+00009A2: F071		; Destination: 0x0009B1
;	Rjmp	AL233
;AL232:
;	Sbrc	R18,7					;+00009A3: FD27
;	Rjmp	AL235					;+00009A4: C003		; Destination: 0x0009A8
;	Sbrc	R18,6					;+00009A5: FD26
;	Rjmp	AL236					;+00009A6: C005		; Destination: 0x0009AC
;	Rjmp	AL237					;+00009A7: C007		; Destination: 0x0009AF
;AL235:
;	Lsr		R18						;+00009A8: 9526
;	Ldi		R16,0x7F				;+00009A9: E70F		; 0x7F = 0b01111111	= 127
;	Add		R18,R16					;+00009AA: 0F20
;	Rjmp	AL233					;+00009AB: C011		; Destination: 0x0009BD
;AL236:
;	Ldi		R16,Sreg				;+00009AC: E30F		; Sreg = 0b00111111	= 63
;	Add		R18,R16					;+00009AD: 0F20
;	Rjmp	AL233					;+00009AE: C00E		; Destination: 0x0009BD
;AL237:
;	Add		R18,R18					;+00009AF: 0F22
;	Rjmp	AL233					;+00009B0: C00C		; Destination: 0x0009BD
;AL234:
;	Sbrs	R18,7					;+00009B1: FF27
;	Rjmp	AL238					;+00009B2: C009		; Destination: 0x0009BC
;	Sbrs	R18,6					;+00009B3: FF26
;	Rjmp	AL239					;+00009B4: C004		; Destination: 0x0009B9
;	Add		R18,R18					;+00009B5: 0F22
;	Ldi		R16,0xFF				;+00009B6: EF0F		; 0xFF = 0b11111111	= 255
;	Sbc		R18,R16					;+00009B7: 0B20
;	Rjmp	AL233					;+00009B8: C004		; Destination: 0x0009BD
;AL239:
;	Ldi		R16,Sreg				;+00009B9: E30F		; Sreg = 0b00111111	= 63
;	Sub		R18,R16					;+00009BA: 1B20
;	Rjmp	AL233					;+00009BB: C001		; Destination: 0x0009BD
;AL238:
;	Lsr		R18						;+00009BC: 9526
AL233:
	Lds		R16,mem_parameters+0x0F				;+00009BD: 9100010F
;	Cpi		R16,0x01				;+00009BF: 3001		; 0x01 = 0b00000001	= 1
;	Breq	AL240					;+00009C0: F029		; Destination: 0x0009C6
	Cpi		R16,0x02				;+00009C1: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL241					;+00009C2: F021		; Destination: 0x0009C7
	Cpi		R16,0x03				;+00009C3: 3003		; 0x03 = 0b00000011	= 3
	Breq	AL242					;+00009C4: F019		; Destination: 0x0009C8
;	Rjmp	AL243					;+00009C5: CF5D		; Destination: 0x000923
	rjmp	commit_pwm8k
;AL240:
;	Rjmp	AL243					;+00009C6: CF5C		; Destination: 0x000923
AL241:
	Rjmp	commit_pwm16k			;+00009C7: CF6F		; Destination: 0x000937
AL242:
	Rjmp	commit_pwm32k					;+00009C8: CF80		; Destination: 0x000949

sw_direct:
	Lds		R16,mem_parameters+25				;+00009CA: 91000119
	Cpi		R16,0x02				;+00009CC: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL246					;+00009CD: F131		; Destination: 0x0009F4

; 2 way about, 方向判别 Cbr
;	Cbr		flag1, 1<<direction

; direction: 0 run at reverse , 1 run at forward
	sbrc	flag1,direction
	rjmp	sw_direct_2
sw_direct_1:
	Ldi		R16,APL1				;+00009CE: E202		; 0x22 = 0b00100010	= 34
	Sts		mem_states,R16				;+00009CF: 93000080
	Ldi		R16,APL2				;+00009D1: E200		; 0x20 = 0b00100000	= 32
	Sts		mem_states+1,R16				;+00009D2: 93000081
	Ldi		R16,APL3				;+00009D4: E802		; 0x82 = 0b10000010	= 130
	Sts		mem_states+2,R16				;+00009D5: 93000082
	Ldi		R16,APL4				;+00009D7: E800		; 0x80 = 0b10000000	= 128
	Sts		mem_states+3,R16				;+00009D8: 93000083
	Ldi		R16,APL5				;+00009DA: E808		; 0x88 = 0b10001000	= 136
	Sts		mem_states+4,R16				;+00009DB: 93000084
	Ldi		R16,APL6				;+00009DD: E800		; 0x80 = 0b10000000	= 128
	Sts		mem_states+5,R16				;+00009DE: 93000085
	Ldi		R16,APL7				;+00009E0: E108		; 0x18 = 0b00011000	= 24
	Sts		mem_states+6,R16				;+00009E1: 93000086
	Ldi		R16,APL8				;+00009E3: E100		; 0x10 = 0b00010000	= 16
	Sts		mem_states+7,R16				;+00009E4: 93000087
	Ldi		R16,APL9				;+00009E6: E101		; 0x11 = 0b00010001	= 17
	Sts		mem_states+8,R16				;+00009E7: 93000088
	Ldi		R16,APLA				;+00009E9: E100		; 0x10 = 0b00010000	= 16
	Sts		mem_states+9,R16				;+00009EA: 93000089
	Ldi		R16,APLB				;+00009EC: E201		; 0x21 = 0b00100001	= 33
	Sts		mem_states+10,R16				;+00009ED: 9300008A
	Ldi		R16,APLC				;+00009EF: E200		; 0x20 = 0b00100000	= 32
	Sts		mem_states+11,R16				;+00009F0: 9300008B
	Ret								;+00009F2: 9508

AL246:

; 2 way about, 方向判别 Sbr
;	Sbr		flag2, 1<<direction
	sbrc	flag1,direction
	rjmp	sw_direct_1
sw_direct_2:
	Ldi		R16,APL3				;+00009F4: E802		; 0x82 = 0b10000010	= 130
	Sts		mem_states,R16				;+00009F5: 93000080
	Ldi		R16,APL4				;+00009F7: E800		; 0x80 = 0b10000000	= 128
	Sts		mem_states+1,R16				;+00009F8: 93000081
	Ldi		R16,APL1				;+00009FA: E202		; 0x22 = 0b00100010	= 34
	Sts		mem_states+2,R16				;+00009FB: 93000082
	Ldi		R16,APL2				;+00009FD: E200		; 0x20 = 0b00100000	= 32
	Sts		mem_states+3,R16				;+00009FE: 93000083
	Ldi		R16,APLB				;+0000A00: E201		; 0x21 = 0b00100001	= 33
	Sts		mem_states+4,R16				;+0000A01: 93000084
	Ldi		R16,APLC				;+0000A03: E200		; 0x20 = 0b00100000	= 32
	Sts		mem_states+5,R16				;+0000A04: 93000085
	Ldi		R16,APL9				;+0000A06: E101		; 0x11 = 0b00010001	= 17
	Sts		mem_states+6,R16				;+0000A07: 93000086
	Ldi		R16,APLA				;+0000A09: E100		; 0x10 = 0b00010000	= 16
	Sts		mem_states+7,R16				;+0000A0A: 93000087
	Ldi		R16,APL7				;+0000A0C: E108		; 0x18 = 0b00011000	= 24
	Sts		mem_states+8,R16				;+0000A0D: 93000088
	Ldi		R16,APL8				;+0000A0F: E100		; 0x10 = 0b00010000	= 16
	Sts		mem_states+9,R16				;+0000A10: 93000089
	Ldi		R16,APL5				;+0000A12: E808		; 0x88 = 0b10001000	= 136
	Sts		mem_states+10,R16				;+0000A13: 9300008A
	Ldi		R16,APL6				;+0000A15: E800		; 0x80 = 0b10000000	= 128
	Sts		mem_states+11,R16				;+0000A16: 9300008B
	Ret								;+0000A19: 9508

;all_fet_off:
;	Ldi		r16,0					;+0000A1A: E000		; 0x00 = 0b00000000	= 0
;	Mov		state_off,r16			;+0000A1B: 2E90
;	Mov		state_on,state_off		;+0000A1C: 2C89
;	Out		PORTD,r16				;+0000A1D: BB02
;	Ret								;+0000A1E: 9508
; useless ----------------------------------------------------------------------
;.if 1==2
;AL076:
;	Rcall	all_fet_off					;+0000A21: 940E0A1A
;	Andi	flag1,0xF7				;+0000A23: 7FB7		; 0xF7 = 0b11110111	= 247
;AL248:
;	Cli								;+0000A24: 94F8
;	Andi	flag1,0xF7				;+0000A25: 7FB7		; 0xF7 = 0b11110111	= 247
;	Rcall	AL247					;+0000A26: D065		; Destination: 0x000A8C
;AL250:
;	Cpi		R29,0x05				;+0000A27: 30D5		; 0x05 = 0b00000101	= 5
;	Brne	AL248					;+0000A28: F7D9		; Destination: 0x000A24
;	Cpi		R28,0x04				;+0000A29: 30C4		; 0x04 = 0b00000100	= 4
;	Breq	AL249					;+0000A2A: F081		; Destination: 0x000A3B
;	Cpi		R28,0x04				;+0000A2B: 30C4		; 0x04 = 0b00000100	= 4
;	Breq	AL249					;+0000A2C: F071		; Destination: 0x000A3B
;	Cpi		R28,0x04				;+0000A2D: 30C4		; 0x04 = 0b00000100	= 4
;	Breq	AL249					;+0000A2E: F061		; Destination: 0x000A3B
;	Cpi		R28,0x04				;+0000A2F: 30C4		; 0x04 = 0b00000100	= 4
;	Breq	AL249					;+0000A30: F051		; Destination: 0x000A3B
;	Rjmp	AL248					;+0000A31: CFF2		; Destination: 0x000A24
;AL254:
;	Rcall	AL247					;+0000A32: D059		; Destination: 0x000A8C
;	Cpi		R29,0x05				;+0000A33: 30D5		; 0x05 = 0b00000101	= 5
;	Breq	AL250					;+0000A34: F391		; Destination: 0x000A27
;	Cpi		R29,0x06				;+0000A35: 30D6		; 0x06 = 0b00000110	= 6
;	Breq	AL250					;+0000A36: F381		; Destination: 0x000A27
;	Cpi		R29,0x07				;+0000A37: 30D7		; 0x07 = 0b00000111	= 7
;	Breq	AL250					;+0000A38: F371		; Destination: 0x000A27
;	Cpi		R29,0x08				;+0000A39: 30D8		; 0x08 = 0b00001000	= 8
;	Breq	AL250					;+0000A3A: F361		; Destination: 0x000A27
;AL249:
;	Rjmp	AL251					;+0000A3B: C004		; Destination: 0x000A40
;AL255:
;	Rcall	AL252					;+0000A3C: 940E0600
;	Rcall	AL253					;+0000A3E: D016		; Destination: 0x000A55
;	Rjmp	AL254					;+0000A3F: CFF2		; Destination: 0x000A32
;AL251:
;	Cpi		R29,0x13				;+0000A40: 31D3		; 0x13 = 0b00010011	= 19
;	Brne	AL255					;+0000A41: F7D1		; Destination: 0x000A3C
;	Sbi		0x15,0					;+0000A42: 9AA8
;	Nop								;+0000A43: 0000
;	Nop								;+0000A44: 0000
;	Sbis	0x13,0					;+0000A45: 9B98
;	Rjmp	AL256					;+0000A46: C004		; Destination: 0x000A4B
;	Mov		R16,R28					;+0000A47: 2F0C
;	Subi	R16,0x04				;+0000A48: 5004		; 0x04 = 0b00000100	= 4
;	Brcs	AL255					;+0000A49: F390		; Destination: 0x000A3C
;	Rjmp	AL257					;+0000A4A: C003		; Destination: 0x000A4E
;AL256:
;	Mov		R16,R28					;+0000A4B: 2F0C
;	Subi	R16,0x04				;+0000A4C: 5004		; 0x04 = 0b00000100	= 4
;	Brcs	AL255					;+0000A4D: F370		; Destination: 0x000A3C
;AL257:
;	Rcall	AL253					;+0000A4E: D006		; Destination: 0x000A55
;	Sbrc	flag1,tcnt2h_ovf					;+0000A4F: FDB3
;	Rjmp	AL254					;+0000A50: CFE1		; Destination: 0x000A32
;	Rcall	AL258					;+0000A51: D027		; Destination: 0x000A79
;	Sbrs	flag1,tcnt2h_ovf					;+0000A52: FFB3
;	Rjmp	AL251					;+0000A53: CFEC		; Destination: 0x000A40
;	Rjmp	AL254					;+0000A54: CFDD		; Destination: 0x000A32
;AL253:
;	Andi	flag1,0xF7				;+0000A55: 7FB7		; 0xF7 = 0b11110111	= 247
;	Ldi		R17,0xFF				;+0000A56: EF1F		; 0xFF = 0b11111111	= 255
;AL261:
;	Ldi		R16,SoundOn				;+0000A57: E108		; 0x18 = 0b00011000	= 24
;	Out		PortD,R16				;+0000A58: BB02
;	Ldi		R16,0x01				;+0000A59: E001		; 0x01 = 0b00000001	= 1
;	Sts		0x009E,R16				;+0000A5A: 9300009E
;	Ldi		R16,0x78				;+0000A5C: E708		; 0x78 = 0b01111000	= 120
;	Sts		0x009F,R16				;+0000A5D: 9300009F
;	Rcall	KsTim					;+0000A5F: 940E06CE
;	Sbic	0x10,2					;+0000A61: 9982
;	Rjmp	AL259					;+0000A62: C012		; Destination: 0x000A75
;	Ldi		R18,0xFF				;+0000A63: EF2F		; 0xFF = 0b11111111	= 255
;AL260:
;	Ldi		R16,SoundOff			;+0000A64: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000A65: BB02
;	Ldi		R16,0x01				;+0000A66: E001		; 0x01 = 0b00000001	= 1
;	Sts		0x009E,R16				;+0000A67: 9300009E
;	Ldi		R16,0x0A				;+0000A69: E00A		; 0x0A = 0b00001010	= 10
;	Sts		0x009F,R16				;+0000A6A: 9300009F
;	Rcall	KsTim					;+0000A6C: 940E06CE
;	Sbic	0x10,2					;+0000A6E: 9982
;	Rjmp	AL259					;+0000A6F: C005		; Destination: 0x000A75
;	Dec		R18						;+0000A70: 952A
;	Brne	AL260					;+0000A71: F791		; Destination: 0x000A64
;	Dec		R17						;+0000A72: 951A
;	Brne	AL261					;+0000A73: F719		; Destination: 0x000A57
;	Ret								;+0000A74: 9508
;AL259:
;	Ldi		R16,SoundOff			;+0000A75: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000A76: BB02
;	Ori		flag1,0x08				;+0000A77: 60B8		; 0x08 = 0b00001000	= 8
;	Ret								;+0000A78: 9508
;AL258:
;	Ldi		R17,0xFF				;+0000A79: EF1F		; 0xFF = 0b11111111	= 255
;AL263:
;	Ldi		R18,0xFF				;+0000A7A: EF2F		; 0xFF = 0b11111111	= 255
;AL262:
;	Ldi		R16,SoundOff			;+0000A7B: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000A7C: BB02
;	Ldi		R16,0x01				;+0000A7D: E001		; 0x01 = 0b00000001	= 1
;	Sts		0x009E,R16				;+0000A7E: 9300009E
;	Ldi		R16,0x0A				;+0000A80: E00A		; 0x0A = 0b00001010	= 10
;	Sts		0x009F,R16				;+0000A81: 9300009F
;	Rcall	KsTim					;+0000A83: 940E06CE
;	Sbic	0x10,2					;+0000A85: 9982
;	Rjmp	AL259					;+0000A86: CFEE		; Destination: 0x000A75
;	Dec		R18						;+0000A87: 952A
;	Brne	AL262					;+0000A88: F791		; Destination: 0x000A7B
;	Dec		R17						;+0000A89: 951A
;	Brne	AL263					;+0000A8A: F779		; Destination: 0x000A7A
;	Ret								;+0000A8B: 9508

;AL247:
;	Sbrs	flag1,tcnt2h_ovf					;+0000A8C: FFB3
;	Rcall	AL264					;+0000A8D: D028		; Destination: 0x000AB6
;	Andi	flag1,0xF7				;+0000A8E: 7FB7		; 0xF7 = 0b11110111	= 247
;	Cbr		flag1,1<<tcnt2h_ovf
;	Rcall	AL265					;+0000A8F: D02B		; Destination: 0x000ABB
;	Ldi		R16,0x08				;+0000A90: E008		; 0x08 = 0b00001000	= 8
;	Sts		mem_temp_90,R16				;+0000A91: 93000090
;	Ldi		R16,0x00				;+0000A93: E000		; 0x00 = 0b00000000	= 0
;	Sts		mem_temp_91,R16				;+0000A94: 93000091
;AL267:
;	Rcall	AL266					;+0000A96: D02E		; Destination: 0x000AC5
;	Clc								;+0000A97: 9488
;	Sbic	0x10,2					;+0000A98: 9982
;	Sec								;+0000A99: 9408
;	Lds		R16,mem_temp_91				;+0000A9A: 91000091
;	Ror		R16						;+0000A9C: 9507
;	Sts		mem_temp_91,R16				;+0000A9D: 93000091
;	Sbi		PORTB,3					;+0000A9F: 9AC3
;	Lds		R16,mem_temp_90				;+0000AA0: 91000090
;	Dec		R16						;+0000AA2: 950A
;	Sts		mem_temp_90,R16				;+0000AA3: 93000090
;	Brne	AL267					;+0000AA5: F781		; Destination: 0x000A96
;	Rcall	AL266					;+0000AA6: D01E		; Destination: 0x000AC5
;	Rcall	AL266					;+0000AA7: D01D		; Destination: 0x000AC5
;	Sbic	0x10,2					;+0000AA8: 9982
;	Rjmp	AL247					;+0000AA9: CFE2		; Destination: 0x000A8C
;	Lds		R16,mem_temp_91				;+0000AAA: 91000091
;	Com		R16						;+0000AAC: 9500
;	Sbrc	R16,7					;+0000AAD: FD07
;	Mov		R29,R16					;+0000AAE: 2FD0
;	Sbrs	R16,7					;+0000AAF: FF07
;	Mov		R28,R16					;+0000AB0: 2FC0
;	Sbrc	R16,7					;+0000AB1: FD07
;	Rjmp	AL247					;+0000AB2: CFD9		; Destination: 0x000A8C
;	Andi	R29,0x7F				;+0000AB3: 77DF		; 0x7F = 0b01111111	= 127
;	Cbi		PORTB,3					;+0000AB4: 98C3
;	Ret								;+0000AB5: 9508
;
;AL264:
;	Sbic	0x10,2					;+0000AB6: 9982
;	Rjmp	AL264					;+0000AB7: CFFE		; Destination: 0x000AB6
;AL268:
;	Sbis	0x10,2					;+0000AB8: 9B82
;	Rjmp	AL268					;+0000AB9: CFFE		; Destination: 0x000AB8
;	Ret								;+0000ABA: 9508
;AL265:
;	Ldi		R16,0x04				;+0000ABB: E004		; 0x04 = 0b00000100	= 4
;	Ldi		R17,0x0D				;+0000ABC: E01D		; 0x0D = 0b00001101	= 13
;AL269:
;	Nop								;+0000ABD: 0000
;	Nop								;+0000ABE: 0000
;	Nop								;+0000ABF: 0000
;	Nop								;+0000AC0: 0000
;	Subi	R16,0x01				;+0000AC1: 5001		; 0x01 = 0b00000001	= 1
;	Sbci	R17,0x00				;+0000AC2: 4010		; 0x00 = 0b00000000	= 0
;	Brcc	AL269					;+0000AC3: F7C8		; Destination: 0x000ABD
;	Ret								;+0000AC4: 9508
;AL266:
;	In		R18,0x10				;+0000AC5: B320
;	Andi	R18,0x04				;+0000AC6: 7024		; 0x04 = 0b00000100	= 4
;	Ldi		R16,0x08				;+0000AC7: E008		; 0x08 = 0b00001000	= 8
;	Ldi		R17,0x1A				;+0000AC8: E11A		; 0x1A = 0b00011010	= 26
;AL270:
;	In		R19,0x10				;+0000AC9: B330
;	Andi	R19,0x04				;+0000ACA: 7034		; 0x04 = 0b00000100	= 4
;	Eor		R19,R18					;+0000ACB: 2732
;	Brne	AL265					;+0000ACC: F771		; Destination: 0x000ABB
;	Subi	R16,0x01				;+0000ACD: 5001		; 0x01 = 0b00000001	= 1
;	Sbci	R17,0x00				;+0000ACE: 4010		; 0x00 = 0b00000000	= 0
;	Brcc	AL270					;+0000ACF: F7C8		; Destination: 0x000AC9
;	Ret								;+0000AD0: 9508
;.endif
; useless end ------------------------------------------------------------------

sDDRX:
	Ldi		R16,0x3E				;+0000AD2: E30E		; 0x3E = 0b00111110	= 62
	Out		DDRB,R16				;+0000AD3: BB07
	Ldi		R16,0x00				;+0000AD4: E000		; 0x00 = 0b00000000	= 0
	Out		DDRC,R16				;+0000AD5: BB04
;	Ldi		R16,0xBB				;+0000AD6: EB0B		; 0xBB = 0b10111011	= 187
	ldi		r16,(1<<anFET)+(1<<apFET)+(1<<bnFET)+(1<<bpFET)+(1<<cnFET)+(1<<cpFET)
	Out		DDRD,r16				;+0000AD7: BB01
	Ret								;+0000AD8: 9508
; useless ----------------------------------------------------------------------
.if 1==2
AL054:
	Lds		R18,0x0111				;+0000ADA: 91200111
	Cpi		R18,0x02				;+0000ADC: 3022		; 0x02 = 0b00000010	= 2
	Breq	AL271					;+0000ADD: F009		; Destination: 0x000ADF
	Rjmp	AL272					;+0000ADE: C075		; Destination: 0x000B54
AL271:
	Mov		R18,R16					;+0000ADF: 2F20
	Mov		R19,R17					;+0000AE0: 2F31
	Ldi		R16,0x33				;+0000AE1: E303		; 0x33 = 0b00110011	= 51
	Ldi		R17,0x01				;+0000AE2: E011		; 0x01 = 0b00000001	= 1
	Rcall	AL273					;+0000AE3: D0C3		; Destination: 0x000BA7
	Lds		R29,0x0113				;+0000AE4: 91D00113
	Cpi		R29,0x01				;+0000AE6: 30D1		; 0x01 = 0b00000001	= 1
	Brne	AL274					;+0000AE7: F449		; Destination: 0x000AF1
	Ldi		R29,0x02				;+0000AE8: E0D2		; 0x02 = 0b00000010	= 2
	Sts		0x0113,R29				;+0000AE9: 93D00113
	Sub		R16,R18					;+0000AEB: 1B02
	Sbc		R17,R19					;+0000AEC: 0B13
	Brcc	AL274					;+0000AED: F418		; Destination: 0x000AF1
	Ldi		R29,0x03				;+0000AEE: E0D3		; 0x03 = 0b00000011	= 3
	Sts		0x0113,R29				;+0000AEF: 93D00113
AL274:
	Ldi		R16,0x2D				;+0000AF1: E20D		; 0x2D = 0b00101101	= 45
	Ldi		R17,0x01				;+0000AF2: E011		; 0x01 = 0b00000001	= 1
	Lds		R29,0x0113				;+0000AF3: 91D00113
	Cpi		R29,0x02				;+0000AF5: 30D2		; 0x02 = 0b00000010	= 2
	Breq	AL275					;+0000AF6: F061		; Destination: 0x000B03
	Ldi		R16,0xC6				;+0000AF7: EC06		; 0xC6 = 0b11000110	= 198
	Ldi		R17,0x01				;+0000AF8: E011		; 0x01 = 0b00000001	= 1
	Lds		R29,0x0113				;+0000AF9: 91D00113
	Cpi		R29,0x03				;+0000AFB: 30D3		; 0x03 = 0b00000011	= 3
	Breq	AL275					;+0000AFC: F031		; Destination: 0x000B03
	Mov		R16,R18					;+0000AFD: 2F02
	Mov		R17,R19					;+0000AFE: 2F13
	Rjmp	AL275					;+0000AFF: C003		; Destination: 0x000B03
;	Nop								;+0000B00: 0000
AL277:
	Rjmp	AL276					;+0000B01: C084		; Destination: 0x000B86
;	Nop								;+0000B02: 0000
AL275:
	Ldi		R18,0xF4				;+0000B03: EF24		; 0xF4 = 0b11110100	= 244
	Ldi		R19,0x3C				;+0000B04: E33C		; 0x3C = 0b00111100	= 60
	Lds		R29,0x0114				;+0000B05: 91D00114
	Cpi		R29,0x01				;+0000B07: 30D1		; 0x01 = 0b00000001	= 1
	Breq	AL277					;+0000B08: F3C1		; Destination: 0x000B01
	Ldi		R18,0x00				;+0000B09: E020		; 0x00 = 0b00000000	= 0
	Ldi		R19,0x40				;+0000B0A: E430		; 0x40 = 0b01000000	= 64
	Lds		R29,0x0114				;+0000B0B: 91D00114
	Cpi		R29,0x02				;+0000B0D: 30D2		; 0x02 = 0b00000010	= 2
	Breq	AL277					;+0000B0E: F391		; Destination: 0x000B01
	Ldi		R18,0x0C				;+0000B0F: E02C		; 0x0C = 0b00001100	= 12
	Ldi		R19,0x43				;+0000B10: E433		; 0x43 = 0b01000011	= 67
	Lds		R29,0x0114				;+0000B11: 91D00114
	Cpi		R29,0x03				;+0000B13: 30D3		; 0x03 = 0b00000011	= 3
	Breq	AL277					;+0000B14: F361		; Destination: 0x000B01
	Ldi		R18,0x18				;+0000B15: E128		; 0x18 = 0b00011000	= 24
	Ldi		R19,0x46				;+0000B16: E436		; 0x46 = 0b01000110	= 70
	Lds		R29,0x0114				;+0000B17: 91D00114
	Cpi		R29,0x04				;+0000B19: 30D4		; 0x04 = 0b00000100	= 4
	Breq	AL277					;+0000B1A: F331		; Destination: 0x000B01
	Ldi		R18,0x25				;+0000B1B: E225		; 0x25 = 0b00100101	= 37
	Ldi		R19,0x49				;+0000B1C: E439		; 0x49 = 0b01001001	= 73
	Lds		R29,0x0114				;+0000B1D: 91D00114
	Cpi		R29,0x05				;+0000B1F: 30D5		; 0x05 = 0b00000101	= 5
	Breq	AL277					;+0000B20: F301		; Destination: 0x000B01
	Ldi		R18,0x31				;+0000B21: E321		; 0x31 = 0b00110001	= 49
	Ldi		R19,0x4C				;+0000B22: E43C		; 0x4C = 0b01001100	= 76
	Lds		R29,0x0114				;+0000B23: 91D00114
	Cpi		R29,0x06				;+0000B25: 30D6		; 0x06 = 0b00000110	= 6
	Breq	AL278					;+0000B26: F161		; Destination: 0x000B53
	Ldi		R18,Sreg				;+0000B27: E32F		; Sreg = 0b00111111	= 63
	Ldi		R19,0x4F				;+0000B28: E43F		; 0x4F = 0b01001111	= 79
	Lds		R29,0x0114				;+0000B29: 91D00114
	Cpi		R29,0x07				;+0000B2B: 30D7		; 0x07 = 0b00000111	= 7
	Breq	AL278					;+0000B2C: F131		; Destination: 0x000B53
	Ldi		R18,0x49				;+0000B2D: E429		; 0x49 = 0b01001001	= 73
	Ldi		R19,0x52				;+0000B2E: E532		; 0x52 = 0b01010010	= 82
	Lds		R29,0x0114				;+0000B2F: 91D00114
	Cpi		R29,0x08				;+0000B31: 30D8		; 0x08 = 0b00001000	= 8
	Breq	AL278					;+0000B32: F101		; Destination: 0x000B53
	Ldi		R18,0x54				;+0000B33: E524		; 0x54 = 0b01010100	= 84
	Ldi		R19,0x55				;+0000B34: E535		; 0x55 = 0b01010101	= 85
	Lds		R29,0x0114				;+0000B35: 91D00114
	Cpi		R29,0x09				;+0000B37: 30D9		; 0x09 = 0b00001001	= 9
	Breq	AL278					;+0000B38: F0D1		; Destination: 0x000B53
	Ldi		R18,0x62				;+0000B39: E622		; 0x62 = 0b01100010	= 98
	Ldi		R19,0x58				;+0000B3A: E538		; 0x58 = 0b01011000	= 88
	Lds		R29,0x0114				;+0000B3B: 91D00114
	Cpi		R29,0x0A				;+0000B3D: 30DA		; 0x0A = 0b00001010	= 10
	Breq	AL278					;+0000B3E: F0A1		; Destination: 0x000B53
	Ldi		R18,0x6D				;+0000B3F: E62D		; 0x6D = 0b01101101	= 109
	Ldi		R19,0x5B				;+0000B40: E53B		; 0x5B = 0b01011011	= 91
	Lds		R29,0x0114				;+0000B41: 91D00114
	Cpi		R29,0x0B				;+0000B43: 30DB		; 0x0B = 0b00001011	= 11
	Breq	AL278					;+0000B44: F071		; Destination: 0x000B53
	Ldi		R18,0x7A				;+0000B45: E72A		; 0x7A = 0b01111010	= 122
	Ldi		R19,0x5E				;+0000B46: E53E		; 0x5E = 0b01011110	= 94
	Lds		R29,0x0114				;+0000B47: 91D00114
	Cpi		R29,0x0C				;+0000B49: 30DC		; 0x0C = 0b00001100	= 12
	Breq	AL278					;+0000B4A: F041		; Destination: 0x000B53
	Ldi		R18,0x88				;+0000B4B: E828		; 0x88 = 0b10001000	= 136
	Ldi		R19,0x61				;+0000B4C: E631		; 0x61 = 0b01100001	= 97
	Lds		R29,0x0114				;+0000B4D: 91D00114
	Cpi		R29,0x0D				;+0000B4F: 30DD		; 0x0D = 0b00001101	= 13
	Breq	AL278					;+0000B50: F011		; Destination: 0x000B53
	Ldi		R18,0x6D				;+0000B51: E62D		; 0x6D = 0b01101101	= 109
	Ldi		R19,0x5B				;+0000B52: E53B		; 0x5B = 0b01011011	= 91
AL278:
	Rjmp	AL276					;+0000B53: C032		; Destination: 0x000B86
AL272:
	Ldi		R18,0x66				;+0000B54: E626		; 0x66 = 0b01100110	= 102
	Ldi		R19,0x06				;+0000B55: E036		; 0x06 = 0b00000110	= 6
	Lds		R29,0x0112				;+0000B56: 91D00112
	Cpi		R29,0x01				;+0000B58: 30D1		; 0x01 = 0b00000001	= 1
	Breq	AL276					;+0000B59: F161		; Destination: 0x000B86
	Ldi		R18,0x92				;+0000B5A: E922		; 0x92 = 0b10010010	= 146
	Ldi		R19,0x24				;+0000B5B: E234		; 0x24 = 0b00100100	= 36
	Lds		R29,0x0112				;+0000B5C: 91D00112
	Cpi		R29,0x02				;+0000B5E: 30D2		; 0x02 = 0b00000010	= 2
	Breq	AL276					;+0000B5F: F131		; Destination: 0x000B86
	Ldi		R18,0xB6				;+0000B60: EB26		; 0xB6 = 0b10110110	= 182
	Ldi		R19,0x2D				;+0000B61: E23D		; 0x2D = 0b00101101	= 45
	Lds		R29,0x0112				;+0000B62: 91D00112
	Cpi		R29,0x03				;+0000B64: 30D3		; 0x03 = 0b00000011	= 3
	Breq	AL276					;+0000B65: F101		; Destination: 0x000B86
	Ldi		R18,0xDB				;+0000B66: ED2B		; 0xDB = 0b11011011	= 219
	Ldi		R19,0x36				;+0000B67: E336		; 0x36 = 0b00110110	= 54
	Lds		R29,0x0112				;+0000B68: 91D00112
	Cpi		R29,0x04				;+0000B6A: 30D4		; 0x04 = 0b00000100	= 4
	Breq	AL276					;+0000B6B: F0D1		; Destination: 0x000B86
	Ldi		R18,0x00				;+0000B6C: E020		; 0x00 = 0b00000000	= 0
	Ldi		R19,0x40				;+0000B6D: E430		; 0x40 = 0b01000000	= 64
	Lds		R29,0x0112				;+0000B6E: 91D00112
	Cpi		R29,0x05				;+0000B70: 30D5		; 0x05 = 0b00000101	= 5
	Breq	AL276					;+0000B71: F0A1		; Destination: 0x000B86
	Ldi		R18,0x24				;+0000B72: E224		; 0x24 = 0b00100100	= 36
	Ldi		R19,0x49				;+0000B73: E439		; 0x49 = 0b01001001	= 73
	Lds		R29,0x0112				;+0000B74: 91D00112
	Cpi		R29,0x06				;+0000B76: 30D6		; 0x06 = 0b00000110	= 6
	Breq	AL276					;+0000B77: F071		; Destination: 0x000B86
	Ldi		R18,0x49				;+0000B78: E429		; 0x49 = 0b01001001	= 73
	Ldi		R19,0x52				;+0000B79: E532		; 0x52 = 0b01010010	= 82
	Lds		R29,0x0112				;+0000B7A: 91D00112
	Cpi		R29,0x07				;+0000B7C: 30D7		; 0x07 = 0b00000111	= 7
	Breq	AL276					;+0000B7D: F041		; Destination: 0x000B86
	Ldi		R18,0x6D				;+0000B7E: E62D		; 0x6D = 0b01101101	= 109
	Ldi		R19,0x5B				;+0000B7F: E53B		; 0x5B = 0b01011011	= 91
	Lds		R29,0x0112				;+0000B80: 91D00112
	Cpi		R29,0x08				;+0000B82: 30D8		; 0x08 = 0b00001000	= 8
	Breq	AL276					;+0000B83: F011		; Destination: 0x000B86
	Ldi		R18,0xDB				;+0000B84: ED2B		; 0xDB = 0b11011011	= 219
	Ldi		R19,0x36				;+0000B85: E336		; 0x36 = 0b00110110	= 54
AL276:
	Rcall	AL273					;+0000B86: D020		; Destination: 0x000BA7
	Push	R31
	Push	R30
	Rcall	AL190					;+0000B87: D003		; Destination: 0x000B8B
	Movw	R16,R18					;+0000B88: 2F02
	Pop		R30
	Pop		R31
	Ret								;+0000B8A: 9508
.endif
; useless end ------------------------------------------------------------------

AL190:
	Sts		mem_r0_temp,R0				;+0000B8B: 920000B8
	Sts		mem_r1_temp,R1				;+0000B8D: 921000B9
	Sts		mem_r2_temp,R2				;+0000B8F: 922000BA
	Clr		R2						;+0000B91: 2422
	FMUL	R19,R17					;+0000B92: 0339
	Movw	r26,R0					;+0000B93: 01C0
	FMUL	R18,R16					;+0000B94: 0328
	Movw	R30,R0					;+0000B95: 01F0
	FMUL	R19,R16					;+0000B96: 0338
	Add		R31,R0					;+0000B97: 0DF0
	Adc		r26,R1					;+0000B98: 1D81
	Adc		r27,R2					;+0000B99: 1D92
	FMUL	R17,R18					;+0000B9A: 031A
	Add		R31,R0					;+0000B9B: 0DF0
	Adc		r26,R1					;+0000B9C: 1D81
	Adc		r27,R2					;+0000B9D: 1D92
	Mov		R18,r26					;+0000B9E: 2F28
	Mov		R19,r27					;+0000B9F: 2F39
	Lds		R0,mem_r0_temp			;+0000BA0: 900000B8
	Lds		R1,mem_r1_temp				;+0000BA2: 901000B9
	Lds		R2,mem_r2_temp				;+0000BA4: 902000BA
	Ret								;+0000BA6: 9508

AL273:
	Sts		0x00C2,R18				;+0000BA7: 932000C2
	Sts		0x00C3,R19				;+0000BA9: 933000C3
	Sts		0x00C0,R16				;+0000BAB: 930000C0
	Sts		0x00C1,R17				;+0000BAD: 931000C1
	Rcall	AL279					;+0000BAF: D020		; Destination: 0x000BD0
	Lds		R16,0x00C4				;+0000BB0: 910000C4
	Lds		R17,0x00C5				;+0000BB2: 911000C5
	Subi	R16,0xF6				;+0000BB4: 5F06		; 0xF6 = 0b11110110	= 246
	Sbci	R17,0x01				;+0000BB5: 4011		; 0x01 = 0b00000001	= 1
	Brcc	AL280					;+0000BB6: F420		; Destination: 0x000BBB
	Com		R16						;+0000BB7: 9500
	Com		R17						;+0000BB8: 9510
	Subi	R16,0xFF				;+0000BB9: 5F0F		; 0xFF = 0b11111111	= 255
	Sbci	R17,0xFF				;+0000BBA: 4F1F		; 0xFF = 0b11111111	= 255
AL280:
;	Push	R31
;	Push	R30
	Ldi		R18,0x83				;+0000BBB: E823		; 0x83 = 0b10000011	= 131
	Ldi		R19,0x00				;+0000BBC: E030		; 0x00 = 0b00000000	= 0
	Rcall	AL190					;+0000BBD: DFCD		; Destination: 0x000B8B
	Lsr		r26						;+0000BBE: 9586
	Ror		R31						;+0000BBF: 95F7
	Ror		R30						;+0000BC0: 95E7
	Movw	R18,R30					;+0000BC1: 2F2E
	Lds		R16,0x00C0				;+0000BC3: 910000C0
	Lds		R17,0x00C1				;+0000BC5: 911000C1
	Rcall	AL190					;+0000BC7: DFC3		; Destination: 0x000B8B
	Movw	R16,R18					;+0000BC8: 2F02
	Lds		R18,0x00C2				;+0000BCA: 912000C2
	Lds		R19,0x00C3				;+0000BCC: 913000C3
;	Pop		R30
;	Pop		R31
	Ret								;+0000BCE: 9508

AL279:
	Ldi		R16,0x62				;+0000BD0: E602		; 0x62 = 0b01100010	= 98
	Sts		mem_eep_addr,R16				;+0000BD1: 93000070
	Rcall	eep_read					;+0000BD3: 940E05F0
	Sts		0x00C4,R16				;+0000BD5: 930000C4
	Ldi		R16,0x63				;+0000BD7: E603		; 0x63 = 0b01100011	= 99
	Sts		mem_eep_addr,R16				;+0000BD8: 93000070
	Rcall	eep_read					;+0000BDA: 940E05F0
	Sts		0x00C5,R16				;+0000BDC: 930000C5
	Mov		R17,R16					;+0000BDE: 2F10
	Lds		R16,0x00C4				;+0000BDF: 910000C4
	Subi	R16,0x88				;+0000BE1: 5808		; 0x88 = 0b10001000	= 136
	Subi	R17,0x13				;+0000BE2: 5113		; 0x13 = 0b00010011	= 19
	Brcs	AL281					;+0000BE3: F030		; Destination: 0x000BEA
	Ldi		R16,0x09				;+0000BE4: E009		; 0x09 = 0b00001001	= 9
	Ldi		R17,0x01				;+0000BE5: E011		; 0x01 = 0b00000001	= 1
	Sts		0x00C4,R16				;+0000BE6: 930000C4
	Sts		0x00C5,R17				;+0000BE8: 931000C5
AL281:
	Nop								;+0000BEA: 0000
	Ret								;+0000BEB: 9508
.if 1==2
load_brake_param:
	Ldi		R17,0x8C				;+0000BEE: E81C		; 0x8C = 0b10001100	= 140
	Lds		R16,mem_parameters+9				;+0000BEF: 91000109
	Cpi		R16,0x01				;+0000BF1: 3001		; 0x01 = 0b00000001	= 1
	Breq	AL282					;+0000BF2: F0D1		; Destination: 0x000C0D
	Ldi		R17,10				;+0000BF3: EF1E		; 0xFE = 0b11111110	= 254
;	Lds		R16,mem_parameters+9				;+0000BF4: 91000109
	Cpi		R16,0x02				;+0000BF6: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL282					;+0000BF7: F0A9		; Destination: 0x000C0D
	Ldi		R17,20				;+0000BF8: EB14		; 0xB4 = 0b10110100	= 180
;	Lds		R16,mem_parameters+9				;+0000BF9: 91000109
	Cpi		R16,0x03				;+0000BFB: 3003		; 0x03 = 0b00000011	= 3
	Breq	AL282					;+0000BFC: F081		; Destination: 0x000C0D
	Ldi		R17,30				;+0000BFD: E81C		; 0x8C = 0b10001100	= 140
;	Lds		R16,mem_parameters+9				;+0000BFE: 91000109
	Cpi		R16,0x04				;+0000C00: 3004		; 0x04 = 0b00000100	= 4
	Breq	AL282					;+0000C01: F059		; Destination: 0x000C0D
	Ldi		R17,40				;+0000C02: E614		; 0x64 = 0b01100100	= 100
;	Lds		R16,mem_parameters+9				;+0000C03: 91000109
	Cpi		R16,0x05				;+0000C05: 3005		; 0x05 = 0b00000101	= 5
	Breq	AL282					;+0000C06: F031		; Destination: 0x000C0D
	Ldi		R17,50				;+0000C07: E416		; 0x46 = 0b01000110	= 70
;	Lds		R16,mem_parameters+9				;+0000C08: 91000109
	Cpi		R16,0x06				;+0000C0A: 3006		; 0x06 = 0b00000110	= 6
	Breq	AL282					;+0000C0B: F009		; Destination: 0x000C0D
	Ldi		R17,30				;+0000C0C: E81C		; 0x8C = 0b10001100	= 140
AL282:
	Sts		mem_brake_param,R17				;+0000C0F: 931000B7
	Ret								;+0000C11: 9508
.endif
;	Nop								;+0000C12: 0000
;	Nop								;+0000C13: 0000

; useless ----------------------------------------------------------------------
.if 1==2
AL022:
	Lds		R16,0x0121				;+0000C35: 91000121
	Cpi		R16,0x02				;+0000C37: 3002		; 0x02 = 0b00000010	= 2
	Breq	AL285					;+0000C38: F1D9		; Destination: 0x000C74
	Ldi		R16,0x00				;+0000C39: E000		; 0x00 = 0b00000000	= 0
	Mov		pwm_duty,R16					;+0000C3A: 2EE0
;	Andi	flag1,0x7F				;+0000C3B: 77BF		; 0x7F = 0b01111111	= 127
	Cbr		flag1,1<<no_idle
	Ldi		R16,0xFF				;+0000C3C: EF0F		; 0xFF = 0b11111111	= 255
	Sts		mem_temp_91,R16				;+0000C3D: 93000091
AL286:
	Sbrs	flag1,RCP_updated			;+0000C3F: FFB6
	Rjmp	AL286					;+0000C40: CFFE		; Destination: 0x000C3F
	Rcall	evaluate_rcp					;+0000C41: 940E017F
	Sbrc	flag1,no_idle					;+0000C43: FDB7
	Rjmp	AL285					;+0000C44: C02F		; Destination: 0x000C74
	Lds		R16,mem_temp_91				;+0000C45: 91000091
	Dec		R16						;+0000C47: 950A
	Sts		mem_temp_91,R16				;+0000C48: 93000091
	Brne	AL286					;+0000C4A: F7A1		; Destination: 0x000C3F
	Ldi		R16,0x05				;+0000C4B: E005		; 0x05 = 0b00000101	= 5
	Sts		mem_temp_91,R16				;+0000C4C: 93000091
AL292:
	Rcall	evaluate_rcp					;+0000C4E: 940E017F
	Sbrc	flag1,no_idle					;+0000C50: FDB7
	Rjmp	AL285					;+0000C51: C022		; Destination: 0x000C74
	Lds		R16,mem_parameters+0xe				;+0000C52: 9100010E
	Subi	R16,0x09				;+0000C54: 5009		; 0x09 = 0b00001001	= 9
	Brcs	AL287					;+0000C55: F060		; Destination: 0x000C62
	Lds		R16,mem_parameters+0xe				;+0000C56: 9100010E
	Subi	R16,0x14				;+0000C58: 5104		; 0x14 = 0b00010100	= 20
	Brcs	AL288					;+0000C59: F058		; Destination: 0x000C65
	Lds		R16,mem_parameters+0xe				;+0000C5A: 9100010E
	Subi	R16,0x1A				;+0000C5C: 510A		; 0x1A = 0b00011010	= 26
	Brcs	AL289					;+0000C5D: F050		; Destination: 0x000C68
	Lds		R16,mem_parameters+0xe				;+0000C5E: 9100010E
	Subi	R16,0xC8				;+0000C60: 5C08		; 0xC8 = 0b11001000	= 200
	Brcs	AL290					;+0000C61: F048		; Destination: 0x000C6B
AL287:
	Rcall	AL094					;+0000C62: 940E06DB
	Rjmp	AL291					;+0000C64: C009		; Destination: 0x000C6E
AL288:
	Rcall	AL095					;+0000C65: 940E06DE
	Rjmp	AL291					;+0000C67: C006		; Destination: 0x000C6E
AL289:
	Rcall	AL096					;+0000C68: 940E06EA
	Rjmp	AL291					;+0000C6A: C003		; Destination: 0x000C6E
AL290:
	;XALL	 0x001FFF				 ;+0000C6B:	940EFFFF
	Rjmp	Reset
	Nop
	Rjmp	AL291					;+0000C6D: C000		; Destination: 0x000C6E
AL291:
	Lds		R16,mem_temp_91				;+0000C6E: 91000091
	Dec		R16						;+0000C70: 950A
	Sts		mem_temp_91,R16				;+0000C71: 93000091
	Brne	AL292					;+0000C73: F6D1		; Destination: 0x000C4E
AL285:
	Ret								;+0000C74: 9508

;AL013:
;;	In		R17,DDRB				;+0000C7A: B317
;;	Ldi		R16,0x0E				;+0000C7B: E00E		; 0x0E = 0b00001110	= 14
;;	Out		DDRB,R16				;+0000C7C: BB07
;; UART
;;	Cbi		PORTB,3					;+0000C7D: 98C3
;;	Sbi		PORTB,4					;+0000C7E: 9AC4
;;	Rcall	usart_func					;+0000C7F: D07B		; Destination: 0x000CFB
;;	In		R16,PINB				;+0000C80: B306
;;	Out		DDRB,R17				;+0000C81: BB17
;
;;	 SBRS	 R16,4					 ;+0000C82:	FF04
;;	 RJMP	 AL294					 ;+0000C83:	C00E	 ; Destination:	0x000C92
;	rjmp	AL285
;; shit thing. disable.
;
;	Ldi		R16,0xFF				;+0000C84: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		mem_eep_addr,R16				;+0000C85: 93000070
;	Rcall	AL295					;+0000C87: D068		; Destination: 0x000CF0
;	Mov		R17,R16					;+0000C88: 2F10
;	Subi	R17,0xF0				;+0000C89: 5F10		; 0xF0 = 0b11110000	= 240
;
;	brcs	AL285
;	Subi	R16,0x01				;+0000C8B: 5001		; 0x01 = 0b00000001	= 1
;	Sts		mem_eep_data,R16				;+0000C8C: 93000071
;	Ldi		R16,0xFF				;+0000C8E: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		mem_eep_addr,R16				;+0000C8F: 93000070
;	Rcall	AL297					;+0000C91: D04E		; Destination: 0x000CE0
;AL294:
;	Ldi		R19,0x0C				;+0000C92: E03C		; 0x0C = 0b00001100	= 12
;AL298:
;	Ldi		R16,0xFF				;+0000C93: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		0x009E,R16				;+0000C94: 9300009E
;	Ldi		R16,0xFF				;+0000C96: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		0x009F,R16				;+0000C97: 9300009F
;	Rcall	KsTim					;+0000C99: 940E06CE
;	Dec		R19						;+0000C9B: 953A
;	Brne	AL298					;+0000C9C: F7B1		; Destination: 0x000C93
;	Ldi		flag1,0x09				;+0000C9D: E0B9		; 0x09 = 0b00001001	= 9
;	Ldi		flag2,0x03				;+0000C9E: E0A3		; 0x03 = 0b00000011	= 3
;	Rcall	AL299					;+0000C9F: D021		; Destination: 0x000CC1
;	Ldi		R17,0x08				;+0000CA0: E018		; 0x08 = 0b00001000	= 8
;AL303:
;	Ldi		R16,SoundOff			;+0000CA1: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000CA2: BB02
;	Rcall	AL300					;+0000CA3: D02A		; Destination: 0x000CCE
;	Add		flag1,flag1					;+0000CA4: 0FBB
;	Brcc	AL301					;+0000CA5: F410		; Destination: 0x000CA8
;	Ldi		R16,SoundOn				;+0000CA6: E108		; 0x18 = 0b00011000	= 24
;	Out		PortD,R16				;+0000CA7: BB02
;AL301:
;	Rcall	AL302					;+0000CA8: D02E		; Destination: 0x000CD7
;	Dec		R17						;+0000CA9: 951A
;	Brne	AL303					;+0000CAA: F7B1		; Destination: 0x000CA1
;	Ldi		R17,0x08				;+0000CAB: E018		; 0x08 = 0b00001000	= 8
;AL305:
;	Ldi		R16,SoundOff			;+0000CAC: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000CAD: BB02
;	Rcall	AL300					;+0000CAE: D01F		; Destination: 0x000CCE
;	Add		flag2,flag2					;+0000CAF: 0FAA
;	Brcc	AL304					;+0000CB0: F410		; Destination: 0x000CB3
;	Ldi		R16,SoundOn				;+0000CB1: E108		; 0x18 = 0b00011000	= 24
;	Out		PortD,R16				;+0000CB2: BB02
;AL304:
;	Rcall	AL302					;+0000CB3: D023		; Destination: 0x000CD7
;	Dec		R17						;+0000CB4: 951A
;	Brne	AL305					;+0000CB5: F7B1		; Destination: 0x000CAC
;	Ldi		R16,SoundOff			;+0000CB6: E000		; 0x00 = 0b00000000	= 0
;	Out		PortD,R16				;+0000CB7: BB02
;	Ldi		R16,0x64				;+0000CB8: E604		; 0x64 = 0b01100100	= 100
;	Sts		0x009E,R16				;+0000CB9: 9300009E
;	Ldi		R16,0xFF				;+0000CBB: EF0F		; 0xFF = 0b11111111	= 255
;	Sts		0x009F,R16				;+0000CBC: 9300009F
;	Rcall	KsTim					;+0000CBE: 940E06CE
;	Ret								;+0000CC0: 9508
AL299:
	Ldi		R16,SoundOn				;+0000CC1: E108		; 0x18 = 0b00011000	= 24
	Out		PortD,R16				;+0000CC2: BB02
	Rcall	AL302					;+0000CC3: D013		; Destination: 0x000CD7
	Ldi		R17,0x04				;+0000CC4: E014		; 0x04 = 0b00000100	= 4
AL306:
	Ldi		R16,SoundOff			;+0000CC5: E000		; 0x00 = 0b00000000	= 0
	Out		PortD,R16				;+0000CC6: BB02
	Rcall	AL300					;+0000CC7: D006		; Destination: 0x000CCE
	Dec		R17						;+0000CC8: 951A
	Brne	AL306					;+0000CC9: F7D9		; Destination: 0x000CC5
	Ldi		R16,SoundOn				;+0000CCA: E108		; 0x18 = 0b00011000	= 24
	Out		PortD,R16				;+0000CCB: BB02
	Rcall	AL302					;+0000CCC: D00A		; Destination: 0x000CD7
	Ret								;+0000CCD: 9508

AL300:
	Ldi		R16,0x0B				;+0000CCE: E00B		; 0x0B = 0b00001011	= 11
	Sts		0x009E,R16				;+0000CCF: 9300009E
	Ldi		R16,0x36				;+0000CD1: E306		; 0x36 = 0b00110110	= 54
	Sts		0x009F,R16				;+0000CD2: 9300009F
	Rcall	KsTim					;+0000CD4: 940E06CE
	Ret								;+0000CD6: 9508

AL302:
	Ldi		R16,0x01				;+0000CD7: E001		; 0x01 = 0b00000001	= 1
	Sts		0x009E,R16				;+0000CD8: 9300009E
	Ldi		R16,0x67				;+0000CDA: E607		; 0x67 = 0b01100111	= 103
	Sts		0x009F,R16				;+0000CDB: 9300009F
	Rcall	KsTim					;+0000CDD: 940E06CE
	Ret								;+0000CDF: 9508

AL297:
	Sbic	EECR,1					;+0000CE0: 99E1
	Rjmp	AL297					;+0000CE1: CFFE		; Destination: 0x000CE0
	Lds		R16,mem_eep_addr				;+0000CE2: 91000070
	Out		EEARL,R16				;+0000CE4: BB0E
	Clr		R16						;+0000CE5: 2700
	Out		0x1F,R16				;+0000CE6: BB0F
	Lds		R16,mem_eep_data				;+0000CE7: 91000071
	Out		EEDR,R16				;+0000CE9: BB0D
	Rcall	usart_func					;+0000CEA: D010		; Destination: 0x000CFB
	Sbi		EECR,2					;+0000CEB: 9AE2
	Nop								;+0000CEC: 0000
	Sbi		EECR,1					;+0000CED: 9AE1
	Rcall	usart_func					;+0000CEE: D00C		; Destination: 0x000CFB
	Ret								;+0000CEF: 9508

AL295:
	Sbic	EECR,1					;+0000CF0: 99E1
	Rjmp	AL295					;+0000CF1: CFFE		; Destination: 0x000CF0
	Lds		R16,mem_eep_addr				;+0000CF2: 91000070
	Out		EEARL,R16				;+0000CF4: BB0E
	Clr		R16						;+0000CF5: 2700
	Out		0x1F,R16				;+0000CF6: BB0F
	Sbi		EECR,0					;+0000CF7: 9AE0
	Rcall	usart_func					;+0000CF8: D002		; Destination: 0x000CFB
	In		R16,EEDR				;+0000CF9: B30D
	Ret								;+0000CFA: 9508

usart_func:
;	Nop								;+0000CFB: 0000
;	Nop								;+0000CFC: 0000
;	Nop								;+0000CFD: 0000
;	Nop								;+0000CFE: 0000
;	Nop								;+0000CFF: 0000
;	Nop								;+0000D00: 0000
;	Nop								;+0000D01: 0000
;	Nop								;+0000D02: 0000
;	Nop								;+0000D03: 0000
;	Nop								;+0000D04: 0000
;	Nop								;+0000D05: 0000
;	Nop								;+0000D06: 0000
	Ret								;+0000D07: 9508
.endif
; useless end ------------------------------------------------------------------

; Near Jump	total: 562
; Far Jump total: 69
; Jump total: 631
; AutoLabel	total: 307
; Shit Happen  139973 Times

; Fuck about that ONLY XALL,What the HELL??
; useless ------------------------------------------------------------
.if 1==2
;NewGame_Master:
;
;;1，高杆以后声音有*	** *** （旧的HIBBEP）每个3次 连续循环
;;取消中杆位置。
;;*，电池为LIPO AUTO
;;**，电池为NIMH	AUTO
;;***，刹车 读EEP位置，有的就改无，无的就改有 刹车用最大
;;到低杆位置就写入，并复位
;
;; 定位数据,放位置
;	Clr		R17
;	Clr		R19
;Command_Circle:
;; 提示声5次
;	Ldi		R18,2
;Next_Command:
;; 返回R19, 1=低杆, 3= 高杆
;;取消中杆位置
;	Ldi		R16,80				; 40*20	= 800ms	= 0.8秒为一个完整输入
;Next_Command_rcp_Loop:
;	Sbrs	flag1, RCP_updated
;	Rjmp	Next_Command_rcp_Loop
;	Cbr		flag1, 1<<RCP_updated
;	Sbrc	flag1, RCP_Hpos
;	Rjmp	NC_High_Position
;;NC_Low_Position:
;	Cpi		R19,1
;	Brne	NC_LowP_init
;	Dec		R16
;	Brne	Next_Command_rcp_Loop
;	Rjmp	NCAccept_Command
;NC_LowP_init:
;	Ldi		R19,1
;	Rjmp	Next_Command
;NC_High_Position:
;	Cpi		R19,3
;	Brne	NC_HighP_init
;	Dec		R16
;	Brne	Next_Command_rcp_Loop
;	Rjmp	NCAccept_Command
;NC_HighP_init:
;	Ldi		R19,3
;	Rjmp	Next_Command
;
;NCAccept_Command:
;	Cpi		R19,1
;	Breq	Option_Select
;	Cpi		R19,3
;	Breq	Option_Hold
;	Rjmp	Command_Circle
;Option_Hold:
;	Rcall	Sound_Show_Location_X
;	Dec		R18
;	Brne	Next_Command
;	Inc		R17
;
;; 严重警告!!! menu
;; 任何菜单项加减必须修改下面的R17比较值为Option数目
;	Cpi		R17,4		; 总共4项菜单, LiPo, NiMh, 刹车, 出厂
;
;	Brlo	Option_Circle
;	Clr		R17
;Option_Circle:
;	Rjmp	Command_Circle
;
;Option_Select:
;	Cpi		R17,0
;	Breq	Option_Cells_Lipo
;	Cpi		R17,1
;	Breq	Option_Cells_Nimh
;	Cpi		R17,2
;	Breq	Option_Break
;	Cpi		R17,3
;	Breq	Option_ResetEEP
;
;	Rjmp	Command_Circle
;Option_Break:
;	Ldi		R16,9		; Break	address
;	Sts		mem_eep_addr,R16
;	Rcall	eep_read		; read Break address
;	Ldi		R19,6
;	Cpi		R16,6
;	Brne	OdBreak_Set
;	Clr		R19
;OdBreak_Set:
;	Mov		R16,R19
;	Ldi		R17,9		; Break	address
;	Rcall	Access_EEprom_Mode2
;	Rjmp	Access_Option_Data
;Option_Cells_Lipo:
;	Ldi		R17,17
;	Ldi		R16,2		; Lipo电池,
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,19
;	Ldi		R16,1		; Lipo cells, 好象lipo数1就会是lipo自动?
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,20		; Lipo 电压	address
;	Ldi		R16,11		; 3.00V
;	Rcall	Access_EEprom_Mode2
;	Rjmp	Access_Option_Data
;Option_Cells_Nimh:
;	Ldi		R17,17
;	Ldi		R16,1		; 普通电池,
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,18		; 普通 Cells address
;	Ldi		R16,6		; 普通 Cells 电压0.8V 写死.
;	Rcall	Access_EEprom_Mode2
;;	ldi		R17,19
;;	ldi		R16,0xFF		; Lipo cells,
;;	RCALL	Access_EEprom_Mode2
;;	ldi		R17,20		; Lipo 电压	address
;;	ldi		R16,0xFF	; 废了Lipo电压
;;	rcall	Access_EEprom_Mode2
;	Rjmp	Access_Option_Data
;Option_ResetEEP:
;; Master没有PWM
;;03	05 14 16 21	22 23 24 25	33
;;01	04 01 03 02	01 01 02 02	01
;
;	Ldi		R17,3
;	Ldi		R16,1
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,5
;	Ldi		R16,4
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,14
;	Ldi		R16,1
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,16
;	Ldi		R16,3
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,21
;	Ldi		R16,2
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,22
;	Ldi		R16,1
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,23
;	Ldi		R16,1
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,24
;	Ldi		R16,3
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,25
;	Ldi		R16,2
;	Rcall	Access_EEprom_Mode2
;	Ldi		R17,33
;	Ldi		R16,1
;	Rcall	Access_EEprom_Mode2
;
;Access_Option_Data:
;	Rcall	old_High_sound
;	Rcall	old_High_sound
;	Rcall	old_High_sound
;	Rcall	old_High_sound
;	Rcall	loc_213_C_LongDelay
;	Cli
;	Rjmp	reset
;	Ret
;
;
;;R17地址
;;R16数据
;Access_EEprom_Mode2:
;	Sbic	EECR,1
;	Rjmp	Access_EEprom_Mode2
;	Out		EEARL,R17
;	Clr		R17
;	Out		EEARH,R17
;	Out		EEDR,R16
;	Rcall	loc_201_C_4nop
;	Sbi		EECR,2
;	Nop
;	Sbi		EECR,1
;	Rcall	loc_201_C_4nop
;	Ret
;
;Sound_Show_Location_X:
;;警告,修改菜单必须修改menu相关
;;根据R17的数据放歌,以确定当前位置.
;; R17 =	IIIIIIII
;;		I= option Index
;;			D=option Data
;
;	Push	R16
;	Mov		R16,R17
;	Inc		R16
;; Option_index_Sound
;SSL_OIS:
;	Rcall	Beep_H
;	Dec		R16
;	Brne	SSL_OIS
;Exit_SSL:
;	Pop		R16
;	Ret
;
;Ultra_Beep:
;	Push	R16
;	Push	R17
;; Ultra_Beep here
;	Ldi		R17,100
;UB_1:
;	Ldi		R16,SoundOn	  ;	0x28 = 0b00101000 =	40
;	Out		PortD,R16
;	Ldi		R16,											1
;	Sts		0x009E,R16
;	Ldi		R16,											150
;	Sts		0x009F,R16
;	Rcall	loc_002_C_delay		; 0x0006D0
;	Ldi		R16,SoundOff   ; 0x00 =	0b00000000 = 0
;	Out		PortD,R16
;	Ldi		R16,											40
;	Sts		0x009E,R16
;	Ldi		R16,0xFF   ; 0xFF =	0b11111111 = 255
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Dec		R17
;	Brne	UB_1		; -0x16
;	Ldi		R17,											70
;UB_2:
;	Ldi		R16,SoundOn	  ;	0x28 = 0b00101000 =	40
;	Out		PortD,R16
;	Ldi		R16,											1
;	Sts		0x009E,R16
;	Ldi		R16,											150
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Ldi		R16,SoundOff   ; 0x00 =	0b00000000 = 0
;	Out		PortD,R16
;	Ldi		R16,											32
;	Sts		0x009E,R16
;	Ldi		R16,0xFF   ; 0xFF =	0b11111111 = 255
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Dec		R17
;	Brne	UB_2		; -0x16
;
;	Ldi		R17,180
;UB_3:
;	Ldi		R16,SoundOn	  ;	0x28 = 0b00101000 =	40
;	Out		PortD,R16
;	Ldi		R16,											1
;	Sts		0x009E,R16
;	Ldi		R16,											150
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Ldi		R16,SoundOff   ; 0x00 =	0b00000000 = 0
;	Out		PortD,R16
;	Ldi		R16,											24
;	Sts		0x009E,R16
;	Ldi		R16,											255
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Dec		R17
;	Brne	UB_3		; -0x16
;	Rcall	loc_800_Longdelay
;	Pop		R17
;	Pop		R16
;	Ret
;
;Beep_H:
;	Push	R16
;	Push	R17
;;	rcall	loc_215_C_Beep2
;; high
;	Ldi		R17,										255
;UB1_2:
;	Ldi		R16,SoundOn	  ;	0x28 = 0b00101000 =	40
;	Out		PortD,R16
;	Ldi		R16,										2
;	Sts		0x009E,R16
;	Ldi		R16,										2
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Ldi		R16,SoundOff   ; 0x00 =	0b00000000 = 0
;	Out		PortD,R16
;	Ldi		R16,										20
;	Sts		0x009E,R16
;	Ldi		R16,										180
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Dec		R17
;	Brne	UB1_2		; -0x16
;	Rcall	loc_801_Longdelay
;	Pop		R17
;	Pop		R16
;	Ret
;
;Beep_H_New:
;	Push	R16
;	Push	R17
;;	rcall	loc_215_C_Beep2
;; high
;	Ldi		R17,										255
;UB9_9:
;	Ldi		R16,SoundOn	  ;	0x28 = 0b00101000 =	40
;	Out		PortD,R16
;	Ldi		R16,										2
;	Sts		0x009E,R16
;	Ldi		R16,										1
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Ldi		R16,SoundOff   ; 0x00 =	0b00000000 = 0
;	Out		PortD,R16
;	Ldi		R16,										20
;	Sts		0x009E,R16
;	Ldi		R16,										180
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay		; 0x0006D0
;	Dec		R17
;	Brne	UB9_9		; -0x16
;;	 rcall	loc_801_Longdelay
;	Pop		R17
;	Pop		R16
;	Ret
;
;Beep_L:
;	Push	R16
;	Push	R17
;loc_187_Beep_Low:
;	Ldi		R17,0xFF
;loc_188:
;	Ldi		R16,SoundOn
;	Out		PortD,R16
;	Ldi		R16,							2
;	Sts		0x009E,R16
;	Ldi		R16,							32
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay
;	Ldi		R16,SoundOff
;	Out		PortD,R16
;	Ldi		R16,							60
;	Sts		0x009E,R16
;	Ldi		R16,							0
;	Sts		0x009F,R16
;	Rcall	 loc_002_C_delay
;	Dec		R17
;	Brne	loc_188
;	Rcall	loc_800_Longdelay
;	Pop		R17
;	Pop		R16
;	Ret
;
;old_High_sound:
;	Ldi		R17,0xFF		;+000007E5:	EF1F			;	0xFF = 0b11111111 =	255
;loc_216_I:
;	Ldi		R16,SoundOn		;+000007E6:	EB00			;	0xB0 = 0b10110000 =	176
;	Out		PortD,R16		;+000007E7:	BB02
;	Ldi		R16,0x01		;+000007E8:	E001			;	0x01 = 0b00000001 =	1
;	Sts		0x009E,R16		;+000007E9:	9300009E
;	Ldi		R16,0x78		;+000007EB:	E708			;	0x78 = 0b01111000 =	120
;	Sts		0x009F,R16		;+000007EC:	9300009F
;	Rcall	loc_002_C_delay							;0x0006ED							;+000007EE:	940E06ED
;	Ldi		R16,SoundOff	;+000007F0:	E301			;	0x31 = 0b00110001 =	49
;	Out		PortD,R16		;+000007F1:	BB02
;	Ldi		R16,0x14		;+000007F2:	E104			;	0x14 = 0b00010100 =	20
;	Sts		0x009E,R16		;+000007F3:	9300009E
;	Ldi		R16,0xFF		;+000007F5:	EF0F			;	0xFF = 0b11111111 =	255
;	Sts		0x009F,R16		;+000007F6:	9300009F
;	Rcall	loc_002_C_delay							;0x0006ED							;+000007F8:	940E06ED
;	Dec		R17				;+000007FA:	951A
;	Brne	loc_216_I								;-0x16		;+000007FB:	F751		;Destination: 0x0007E6
;	Ret						;+000007FC:	9508
;
;loc_800_Longdelay:
;	Push	R19
;	Ldi		R19,10
;l800ld:
;	Ldi		R16,0
;	Sts		0x009E,R16
;	Sts		0x009F,R16
;	Rcall	loc_002_C_delay
;	Dec		R19
;	Brne	l800ld
;	Pop		R19
;	Ret
;
;loc_801_Longdelay:
;	Push	R19
;	Ldi		R19,2
;l800ld1:
;	Ldi		R16,0
;	Sts		0x009E,R16
;	Sts		0x009F,R16
;	Rcall	loc_002_C_delay
;	Dec		R19
;	Brne	l800ld1
;	Pop		R19
;	Ret
;
;
;loc_002_C_delay:
;	Lds		R16,0x009F		;+000006ED:	9100009F
;loc_211_I:
;	Dec		R16				;+000006EF:	950A
;	Brne	loc_211_I								;-0x02		;+000006F0:	F7F1		;Destination: 0x0006EF
;	Sts		0x009F,R16		;+000006F1:	9300009F
;	Lds		R16,0x009E		;+000006F3:	9100009E
;	Dec		R16				;+000006F5:	950A
;	Sts		0x009E,R16		;+000006F6:	9300009E
;	Brne	loc_002_C_delay							;-0x0C		;+000006F8:	F7A1		;Destination: 0x0006ED
;	Ret						;+000006F9:	9508
;
;loc_103_C_Write_EEP:
;	Sbic	EECR,1			;+000005FF:	99E1
;	Rjmp	loc_103_C_Write_EEP						;-0x0002	;+00000600:	CFFE		;Destination: 0x0005FF
;	Lds		R16,mem_eep_addr		;+00000601:	91000070
;	Out		EEARL,R16		;+00000603:	BB0E
;	Clr		R16				;+00000604:	2700
;	Out		EEARH,R16		;+00000605:	BB0F
;	Lds		R16,mem_eep_data		;+00000606:	91000071
;	Out		EEDR,R16		;+00000608:	BB0D
;	Rcall	loc_201_C_4nop							;+0x0010	;+00000609:	D010		;Destination: 0x00061A
;	Sbi		EECR,2			;+0000060A:	9AE2
;	Nop						;+0000060B:	0000
;	Sbi		EECR,1			;+0000060C:	9AE1
;	Rcall	loc_201_C_4nop							;+0x000C	;+0000060D:	D00C		;Destination: 0x00061A
;	Ret						;+0000060E:	9508
;
;loc_213_C_LongDelay:
;	Ldi		R16,0x64		;+0000079A:	E604			;	0x64 = 0b01100100 =	100
;	Sts		mem_temp_90,R16		;+0000079B:	93000090
;loc_214_I:
;	Ldi		R16,0xFF		;+0000079D:	EF0F			;	0xFF = 0b11111111 =	255
;	Sts		0x009E,R16		;+0000079E:	9300009E
;	Ldi		R16,0xFF		;+000007A0:	EF0F			;	0xFF = 0b11111111 =	255
;	Sts		0x009F,R16		;+000007A1:	9300009F
;	Rcall	loc_002_C_delay							;0x0006ED							;+000007A3:	940E06ED
;	Lds		R16,mem_temp_90		;+000007A5:	91000090
;	Dec		R16				;+000007A7:	950A
;	Sts		mem_temp_90,R16		;+000007A8:	93000090
;	Brne	loc_214_I								;-0x0E		;+000007AA:	F791		;Destination: 0x00079D
;	Ret						;+000007AB:	9508
;
;loc_201_C_4nop:
;	Nop						;+0000061A:	0000
;	Nop						;+0000061B:	0000
;	Nop						;+0000061C:	0000
;	Nop						;+0000061D:	0000
;	Ret						;+0000061E:	9508
.endif
; useless end --------------------------------------------------------

; 2 way about: Make_It_Two_Way

Make_It_Two_Way:

	lds		R18, mem_neutral_rcp
	lds		R19, mem_neutral_rcp+1
	Cp		rcp_l, R18
	Cpc		rcp_h, R19
	Brcs	rcp_low_pos
; 高杆
;	set
	movw	r16,rcp_l
	Sub		R16, R18
	Sbc		R17, R19
	Movw	r26, R16

	Sbiw	r26, RCP_IDLE_ZONE
	Brcs	mitw_idle_exit

	motor_dir r26
;	cpi		r26,BRAKE
;	breq	mitw_idle_exit
;	breq	mitw_exit
	cpi		r26,REVERSE
	breq	mitw_brake_exit
	motor_forward
	
	movw	r26,rcp_top_l
	sub		r26,r18
	sbc		r27,r19
	movw	r0,r26
	Rjmp	convert_rcp_to_pwm
mitw_brake_exit:
;	rcall	output_off
;	rcall	brake_delay
	motor_brake
;	ldi		r18,205
;	mov		pwm_duty,r18
	rjmp	mitw_exit
rcp_low_pos:
; 低杆
;	clt
	Movw	r26, R18
	Sub		r26, rcp_l
	Sbc		r27, rcp_h
	Movw	R16, r26

	Sbiw	r26, RCP_IDLE_ZONE
	Brcs	mitw_idle_exit
	lds		r27,mem_reverse_pwm_factor
	sbrc	r27,7			; no reverse, only brake
	rjmp	mitw_brake_exit
	
	motor_dir r26
	cpi		r26,BRAKE
	breq	mitw_exit
	cpi		r26,FORWARD
	breq	mitw_brake_exit
	motor_reverse

	sub		r18,rcp_bottom_l
	sbc		r19,rcp_bottom_h
	inc		r27
rlp_1:
	dec		r27
	breq	rlp_2
	lsr		r17
	ror		r16
	rjmp	rlp_1
rlp_2:
	movw	r0,r18
	Rjmp	convert_rcp_to_pwm
mitw_idle_exit:
;debug ----------------------
;	cpi		r26,FORWARD
;	brne	debug_loc_1
;	rjmp	break_point1
;debug_loc_1:
;debug end ------------------
	motor_idle
mitw_exit:
	Clr		r27
	Ret
;brake_delay:
;	ret
;	ldi		r17,10
;bdelay_0:
;	ldi		r16,255
;bdelay_1:
;	dec		r16
;	brne	bdelay_1
;	dec		r17
;	brne	bdelay_0
;	ret

convert_rcp_to_pwm:
;	Ldi		r26, low(700)
;	Ldi		r27, high(700)
;	Movw	R0, r26
;	Ldi		r26, Wast_Time_2Way
;	Sts		0x00FD, r26

	cp		r16,r0
	cpc		r17,r1
	brcc	rcp_c_pwm_1
	Clr		r27						;+00001D3: 2799
	Ldi		r26, 0xFF				;+00001D4: EF8F		; 0xFF = 0b11111111	= 255
	Rjmp	AL071					;+00001DC: C005		; Destination: 0x0001E2
AL073:
	Lsr		r26						;+00001DD: 9586
	And		r26, r26				;+00001DE: 2388
	Breq	AL072					;+00001DF: F059		; Destination: 0x0001EB
	Lsr		R1						;+00001E0: 9406
	Ror		R0						;+00001E1: 9417
AL071:
	Movw	R18, R16				;+00001E2: 2F20
	Sub		R18, R0					;+00001E4: 1921
	Sbc		R19, R1					;+00001E5: 0930
	Brcs	AL073					;+00001E6: F3B0		; Destination: 0x0001DD
	Movw	R16, R18				;+00001E7: 2F02
	Add		r27, r26				;+00001E9: 0F98
	Rjmp	AL073					;+00001EA: CFF2		; Destination: 0x0001DD
rcp_c_pwm_1:
	ldi		r27,0xff
AL072:
	Ret								;+00001EB: 9508

; r16 the number of beep
; r16 0 unselected
;     1 selected
;     2 neutral position to exit menu
.equ	UNSELECTED		= 0
.equ	SELECTED		= 1
.equ	NEUTRAL_EXIT	= 2
option_lvl1:
	lds		r16,mem_temp1
	cli
option_lvl_loop:
	push	r16
	rcall	beep_a
	rcall	short_delay
	pop		r16
	dec		r16
	brne	option_lvl_loop
	sei
	ldi		r16,150
	ldi		r17,150
	ldi		r26,150
ol1_1:
	rcp_ready
	
	ldi		r18,low(RCP_NEUTRAL_AREA_H)
	ldi		r19,high(RCP_NEUTRAL_AREA_H)
	cp		rcp_l,r18
	cpc		rcp_h,r19
	brcc	ol1_2
	ldi		r18,low(RCP_NEUTRAL_AREA_L)
	ldi		r19,high(RCP_NEUTRAL_AREA_L)
	cp		rcp_l,r18
	cpc		rcp_h,r19
	brcs	ol1_3
	; neutral position
	dec		r17
	brne	ol1_1
	ldi		r16,NEUTRAL_EXIT
	rjmp	option_lvl1_exit
ol1_2:
	; high position
	dec		r26
	brne	ol1_1
	ldi		r16,SELECTED
	rjmp	option_lvl1_exit
ol1_3:
	; low position
	dec		r16
	brne	ol1_1
	ldi		r16,UNSELECTED
option_lvl1_exit:
	ret
option_lvl2:
	lds		r16,mem_temp1
	cli
option_lvl2_loop:	
	push	r16
	rcall	beep_b
	rcall	short_delay
	pop		r16
	dec		r16
	brne	option_lvl2_loop
	sei
	ldi		r16,150
	ldi		r17,150
	ldi		r26,150
ol2_1:
	rcp_ready
	ldi		r18,low(RCP_NEUTRAL_AREA_H)
	ldi		r19,high(RCP_NEUTRAL_AREA_H)
	cp		rcp_l,r18
	cpc		rcp_h,r19
	brcc	ol2_3
	ldi		r18,low(RCP_NEUTRAL_AREA_L)
	ldi		r19,high(RCP_NEUTRAL_AREA_L)
	cp		rcp_l,r18
	cpc		rcp_h,r19
	brcc	ol2_2
	;low
	dec		r26
	brne	ol2_1
	ldi		r16,SELECTED
	rjmp	ol2_exit
ol2_2:
	;neutral
	dec		r17
	brne	ol2_1
	ldi		r16,NEUTRAL_EXIT
	rjmp	ol2_exit
ol2_3:
	;high
	dec		r16
	brne	ol2_1
	ldi		r16,UNSELECTED
ol2_exit:
	ret
root_menu:
	ldi		zl,low(menu_item_count*2)
	ldi		zh,high(menu_item_count*2)
	lpm		r16,Z
	sts		mem_temp2,r16
	ldi		r16,0
	sts		mem_temp1,r16
root_menu1:
	lds		r16,mem_temp1
	inc		r16
	sts		mem_temp1,r16
	rcall	option_lvl1
	cpi		r16,NEUTRAL_EXIT
	breq	menu_exit
	cpi		r16,UNSELECTED
	breq	root_menu2
	lds		r16,mem_temp1
	sts		mem_temp_90,r16
	rjmp	child_menu
root_menu2:
	lds		r16,mem_temp2
	dec		r16
	sts		mem_temp2,r16
	brne	root_menu1
	rjmp	root_menu
menu_exit:
	ret
child_menu:
	lds		r16,mem_temp_90
	clr		r0
	ldi		zl,low(menu_item_count*2)
	ldi		zh,high(menu_item_count*2)
	add		zl,r16
	adc		zh,r0
	lpm		r16,Z

	sts		mem_temp2,r16
	clr		r16
	sts		mem_temp1,r16
child_menu1:
	lds		r16,mem_temp1
	inc		r16
	sts		mem_temp1,r16
	rcall	option_lvl2
	cpi		r16,NEUTRAL_EXIT
	breq	menu_exit
	cpi		r16,UNSELECTED
	breq	child_menu2
;do setting function here
	ldi		zl,low(menu_func)
	ldi		zh,high(menu_func)
	lds		r16,mem_temp_90
	dec		r16
	add		zl,r16
	adc		zh,r0
	icall
	rjmp	confirm_beep
child_menu2:
	lds		r16,mem_temp2
	dec		r16
	sts		mem_temp2,r16
	brne	child_menu1
	rjmp	child_menu

confirm_beep:
	cli
	rcall	beep_c
	rcall	beep_c
	rcall	beep_c
	sei
	rjmp	root_menu

;----------------------------------------------------------------------------
;--------------------------- menu options -----------------------------------
;----------------------------------------------------------------------------

menu_item_count:
.db	5,4,2,3,4,5
; mem_temp1 子菜单的选择项
menu_func:
	rjmp	setting_reverse
	rjmp	setting_ccv
	rjmp	setting_acc
	rjmp	setting_voltage_protected
	rjmp	setting_timing_advance


; mem_temp1 子菜单的选择项
; 倒车 NONE/25%/50%/100%
setting_reverse:
	lds		r16,mem_temp1
	cli
	sts		mem_eep_data,r16
	sts		mem_parameters+8,r16
	ldi		r16,8
	sts		mem_eep_addr,r16
	rcall	eep_write
	sei
load_reverse:
	lds		r16,mem_parameters+8
	ldi		r17,-2
	cpi		r16,1
	breq	set_rev_exit
	ldi		r17,2
	cpi		r16,2
	breq	set_rev_exit
	ldi		r17,1
	cpi		r16,3
	breq	set_rev_exit
	ldi		r17,0
	cpi		r16,4
	breq	set_rev_exit
	ldi		r17,1
set_rev_exit:
	sts		mem_reverse_pwm_factor,r17
	ret
setting_ccv:
	lds		r16,mem_temp1
	cli
	sts		mem_eep_data,r16
	sts		mem_parameters+25,r16
	ldi		r16,25
	sts		mem_eep_addr,r16
	rcall	eep_write
	ret
; ACC 轻 1/2/3 重
setting_acc:
	lds		r16,mem_temp1
	cli
	sts		mem_eep_data,r16
	sts		mem_parameters+16,r16
	ldi		r16,16
	sts		mem_eep_addr,r16
	rcall	eep_write
	sei
	
	ret
; 保护电压 5.5v/6v/9v/12v
setting_voltage_protected:
	lds		r16,mem_temp1
	cli
	sts		mem_eep_data,r16
	sts		mem_parameters+21,r16
	ldi		r16,21
	sts		mem_eep_addr,r16
	rcall	eep_write
	sei
load_volt_protect:
	lds		r16,mem_parameters+21
	ldi		r18,low(V55)
	ldi		r19,high(V55)
	cpi		r16,1
	breq	lvp_exit
	ldi		r18,low(V60)
	ldi		r19,high(V60)
	cpi		r16,2
	breq	lvp_exit
	ldi		r18,low(V90)
	ldi		r19,high(V90)
	cpi		r16,3
	breq	lvp_exit
	ldi		r18,low(V120)
	ldi		r19,high(V120)
	cpi		r16,4
	breq	lvp_exit
	ldi		r18,low(V60)
	ldi		r19,high(V60)
lvp_exit:
	sts		mem_volt_protect,r18
	sts		mem_volt_protect+1,r19
	ret
; 提前角 1/7/15/22/30
setting_timing_advance:
	lds		r16,mem_parameters+0xe
	ldi		r18,2
	cpi		r16,1
	breq	sta_exit
	ldi		r18,8
	cpi		r16,2
	breq	sta_exit
	ldi		r18,16
	cpi		r16,3
	breq	sta_exit
	ldi		r18,23
	cpi		r16,4
	breq	sta_exit
	ldi		r18,31
	cpi		r16,5
	breq	sta_exit
	ldi		r18,1
sta_exit:
	cli
	sts		mem_eep_data,r18
	sts		mem_parameters+0x0e,r18
	ldi		r16,0x0e
	sts		mem_eep_addr,r16
	rcall	eep_write
	sei
load_timing_adv:
	Ldi		R16,0x20				;+0000C14: E200		; 0x20 = 0b00100000	= 32
	Ldi		R17,0x35				;+0000C15: E315		; 0x35 = 0b00110101	= 53
	Ldi		R18,0x00				;+0000C16: E020		; 0x00 = 0b00000000	= 0
	Ldi		R19,0x60				;+0000C17: E630		; 0x60 = 0b01100000	= 96
	Lds		R29,mem_parameters+0xe				;+0000C18: 91D0010E
	Cpi		R29,0x00				;+0000C1A: 30D0		; 0x00 = 0b00000000	= 0
	Breq	AL283					;+0000C1B: F099		; Destination: 0x000C2F
	Subi	R29,0x28				;+0000C1C: 52D8		; 0x28 = 0b00101000	= 40
	Brcc	AL283					;+0000C1D: F488		; Destination: 0x000C2F
	Lds		R29,mem_parameters+0xe				;+0000C1E: 91D0010E
AL284:
	Subi	R16,0x89				;+0000C20: 5809		; 0x89 = 0b10001001	= 137
	Sbci	R17,0xFE				;+0000C21: 4F1E		; 0xFE = 0b11111110	= 254
	Subi	R18,0xE1				;+0000C22: 5E21		; 0xE1 = 0b11100001	= 225
	Sbci	R19,0x02				;+0000C23: 4032		; 0x02 = 0b00000010	= 2
	Dec		R29						;+0000C24: 95DA
	Brne	AL284					;+0000C25: F7D1		; Destination: 0x000C20
	Sts		mem_unknown_bb+1,R16				;+0000C26: 930000BC
	Sts		mem_unknown_bb,R17				;+0000C28: 931000BB
	Sts		mem_unknown_bd+1,R18				;+0000C2A: 932000BE
	Sts		mem_unknown_bd,R19				;+0000C2C: 933000BD
	Ret								;+0000C2E: 9508
AL283:
	Ldi		R29,0x01				;+0000C2F: E0D1		; 0x01 = 0b00000001	= 1
	Sts		mem_parameters+0xe,R29				;+0000C30: 93D0010E
	Rjmp	AL284					;+0000C32: CFED		; Destination: 0x000C20

boot_checking:
	lds		r16,mem_mcucsr
	
	and		r16,r16
	breq	boot_soft
	sbrc	r16,PORF		; power-on reset
	ret
	sbrc	r16,BORF		; brown-out reset
	rjmp	brown_out
	sbrc	r16,WDRF
	rjmp	watch_dog
	ret						; never reach here
brown_out:
	rcall	beep_a
	rcall	beep_b
	ret
boot_soft:
	rcall	beep_a
	rjmp	infinity
watch_dog:
	rcall	beep_a
	rcall	beep_b
	rcall	beep_c
	rjmp	infinity
.def	r_temp1	= r16
.def	r_temp2 = r17
.def	r_temp3 = r18
.def	r_temp4 = r19
.include "../brushless/sound.inc"
; program finish.......
.EXIT
