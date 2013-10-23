
; 6 p1.7 fan1
; 7 fan_out
; 8 p1.5 fan2
; 9 fan2_out
; 10 p1.3 press sense 1
; 11 p1.2 press sense 2
; 12 light 照明
; 13 l2 杀菌
; 14 报警
$NOPAGING
$NOTABS



$include(c8051f336.inc)
;
;	Register/Memory Equates
;
rb0r0	equ	0
rb0r1	equ	1
rb0r2	equ	2
rb0r3	equ	3
rb0r4	equ	4
rb0r5	equ	5
rb0r6	equ	6
rb0r7	equ	7
rb1r0	equ	8
rb1r1	equ	9
rb1r2	equ	0ah
rb1r3	equ	0bh
rb1r4	equ	0ch
rb1r5	equ	0dh
rb1r6	equ	0eh
rb1r7	equ	0fh
rb2r0	equ	10h
rb2r1	equ	11h
rb2r2	equ	12h
rb2r3	equ	13h
rb2r4	equ	14h
rb2r6	equ	16h
rb2r7	equ	17h
rb3r0	equ	18h
rb3r1	equ	19h
rb3r2	equ	1ah
rb3r3	equ	1bh
rb3r4	equ	1ch
rb3r5	equ	1dh
rb3r6	equ	1eh
rb3r7	equ	1fh



OPEN_DIALOG		equ 9
CLOSE_DIALOG	equ 21


green_led	bit p1.3
red_led		bit	p1.4


temp1		equ	30h
temp2		equ	31h
temp3		equ	32h


; 0 idle
; 1 command start
; 2 command id	(include 0x78-press 0x79-release)
; 3 cc
; 4	data1
; 5	data2
; 6 33
; 7 c3
; 8 3c
buf_first		equ	33h
buf_last		equ	34h
buf_empty		bit	20h.0


xl			equ	35h
xh			equ	36h
yl			equ	37h
yh			equ	38h

hour		equ	39h
minute		equ	3ah
second		equ	3bh
; 2 byte
day			equ	3ch		;3dh
tick		equ	3eh

send_cmd_idx	equ	3fh
; 当second有更新，标志设1，然后计算一次minute和hour
clock_tick	bit	20h.1
show_sys_clock bit 20h.3



recv_cmd_idx	equ 40h
recv_cmd		equ 41h
recv_cmd_ready	bit	20h.2



PIPO_TOP		equ 0d0h
PIPO_BUTTON		equ	0c0h



LED_MDIN	equ	P1MDIN
LED_MDOUT	equ	P1MDOUT


	cseg	at 0
;
	ljmp	start
org 0bh
	push	acc
	sjmp	t0overflow_int
org 23h
	ljmp	uart0_int
org 7bh
t0overflow_int:
	inc		tick
	mov		a,tick
	cjne	a,#8,t0ovf_exit
	mov		tick,#0
	setb	clock_tick
	inc		second
t0ovf_exit:
	pop		acc
	reti



start:
	clr		ea
	mov		sp,#0cfh
	mov		psw,#0


;	mov		cmd_stage,#0	;idle
	
;clr		debug_stop	

	lcall	init
	lcall	init_timer_01
	lcall	init_led
	lcall	init_uart_02
	lcall	init_final
	clr		red_led
	lcall	long_long_delay
	clr		green_led
	clr		a
	mov		day,a
	mov		day+1,a
	mov		hour,a
	mov		second,a
	mov		minute,a
	mov		tick,a
	
	mov		recv_cmd_idx,a
	setb	show_sys_clock
	

	

;	lcall	long_delay
;	lcall	tft_cls

;	mov		xh,#0
;	mov		yh,#high(300h)
;	mov		xl,#10
;	mov		yl,#low(300h)
;	mov		dptr,#string
;	lcall	puts32
;	lcall	long_delay

	
	
	lcall	long_delay

;	lcall	read_uart
	mov		a,#PIPO_BUTTON
	mov		buf_first,a
	mov		buf_last,a
	
	lcall	long_long_delay
	lcall	long_long_delay
; set background color
;	mov		r0,#0
;	mov		r1,#4
;	mov		r2,#40h
;	lcall	send_cmd
	mov		a,#0aah
	lcall	send_uart
	mov		a,#42h
	lcall	send_uart
	mov		a,#0
	lcall	send_uart
	mov		a,#10
	lcall	send_uart
	mov		a,#0
	lcall	send_uart
	mov		a,#10
	lcall	send_uart
	
	mov		a,#0cch
	lcall	send_uart
	mov		a,#33h
	lcall	send_uart
	mov		a,#0c3h
	lcall	send_uart
	mov		a,#3ch
	lcall	send_uart
	


	setb	ea
;	mov		xl,#40
;	mov		xh,#0
;	mov		yl,#low(380)
;	mov		yh,#high(380)
;	mov		r2,#59h
;	lcall 	vputs32_h
loop:
	lcall	read_uart
	jb		buf_empty,check_clock
	cpl		red_led
	lcall	parse_cmd
	jnb		recv_cmd_ready,check_clock
;	setb	green_led
	clr		recv_cmd_ready
	mov		a,recv_cmd
	cjne	a,#OPEN_DIALOG,loop1
	clr		show_sys_clock
loop1:
	cjne	a,#CLOSE_DIALOG,check_clock
	setb	show_sys_clock
check_clock:
	jnb		clock_tick,loop
	clr		clock_tick

	lcall	update_clock
;	cpl		green_led
	sjmp	loop
day_conv:
	mov		a,day
	clr		c
	subb	a,#low(10000)
	mov		a,day+1
	subb	a,#high(10000)
	mov		r0,send_cmd_idx

	jc		day_conv_lbl1
	mov		a,#'9'
	movx	@r0,a
	inc		r0
	movx	@r0,a
	inc		r0
	movx	@r0,a
	inc		r0
	movx	@r0,a
	ljmp	day_conv_ret
day_conv_lbl1:
	mov		r1,#0
	mov		r4,day
	mov		r5,day+1
day_conv_lbl2:
	mov		a,r4
	clr		c
	subb	a,#low(1000)
	mov		a,r5
	subb	a,#high(1000)
	jc		day_conv_lbl3
	inc		r1
	mov		a,r4
	clr		c
	subb	a,#low(1000)
	mov		r4,a
	mov		a,r5
	subb	a,#high(1000)
	mov		r5,a
	sjmp	day_conv_lbl2
day_conv_lbl3:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	mov		r1,#0
	inc		r0
dc_lbl_51:
	mov		a,r4
	clr		c
	subb	a,#100
	mov		a,r5
	subb	a,#0
	jc		dc_lbl6
	mov		a,r4
	clr		c
	subb	a,#100
	mov		r4,a
	mov		a,r5
	subb	a,#0
	mov		r5,a
	inc		r1
	sjmp	dc_lbl_51
dc_lbl6:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a

	mov		r1,#0
	inc		r0
dc_lbl9:
	mov		a,r4
	clr		c
	subb	a,#10
	jc		dc_lbl10
	mov		r4,a
	inc		r1
	sjmp	dc_lbl9
dc_lbl10:
	mov		a,r1
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	inc		r0
	mov		a,r4
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
day_conv_ret:
	inc		r0
	mov		send_cmd_idx,r0
	ret
update_clock:
	mov		a,second
	cjne	a,#60,uc_show_clock
	mov		second,#0
	inc		minute
	mov		a,minute
	cjne	a,#60,uc_show_clock
	mov		minute,#0
	inc		hour
	mov		a,hour
	cjne	a,#24,uc_show_clock
	mov		hour,#0
	inc		day
	mov		a,day
	jnz		uc_show_clock
	inc		day+1
uc_show_clock:
	jb		show_sys_clock,uc_show_clock_1
	ret
uc_show_clock_1:
	mov		r0,#0
	mov		dptr,#running_time
uc_sc_1:
	mov		a,r0
	movc	a,@a+dptr
	movx	@r0,a
	inc		r0
	cjne	r0,#10,uc_sc_1
	mov		send_cmd_idx,r0
	
	
	mov		a,day+1
	jz		skip_1
	sjmp	skip_2
skip_1:
	mov		a,day
	jz		skip_3
skip_2:
	acall	day_conv
	mov		a,#0cch
	movx	@r0,a
	inc		r0
	mov		a,#0ech
	movx	@r0,a
	inc		r0
	mov		send_cmd_idx,r0
skip_3:
	
	mov		r0,send_cmd_idx
	mov		r2,hour
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,minute
	acall	hex_bcdascii
	inc		r0
	mov		a,#':'
	movx	@r0,a
	inc		r0
	mov		r2,second
	acall	hex_bcdascii
	inc		r0
	clr		a
	movx	@r0,a

	mov		xl,#40
	mov		xh,#0
	mov		yl,#low(380)
	mov		yh,#high(380)
	mov		r0,#0
	lcall	iputs32
	ret
;[in] r2
;[out] @r0
hex_bcdascii:
	mov		a,r2
	mov		r5,#0
	mov		r4,a
hbcd_1:
	clr		c
	subb	a,#10
	jc		hbcd_exit
	inc		r5
	mov		r4,a
	sjmp	hbcd_1
hbcd_exit:
	mov		a,r5
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	movx	@r0,a
	mov		a,r4
	mov		dptr,#hex_buf
	movc	a,@a+dptr
	inc		r0
	movx	@r0,a
	ret
iputs32:
	mov		r2,#55h
	sjmp	iputs
iputs24:
	mov		r2,#6fh
	sjmp	iputs
iputs16:
	mov		r2,#54h
; print string in i-ram
;[in] r2 command code 0x55 32,0x54 16, 0x6f 24
;@r0 string
iputs:
	mov		a,#0aah
	lcall	send_uart
	mov		a,r2
	lcall	send_uart
	mov		a,xh
	lcall	send_uart
	mov		a,xl
	lcall	send_uart
	mov		a,yh
	lcall	send_uart
	mov		a,yl
	lcall	send_uart
iputs_lbl1:
	movx	a,@r0
	jz		iputs_exit
	lcall	send_uart
	inc		r0
	sjmp	iputs_lbl1
iputs_exit:
	mov		a,#0cch
	lcall	send_uart
	mov		a,#33h
	lcall	send_uart
	mov		a,#0c3h
	lcall	send_uart
	mov		a,#3ch
	lcall	send_uart
	ret

; receive command function **********************************************************************
parse_cmd:
	mov		r2,a
	mov		a,recv_cmd_idx
	mov		dptr,#cmd_operate
	rl		a
	jmp		@a+dptr
cmd_operate:
	sjmp	byte1
	sjmp	byte2
	sjmp	byte3
	sjmp	byte4
	sjmp	byte5
	sjmp	byte6
	sjmp	byte7
;	sjmp	byte8
	cjne	r2,#3ch,bad_cmd
	setb	recv_cmd_ready
	mov		recv_cmd_idx,#0
	ret
byte1:

	cjne	r2,#0aah,bad_cmd
;	setb	green_led
byte2:
byte3:
	inc		recv_cmd_idx
	ret
byte4:
	mov		recv_cmd,r2
	inc		recv_cmd_idx
	ret
byte5:
	cjne	r2,#0cch,bad_cmd
	sjmp	byte3
byte6:
	cjne	r2,#33h,bad_cmd
	sjmp	byte3
byte7:
	cjne	r2,#0c3h,bad_cmd
	sjmp	byte3
	

	ret
bad_cmd:
	mov		recv_cmd_idx,#0
	clr		recv_cmd_ready
	ret
; receive command function end ******************************************************************

; uart funciont *********************************************************************************
read_uart:
; atom operate
	clr		ea
	mov		a,buf_first
	cjne	a,buf_last,ru_1
	setb	ea
	setb	buf_empty
;	setb	red_led
	ret
ru_1:
	setb	ea
	clr		buf_empty
	mov		r0,a
	inc		a

	cjne	a,#PIPO_TOP,ru_2
	mov		a,#PIPO_BUTTON
ru_2:
	mov		buf_first,a
	mov		a,@r0
	ret
uart0_int:
	jb		ri,uart_int_read
	reti
uart_int_read:
	clr		ri
	push	psw
	push	acc
	push	dpl
	push	dph
	setb	rs1
	setb	rs0
	mov		r0,buf_last
	mov		@r0,sbuf
	inc		r0
	mov		a,r0
	cjne	a,#PIPO_TOP,int_1
	mov		r0,#PIPO_BUTTON
int_1:
	mov		buf_last,r0
;	clr		red_led
int_exit:
	pop		dph
	pop		dpl
	pop		acc
	pop		psw
	reti
init_uart_02:
	; 8BIT START 1 STOP 1 
	; S0MODE =0
	; MCE0 = 1 
	; ren0 = 1 receive enable
;[S0MODE|-|MCE0|REN0|TB80|RB80|TI0|RI0]
	mov		scon,#00010000b

	; T1 mode 2
	; C/T1 = 0
	; T1M = 10 MODE 2 8bit counter/timer with auto-reload
	; 使用24.5Mhz,TH1=0x96 即可是uart0的baud rate=115200
	mov		a,tmod
	anl		a,#00001111b
	setb	acc.5
	mov		tmod,a
	
;	mov		tmod,#00100000b
	; TR1 timer 1 is enabled
	; [TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT0]
;	mov		TCON,#40h
	mov		a,TCON
	anl		a,#00110011b
	setb	acc.6
	mov		TCON,a
	;T1 = 1 uses the system clock
	mov		a,CKCON
	setb	acc.3
	mov		CKCON,a
;	mov		CKCON,#00001000b
	
	mov		TH1,#96h
;	mov		TL1,#96h
	
	; tx和rx使用crossbar
	mov		a,P0SKIP
	clr		acc.4
	clr		acc.5
	mov		P0SKIP,a
; p0.5 rx
; p0.4 tx
	mov		a,P0MDIN
	setb	acc.4
	setb	acc.5
	mov		P0MDIN,a
	mov		a,P0MDOUT
	setb	acc.4
	clr		acc.5
	mov		P0MDOUT,a

	; enable uart interrupt
	setb	es
	ret
send_uart:
	;acall	read_uart
;	setb	green_led
	mov		sbuf,a
	jnb		ti,$
	clr		ti
;	clr		green_led
	ret

; uart function end *********************************************************************

init:
	; set Internal oscillator
	; OSCICN [IOSCEN|IFRDY|SUSPEND|STSYNC|-|-|IFCN1|IFCN0]
	; IOSCEN 1:Internal High-Frequency Oscillator enabled
	; IFCN[1:0] 11:SYSCLK DERIVED FROM INTERNAL H-F OSCILLATOR divided by 1
	mov		OSCICN,#83h	; 3c3c   75 b2 81   u2.
	; SET oscillator source, use internal H-F Oscilator
	mov		CLKSEL,#0		; 3c3f   75 a9 00   u).

	; set Vdd Monitor Contorl
	mov		VDM0CN,#80h		; 3c42   75 ff 80   u..
	; TURN OFF WATCHDOG
	; PCA0MD[CIDL|WDTE|WDLCK|-|CPS2|CPS1+CPS-|ECF]
	; WDTE was set to 0
	anl		PCA0MD,#0bfh	; 3c45   53 d9 bf   SY?


	mov		a,#0ffh
	mov		P0SKIP,a
	mov		P1SKIP,a
	mov		P2SKIP,a
	
;	mov		a,#0
;	mov		r0,a
;init_1:
;	movx	@r0,a
;	djnz	r0,init_1
	ret
init_final:
	mov		XBR0,#1
	mov		XBR1,#40h			; enable Crossbar and weak pull-ups
	ret
init_led:
	mov		a,LED_MDIN
	setb	acc.3
	setb	acc.4
	mov		LED_MDIN,a
	mov		a,LED_MDOUT
	setb	acc.3
	setb	acc.4
	mov		LED_MDOUT,a
	ret
init_timer_01:
	; set timer0 to mode 1 16bit
	; C/T0 =0
	; GATE0=0
	mov		tmod,#1
	mov		tcon,#0
	;timer0 us /48 prescaler
	mov		ckcon,#2

	; enable timer0 overflow flag
	setb	et0
	setb	tr0

	ret
; hex to charaters
; [in] r2
;[out] r4,r5
htoc:
	mov		dptr,#hex_buf
	mov		a,r2
	swap	a
	anl		a,#0fh
	movc	a,@a+dptr
	mov		r4,a

	mov		dptr,#hex_buf
	mov		a,r2
	anl		a,#0fh
	movc	a,@a+dptr
	mov		r5,a

	ret
hex_buf:
	db "0123456789ABCDEF"
; "运行时间："
running_time:
	db 0d4h,0cbh,0d0h,0d0h,0cah,0b1h,0bch,0e4h,0a3h,0bah
long_long_delay:
	mov		temp3,#16
lld_1:
	lcall	long_delay
	djnz	temp3,lld_1

long_delay:
	mov		temp2,#0
ld_1:
	lcall	delay
	djnz	temp2,ld_1
delay:
	mov		temp1,#0
	djnz	temp1,$
	ret
end