
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


cur_char		equ	35h
fun_idx			equ	36h


PIPO_TOP		equ 0d0h
PIPO_BUTTON		equ	0c0h

LED_MDIN	equ	P1MDIN
LED_MDOUT	equ	P1MDOUT

; debug defination
debug_stop	bit	20h.7
debug_idx	equ	40h


	cseg	at 0
;
	ljmp	start
org 23h
	ljmp	uart0_int
org 7bh

start:
	clr		ea
	mov		sp,#0cfh
	mov		psw,#0


;	mov		cmd_stage,#0	;idle
	
;clr		debug_stop	

	lcall	init
	lcall	init_led
	lcall	init_uart
	lcall	init_final
	clr		red_led
	lcall	long_long_delay
	clr		green_led
	

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
	setb	ea
main_menu:
	mov		dptr,#welcome
	lcall	puts
loop:
	lcall	read_uart
	jb		buf_empty,loop
	lcall	send_uart
	cjne	a,#0dh,main_lbl_1
	mov		a,#0ah
	lcall	send_uart
	mov		a,fun_idx
	mov		dptr,#fun_select
	rl		a
	jmp		@a+dptr
	sjmp	loop
main_lbl_1:
	mov		dptr,#cmd_char
	mov		r0,#0
	mov		cur_char,a
	mov		fun_idx,#0
main_lbl_2:
	mov		a,r0
	inc		r0
	movc	a,@a+dptr
	jz		loop
	cjne	a,cur_char,main_lbl_2
	mov		fun_idx,r0
fun_select:
	sjmp	loop
	sjmp	fun_0
	sjmp	fun_1
;	sjmp	fun_2

fun_1:

fun_led:
; green led switch
	mov		dptr,#led_str
	lcall	puts
fl_1:
	lcall	read_uart
	jb		buf_empty,fl_1
	cjne	a,#'q',fl_2
	sjmp	main_menu
fl_2:
	cjne	a,#'0',fl_3
	clr		green_led
fl_3:
	cjne	a,#'1',fl_1
	setb	green_led
	sjmp	fl_1
	
fun_0:
	lcall	show_hex
	sjmp	loop
led_str:
	db 'LED switch',0dh,0ah,9,'0 - off',0dh,0ah,9,'1 - on',0dh,0ah,9,'q - return',0

welcome:
	db 0ah,0dh,'*********************',0ah,0dh,'*       Welcome     *',0ah,0dh,'*********************',0ah,0dh
menu:
	db '0 - show hex',0ah,0dh,'1 - green switch',0ah,0dh,'2 - red switch',0ah,0dh
	db 'Your choose?',0
answer:
	db 'chosen:',0
cmd_char:
	db '012',0

show_hex:
	lcall	read_uart
	jb		buf_empty,show_hex
; lcall	send_uart
	mov		r2,a
	lcall	htoc
	mov		a,#'-'
	lcall	send_uart
	mov		a,r4
	lcall	send_uart
	mov		a,r5
	lcall	send_uart
	mov		a,#' '
	lcall	send_uart
	sjmp	show_hex
	ret
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
init_uart:
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
	mov		tmod,#00100000b
	; TR1 timer 1 is enabled
	; [TF1|TR1|TF0|TR0|IE1|IT1|IE0|IT0]
	mov		TCON,#40h
	;T1 = 1 uses the system clock
	mov		CKCON,#00001000b
	
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
	
puts:
	clr		a
	movc	a,@a+dptr
	inc		dptr
	jz		puts_exit
	lcall	send_uart
	sjmp	puts
puts_exit:
	ret

xputs:
	mov		r0,#0
	movx	a,@r0
	inc		r0
	jz		xputs_exit
	lcall	send_uart
	sjmp	xputs
xputs_exit:
	ret


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

test_uart:
	jnb		ri,$
	clr		ri
	mov		a,sbuf
	movx	@r0,a
	cpl		red_led

	lcall	send_uart

	cpl		green_led
	inc		r0
	sjmp	test_uart
end